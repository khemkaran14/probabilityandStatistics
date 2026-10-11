import 'package:chance/services/key_value_store.dart';
import 'package:chance/services/purchase_service.dart';
import 'package:chance/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('levels', () {
    test('thresholds are 0, 100, 300, 600', () {
      expect([1, 2, 3, 4].map(xpForLevel), [0, 100, 300, 600]);
    });

    test('level and progress follow XP', () {
      final s = makeState();
      expect(s.level, 1);
      s.completeLesson('galton', correct: 3, total: 3); // 40 XP
      s.completeLesson('coin_flips', correct: 3, total: 3); // 80
      s.completeLesson('monty_hall', correct: 3, total: 3); // 120
      expect(s.xp, 120);
      expect(s.level, 2);
      expect(s.levelProgress, closeTo(20 / 200, 1e-9));
      expect(s.xpToNextLevel, 180);
    });
  });

  group('lesson rewards', () {
    test('first completion pays, replay pays nothing', () {
      final s = makeState();
      expect(s.completeLesson('galton', correct: 2, total: 3), lessonReward(2));
      expect(s.completeLesson('galton', correct: 3, total: 3), 0);
      expect(s.xp, 30);
      expect(s.completed, {'galton'});
      expect(s.perfect, {'galton'}, reason: 'a perfect replay still counts for the badge');
    });
  });

  group('streaks', () {
    test('consecutive days grow the streak, a gap resets it', () {
      final clock = TestClock(DateTime(2026, 3, 10, 23, 50));
      final s = makeState(clock: clock);
      s.completePractice(1);
      expect(s.currentStreak, 1);

      clock.advanceDays(1);
      s.completePractice(1);
      s.completePractice(1); // same day: no double count
      expect(s.currentStreak, 2);

      clock.advanceDays(1);
      s.completePractice(1);
      expect(s.currentStreak, 3);
      expect(s.bestStreak, 3);

      clock.advanceDays(2); // missed a whole day
      expect(s.currentStreak, 0, reason: 'shown as broken before any new activity');
      s.completePractice(1);
      expect(s.currentStreak, 1);
      expect(s.bestStreak, 3);
    });

    test('streak survives a DST change', () {
      // Europe/US DST shifts fall in March; day maths must use calendar days.
      final clock = TestClock(DateTime(2026, 3, 28, 12));
      final s = makeState(clock: clock);
      s.completePractice(1);
      clock.now = DateTime(2026, 3, 29, 12);
      s.completePractice(1);
      clock.now = DateTime(2026, 3, 30, 12);
      s.completePractice(1);
      expect(s.currentStreak, 3);
    });
  });

  group('daily goal & challenge', () {
    test('today XP counts toward the goal', () {
      final s = makeState()..setDailyGoal(20);
      expect(s.goalMetToday, isFalse);
      s.completeLesson('galton', correct: 1, total: 3); // 20 XP
      expect(s.todayXp, 20);
      expect(s.goalMetToday, isTrue);
    });

    test('challenge pays once per day', () {
      final clock = TestClock(DateTime(2026, 3, 10, 9));
      final s = makeState(clock: clock);
      expect(s.completeChallenge(4), challengeReward(4));
      expect(s.completeChallenge(5), 0);
      expect(s.challengesDone, 1);
      clock.advanceDays(1);
      expect(s.challengeDoneToday, isFalse);
      expect(s.completeChallenge(5), challengeReward(5));
      expect(s.challengesDone, 2);
    });

    test('recentDays lists 7 days oldest first with XP', () {
      final clock = TestClock(DateTime(2026, 3, 10, 9));
      final s = makeState(clock: clock);
      s.completePractice(2); // 10 XP on the 10th
      clock.advanceDays(2);
      s.completePractice(4); // 20 XP on the 12th
      final days = s.recentDays();
      expect(days.length, 7);
      expect(days.last.key, DateTime(2026, 3, 12));
      expect(days.last.value, 20);
      expect(days[4].value, 10);
      expect(days[5].value, 0);
    });
  });

  group('persistence', () {
    test('everything survives a restart', () {
      final store = MemoryStore();
      final clock = TestClock(DateTime(2026, 3, 10, 9));
      final a = makeState(store: store, clock: clock)
        ..setDailyGoal(100)
        ..setHaptics(false)
        ..setPremium(true);
      a.completeLesson('galton', correct: 3, total: 3);
      a.completeChallenge(3);

      final b = makeState(store: store, clock: clock, onboarded: false);
      expect(b.onboarded, isTrue);
      expect(b.xp, a.xp);
      expect(b.completed, {'galton'});
      expect(b.perfect, {'galton'});
      expect(b.dailyGoal, 100);
      expect(b.haptics, isFalse);
      expect(b.premium, isTrue);
      expect(b.challengeDoneToday, isTrue);
      expect(b.todayXp, a.todayXp);
      expect(b.currentStreak, 1);
    });

    test('corrupt history is ignored instead of crashing', () {
      final store = MemoryStore({'chance.history': 'not json', 'chance.xp': 'abc'});
      final s = makeState(store: store);
      expect(s.history, isEmpty);
      expect(s.xp, 0);
    });

    test('reset clears progress but keeps purchase and settings', () {
      final s = makeState()
        ..setPremium(true)
        ..setDailyGoal(20);
      s.completeLesson('galton', correct: 3, total: 3);
      s.resetProgress();
      expect(s.xp, 0);
      expect(s.completed, isEmpty);
      expect(s.currentStreak, 0);
      expect(s.premium, isTrue);
      expect(s.dailyGoal, 20);
      expect(s.onboarded, isTrue);
    });
  });

  group('premium', () {
    test('free lessons open without premium; premium opens all', () {
      final s = makeState();
      expect(s.canOpen('coin_flips'), isTrue, reason: 'chapter 3 is free');
      expect(s.canOpen('galton'), isTrue, reason: 'preview lesson');
      expect(s.canOpen('monty_hall'), isTrue, reason: 'preview lesson');
      expect(s.canOpen('clt_dice'), isFalse);
      s.setPremium(true);
      expect(s.canOpen('clt_dice'), isTrue);
    });

    test('buying unlocks, an unavailable store does not', () async {
      final s = makeState();
      expect(await s.buyPremium(), PurchaseOutcome.purchased);
      expect(s.premium, isTrue);

      final t = makeState(purchases: FakePurchaseService(available: false));
      expect(await t.buyPremium(), PurchaseOutcome.unavailable);
      expect(t.premium, isFalse);
    });
  });
}
