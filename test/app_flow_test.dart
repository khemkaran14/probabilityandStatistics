import 'package:chance/services/purchase_service.dart';
import 'package:chance/services/reminder_service.dart';
import 'package:chance/services/share_service.dart';
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
    final state = makeState(share: share);
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
}

final _settingsScroll =
    find.descendant(of: find.byKey(const ValueKey('settings-list')), matching: find.byType(Scrollable)).first;
