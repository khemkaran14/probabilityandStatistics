import 'package:chance/main.dart';
import 'package:chance/services/account_service.dart';
import 'package:chance/services/purchase_service.dart';
import 'package:chance/services/reminder_service.dart';
import 'package:chance/services/share_service.dart';
import 'package:chance/services/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('first launch shows onboarding, then the tabs', (tester) async {
    final state = makeState(onboarded: false);
    await pumpApp(tester, state);

    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Serious'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();

    expect(state.onboarded, isTrue);
    expect(state.dailyGoal, 100);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Practice'), findsWidgets);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('play a free lesson and finish its quiz for XP', (tester) async {
    final share = FakeShareService();
    final sounds = FakeSoundService();
    final state = makeState(share: share, sounds: sounds);
    await pumpApp(tester, state);

    // The "try the first lesson" card opens the first free lesson.
    await tester.tap(find.text('TRY THE FIRST LESSON'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Types of data ·'), findsOneWidget);

    // Let the animation run a little, then start the quiz.
    await tester.pump(const Duration(seconds: 2));
    final quizButton = find.textContaining('Quick check');
    await tester.scrollUntilVisible(quizButton, 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(quizButton);
    await tester.pumpAndSettle();

    await answerQuiz(tester, 3);

    // One sound per answer, then the finish fanfare.
    expect(sounds.played, hasLength(4));
    expect(sounds.played.take(3), everyElement(isIn([Sfx.correct, Sfx.wrong])));
    expect(sounds.played.last, Sfx.finish);
    expect(state.completed, contains('types_of_data'));
    expect(state.xp, greaterThanOrEqualTo(10));
    expect(find.textContaining('XP today'), findsOneWidget);

    await tester.tap(find.text('Share my score'));
    await tester.pumpAndSettle();
    expect(share.shared.single, contains('/3'));

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('UP NEXT'), findsOneWidget);
  });

  testWidgets('a locked lesson opens the paywall, buying unlocks it', (tester) async {
    final state = makeState(purchases: FakePurchaseService());
    await pumpApp(tester, state);

    final chapter = find.text('The big theorems');
    await tester.scrollUntilVisible(chapter, 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(chapter);
    await tester.pumpAndSettle();
    await tester.tap(chapter);
    await tester.pumpAndSettle();
    final lesson = find.text('Central Limit Theorem');
    await tester.ensureVisible(lesson);
    await tester.pumpAndSettle();
    await tester.tap(lesson);
    await tester.pumpAndSettle();

    expect(find.text('Unlock all of Chance'), findsOneWidget);
    await tester.tap(find.textContaining('Unlock everything'));
    await tester.pumpAndSettle();

    expect(state.premium, isTrue);
    expect(find.text('Unlock all of Chance'), findsNothing);

    // The chapter stays open and the lesson now plays.
    await tester.scrollUntilVisible(lesson, 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(lesson);
    await tester.pumpAndSettle();
    await tester.tap(lesson);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Central Limit Theorem ·'), findsOneWidget);
  });

  testWidgets('daily challenge pays once a day', (tester) async {
    final state = makeState();
    await pumpApp(tester, state);

    await tester.tap(find.text('Practice').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('daily-challenge')));
    await tester.pumpAndSettle();

    await answerQuiz(tester, 5);
    expect(state.challengesDone, 1);
    expect(state.xp, greaterThanOrEqualTo(20));

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Done for today!'), findsOneWidget);
  });

  testWidgets('progress and settings tabs render and reset works', (tester) async {
    final state = makeState();
    state.completeLesson('galton', correct: 3, total: 3);
    await pumpApp(tester, state);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('First steps'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final reset = find.text('Reset progress');
    await tester.scrollUntilVisible(reset, 300, scrollable: _settingsScroll);
    await tester.pumpAndSettle();
    await tester.tap(reset);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(state.xp, 0);
  });

  testWidgets('daily reminder: switch on, pick a time, skipped once the goal is met', (tester) async {
    final reminders = FakeReminderService();
    final state = makeState(reminders: reminders);
    await pumpApp(tester, state);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reminder-switch')));
    await tester.pumpAndSettle();
    expect(state.reminderOn, isTrue);
    expect(reminders.scheduled, (19, 0, false));

    await tester.tap(find.byKey(const ValueKey('reminder-time')));
    await tester.pumpAndSettle();
    expect(find.text('Remind me at'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    state.completePractice(10); // 50 XP meets the default goal
    await tester.pump();
    expect(reminders.scheduled, (19, 0, true));

    await tester.tap(find.byKey(const ValueKey('reminder-switch')));
    await tester.pumpAndSettle();
    expect(reminders.scheduled, isNull);
  });

  testWidgets('daily reminder stays off when notifications are refused', (tester) async {
    final state = makeState(reminders: FakeReminderService(grant: false));
    await pumpApp(tester, state);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reminder-switch')));
    await tester.pumpAndSettle();
    expect(state.reminderOn, isFalse);
    expect(find.textContaining('Allow them in your phone'), findsOneWidget);
  });

  testWidgets('tablets get a side rail instead of the bottom bar', (tester) async {
    final state = makeState();
    tester.view.physicalSize = const Size(2560, 1600); // 1280 × 800 dp landscape tablet
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChanceApp(state: state));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Daily reminder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('screen readers get a description of the animation and labelled controls', (tester) async {
    final handle = tester.ensureSemantics();
    final state = makeState();
    await pumpApp(tester, state);
    await tester.tap(find.text('TRY THE FIRST LESSON'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel(RegExp(r'^Animation: Labels or numbers\?')), findsOneWidget);
    expect(find.bySemanticsLabel('Speed triple'), findsOneWidget);
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('account: sign in is required, then the profile with a verified mobile', (tester) async {
    final accounts = FakeAccountService(nextUser: _asha);
    final state = makeState(accounts: accounts);
    await pumpApp(tester, state);

    // Signed out: only the sign-in screen.
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Learn'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('required-sign-in')));
    await tester.pumpAndSettle();

    // Profile setup: name from Google, can't continue without a verified mobile.
    expect(find.text('Complete your profile'), findsOneWidget);
    expect(find.text('Asha'), findsWidgets);
    expect(tester.widget<FilledButton>(_saveButton).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('phone-number')), '98765 43210');
    await tester.tap(find.byKey(const ValueKey('send-code')));
    await tester.pumpAndSettle();
    expect(accounts.codesSentTo, ['+919876543210']);

    await tester.enterText(find.byKey(const ValueKey('sms-code')), '000000');
    await tester.tap(find.byKey(const ValueKey('verify-code')));
    await tester.pumpAndSettle();
    expect(find.textContaining('code is not right'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('sms-code')), FakeAccountService.smsCode);
    await tester.tap(find.byKey(const ValueKey('verify-code')));
    await tester.pumpAndSettle();
    expect(find.text('Mobile number verified'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('marketing-consent')));
    await tester.tap(find.byKey(const ValueKey('marketing-consent')));
    await tester.pump();
    await tester.ensureVisible(_saveButton);
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Learn'), findsOneWidget);
    final saved = accounts.profiles['u1']!;
    expect((saved.name, saved.email, saved.phone, saved.marketingOptIn),
        ('Asha', 'asha@example.com', '+919876543210', true));
    expect(saved.consentAt, isNotNull);
  });

  testWidgets('account: a failed sign-in shows the reason', (tester) async {
    final state = makeState(accounts: FakeAccountService(failWith: const AccountException('No internet connection')));
    await pumpApp(tester, state);
    await tester.tap(find.byKey(const ValueKey('required-sign-in')));
    await tester.pumpAndSettle();
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('account: no sign-in at all when the build has no cloud project', (tester) async {
    final state = makeState();
    await pumpApp(tester, state);
    expect(find.text('Learn'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('google-sign-in')), findsNothing);
  });

  testWidgets('account: a returning learner signs in during onboarding and goes straight in', (tester) async {
    final accounts = FakeAccountService(nextUser: _ashaVerified);
    accounts.cloud['u1'] = {'xp': '700', 'completed': 'galton'};
    accounts.profiles['u1'] = const UserProfile(name: 'Asha', email: 'asha@example.com', phone: '+919876543210');
    final state = makeState(accounts: accounts, onboarded: false);
    await pumpApp(tester, state);
    await tester.tap(find.byKey(const ValueKey('onboarding-sign-in')));
    await tester.pumpAndSettle();
    expect(state.onboarded, isTrue);
    expect(state.xp, 700);
    expect(find.text('Learn'), findsOneWidget);
  });

  testWidgets('account: profile screen edits name and photo, then deletes the account', (tester) async {
    final accounts = FakeAccountService()..user = _ashaVerified;
    accounts.profiles['u1'] = const UserProfile(name: 'Asha', email: 'asha@example.com', phone: '+919876543210');
    final state = makeState(accounts: accounts);
    await state.refreshProfile();
    await pumpApp(tester, state);

    await tester.tap(find.byKey(const ValueKey('header-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);
    expect(find.text('+919876543210'), findsOneWidget);

    accounts.nextPhotoUrl = 'https://example.com/asha.jpg';
    await tester.tap(find.byKey(const ValueKey('change-photo')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('profile-name')), 'Asha K');
    await tester.ensureVisible(_saveButton);
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    expect(accounts.profiles['u1']!.name, 'Asha K');
    expect(accounts.profiles['u1']!.photoUrl, 'https://example.com/asha.jpg');

    await tester.ensureVisible(find.byKey(const ValueKey('delete-account')));
    await tester.tap(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(accounts.profiles, isEmpty);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('account screens fit a small 360 dp phone', (tester) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final accounts = FakeAccountService(nextUser: _asha);
    final state = makeState(accounts: accounts);
    await tester.pumpWidget(ChanceApp(state: state));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'sign-in screen');

    await tester.tap(find.byKey(const ValueKey('required-sign-in')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('phone-number')), '9876543210');
    await tester.ensureVisible(find.byKey(const ValueKey('send-code')));
    await tester.tap(find.byKey(const ValueKey('send-code')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'profile setup with code field');

    await tester.enterText(find.byKey(const ValueKey('sms-code')), FakeAccountService.smsCode);
    await tester.ensureVisible(find.byKey(const ValueKey('verify-code')));
    await tester.tap(find.byKey(const ValueKey('verify-code')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_saveButton);
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('header-profile')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'learn header with the profile photo');
  });

  testWidgets('account: free plan asks for the mobile number without SMS and has no upload', (tester) async {
    final accounts = FakeAccountService(nextUser: _asha, verifiesPhone: false, canUploadPhoto: false);
    final state = makeState(accounts: accounts);
    await pumpApp(tester, state);
    await tester.tap(find.byKey(const ValueKey('required-sign-in')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('send-code')), findsNothing);
    expect(find.byKey(const ValueKey('change-photo')), findsNothing);
    expect(find.text('Photo from your Google account'), findsOneWidget);
    expect(tester.widget<FilledButton>(_saveButton).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('phone-number')), '12345');
    await tester.pump();
    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('phone-number')), '9876543210');
    await tester.pump();
    await tester.ensureVisible(_saveButton);
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Learn'), findsOneWidget);
    expect(accounts.profiles['u1']!.phone, '+919876543210');
    expect(accounts.profiles['u1']!.phoneVerified, isFalse);
  });
}

final _settingsScroll =
    find.descendant(of: find.byKey(const ValueKey('settings-list')), matching: find.byType(Scrollable)).first;

const _asha = AccountUser(uid: 'u1', name: 'Asha', email: 'asha@example.com');
const _ashaVerified = AccountUser(uid: 'u1', name: 'Asha', email: 'asha@example.com', phone: '+919876543210');
final _saveButton =
    find.descendant(of: find.byKey(const ValueKey('save-profile')), matching: find.byType(FilledButton));
