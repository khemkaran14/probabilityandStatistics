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

      // Scroll through the whole page so every card is built and laid out.
      final quiz = find.textContaining('Quick check');
      await tester.scrollUntilVisible(quiz, 300, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(quiz, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
