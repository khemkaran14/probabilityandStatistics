import 'package:flutter/material.dart';

import 'package:chance/theme/app_theme.dart';

class Lesson {
  const Lesson(this.title, {this.id, this.preview = false});
  final String title;

  /// Set only for lessons that have a built animation.
  final String? id;

  /// Free to play even when its chapter is premium.
  final bool preview;

  bool isFreeIn(Chapter chapter) => chapter.free || preview;
}

class Chapter {
  const Chapter({
    required this.number,
    required this.title,
    required this.tagline,
    required this.free,
    required this.lessons,
  });

  final int number;
  final String title;
  final String tagline;
  final bool free;
  final List<Lesson> lessons;

  Color get color => AppColors.rainbow[(number - 1) % AppColors.rainbow.length];
}

const List<Chapter> kChapters = [
  Chapter(number: 1, title: 'Data & averages', tagline: 'Find the centre and the spread', free: true, lessons: [
    Lesson('Types of data', id: 'types_of_data'),
    Lesson('Mean, median, mode', id: 'averages'),
    Lesson('Range, variance & standard deviation', id: 'spread'),
    Lesson('Percentiles & quartiles', id: 'percentiles'),
    Lesson('Skew & shape', id: 'skew'),
    Lesson('Outliers', id: 'outliers'),
    Lesson('Z-scores', id: 'zscores'),
  ]),
  Chapter(number: 2, title: 'Seeing data', tagline: 'Charts that tell the truth', free: true, lessons: [
    Lesson('Bar & pie charts', id: 'bar_pie'),
    Lesson('Histograms', id: 'histograms'),
    Lesson('Box plots', id: 'box_plots'),
    Lesson('Scatter plots', id: 'scatter'),
    Lesson('Stem-and-leaf plots', id: 'stem_leaf'),
    Lesson('How graphs lie', id: 'graphs_lie'),
  ]),
  Chapter(number: 3, title: 'Probability basics', tagline: 'Chance, counted', free: true, lessons: [
    Lesson('Experiments, outcomes & events', id: 'events'),
    Lesson('Theory vs experiment: coin flips', id: 'coin_flips'),
    Lesson('The complement rule', id: 'complement'),
    Lesson('Addition rule & Venn diagrams', id: 'venn'),
    Lesson('Mutually exclusive events', id: 'mutually_exclusive'),
  ]),
  Chapter(number: 4, title: 'Counting', tagline: 'How many ways?', free: false, lessons: [
    Lesson('Multiplication principle', id: 'multiplication_principle'),
    Lesson('Permutations', id: 'permutations'),
    Lesson('Combinations', id: 'combinations'),
    Lesson('Arrangements with repeats', id: 'repeats'),
    Lesson('Pigeonhole principle', id: 'pigeonhole'),
    Lesson('The birthday paradox', id: 'birthday'),
  ]),
  Chapter(
      number: 5,
      title: 'Conditional probability',
      tagline: 'When new info changes the odds',
      free: false,
      lessons: [
        Lesson('Conditional probability', id: 'conditional'),
        Lesson('Independence', id: 'independence'),
        Lesson('Tree diagrams', id: 'tree_diagrams'),
        Lesson('Multiplication rule', id: 'multiplication_rule'),
        Lesson('Law of total probability', id: 'total_probability'),
        Lesson("Bayes' theorem: the medical test", id: 'bayes', preview: true),
        Lesson('Monty Hall', id: 'monty_hall', preview: true),
      ]),
  Chapter(number: 6, title: 'Random variables', tagline: 'Turning chance into numbers', free: false, lessons: [
    Lesson('Discrete vs continuous', id: 'discrete_continuous'),
    Lesson('PMF, PDF & CDF', id: 'pmf_cdf'),
    Lesson('Expected value', id: 'expected_value'),
    Lesson('Variance of a random variable', id: 'variance_rv'),
    Lesson('Linearity of expectation', id: 'linearity'),
  ]),
  Chapter(number: 7, title: 'Discrete distributions', tagline: 'Counting successes', free: false, lessons: [
    Lesson('Bernoulli trials', id: 'bernoulli'),
    Lesson('Binomial: the Galton board', id: 'galton', preview: true),
    Lesson('Geometric', id: 'geometric'),
    Lesson('Negative binomial', id: 'negative_binomial'),
    Lesson('Hypergeometric', id: 'hypergeometric'),
    Lesson('Poisson', id: 'poisson'),
    Lesson('Discrete uniform', id: 'discrete_uniform'),
  ]),
  Chapter(number: 8, title: 'Continuous distributions', tagline: 'Smooth curves of chance', free: false, lessons: [
    Lesson('Continuous uniform', id: 'continuous_uniform'),
    Lesson('The normal curve', id: 'normal_curve'),
    Lesson('Standard normal & z-tables', id: 'standard_normal'),
    Lesson('The 68-95-99.7 rule', id: 'rule_68_95'),
    Lesson('Exponential', id: 'exponential'),
    Lesson('Gamma & Beta', id: 'gamma_beta'),
    Lesson('t, chi-square & F', id: 't_chi_f'),
  ]),
  Chapter(number: 9, title: 'Two variables together', tagline: 'How things move together', free: false, lessons: [
    Lesson('Joint & marginal distributions', id: 'joint_marginal'),
    Lesson('Covariance', id: 'covariance'),
    Lesson('Correlation', id: 'correlation'),
    Lesson('Correlation vs causation', id: 'correlation_causation'),
  ]),
  Chapter(number: 10, title: 'The big theorems', tagline: 'Why averages are so reliable', free: false, lessons: [
    Lesson('Law of Large Numbers', id: 'coin_flips'),
    Lesson('Central Limit Theorem', id: 'clt_dice'),
    Lesson("Chebyshev's inequality", id: 'chebyshev'),
  ]),
  Chapter(number: 11, title: 'Sampling', tagline: 'Learning about everyone from a few', free: false, lessons: [
    Lesson('Population vs sample', id: 'population_sample'),
    Lesson('Sampling methods', id: 'sampling_methods'),
    Lesson('Sampling bias', id: 'sampling_bias'),
    Lesson('Sampling distributions', id: 'sampling_distributions'),
    Lesson('Standard error', id: 'standard_error'),
  ]),
  Chapter(number: 12, title: 'Estimation', tagline: 'Best guesses with honest error bars', free: false, lessons: [
    Lesson('Point estimates', id: 'point_estimates'),
    Lesson('Maximum likelihood', id: 'mle'),
    Lesson('Confidence intervals', id: 'confidence_intervals'),
    Lesson('Margin of error', id: 'margin_of_error'),
    Lesson('Choosing a sample size', id: 'sample_size'),
  ]),
  Chapter(number: 13, title: 'Hypothesis testing', tagline: 'Is it real or just luck?', free: false, lessons: [
    Lesson('Null vs alternative', id: 'null_alternative'),
    Lesson('p-values', id: 'p_values'),
    Lesson('Type I & Type II errors', id: 'type_errors'),
    Lesson('Statistical power', id: 'power'),
    Lesson('z-test', id: 'z_test'),
    Lesson('t-tests', id: 't_tests'),
    Lesson('Chi-square tests', id: 'chi_square'),
    Lesson('ANOVA', id: 'anova'),
  ]),
  Chapter(number: 14, title: 'Regression', tagline: 'Drawing the best line', free: false, lessons: [
    Lesson('Line of best fit', id: 'line_of_best_fit'),
    Lesson('Residuals', id: 'residuals'),
    Lesson('R-squared', id: 'r_squared'),
    Lesson('Multiple regression', id: 'multiple_regression'),
    Lesson('Logistic regression', id: 'logistic_regression'),
  ]),
  Chapter(number: 15, title: 'Bayesian thinking', tagline: 'Updating beliefs with evidence', free: false, lessons: [
    Lesson('Prior to posterior', id: 'prior_posterior'),
    Lesson('Updating with evidence', id: 'updating_evidence'),
    Lesson('Bayesian vs frequentist', id: 'bayes_vs_frequentist'),
  ]),
  Chapter(number: 16, title: 'Stats in the real world', tagline: 'A/B tests, simulations & AI', free: false, lessons: [
    Lesson('A/B testing'),
    Lesson('Monte Carlo simulation'),
    Lesson('Random walks'),
    Lesson('Markov chains'),
    Lesson('Probability in AI & ML'),
  ]),
  Chapter(number: 17, title: 'Paradoxes & puzzles', tagline: 'Where intuition fails', free: false, lessons: [
    Lesson('Monty Hall', id: 'monty_hall', preview: true),
    Lesson('Birthday paradox', id: 'birthday'),
    Lesson("Simpson's paradox"),
    Lesson("Gambler's fallacy"),
    Lesson('Base-rate fallacy'),
    Lesson('St. Petersburg paradox'),
  ]),
];

int get kLessonCount => kChapters.fold(0, (sum, c) => sum + c.lessons.length);

/// A lesson together with the chapter it is listed in.
class LessonRef {
  const LessonRef(this.chapter, this.lesson);
  final Chapter chapter;
  final Lesson lesson;

  bool get isFree => lesson.isFreeIn(chapter);
}

/// First catalogue entry for every lesson id. Some lessons appear in two
/// chapters (e.g. Monty Hall); the first listing decides where it "lives".
Map<String, LessonRef> get kLessonsById {
  final out = <String, LessonRef>{};
  for (final c in kChapters) {
    for (final l in c.lessons) {
      if (l.id != null) out.putIfAbsent(l.id!, () => LessonRef(c, l));
    }
  }
  return out;
}

/// A lesson id is free if any of its listings is free.
bool isLessonFree(String id) => kChapters.any(
      (c) => c.lessons.any((l) => l.id == id && l.isFreeIn(c)),
    );
