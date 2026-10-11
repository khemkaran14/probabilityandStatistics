import 'package:chance/main.dart';
import 'package:chance/services/key_value_store.dart';
import 'package:chance/services/purchase_service.dart';
import 'package:chance/services/share_service.dart';
import 'package:chance/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A controllable clock for streak tests.
class TestClock {
  TestClock(this.now);
  DateTime now;
  DateTime call() => now;
  void advanceDays(int days) => now = now.add(Duration(days: days));
}

AppState makeState({
  MemoryStore? store,
  TestClock? clock,
  PurchaseService? purchases,
  FakeShareService? share,
  bool onboarded = true,
}) {
  final s = AppState(
    store: store ?? MemoryStore(),
    purchases: purchases ?? FakePurchaseService(),
    share: share ?? FakeShareService(),
    clock: (clock ?? TestClock(DateTime(2026, 3, 10, 9))).call,
  );
  if (onboarded && !s.onboarded) s.finishOnboarding(goal: 50);
  return s;
}

/// Pumps the whole app on a phone-sized screen.
Future<void> pumpApp(WidgetTester tester, AppState state) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChanceApp(state: state));
  await tester.pumpAndSettle();
}

/// Answers every question of an open quiz with its first option.
Future<void> answerQuiz(WidgetTester tester, int questions) async {
  for (var q = 0; q < questions; q++) {
    await tester.tap(find.descendant(of: find.byType(ListView), matching: find.byType(InkWell)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(q < questions - 1 ? 'Next' : 'Finish'));
    await tester.pumpAndSettle();
  }
}
