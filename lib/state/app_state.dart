import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:chance/data/catalogue.dart';
import 'package:chance/services/key_value_store.dart';
import 'package:chance/services/purchase_service.dart';
import 'package:chance/services/reminder_service.dart';
import 'package:chance/services/share_service.dart';
import 'package:chance/services/sound_service.dart';

/// Daily XP goals offered in onboarding and settings.
const Map<int, String> kDailyGoals = {20: 'Casual', 50: 'Regular', 100: 'Serious'};

/// XP for finishing a lesson quiz the first time.
int lessonReward(int correct) => 10 + correct * 10;

/// XP for the daily challenge (once a day).
int challengeReward(int correct) => 20 + correct * 10;

/// XP per correct answer in free practice.
const int kPracticeXpPerCorrect = 5;

/// Total XP at which [level] starts: 0, 100, 300, 600, 1000, …
int xpForLevel(int level) => 50 * level * (level - 1);

String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

/// Whole calendar days from [from] to [to] (both yyyy-mm-dd), DST-safe.
int _daysBetween(String from, String to) =>
    DateTime.utc(int.parse(to.substring(0, 4)), int.parse(to.substring(5, 7)), int.parse(to.substring(8, 10)))
        .difference(DateTime.utc(
            int.parse(from.substring(0, 4)), int.parse(from.substring(5, 7)), int.parse(from.substring(8, 10))))
        .inDays;

/// Everything the learner has earned, saved on the device after every change.
class AppState extends ChangeNotifier {
  AppState({
    required this.store,
    required this.purchases,
    required this.share,
    ReminderService? reminders,
    SoundService? sounds,
    DateTime Function()? clock,
  })  : reminders = reminders ?? FakeReminderService(supported: false),
        sounds = sounds ?? FakeSoundService(),
        clock = clock ?? DateTime.now {
    _load();
    purchases.listen((premium) {
      if (premium) setPremium(true);
    });
    // Today's reminder is skipped once the goal is met, so refresh it on launch.
    _syncReminder();
  }

  final KeyValueStore store;
  final PurchaseService purchases;
  final ShareService share;
  final ReminderService reminders;
  final SoundService sounds;
  final DateTime Function() clock;

  static const _p = 'chance.';

  int xp = 0;
  Set<String> completed = {};
  Set<String> perfect = {};
  int streak = 0;
  int bestStreak = 0;
  String? lastActive;
  int dailyGoal = 50;
  Map<String, int> history = {};
  String? challengeDay;
  int challengesDone = 0;
  bool premium = false;
  bool onboarded = false;
  bool haptics = true;
  bool sound = true;
  bool reminderOn = false;
  int reminderHour = 19;
  int reminderMinute = 0;

  String get today => dayKey(clock());

  // ---------------------------------------------------------------- derived

  int get level {
    var l = 1;
    while (xp >= xpForLevel(l + 1)) {
      l++;
    }
    return l;
  }

  /// 0 → 1 progress through the current level.
  double get levelProgress {
    final start = xpForLevel(level);
    final end = xpForLevel(level + 1);
    return (xp - start) / (end - start);
  }

  int get xpToNextLevel => xpForLevel(level + 1) - xp;

  int get todayXp => history[today] ?? 0;

  bool get goalMetToday => todayXp >= dailyGoal;

  /// The streak as it should be shown now: it breaks once a whole day
  /// passes with no activity.
  int get currentStreak {
    if (lastActive == null) return 0;
    return _daysBetween(lastActive!, today) <= 1 ? streak : 0;
  }

  bool get challengeDoneToday => challengeDay == today;

  /// XP per day for the last [days] days, oldest first.
  List<MapEntry<DateTime, int>> recentDays([int days = 7]) {
    final now = clock();
    return [
      for (var i = days - 1; i >= 0; i--)
        MapEntry(
          DateTime(now.year, now.month, now.day - i),
          history[dayKey(DateTime(now.year, now.month, now.day - i))] ?? 0,
        ),
    ];
  }

  bool canOpen(String lessonId) => premium || isLessonFree(lessonId);

  // ---------------------------------------------------------------- actions

  /// Records quiz results. Returns the XP awarded (0 on a replay).
  int completeLesson(String lessonId, {required int correct, required int total}) {
    if (correct == total) perfect = {...perfect, lessonId};
    if (completed.contains(lessonId)) {
      _save();
      notifyListeners();
      return 0;
    }
    completed = {...completed, lessonId};
    final reward = lessonReward(correct);
    _addXp(reward);
    return reward;
  }

  /// Records the daily challenge. Returns XP awarded (0 if already done today).
  int completeChallenge(int correct) {
    if (challengeDoneToday) return 0;
    challengeDay = today;
    challengesDone++;
    final reward = challengeReward(correct);
    _addXp(reward);
    return reward;
  }

  /// Free practice. Returns XP awarded.
  int completePractice(int correct) {
    final reward = correct * kPracticeXpPerCorrect;
    if (reward > 0) _addXp(reward);
    return reward;
  }

  void _addXp(int amount) {
    final day = today;
    if (lastActive != day) {
      streak = (lastActive != null && _daysBetween(lastActive!, day) == 1) ? streak + 1 : 1;
      bestStreak = math.max(bestStreak, streak);
      lastActive = day;
    }
    final goalWasMet = goalMetToday;
    xp += amount;
    history = {...history, day: (history[day] ?? 0) + amount};
    _save();
    notifyListeners();
    if (!goalWasMet && goalMetToday) _syncReminder();
  }

  void setDailyGoal(int goal) {
    dailyGoal = goal;
    _save();
    notifyListeners();
    _syncReminder();
  }

  void setSound(bool value) {
    sound = value;
    _save();
    notifyListeners();
  }

  /// Plays [sfx] unless sound effects are switched off.
  void playSound(Sfx sfx) {
    if (sound) sounds.play(sfx);
  }

  /// Turns the daily reminder on (asking for permission first) or off.
  /// Returns whether it is on afterwards.
  Future<bool> setReminder(bool on) async {
    if (on && !(reminders.supported && await reminders.requestPermission())) return false;
    reminderOn = on;
    _save();
    notifyListeners();
    await _syncReminder();
    return reminderOn;
  }

  void setReminderTime(int hour, int minute) {
    reminderHour = hour;
    reminderMinute = minute;
    _save();
    notifyListeners();
    _syncReminder();
  }

  /// The text of the next reminder.
  String get reminderBody => currentStreak > 0
      ? 'Keep your streak going: one 2-minute lesson is enough.'
      : 'One short animated lesson a day builds real intuition.';

  /// Schedules or cancels the reminder to match the settings. The reminder
  /// skips today once the daily goal is met.
  Future<void> _syncReminder() async {
    if (!reminders.supported) return;
    try {
      if (!reminderOn) return await reminders.cancel();
      await reminders.scheduleDaily(
        hour: reminderHour,
        minute: reminderMinute,
        skipToday: goalMetToday,
        title: 'Time for a quick lesson',
        body: reminderBody,
      );
    } on Object catch (e) {
      // A reminder that fails to schedule must never break the app.
      debugPrint('Reminder not scheduled: $e');
    }
  }

  void setHaptics(bool value) {
    haptics = value;
    _save();
    notifyListeners();
  }

  void finishOnboarding({required int goal}) {
    dailyGoal = goal;
    onboarded = true;
    _save();
    notifyListeners();
  }

  void setPremium(bool value) {
    if (premium == value) return;
    premium = value;
    _save();
    notifyListeners();
  }

  Future<PurchaseOutcome> buyPremium() => _unlockVia(purchases.buy);

  Future<PurchaseOutcome> restorePurchases() => _unlockVia(purchases.restore);

  Future<PurchaseOutcome> _unlockVia(Future<PurchaseOutcome> Function() action) async {
    final outcome = await action();
    if (outcome == PurchaseOutcome.purchased || outcome == PurchaseOutcome.restored) setPremium(true);
    return outcome;
  }

  /// Wipes learning progress. Keeps premium, onboarding and settings.
  void resetProgress() {
    xp = 0;
    completed = {};
    perfect = {};
    streak = 0;
    bestStreak = 0;
    lastActive = null;
    history = {};
    challengeDay = null;
    challengesDone = 0;
    _save();
    notifyListeners();
    _syncReminder();
  }

  // ------------------------------------------------------------ persistence

  void _load() {
    String? s(String k) => store.getString('$_p$k');
    int i(String k, int fallback) => int.tryParse(s(k) ?? '') ?? fallback;
    Set<String> set(String k) {
      final v = s(k);
      return v == null || v.isEmpty ? <String>{} : v.split(',').toSet();
    }

    xp = i('xp', 0);
    completed = set('completed');
    perfect = set('perfect');
    streak = i('streak', 0);
    bestStreak = i('bestStreak', 0);
    lastActive = s('lastActive');
    dailyGoal = i('dailyGoal', 50);
    challengeDay = s('challengeDay');
    challengesDone = i('challengesDone', 0);
    premium = s('premium') == 'true';
    onboarded = s('onboarded') == 'true';
    haptics = s('haptics') != 'false';
    sound = s('sound') != 'false';
    reminderOn = s('reminderOn') == 'true';
    reminderHour = i('reminderHour', 19).clamp(0, 23);
    reminderMinute = i('reminderMinute', 0).clamp(0, 59);
    try {
      final raw = jsonDecode(s('history') ?? '{}') as Map<String, dynamic>;
      history = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
    } on Object {
      history = {};
    }
  }

  void _save() {
    // Keep two months of daily history.
    final cutoff = dayKey(clock().subtract(const Duration(days: 60)));
    history.removeWhere((k, _) => k.compareTo(cutoff) < 0);

    final values = <String, String?>{
      'xp': '$xp',
      'completed': completed.join(','),
      'perfect': perfect.join(','),
      'streak': '$streak',
      'bestStreak': '$bestStreak',
      'lastActive': lastActive,
      'dailyGoal': '$dailyGoal',
      'history': jsonEncode(history),
      'challengeDay': challengeDay,
      'challengesDone': '$challengesDone',
      'premium': '$premium',
      'onboarded': '$onboarded',
      'haptics': '$haptics',
      'sound': '$sound',
      'reminderOn': '$reminderOn',
      'reminderHour': '$reminderHour',
      'reminderMinute': '$reminderMinute',
    };
    values.forEach((k, v) => v == null ? store.remove('$_p$k') : store.setString('$_p$k', v));
  }

  @override
  void dispose() {
    purchases.dispose();
    super.dispose();
  }
}

/// Makes [AppState] available to the widget tree and rebuilds dependants
/// when it changes.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Access without subscribing to changes (for callbacks).
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
