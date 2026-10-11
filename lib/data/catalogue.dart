import 'package:flutter/material.dart';

import 'package:chance/theme/app_theme.dart';

class Lesson {
  const Lesson(this.title, {this.id});
  final String title;

  /// Set only for lessons that have a built animation.
  final String? id;
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
    Lesson('Types of data'),
    Lesson('Mean, median, mode'),
    Lesson('Range, variance & standard deviation'),
    Lesson('Percentiles & quartiles'),
    Lesson('Skew & shape'),
    Lesson('Outliers'),
    Lesson('Z-scores'),
  ]),
  Chapter(number: 2, title: 'Seeing data', tagline: 'Charts that tell the truth', free: true, lessons: [
    Lesson('Bar & pie charts'),
    Lesson('Histograms'),
    Lesson('Box plots'),
    Lesson('Scatter plots'),
    Lesson('Stem-and-leaf plots'),
    Lesson('How graphs lie'),
  ]),
  Chapter(number: 3, title: 'Probability basics', tagline: 'Chance, counted', free: true, lessons: [
    Lesson('Experiments, outcomes & events'),
    Lesson('Theory vs experiment: coin flips'),
    Lesson('The complement rule'),
    Lesson('Addition rule & Venn diagrams'),
    Lesson('Mutually exclusive events'),
  ]),
  Chapter(number: 4, title: 'Counting', tagline: 'How many ways?', free: false, lessons: [
    Lesson('Multiplication principle'),
    Lesson('Permutations'),
    Lesson('Combinations'),
    Lesson('Arrangements with repeats'),
    Lesson('Pigeonhole principle'),
    Lesson('The birthday paradox'),
  ]),
  Chapter(number: 5, title: 'Conditional probability', tagline: 'When new info changes the odds', free: false, lessons: [
    Lesson('Conditional probability'),
    Lesson('Independence'),
    Lesson('Tree diagrams'),
    Lesson('Multiplication rule'),
    Lesson('Law of total probability'),
    Lesson("Bayes' theorem: the medical test"),
    Lesson('Monty Hall'),
  ]),
  Chapter(number: 6, title: 'Random variables', tagline: 'Turning chance into numbers', free: false, lessons: [
    Lesson('Discrete vs continuous'),
    Lesson('PMF, PDF & CDF'),
    Lesson('Expected value'),
    Lesson('Variance of a random variable'),
    Lesson('Linearity of expectation'),
  ]),
  Chapter(number: 7, title: 'Discrete distributions', tagline: 'Counting successes', free: false, lessons: [
    Lesson('Bernoulli trials'),
    Lesson('Binomial: the Galton board', id: 'galton'),
    Lesson('Geometric'),
    Lesson('Negative binomial'),
    Lesson('Hypergeometric'),
    Lesson('Poisson'),
    Lesson('Discrete uniform'),
  ]),
  Chapter(number: 8, title: 'Continuous distributions', tagline: 'Smooth curves of chance', free: false, lessons: [
    Lesson('Continuous uniform'),
    Lesson('The normal curve'),
    Lesson('Standard normal & z-tables'),
    Lesson('The 68-95-99.7 rule'),
    Lesson('Exponential'),
    Lesson('Gamma & Beta'),
    Lesson('t, chi-square & F'),
  ]),
  Chapter(number: 9, title: 'Two variables together', tagline: 'How things move together', free: false, lessons: [
    Lesson('Joint & marginal distributions'),
    Lesson('Covariance'),
    Lesson('Correlation'),
    Lesson('Correlation vs causation'),
  ]),
  Chapter(number: 10, title: 'The big theorems', tagline: 'Why averages are so reliable', free: false, lessons: [
    Lesson('Law of Large Numbers'),
    Lesson('Central Limit Theorem'),
    Lesson("Chebyshev's inequality"),
  ]),
  Chapter(number: 11, title: 'Sampling', tagline: 'Learning about everyone from a few', free: false, lessons: [
    Lesson('Population vs sample'),
    Lesson('Sampling methods'),
    Lesson('Sampling bias'),
    Lesson('Sampling distributions'),
    Lesson('Standard error'),
  ]),
  Chapter(number: 12, title: 'Estimation', tagline: 'Best guesses with honest error bars', free: false, lessons: [
    Lesson('Point estimates'),
    Lesson('Maximum likelihood'),
    Lesson('Confidence intervals'),
    Lesson('Margin of error'),
    Lesson('Choosing a sample size'),
  ]),
  Chapter(number: 13, title: 'Hypothesis testing', tagline: 'Is it real or just luck?', free: false, lessons: [
    Lesson('Null vs alternative'),
    Lesson('p-values'),
    Lesson('Type I & Type II errors'),
    Lesson('Statistical power'),
    Lesson('z-test'),
    Lesson('t-tests'),
    Lesson('Chi-square tests'),
    Lesson('ANOVA'),
  ]),
  Chapter(number: 14, title: 'Regression', tagline: 'Drawing the best line', free: false, lessons: [
    Lesson('Line of best fit'),
    Lesson('Residuals'),
    Lesson('R-squared'),
    Lesson('Multiple regression'),
    Lesson('Logistic regression'),
  ]),
  Chapter(number: 15, title: 'Bayesian thinking', tagline: 'Updating beliefs with evidence', free: false, lessons: [
    Lesson('Prior to posterior'),
    Lesson('Updating with evidence'),
    Lesson('Bayesian vs frequentist'),
  ]),
  Chapter(number: 16, title: 'Stats in the real world', tagline: 'A/B tests, simulations & AI', free: false, lessons: [
    Lesson('A/B testing'),
    Lesson('Monte Carlo simulation'),
    Lesson('Random walks'),
    Lesson('Markov chains'),
    Lesson('Probability in AI & ML'),
  ]),
  Chapter(number: 17, title: 'Paradoxes & puzzles', tagline: 'Where intuition fails', free: false, lessons: [
    Lesson('Monty Hall'),
    Lesson('Birthday paradox'),
    Lesson("Simpson's paradox"),
    Lesson("Gambler's fallacy"),
    Lesson('Base-rate fallacy'),
    Lesson('St. Petersburg paradox'),
  ]),
];

int get kLessonCount => kChapters.fold(0, (sum, c) => sum + c.lessons.length);
