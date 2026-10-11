import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/averages.dart';
import 'package:chance/lessons/bayes_test.dart';
import 'package:chance/lessons/clt_dice.dart';
import 'package:chance/lessons/coin_flips.dart';
import 'package:chance/lessons/galton_board.dart';
import 'package:chance/lessons/monty_hall.dart';
import 'package:chance/lessons/outliers.dart';
import 'package:chance/lessons/percentiles.dart';
import 'package:chance/lessons/skew.dart';
import 'package:chance/lessons/spread.dart';
import 'package:chance/lessons/types_of_data.dart';
import 'package:chance/lessons/venn.dart';
import 'package:chance/lessons/zscores.dart';

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
    typesOfDataLesson,
    percentilesLesson,
    skewLesson,
    outliersLesson,
    zScoresLesson,
  ])
    spec.id: spec,
};
