import 'package:chance/data/why.dart';
import 'package:chance/lessons/registry.dart';
import 'package:chance/screens/lesson_screen.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  for (final spec in lessonRegistry.values) {
    testWidgets('${spec.id}: animates and lays out on a small phone', (tester) async {
      // 360 × 740 dp: a small Android phone.
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        AppScope(
          state: makeState(),
          child: MaterialApp(theme: buildAppTheme(), home: LessonScreen(spec: spec)),
        ),
      );
      // Run the animation for 5 seconds of frames.
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Open the "why" panel, then scroll through the whole page so every
      // card is built and laid out.
      final why = find.byKey(const ValueKey('why-toggle'));
      await tester.scrollUntilVisible(why, 300, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(why);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(why);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(kWhy[spec.id]!), findsOneWidget);
      final quiz = find.textContaining('Quick check');
      // The list only learns its true length once the last cards are laid
      // out, so scroll again until the button stays on screen.
      for (var tries = 0; tries < 3 && (tries == 0 || quiz.evaluate().isEmpty); tries++) {
        await tester.scrollUntilVisible(quiz, 300, scrollable: find.byType(Scrollable).first);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(quiz, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
