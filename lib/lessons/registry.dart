import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/averages.dart';
import 'package:chance/lessons/bayes_test.dart';
import 'package:chance/lessons/clt_dice.dart';
import 'package:chance/lessons/coin_flips.dart';
import 'package:chance/lessons/galton_board.dart';
import 'package:chance/lessons/monty_hall.dart';
import 'package:chance/lessons/spread.dart';
import 'package:chance/lessons/venn.dart';

/// Every lesson with a built animation, keyed by its catalogue id.
/// Add new lessons here as they're built.
final Map<String, LessonSpec> lessonRegistry = {
  for (final spec in [
    averagesLesson,
    spreadLesson,
    coinFlipsLesson,
    vennLesson,
    bayesLesson,
    montyHallLesson,
    galtonLesson,
    cltLesson,
  ])
    spec.id: spec,
};
