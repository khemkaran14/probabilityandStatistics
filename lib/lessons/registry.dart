import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/clt_dice.dart';
import 'package:chance/lessons/coin_flips.dart';
import 'package:chance/lessons/galton_board.dart';
import 'package:chance/lessons/monty_hall.dart';

/// Every lesson with a built animation, keyed by its catalogue id.
/// Add new lessons here as they're built.
final Map<String, LessonSpec> lessonRegistry = {
  for (final spec in [coinFlipsLesson, montyHallLesson, galtonLesson, cltLesson]) spec.id: spec,
};
