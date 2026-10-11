import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/arrangements_repeats.dart';
import 'package:chance/lessons/averages.dart';
import 'package:chance/lessons/bar_pie.dart';
import 'package:chance/lessons/bayes_test.dart';
import 'package:chance/lessons/birthday.dart';
import 'package:chance/lessons/box_plots.dart';
import 'package:chance/lessons/ch07_discrete.dart';
import 'package:chance/lessons/ch08_continuous.dart';
import 'package:chance/lessons/clt_dice.dart';
import 'package:chance/lessons/coin_flips.dart';
import 'package:chance/lessons/combinations.dart';
import 'package:chance/lessons/complement.dart';
import 'package:chance/lessons/conditional.dart';
import 'package:chance/lessons/discrete_continuous.dart';
import 'package:chance/lessons/events.dart';
import 'package:chance/lessons/expected_value.dart';
import 'package:chance/lessons/galton_board.dart';
import 'package:chance/lessons/graphs_lie.dart';
import 'package:chance/lessons/histograms.dart';
import 'package:chance/lessons/independence.dart';
import 'package:chance/lessons/linearity.dart';
import 'package:chance/lessons/monty_hall.dart';
import 'package:chance/lessons/multiplication_principle.dart';
import 'package:chance/lessons/multiplication_rule.dart';
import 'package:chance/lessons/mutually_exclusive.dart';
import 'package:chance/lessons/outliers.dart';
import 'package:chance/lessons/percentiles.dart';
import 'package:chance/lessons/permutations.dart';
import 'package:chance/lessons/pigeonhole.dart';
import 'package:chance/lessons/pmf_cdf.dart';
import 'package:chance/lessons/scatter.dart';
import 'package:chance/lessons/skew.dart';
import 'package:chance/lessons/spread.dart';
import 'package:chance/lessons/stem_leaf.dart';
import 'package:chance/lessons/total_probability.dart';
import 'package:chance/lessons/tree_diagrams.dart';
import 'package:chance/lessons/types_of_data.dart';
import 'package:chance/lessons/variance_rv.dart';
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
    barPieLesson,
    histogramsLesson,
    boxPlotsLesson,
    scatterLesson,
    stemLeafLesson,
    graphsLieLesson,
    eventsLesson,
    complementLesson,
    mutuallyExclusiveLesson,
    multiplicationPrincipleLesson,
    permutationsLesson,
    combinationsLesson,
    repeatsLesson,
    pigeonholeLesson,
    birthdayLesson,
    conditionalLesson,
    independenceLesson,
    treeDiagramsLesson,
    multiplicationRuleLesson,
    totalProbabilityLesson,
    discreteContinuousLesson,
    pmfCdfLesson,
    expectedValueLesson,
    varianceRvLesson,
    linearityLesson,
    bernoulliLesson,
    geometricLesson,
    negativeBinomialLesson,
    hypergeometricLesson,
    poissonLesson,
    discreteUniformLesson,
    continuousUniformLesson,
    normalCurveLesson,
    standardNormalLesson,
    ruleLesson,
    exponentialLesson,
    gammaBetaLesson,
    tChiFLesson,
  ])
    spec.id: spec,
};
