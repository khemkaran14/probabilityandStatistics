// Chance – single-file preview for DartPad. Generated; edit lib/ instead.

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// ===== lib/main.dart =====
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final backends = await Backends.create();
  final state = AppState(
    store: backends.store,
    purchases: backends.purchases,
    share: backends.share,
    reminders: backends.reminders,
  );
  runApp(ChanceApp(state: state));
}

class ChanceApp extends StatelessWidget {
  const ChanceApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Chance',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _Root(),
      ),
    );
  }
}

/// Onboarding on first launch, the tabbed app afterwards.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final onboarded = AppScope.of(context).onboarded;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: onboarded ? const ShellScreen() : const OnboardingScreen(),
    );
  }
}

// ===== lib/data/achievements.dart =====
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.earned,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool Function(AppState s) earned;
}

final List<Achievement> kAchievements = [
  Achievement(
    id: 'first_lesson',
    title: 'First steps',
    description: 'Finish your first lesson',
    icon: Icons.flag_rounded,
    color: AppColors.green,
    earned: (s) => s.completed.isNotEmpty,
  ),
  Achievement(
    id: 'perfect',
    title: 'Sharp mind',
    description: 'Get every quiz question right',
    icon: Icons.verified_rounded,
    color: AppColors.violet,
    earned: (s) => s.perfect.isNotEmpty,
  ),
  Achievement(
    id: 'free_tour',
    title: 'Free tour',
    description: 'Finish every free lesson',
    icon: Icons.map_rounded,
    color: AppColors.cyan,
    earned: (s) => lessonRegistry.keys.where(isLessonFree).every(s.completed.contains),
  ),
  Achievement(
    id: 'all_lessons',
    title: 'Completionist',
    description: 'Finish every animated lesson',
    icon: Icons.workspace_premium_rounded,
    color: AppColors.orange,
    earned: (s) => lessonRegistry.keys.every(s.completed.contains),
  ),
  Achievement(
    id: 'streak3',
    title: 'On fire',
    description: 'Reach a 3-day streak',
    icon: Icons.local_fire_department_rounded,
    color: AppColors.orange,
    earned: (s) => s.bestStreak >= 3,
  ),
  Achievement(
    id: 'streak7',
    title: 'Week warrior',
    description: 'Reach a 7-day streak',
    icon: Icons.whatshot_rounded,
    color: AppColors.pink,
    earned: (s) => s.bestStreak >= 7,
  ),
  Achievement(
    id: 'challenge1',
    title: 'Challenger',
    description: 'Finish a daily challenge',
    icon: Icons.bolt_rounded,
    color: AppColors.yellow,
    earned: (s) => s.challengesDone >= 1,
  ),
  Achievement(
    id: 'challenge10',
    title: 'Regular',
    description: 'Finish 10 daily challenges',
    icon: Icons.event_available_rounded,
    color: AppColors.blue,
    earned: (s) => s.challengesDone >= 10,
  ),
  Achievement(
    id: 'xp500',
    title: 'Level climber',
    description: 'Earn 500 XP',
    icon: Icons.trending_up_rounded,
    color: AppColors.green,
    earned: (s) => s.xp >= 500,
  ),
  Achievement(
    id: 'supporter',
    title: 'Supporter',
    description: 'Unlock all lessons',
    icon: Icons.favorite_rounded,
    color: AppColors.pink,
    earned: (s) => s.premium,
  ),
];

// ===== lib/data/catalogue.dart =====
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
    Lesson('A/B testing', id: 'ab_testing'),
    Lesson('Monte Carlo simulation', id: 'monte_carlo'),
    Lesson('Random walks', id: 'random_walks'),
    Lesson('Markov chains', id: 'markov_chains'),
    Lesson('Probability in AI & ML', id: 'ai_ml'),
  ]),
  Chapter(number: 17, title: 'Paradoxes & puzzles', tagline: 'Where intuition fails', free: false, lessons: [
    Lesson('Monty Hall', id: 'monty_hall', preview: true),
    Lesson('Birthday paradox', id: 'birthday'),
    Lesson("Simpson's paradox", id: 'simpsons'),
    Lesson("Gambler's fallacy", id: 'gamblers_fallacy'),
    Lesson('Base-rate fallacy', id: 'bayes'),
    Lesson('St. Petersburg paradox', id: 'st_petersburg'),
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

// ===== lib/data/practice_bank.dart =====
/// General questions for the daily challenge, on top of lesson quizzes.
const List<QuizQuestion> kPracticeBank = [
  QuizQuestion(
    prompt: 'What is the mean of 2, 4, 4, 5 and 10?',
    options: ['4', '5', '4.5', '10'],
    answer: 1,
    explanation: '(2 + 4 + 4 + 5 + 10) / 5 = 25 / 5 = 5.',
  ),
  QuizQuestion(
    prompt: 'What is the median of 2, 4, 4, 5 and 10?',
    options: ['4', '5', '4.5', '2'],
    answer: 0,
    explanation: 'Sorted, the middle value of five numbers is the 3rd one: 4. '
        'Unlike the mean, the median ignores how big the 10 is.',
  ),
  QuizQuestion(
    prompt: 'You roll a fair die. What is P(not a 6)?',
    options: ['1/6', '1/2', '5/6', '6/5'],
    answer: 2,
    explanation: 'Complement rule: 1 − P(6) = 1 − 1/6 = 5/6.',
  ),
  QuizQuestion(
    prompt: 'You flip two fair coins. What is P(both heads)?',
    options: ['1/2', '1/3', '1/4', '2/3'],
    answer: 2,
    explanation: 'Independent events multiply: 1/2 × 1/2 = 1/4. '
        'Outcomes: HH, HT, TH, TT.',
  ),
  QuizQuestion(
    prompt: 'How many ways can 3 people stand in a line?',
    options: ['3', '6', '9', '27'],
    answer: 1,
    explanation: '3 choices for first, 2 for second, 1 for last: 3! = 6.',
  ),
  QuizQuestion(
    prompt: 'How many 2-person teams can you pick from 5 people?',
    options: ['10', '20', '25', '5'],
    answer: 0,
    explanation: 'Order doesn\'t matter: C(5, 2) = 5 × 4 / 2 = 10.',
  ),
  QuizQuestion(
    prompt: 'A dataset has a few very large values. Which is pulled up the most?',
    options: ['The median', 'The mode', 'The mean', 'None of them'],
    answer: 2,
    explanation: 'The mean uses every value\'s size, so outliers drag it. '
        'That\'s why incomes are usually reported as medians.',
  ),
  QuizQuestion(
    prompt: 'Roughly what share of a normal distribution lies within 1 sd of the mean?',
    options: ['50%', '68%', '95%', '99.7%'],
    answer: 1,
    explanation: 'The 68-95-99.7 rule: about 68% within 1 sd, 95% within 2, '
        '99.7% within 3.',
  ),
  QuizQuestion(
    prompt: 'Ice-cream sales and drownings rise together. The best explanation?',
    options: [
      'Ice cream causes drowning',
      'Drowning causes ice-cream sales',
      'Hot weather drives both',
      'It must be a coincidence',
    ],
    answer: 2,
    explanation: 'Correlation is not causation. A hidden third variable '
        '(summer heat) pushes both up.',
  ),
  QuizQuestion(
    prompt: 'In a room of 23 people, the chance two share a birthday is about…',
    options: ['6%', '25%', '50%', '90%'],
    answer: 2,
    explanation: 'The birthday paradox: 23 people make 253 pairs, which is '
        'plenty of chances for a match.',
  ),
  QuizQuestion(
    prompt: 'A z-score of −2 means the value is…',
    options: [
      '2 below the mean',
      '2 standard deviations below the mean',
      'In the bottom 2%',
      'An error',
    ],
    answer: 1,
    explanation: 'z = (x − mean) / sd, so it counts standard deviations from the mean.',
  ),
  QuizQuestion(
    prompt: 'What is the expected value of one roll of a fair die?',
    options: ['3', '3.5', '4', '6'],
    answer: 1,
    explanation: '(1 + 2 + 3 + 4 + 5 + 6) / 6 = 21 / 6 = 3.5.',
  ),
];

/// Every question available: the bank plus all built lesson quizzes.
List<QuizQuestion> get allQuestions => [
      ...kPracticeBank,
      for (final spec in lessonRegistry.values) ...spec.quiz,
    ];

/// Today's 5 daily-challenge questions. Same for everyone on the same day.
List<QuizQuestion> dailyChallengeFor(DateTime day, {int count = 5}) {
  final seed = day.year * 10000 + day.month * 100 + day.day;
  final pool = [...allQuestions]..shuffle(math.Random(seed));
  return pool.take(count).toList();
}

/// Random questions from lessons the learner has finished (plus the bank).
List<QuizQuestion> practiceSet(Set<String> completed, {int count = 5, math.Random? rng}) {
  final pool = [
    ...kPracticeBank,
    for (final id in completed) ...?lessonRegistry[id]?.quiz,
  ]..shuffle(rng ?? math.Random());
  return pool.take(count).toList();
}

// ===== lib/data/why.dart =====
/// "Why does this work?": the reasoning behind each lesson's formula,
/// shown under the big idea. Keyed by lesson id; every lesson has one.
const Map<String, String> kWhy = {
  'types_of_data':
      'An average needs arithmetic: adding values and dividing only means something if the gaps between values are real amounts. The gap from 3 to 4 children is one child, the same as from 7 to 8. The gap from \'medium\' to \'large\' has no size at all. So categories can only be counted (use the mode), ordered labels can also be ranked (median, percentiles), and only true numbers can be averaged.',
  'averages':
      'The mean is the balance point: mean × n = total. Add an outlier of 200 to ten values and the total jumps by 200, so the mean jumps by about 200 ÷ 11 ≈ 18. The median only cares which value sits in the middle position. An outlier, however huge, moves the middle by at most one place, so the median barely shifts. The mode only counts repeats, so it ignores the outlier completely.',
  'spread':
      'Plain distances from the mean always add up to exactly zero: that\'s what makes it the mean. Squaring makes every distance positive and has a bonus: variances of independent things simply add. The square root then brings the answer back to the original units. We divide by n − 1, not n, because distances measured from the sample\'s own mean come out slightly too small (see \'Why divide by n − 1?\' in chapter 12).',
  'percentiles':
      'The smallest value sits at position 0 and the largest at position n − 1. Going p of the way along that line lands at position p × (n − 1). If that falls between two values, take the point the same fraction of the way between them. Software packages use slightly different conventions for this, but they agree closely once there is plenty of data.',
  'skew':
      'The mean is a balance point, and a value far out on a long tail is like a weight on a long lever: it pulls the balance point towards the tail. The median only counts how many values are on each side, not how far away they are, so it stays with the bulk of the data. That\'s why mean − median > 0 points to a right skew and < 0 to a left skew.',
  'outliers':
      'The IQR uses only the middle half of the data, so the outliers themselves can\'t inflate it. The standard deviation would get stretched by the very values you\'re trying to catch. For bell-shaped data, the fences at Q1 − 1.5·IQR and Q3 + 1.5·IQR sit about 2.7 standard deviations from the middle, so only about 0.7% of values get flagged. A flagged value really is unusual.',
  'zscores':
      'Subtracting the mean moves the average to 0, so the sign tells you above or below. Dividing by the sd changes the units from \'marks\' to \'standard deviations\'. On a test where marks are tightly bunched, each extra mark is harder to get, so it counts for more. English: 8 marks above with sd 5 gives 1.6. Maths: 18 above with sd 12 gives only 1.5. Z-scores always have mean 0 and sd 1, whatever the original scale.',
  'bar_pie':
      'Experiments on how people read charts (Cleveland & McGill, 1984) found we judge positions along a shared scale most accurately, then lengths, then angles and areas. Bars use position and length; pies use angle and area. A slice\'s angle is share × 360° because the whole circle stands for 100%. That\'s also why a pie only makes sense when the parts add up to one whole.',
  'histograms':
      'With k bins, each bin holds about n/k values, and a count of c values naturally wobbles by about √c. Too many bins leave a handful of values per bin and the wobble drowns the shape. Too few bins average the shape away. About √n bins balances the two: roughly √n values per bin. Other rules of thumb, like Sturges\' 1 + log₂n, are just different compromises.',
  'box_plots':
      'The median and quartiles depend only on the order of the values, not on how extreme the biggest ones are. That makes them resistant: one wild value can\'t drag the box around. The box is the spread of the middle half (the IQR), so comparing boxes compares typical values. Whiskers usually stop at the 1.5 × IQR fences and show any outliers beyond them as separate dots.',
  'scatter':
      'Each dot adds (x − x̄)(y − ȳ) to the top of the formula. That\'s positive in the top-right and bottom-left quarters around the averages, and negative in the other two. The sum says which diagonal wins. Dividing by √(Σ(x − x̄)² · Σ(y − ȳ)²) removes the units, and the Cauchy–Schwarz inequality guarantees the answer lies between −1 and +1. It only reaches ±1 when every point sits exactly on a line.',
  'stem_leaf':
      'Each stem is a bin ten wide, and the number of leaves in a row is the count in that bin. The row of leaves is literally a bar, so you get a histogram for free. Because each leaf is a real digit, no information is lost: you can read every value back. With sorted leaves the data is in order, so the median is just the (n + 1)/2-th leaf.',
  'graphs_lie':
      'Your eye reads the ratio of bar heights. If the axis starts at b, the bars show (55 − b) ÷ (52 − b). Starting at 0 gives the honest 1.06. Starting at 50 gives 5 ÷ 2 = 2.5, which makes a 6% gap look like 150%. Only a zero baseline makes the picture\'s ratio equal the real ratio. Line charts are different: they show change, so their axis doesn\'t need to start at 0.',
  'events':
      'If all n outcomes are equally likely and their chances add up to 1, each one must have chance 1/n. An event\'s chance is the sum of its outcomes\' chances, so an event with k outcomes has k/n. The catch is the \'equally likely\' part. \'Rain or no rain\' has two outcomes, but that doesn\'t make rain a 50-50 chance.',
  'coin_flips':
      'The number of heads in n flips wobbles by about √(n·p(1 − p)). That wobble grows, but much more slowly than n does. So the share of heads, heads ÷ n, wobbles by only √(p(1 − p)/n), which shrinks towards 0. With 100 flips the share is typically within ±5% of p; with 10,000 flips, within ±0.5%. The count of heads minus tails can still drift: it\'s the proportion that settles.',
  'complement':
      'Every outcome is either \'at least one six\' or \'no six\', never both and never neither. All the chances add up to 1, so P(A) + P(not A) = 1. \'No six\' on four dice means each die independently misses, with chance 5/6 each. Multiplying gives (5/6)⁴ ≈ 0.482, so P(at least one six) = 1 − 0.482 = 0.518.',
  'venn':
      'P(A) counts every outcome inside A, including those that are also in B. P(B) counts those shared outcomes too. So in P(A) + P(B), everything in the overlap is counted twice. Subtracting P(A and B) once leaves every outcome in \'A or B\' counted exactly once. With three sets you subtract the pairwise overlaps and add back the triple overlap. This pattern is called inclusion–exclusion.',
  'mutually_exclusive':
      'When two events can\'t happen together, P(A and B) = 0, so the addition rule loses its last term and you just add. Hearts or spades: 13 + 13 = 26 out of 52. Hearts or kings: 13 + 4 − 1 = 16 out of 52, because the king of hearts belongs to both. Careful: mutually exclusive is the opposite of independent. If A happens, B certainly doesn\'t, so knowing one tells you a lot about the other.',
  'multiplication_principle':
      'Draw the choices as a tree: 3 shirt branches, each splitting into 2 trouser branches, each splitting into 2 shoe branches. Every outfit is exactly one path from the root to a leaf, and every path is an outfit, so counting leaves counts outfits: 3 × 2 × 2. It works whenever the number of options at each step stays the same, even if which options are available changes.',
  'permutations':
      'By the multiplication principle, filling r places from n gives n × (n − 1) × … × (n − r + 1). Write it as n! ÷ (n − r)!: the (n − r)! cancels the tail of n! that you never used. With r = n you\'re arranging everyone, and since 0! = 1 you get n! arrangements.',
  'combinations':
      'Every team of r people can be put in order in r! different ways, and each ordering is a different permutation. So the number of permutations is the number of teams × r!. Divide it out: nCr = n! ÷ (r!(n − r)!). There\'s a nice symmetry too: choosing r people to include is the same as choosing n − r to leave out, so nCr = nC(n − r).',
  'repeats':
      'Pretend the letters are all different: label them A₁ A₂ A₃ and N₁ N₂. That gives 6! = 720 arrangements. Each real word matches 3! × 2! = 12 labelled ones, because the labels can be shuffled among the A positions and among the N positions without changing the word. So there are 720 ÷ 12 = 60 words. In general it\'s n! ÷ (n₁! n₂! …).',
  'pigeonhole':
      'Suppose no hole held two pigeons. Then each hole holds at most one, so 5 holes hold at most 5 pigeons, but there are 6. That\'s a contradiction, so some hole must hold two. In general, n items in k holes put at least ⌈n/k⌉ in some hole. A head has at most about 150,000 hairs: far fewer possible counts than a million people, so two must share a count.',
  'birthday':
      'Count the opposite. Person 1 can have any birthday. Person 2 must avoid one day (364/365), person 3 must avoid two days (363/365), and so on. Multiply these, since each step assumes everyone so far is different. For 23 people the product is about 0.493, so P(match) ≈ 0.507. A quick check: 253 pairs, each matching with chance 1/365, gives about e^(−253/365) ≈ 0.50 for no match.',
  'conditional':
      'Being told that B happened makes B the whole world, so its chances must be rescaled until B has total probability 1. The only part of A that is still possible is \'A and B\'. Dividing by P(B) does the rescaling: P(A | B) = P(A and B) ÷ P(B). In counts it\'s just 12 cricketers among the 40 glasses-wearers, which is 0.30.',
  'independence':
      'The multiplication rule always says P(A and B) = P(A) × P(B | A). Independence means knowing A changes nothing, so P(B | A) = P(B), and the rule becomes P(A) × P(B). For two fair coins that\'s ½ × ½ = ¼. With the sticky coin, P(B | A) is bigger than P(B), so heads-heads turns up more than a quarter of the time.',
  'tree_diagrams':
      'A path is a sequence: first this happens, then that happens given the first. By the multiplication rule its chance is the product of the branches. Different paths can\'t both happen, so for \'either\' you add their chances. One of each = RB + BR = (3/5 × 2/4) + (2/5 × 3/4) = 0.3 + 0.3 = 0.6. All the leaf probabilities add up to 1, which is a handy check.',
  'multiplication_rule':
      'This is the definition of conditional probability rearranged: P(B | A) = P(A and B) ÷ P(A), so multiply both sides by P(A). In the picture, the strip\'s width is P(A) and the purple part\'s height inside it is P(B | A). The area is width × height. You can also slice it the other way, P(B) × P(A | B), and get the same area.',
  'total_probability':
      'Factories A, B and C split all the bulbs into groups that don\'t overlap and leave nothing out (a partition). So \'faulty\' splits the same way into faulty-and-A, faulty-and-B and faulty-and-C. Separate pieces add up. Each piece is P(factory) × P(faulty | factory), by the multiplication rule: 0.020 + 0.018 + 0.030 = 0.068.',
  'bayes':
      'Bayes\' theorem: P(sick | +) = P(+ | sick) · P(sick) ÷ P(+). The bottom comes from the law of total probability: P(+) = P(+ | sick)·P(sick) + P(+ | healthy)·P(healthy). In counts, imagine 1,000 people at 1% prevalence: 10 are sick and 9 test positive; 990 are healthy and 9% of them, about 89, also test positive. So 9 ÷ (9 + 89) ≈ 9%. Thinking in counts makes Bayes easy.',
  'monty_hall':
      'List the cases. You pick door 1. The car is behind door 1 (chance 1/3): switching loses. Behind door 2 (1/3): the host must open door 3, and switching wins. Behind door 3 (1/3): the host must open door 2, and switching wins. Switching wins 2 cases out of 3. It isn\'t 50-50 because the host never opens the car\'s door. Imagine 100 doors where the host opens 98 goats: switching is obviously smart.',
  'discrete_continuous':
      'On a fair spinner, the chance of landing in a range is its length: P(0.4 ≤ X ≤ 0.6) = 0.2. Shrink the range around 0.5: [0.49, 0.51] gives 0.02, and [0.4999, 0.5001] gives 0.0002. A single point has length 0, so its chance is 0, even though some exact value always comes up. That\'s why continuous variables use a density: probability per unit of length.',
  'pmf_cdf':
      'Count the dice pairs. A total of 7 comes from (1,6), (2,5), … , (6,1): 6 of the 36 rolls. A total of 2 comes only from (1,1). Counting every total gives the triangle 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1 (out of 36). The CDF F(x) = P(X ≤ x) adds the bars up to x, so it jumps by each bar\'s height and has to finish at 1. Ranges come for free: P(a < X ≤ b) = F(b) − F(a).',
  'expected_value':
      'Picture 100 spins landing in exactly the right proportions. 60 lose ₹10 (−₹600), 25 win nothing, 10 win ₹10 (+₹100) and 5 win ₹90 (+₹450). The total is −₹50, which is −₹0.50 per spin. That calculation is exactly Σ x·p(x): the average you\'d get if every outcome came up in its true share. The Law of Large Numbers says real long-run averages head there.',
  'variance_rv':
      'When rounds are independent, variances add. So n rounds have variance n·Var(X), and the spread of your total is sd × √n. The risky game pays +₹9 one time in 10 and −₹1 nine times in 10. That averages 0, with variance 9 and sd ₹3. After 100 rounds the expected total is still ₹0, but a typical player is about 3 × 10 = ₹30 away from it.',
  'linearity':
      'E[X + Y] is a weighted sum over all outcomes, and a sum can always be split up: Σ(X + Y)·p = ΣX·p + ΣY·p. Nothing in that step needs X and Y to be independent. Person i\'s score averages P(they get their own hat), and their hat is equally likely to be any of the n hats, so that\'s 1/n. Adding n of them gives 1. (Adding variances is what needs independence, not adding averages.)',
  'bernoulli':
      'E[X] = 1·p + 0·(1 − p) = p. Because X is only ever 0 or 1, X² = X, so E[X²] = p too. Then Var(X) = E[X²] − (E[X])² = p − p² = p(1 − p). This is largest at p = 0.5 (0.25): a fair coin is the hardest to predict, and p near 0 or 1 is nearly certain.',
  'galton':
      'To land in bin k, a ball must go right exactly k times out of 8. Any one such path has chance p^k (1 − p)^(8−k), and there are C(8, k) of them (choose which rows go right). So P(bin k) = C(8, k) p^k (1 − p)^(8−k): the binomial. The middle bins have by far the most paths: C(8, 4) = 70, against just 1 for the edge. The mean is n·p because each row adds p rights on average.',
  'geometric':
      'Needing exactly k tries means k − 1 independent misses and then a hit: (1 − p)^(k−1)·p. For the average: with chance p you\'re done in 1 try. Otherwise you\'ve spent 1 try and you\'re back at the start, because the process has no memory. So E = 1 + (1 − p)·E, which solves to E = 1/p. With p = 0.3 that\'s about 3.33 tries.',
  'negative_binomial':
      'The k-th trial must be the r-th success. Among the first k − 1 trials, choose which r − 1 were successes: C(k − 1, r − 1) ways. Each arrangement has chance p^r (1 − p)^(k−r). The total wait is r separate geometric waits in a row, each averaging 1/p, so by linearity E = r/p. Adding several waits together is also why the shape becomes more bell-like as r grows.',
  'hypergeometric':
      'All C(20, 5) handfuls are equally likely. Those with exactly k reds pick k of the 8 reds and 5 − k of the 12 blues: C(8, k)·C(12, 5 − k) ways. For the mean, notice that any single draw is equally likely to be any ball, so each draw is red with chance 8/20. By linearity E = 5 × 8/20 = 2, just like drawing with replacement. The variance is smaller by the factor (20 − 5)/(20 − 1).',
  'poisson':
      'Cut the window into n tiny slices, each with chance λ/n of an arrival. The count is then Binomial(n, λ/n). As the slices shrink (n → ∞), C(n, k)(λ/n)^k (1 − λ/n)^(n−k) turns into λ^k e^(−λ) / k!, because (1 − λ/n)^n → e^(−λ). The mean n·λ/n = λ, and the variance n(λ/n)(1 − λ/n) also tends to λ.',
  'discrete_uniform':
      'Pair the values up: 1 with n, 2 with n − 1, and so on. Every pair averages (n + 1)/2, so that\'s the mean. For the variance, E[X²] = (n + 1)(2n + 1)/6. Subtract the squared mean (n + 1)²/4 and it simplifies to (n² − 1)/12. For a die that\'s 35/12 ≈ 2.92.',
  'continuous_uniform':
      'The total area under a density must be 1. Over a width of b − a, that forces a height of 1/(b − a). The chance of [a, t] is then a rectangle: (t − a) × 1/(b − a). By symmetry the mean is the midpoint, (a + b)/2. The variance (b − a)²/12 is the continuous cousin of the die\'s (n² − 1)/12.',
  'normal_curve':
      'When a value is the sum of many small independent nudges, the Central Limit Theorem says the total is close to normal, whatever the nudges look like: the Galton board in slow motion. The formula e^(−(x−μ)²/2σ²) falls off with the squared distance from μ, so the tails thin out very fast. Dividing by σ√(2π) makes the area exactly 1. That puts the peak at 1/(σ√(2π)), which is why a wider bell must be shorter.',
  'standard_normal':
      'If X is normal with mean μ and sd σ, then Z = (X − μ)/σ is standard normal. Subtracting slides the bell to 0 and dividing rescales its width, but the shape stays the same. Since X ≤ x exactly when Z ≤ (x − μ)/σ, we get P(X ≤ x) = Φ((x − μ)/σ), so one table covers every normal. The curve is symmetric, so Φ(−z) = 1 − Φ(z), and tables only need positive z.',
  'rule_68_95':
      'These are just areas under the standard normal curve: Φ(1) − Φ(−1) = 0.683, Φ(2) − Φ(−2) = 0.954 and Φ(3) − Φ(−3) = 0.997. Any normal turns into the standard one through z-scores, so the same percentages hold for every mean and sd. The famous 1.96 is the exact cut-off that gives 95%; 2 is the rounded version.',
  'exponential':
      'Waiting longer than t means no arrivals in [0, t]. The Poisson count in that window has mean λt, so P(none) = e^(−λt), and that is P(X > t). Memorylessness falls out of the algebra: P(X > s + t | X > s) = e^(−λ(s+t)) ÷ e^(−λs) = e^(−λt), the same as starting fresh. The average wait is 1/λ.',
  'gamma_beta':
      'A Gamma(k) is the sum of k independent exponential waits with rate 1. Each wait has mean 1 and variance 1, so the sum has mean k and variance k, and by the CLT it gets bell-shaped as k grows. If X ~ Gamma(a) and Y ~ Gamma(b), then X/(X + Y) ~ Beta(a, b), with mean a/(a + b). The Beta density ∝ p^(a−1)(1 − p)^(b−1) has the same shape as the likelihood of a − 1 successes and b − 1 failures. That\'s why it pairs so well with yes/no data.',
  't_chi_f':
      'Chi-square: each Z² averages 1, so a sum of df of them averages df. t: if you knew σ, (x̄ − μ)/(σ/√n) would be exactly normal. Using the sample\'s s instead adds randomness to the bottom of the fraction. When s happens to come out small, the statistic is inflated, and that fattens the tails. With more data s ≈ σ, and t becomes normal. F is a ratio of two chi-squares, each divided by its df. Both are near 1 when nothing is going on, so F is near 1.',
  'joint_marginal':
      'By the multiplication rule, P(X = x, Y = y) = P(X = x) × P(Y = y | X = x) = 1/6 × C(x, y)/2^x, since Y given x coins is binomial. For the marginal of Y, the cells (X = 1, Y = y) … (X = 6, Y = y) don\'t overlap and together make up \'Y = y\', so you add down the column (total probability). The whole grid adds up to 1. For example, P(X = 4, Y = 2) = 1/6 × 6/16 = 0.0625.',
  'covariance':
      '(x − x̄)(y − ȳ) is literally the signed area of the rectangle from the averages\' cross to the dot. Dots in the top-right and bottom-left give positive areas; the other two corners give negative ones. Their average is the covariance (using n − 1 for the same reason as the sample variance). The units are hours × marks, so switching hours to minutes multiplies the covariance by 60 even though nothing real has changed.',
  'correlation':
      'Change units by multiplying x by c, and both cov(x, y) and sₓ get multiplied by c, so the c\'s cancel in r. In fact r is just the covariance of the z-scores. The Cauchy–Schwarz inequality keeps r between −1 and +1, and it only hits ±1 when every point is on a line. In a U-shape, the positive rectangles on one side cancel the negative ones on the other, so r ≈ 0 even though y depends perfectly on x.',
  'correlation_causation':
      'Inside a narrow temperature band, temperature is almost constant, so it can no longer push ice cream and swimming up together. Whatever link remains would have to come from somewhere else, and here almost none does. Experiments go further. Randomly assigning who gets a treatment makes the groups alike, on average, in everything else, measured or not. So any difference that appears has to be caused by the treatment.',
  'clt_dice':
      'The sum of n independent dice has variance nσ² (variances add). The average is the sum ÷ n, which divides the variance by n², leaving σ²/n and an sd of σ/√n. For a die, σ = √(35/12) ≈ 1.71. The bell shape appears because there are vastly more ways to make an average near 3.5 than an extreme one, just like on the Galton board. Adding independent pieces smooths almost any starting shape towards the normal curve.',
  'chebyshev':
      'Every value more than kσ from the mean adds at least (kσ)² to the variance\'s sum of squared distances. If a fraction q of the values are that far out, the variance is at least q·k²σ², and it equals σ², so q ≤ 1/k². That means at least 1 − 1/k² are within kσ. The proof only uses the definition of variance, which is why it works for any shape.',
  'population_sample':
      'In a simple random sample everyone is equally likely to be picked, so each person in it says \'yes\' with chance p. The sample share p̂ is an average of n such 0/1 answers. Its expected value is exactly p (it\'s unbiased), and it typically misses by √(p(1 − p)/n). The parameter p is fixed; p̂ changes with every sample. Surprisingly, the size of the population hardly matters. What matters is n.',
  'sampling_methods':
      'Estimates wobble because each sample mixes people differently. Stratifying fixes how many come from each neighbourhood, so differences between neighbourhoods can\'t cause wobble; only the randomness within each group is left. Cluster sampling picks whole blocks of people who think alike, which is like having far fewer independent opinions, so the estimate swings with which blocks get chosen. Systematic sampling behaves like random sampling unless the list has a repeating pattern.',
  'sampling_bias':
      'Error = bias + random noise. Random noise shrinks like 1/√n, but bias doesn\'t depend on n at all: every extra mall shopper comes from the same lopsided group. A huge biased sample gives a very precise wrong answer. In 1936 the Literary Digest poll had 2.4 million replies, mostly from car and telephone owners, and still predicted the wrong winner of the US election.',
  'sampling_distributions':
      'The sample is random, so anything you compute from it is a random variable with its own distribution. For the mean, linearity gives E[x̄] = μ, and adding variances gives an sd of σ/√n. The Central Limit Theorem makes it bell-shaped even when the population is skewed. The maximum of n values is always at least as big as a typical value, so its distribution sits higher and leans towards the top.',
  'standard_error':
      'Var(x̄) = Var(sum) ÷ n² = nσ² ÷ n² = σ²/n, so SE = σ/√n. Averaging cancels people\'s random ups and downs, but only partly: they don\'t line up perfectly, so the cancelling happens at the √n rate, not the n rate. In real studies σ is unknown, so you plug in the sample\'s s: SE ≈ s/√n.',
  'point_estimates':
      'The sample mean x̄ is the single point that makes Σ(x − point)² as small as possible. So Σ(x − x̄)² is always a little smaller than Σ(x − μ)² measured from the true mean. Exactly: Σ(x − μ)² = Σ(x − x̄)² + n(x̄ − μ)², and the last term averages σ². So on average Σ(x − x̄)² = (n − 1)σ², and dividing by n − 1 lands right on σ². We say one degree of freedom was used up estimating the mean.',
  'mle':
      'The likelihood is L(p) = p^h (1 − p)^t. Taking logs turns the product into a sum with the same peak: h·ln p + t·ln(1 − p). Its slope is h/p − t/(1 − p), which is zero at p = h/(h + t): heads ÷ flips. With more flips, the likelihood of values away from the peak drops off exponentially faster, so the curve narrows.',
  'confidence_intervals':
      'x̄ is normal around μ with sd σ/√n, so 95% of the time |x̄ − μ| < 1.96σ/√n. That inequality reads the same both ways: μ is within 1.96σ/√n of x̄. So the recipe \'x̄ ± 1.96σ/√n\' catches μ in 95% of samples. Once a particular interval has been computed it either contains μ or it doesn\'t; the 95% belongs to the recipe.',
  'margin_of_error':
      'A poll share p̂ is an average of n yes/no answers, so its sd is √(p(1 − p)/n), and the margin is 1.96 × that. p(1 − p) is largest at p = 0.5, where it\'s 0.25. That gives a worst-case margin of 1.96 × √(0.25/n) ≈ 1/√n: about ±3 points for n = 1,000. In a two-way race, the lead (A − B) has a margin about twice as big.',
  'sample_size':
      'Start from the margin, E = z√(p(1 − p)/n), and solve for n: n = z²·p(1 − p)/E². With the worst case p = 0.5 that\'s (z × 0.5 / E)². Because n grows with 1/E², halving the margin quadruples the sample. The population size doesn\'t even appear, unless you\'re sampling a big chunk of it. For ±1 point at 95%: (1.96 × 0.5 / 0.01)² = 9,604.',
  'null_alternative':
      'If the coin is fair, we know exactly what to expect: heads in 20 flips is Binomial(20, ½). \'Biased\' covers infinitely many possible values of p, so there\'s no single prediction to check against. So we assume H₀ and pick outcomes that would be rare under it. P(≤ 5 or ≥ 15 heads | fair) = 2 × 0.0207 ≈ 0.041. That is the chance of a false alarm, α.',
  'p_values':
      'If H₀ is true, the chance of getting p ≤ 0.05 is 5%, because that\'s what the p-value measures: being among H₀\'s most extreme 5% of results. The same holds for every cut-off c: P(p ≤ c) = c. That\'s exactly an even (uniform) spread. With a real effect, extreme results happen more often, so p-values pile up near 0. To get P(H₀ is true | data) you\'d need Bayes\' theorem and a prior. The p-value doesn\'t give it.',
  'type_errors':
      'The cut-off splits both bells. α is the area of H₀\'s bell beyond the cut-off; β is the area of H₁\'s bell on the near side of it. Moving the cut-off shrinks one area and grows the other, so you can\'t win both with the cut-off alone. To shrink both, pull the bells apart (a bigger effect) or make them narrower (more data, since their width is σ/√n).',
  'power':
      'The test rejects when z > 1.645 (one-sided, α = 0.05). If the true effect is d standard deviations, the sample mean shifts by d·σ, so z is centred at d√n instead of 0. P(reject) = P(Z + d√n > 1.645) = 1 − Φ(1.645 − d√n). Increasing d or n pushes this towards 1. For 80% power you need d√n ≈ 2.49, so n ≈ (2.49/d)².',
  'z_test':
      'If the claim is true, x̄ is normal with mean 500 g and sd 10/√25 = 2 g. So z = (x̄ − 500)/2 is standard normal, and |z| > 1.96 happens only 5% of the time: that\'s the rejection rule. We can use z, not t, because the sd is known. If the real mean is 497 g, z is centred at −1.5, so the test rejects much more often.',
  't_tests':
      'Both groups\' sample sds estimate the same σ, so pooling them uses all 16 values: s_p² is the average of the two variances. The difference of two means has variance σ²/n + σ²/n = 2σ²/n, so its standard error is s_p√(2/n). There are 16 − 2 = 14 degrees of freedom, because two means were estimated. With df 14, the two-sided 5% cut-off is 2.145 instead of the normal 1.96.',
  'chi_square':
      'Each face count O wobbles around its expected count E with a variance close to E, so (O − E)/√E behaves roughly like a standard normal. Squaring and adding gives a chi-square. There are only 5 degrees of freedom because the six counts must add up to 60: once you know five, the sixth is fixed. 11.07 is the 95th percentile of χ² with 5 df.',
  'anova':
      'If all groups share one mean, the group averages differ only by chance, and their spread (scaled by group size) estimates σ². The scatter inside the groups estimates σ² whether or not H₀ is true. So under H₀ the two estimates agree and F ≈ 1. Real differences inflate only the between-group part, so F grows. Doing three separate 5% t-tests instead would give about 1 − 0.95³ ≈ 14% chance of at least one false alarm.',
  'line_of_best_fit':
      'For any slope, the best intercept makes the residuals average zero, and that puts the line through (x̄, ȳ). What\'s left is to minimise Σ(y − ȳ − b(x − x̄))² over b. That\'s a parabola in b, and setting its slope to zero gives b = Σ(x − x̄)(y − ȳ) / Σ(x − x̄)². This also equals r × s_y / s_x, so the fitted line and the correlation are closely tied.',
  'residuals':
      'Least squares guarantees the residuals average zero and have no straight-line link with x. So if a straight line is the right model, nothing systematic is left: just random scatter. If the truth is curved, the line is too high in the middle and too low at the ends (or the other way round), and the residuals trace a U. A funnel shape means the spread changes with x.',
  'r_squared':
      'For a least-squares line the total variation splits exactly in two: Σ(y − ȳ)² = Σ(ŷ − ȳ)² + Σ(y − ŷ)². That\'s explained plus left over; the cross term cancels. So R² = 1 − left over ÷ total = explained ÷ total. With a single x, ŷ − ȳ = b(x − x̄), and the algebra simplifies to exactly r².',
  'multiple_regression':
      'Bigger homes tend to have more bedrooms, so when size goes up, bedrooms usually go up too. The size-only slope therefore picks up both effects: the true size effect plus (bedroom effect × how many extra bedrooms come with extra size). This is called omitted-variable bias. Fitting both inputs together solves for each coefficient using only the part of that input the other one can\'t explain. That\'s what \'holding the others fixed\' means.',
  'logistic_regression':
      'The sigmoid 1/(1 + e^(−z)) squeezes any number z into (0, 1). Turn it around and ln(p/(1 − p)) = a + b·x: the line describes the log-odds, so each extra hour multiplies the odds of passing by e^b. There\'s no formula for the best fit, so we climb the log-likelihood step by step. Each point pulls with (y − p)·x: it pushes the curve up where a student passed but the predicted p was low.',
  'prior_posterior':
      'Bayes\' rule: posterior ∝ prior × likelihood. With h heads and t tails the likelihood is p^h (1 − p)^t. A Beta(a, b) prior is ∝ p^(a−1)(1 − p)^(b−1). Multiply them and you get p^(a+h−1)(1 − p)^(b+t−1): still a Beta, now Beta(a + h, b + t). So the prior acts like heads and tails you\'d already seen. The mean (a + h)/(a + b + h + t) is swamped by the data as h + t grows.',
  'updating_evidence':
      'Bayes\' rule in odds form: posterior odds = prior odds × (chance of this ball under A ÷ chance under B). Each red multiplies the odds for A by 0.7/0.3 = 7/3, and each blue divides them by 7/3. So only reds minus blues matters, and the order doesn\'t. As draws pile up that difference tends to grow, which pushes the belief towards 0% or 100%.',
  'bayes_vs_frequentist':
      'With a flat Beta(1, 1) prior, k clicks in n visits gives a Beta(1 + k, 1 + n − k) posterior. For large n its mean is close to p̂, its sd is close to √(p̂(1 − p̂)/n), and it\'s nearly normal. So the 95% credible interval ≈ p̂ ± 1.96√(p̂(1 − p̂)/n), the confidence interval. With 0 clicks in 10, p̂ = 0 gives a zero-width confidence interval, while the Beta(1, 11) posterior still allows small positive rates.',
  'ab_testing':
      'If the buttons are really the same, both share one click rate p̄. Then p̂_B − p̂_A has sd √(p̄(1 − p̄)(1/n_A + 1/n_B)), and dividing by it gives a z that\'s roughly standard normal. Peeking breaks this: every look is another roughly 5% chance of a false alarm. Check after every visitor and you get dozens of chances, so the chance of ever seeing p < 0.05 by luck is far above 5%.',
  'monte_carlo':
      'Each dart lands uniformly in the unit square, so its chance of landing inside the quarter circle equals that area, π/4. The count inside is binomial, and by the Law of Large Numbers the share heads to π/4. The error of 4 × share is about 4√(p(1 − p)/n) ≈ 1.64/√n. So 10,000 darts give π to about ±0.016, and each extra digit needs 100 times more darts.',
  'random_walks':
      'After n steps, the position is the sum of n independent steps of ±1, each with mean 0 and variance 1. Variances add, so the position has variance n, and its root-mean-square distance from the start is √n. The same holds in 2D: the squared distance adds 1 per unit step on average, so it\'s again √n. Spreading like √n, not n, is the signature of diffusion.',
  'markov_chains':
      'If today\'s chances of each state are π, tomorrow\'s are πP. A stationary distribution is one that stays put: π = πP. When every state can reach every other and nothing forces a fixed rhythm, each step blends the rows of P together. The differences caused by where you started shrink away, so the chain converges to that π. The long-run share of days in each state then equals π.',
  'ai_ml':
      'e^score is always positive and keeps the order of the scores. Dividing by the sum makes the results add up to 1, so they\'re valid probabilities. Dividing the scores by T first controls the gaps: T < 1 stretches them so the top word dominates, and T > 1 squeezes them so the odds become more even. A word that scores 1 point higher is e^(1/T) times as likely.',
  'simpsons':
      'Each treatment\'s overall rate is an average of its small-stone and large-stone rates, weighted by how many patients of each kind it got. A got mostly large stones (263 of 350), where success is lower, so its overall rate is pulled towards 73%. B got mostly small stones (270 of 350), so it\'s pulled towards 87%. It\'s the mix of cases that flips the comparison, not the treatments. Compare within groups, or randomise who gets what.',
  'gamblers_fallacy':
      'The spins are independent: P(red | any history) = P(red). The wheel has no idea what happened before. \'Evening out\' is just dilution. After 26 extra blacks, the next 1,000 spins come out about 500–500, so black\'s share is about 526/1,026 ≈ 51%. The extra 26 never get cancelled; they just matter less and less.',
  'st_petersburg':
      'E = Σ (½)^k × 2^k = 1 + 1 + 1 + … over every possible k, which is infinite. But in N games the biggest prize you\'ll typically see is only about N, so the average prize grows like log₂N: roughly ₹10 after 1,000 games. And no real banker can pay out 2⁴⁰ rupees. Cap the prize at the bank\'s wealth W and the game is worth only about log₂W + 1: even a ₹1 trillion bank makes it worth about ₹41.',
};

// ===== lib/engine/lesson_sim.dart =====
/// Base class every animated lesson extends.
///
/// The lesson screen owns a ticker and calls [advance] every frame while
/// [playing] is true, already multiplied by [speed]. Subclasses update their
/// state and call [notifyListeners] so painters and labels redraw.
abstract class LessonSim extends ChangeNotifier {
  bool playing = true;
  double speed = 1.0;

  /// Move the simulation forward by [dt] seconds (speed already applied).
  void advance(double dt);

  /// One small, visible step. Used by the "step" button while paused.
  void step();

  /// Back to the starting state.
  void reset();

  void togglePlay() {
    playing = !playing;
    notifyListeners();
  }

  void setSpeed(double value) {
    speed = value;
    notifyListeners();
  }
}

// ===== lib/engine/lesson_spec.dart =====
/// A piece of the lesson title; [color] highlights a word.
class TitlePart {
  const TitlePart(this.text, [this.color]);
  final String text;
  final Color? color;
}

class StatChip {
  const StatChip(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  final String prompt;
  final List<String> options;
  final int answer;
  final String explanation;
}

/// Everything the generic lesson screen needs to show one lesson:
/// watch (visual) → understand (big idea) → play (try it) → check (quiz).
class LessonSpec {
  const LessonSpec({
    required this.id,
    required this.chapterLabel,
    required this.title,
    required this.subtitle,
    required this.createSim,
    required this.buildVisual,
    required this.visualAspectRatio,
    required this.stats,
    required this.bigIdea,
    required this.formula,
    required this.tryItTitle,
    required this.buildTryIt,
    required this.quiz,
  });

  final String id;
  final String chapterLabel;
  final List<TitlePart> title;
  final String subtitle;

  final LessonSim Function() createSim;
  final Widget Function(LessonSim sim) buildVisual;

  /// width / height of the animation stage.
  final double visualAspectRatio;

  final List<StatChip> Function(LessonSim sim) stats;
  final String bigIdea;
  final String Function(LessonSim sim) formula;
  final String tryItTitle;
  final Widget Function(LessonSim sim) buildTryIt;
  final List<QuizQuestion> quiz;
}

// ===== lib/lessons/arrangements_repeats.dart =====
const List<String> kRepeatWords = ['BOOK', 'LEVEL', 'APPLE', 'BANANA', 'LETTER'];

/// Shuffles the letters of a word and collects the distinct words made.
class RepeatsSim extends TickSim {
  RepeatsSim({super.rng}) {
    restart();
  }

  String word = 'BANANA';
  late List<String> letters;
  final Set<String> seen = {};
  int shuffles = 0;

  Map<String, int> get letterCounts {
    final m = <String, int>{};
    for (final c in word.split('')) {
      m[c] = (m[c] ?? 0) + 1;
    }
    return m;
  }

  int get total {
    var t = factorial(word.length);
    for (final k in letterCounts.values) {
      t ~/= factorial(k);
    }
    return t;
  }

  @override
  double get interval => shuffles < 6 ? 0.8 : 0.12;

  @override
  void tick() {
    letters.shuffle(rng);
    shuffles++;
    seen.add(letters.join());
  }

  @override
  void restart() {
    letters = word.split('');
    seen.clear();
    shuffles = 0;
  }
}

void _paintRepeats(Canvas canvas, Size size, RepeatsSim sim) {
  final w = size.width;
  final h = size.height;
  final repeated = sim.letterCounts.entries.where((e) => e.value > 1).map((e) => e.key).toList();
  Color colorFor(String c) {
    final i = repeated.indexOf(c);
    return i < 0 ? AppColors.peg : [AppColors.pink, AppColors.blue, AppColors.green][i % 3];
  }

  // Tiles.
  final n = sim.letters.length;
  final tile = ((w - 40) / n).clamp(0.0, 52.0) - 6;
  final rowW = n * (tile + 6) - 6;
  for (var i = 0; i < n; i++) {
    final rect = Rect.fromLTWH((w - rowW) / 2 + i * (tile + 6), 20, tile, tile * 1.15);
    roundRect(canvas, rect, colorFor(sim.letters[i]), radius: 10);
    label(canvas, sim.letters[i], rect.center, size: tile * 0.55, color: Colors.white, weight: FontWeight.w900);
  }
  final legend = repeated.map((c) => '$c ×${sim.letterCounts[c]}').join('  ');
  label(canvas, legend.isEmpty ? 'no repeated letters' : 'repeated: $legend', Offset(w / 2, 34 + tile * 1.15),
      size: 12, color: AppColors.muted);

  // Progress.
  final y = 64 + tile * 1.15;
  final barW = w - 40;
  final frac = sim.seen.length / sim.total;
  label(canvas, 'Different words made', Offset(20, y), size: 12, align: TextAlign.left);
  roundRect(canvas, Rect.fromLTWH(20, y + 12, barW, 24), Colors.white, radius: 8);
  roundRect(canvas, Rect.fromLTWH(20, y + 12, barW * frac, 24), AppColors.violet, radius: 8);
  label(canvas, '${sim.seen.length} of ${sim.total}', Offset(w / 2, y + 24),
      size: 12, color: frac > 0.5 ? Colors.white : AppColors.ink);

  // Recent words.
  final recent = sim.seen.toList().reversed.take(12).toList();
  final colW = barW / 3;
  for (var i = 0; i < recent.length; i++) {
    label(canvas, recent[i], Offset(20 + colW * (i % 3) + colW / 2, y + 58 + (i ~/ 3) * 20.0),
        size: 13, color: i == 0 ? AppColors.ink : AppColors.muted);
  }
  label(canvas, '${sim.shuffles} shuffles', Offset(w - 20, h - 12),
      size: 11, color: AppColors.muted, align: TextAlign.right);
}

final LessonSpec repeatsLesson = LessonSpec(
  id: 'repeats',
  chapterLabel: 'Ch 4 · Counting',
  title: const [
    TitlePart('Why '),
    TitlePart('BANANA', AppColors.yellow),
    TitlePart(' has fewer arrangements than you think'),
  ],
  subtitle: 'Arrangements with repeats · 2-minute animated lesson',
  createSim: () => RepeatsSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<RepeatsSim>(sim, _paintRepeats),
  stats: (sim) {
    final r = sim as RepeatsSim;
    return [
      StatChip('letters', '${r.word.length}', AppColors.yellow),
      StatChip('if all different', '${factorial(r.word.length)}', AppColors.pink),
      StatChip('really', '${r.total}', AppColors.violet),
    ];
  },
  bigIdea: 'Six different letters can be arranged 6! = 720 ways. But BANANA\'s three '
      'A\'s are identical: swapping them changes nothing, so each word is counted '
      '3! = 6 times too often. The two N\'s add another 2! repeat. Divide out the '
      'repeats for each repeated letter.',
  formula: (sim) {
    final r = sim as RepeatsSim;
    final denominators = r.letterCounts.values.where((k) => k > 1).map((k) => '$k!').join(' × ');
    return denominators.isEmpty
        ? '${r.word.length}! = ${r.total}'
        : '${r.word.length}! / ($denominators) = ${factorial(r.word.length)} / '
            '${factorial(r.word.length) ~/ r.total} = ${r.total}';
  },
  tryItTitle: 'Try it: pick a word',
  buildTryIt: (sim) {
    final r = sim as RepeatsSim;
    return watch(
      r,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<String>(
            options: {for (final word in kRepeatWords) word: word},
            selected: r.word,
            onSelected: (v) => r.change(() => r.word = v),
          ),
          const SizedBox(height: 8),
          ControlRow(children: [ActionButton('Shuffle 500 times', () => r.runMany(500))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'How many different arrangements of the letters in "MOM"?',
      options: ['2', '3', '6', '9'],
      answer: 1,
      explanation: '3! / 2! = 3: MOM, MMO, OMM.',
    ),
    QuizQuestion(
      prompt: 'How many arrangements of "LEVEL" (two L\'s, two E\'s)?',
      options: ['30', '60', '120', '24'],
      answer: 0,
      explanation: '5! / (2! × 2!) = 120 / 4 = 30.',
    ),
    QuizQuestion(
      prompt: 'Why divide by 3! for a letter that appears three times?',
      options: [
        'Because there are three vowels',
        'The 3! orders of identical letters all give the same word',
        'To make the answer smaller',
        'Because 3! = 3',
      ],
      answer: 1,
      explanation: 'Identical letters can be swapped in 3! ways without changing the word.',
    ),
  ],
);

// ===== lib/lessons/averages.dart =====
// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

/// Shape of the data being dropped onto the number line.
enum DataShape { symmetric, skewed }

class AveragesSim extends LessonSim {
  AveragesSim({math.Random? rng}) : _rng = rng ?? math.Random();

  /// Values run 0 … [maxValue] (think "salary in lakh").
  static const int maxValue = 20;

  /// Dots stop arriving at this many.
  static const int target = 40;

  final math.Random _rng;
  DataShape shape = DataShape.skewed;

  /// Values in arrival order.
  final List<int> values = [];

  /// The newest dot falls from the top: 0 → 1.
  double drop = 1;

  /// Outliers added by the learner (drawn past the end of the axis).
  int outliers = 0;

  /// Value an outlier counts as.
  static const int outlierValue = 200;

  double _timer = 0;

  int _sample() {
    switch (shape) {
      case DataShape.symmetric:
        // Sum of 4 dice-ish draws centred on 10.
        var s = 0;
        for (var i = 0; i < 4; i++) {
          s += _rng.nextInt(6);
        }
        return (s * maxValue / 20).round().clamp(0, maxValue);
      case DataShape.skewed:
        // Most values small, a long tail to the right.
        final x = -math.log(1 - _rng.nextDouble()) * 4 + 2;
        return x.round().clamp(0, maxValue);
    }
  }

  List<int> get _all => [...values, for (var i = 0; i < outliers; i++) outlierValue];

  double get mean {
    final all = _all;
    if (all.isEmpty) return 0;
    return all.fold(0, (a, b) => a + b) / all.length;
  }

  double get median {
    final all = _all..sort();
    if (all.isEmpty) return 0;
    final mid = all.length ~/ 2;
    return all.length.isOdd ? all[mid].toDouble() : (all[mid - 1] + all[mid]) / 2;
  }

  /// Most common value among the regular dots (smallest on a tie).
  int? get mode {
    if (values.isEmpty) return null;
    final counts = List<int>.filled(maxValue + 1, 0);
    for (final v in values) {
      counts[v]++;
    }
    var best = 0;
    for (var v = 1; v <= maxValue; v++) {
      if (counts[v] > counts[best]) best = v;
    }
    return best;
  }

  int get count => values.length + outliers;

  @override
  void advance(double dt) {
    if (drop < 1) drop = math.min(1, drop + dt * 4);
    if (values.length < target) {
      _timer += dt;
      final every = values.length < 8 ? 0.45 : 0.15;
      while (_timer >= every && values.length < target) {
        _timer -= every;
        _add();
      }
    }
    notifyListeners();
  }

  void _add() {
    values.add(_sample());
    drop = 0;
  }

  void addOutlier() {
    outliers++;
    notifyListeners();
  }

  void setShape(DataShape s) {
    shape = s;
    reset();
  }

  @override
  void step() {
    if (values.length < target) _add();
    drop = 1;
    notifyListeners();
  }

  @override
  void reset() {
    values.clear();
    outliers = 0;
    drop = 1;
    _timer = 0;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class AveragesPainter extends CustomPainter {
  AveragesPainter(this.sim) : super(repaint: sim);

  final AveragesSim sim;

  static const double aspectRatio = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const left = 18.0;
    final right = w - (sim.outliers > 0 ? 58 : 18);
    final axisY = h * 0.72;
    final unit = (right - left) / AveragesSim.maxValue;
    final dotR = math.min(unit * 0.42, 9.0);
    double xFor(double v) => left + v * unit;

    // Axis and ticks.
    final axis = Paint()
      ..color = AppColors.peg
      ..strokeWidth = 2;
    canvas.drawLine(Offset(left, axisY), Offset(right, axisY), axis);
    for (var v = 0; v <= AveragesSim.maxValue; v += 5) {
      canvas.drawLine(Offset(xFor(v.toDouble()), axisY), Offset(xFor(v.toDouble()), axisY + 6), axis);
      _text(canvas, '$v', Offset(xFor(v.toDouble()), axisY + 16), 11, AppColors.muted);
    }

    // Stacked dots (dot plot).
    final stacks = List<int>.filled(AveragesSim.maxValue + 1, 0);
    for (var i = 0; i < sim.values.length; i++) {
      final v = sim.values[i];
      final level = stacks[v]++;
      final restY = axisY - dotR - 2 - level * dotR * 2.1;
      final isNewest = i == sim.values.length - 1;
      final y = isNewest ? 14 + (restY - 14) * Curves.easeIn.transform(sim.drop) : restY;
      canvas.drawCircle(
        Offset(xFor(v.toDouble()), y),
        dotR,
        Paint()..color = AppColors.rainbow[i % AppColors.rainbow.length],
      );
    }

    // Outliers: drawn just past the axis end with a "200" tag.
    if (sim.outliers > 0) {
      final ox = w - 32;
      for (var i = 0; i < sim.outliers; i++) {
        canvas.drawCircle(Offset(ox, axisY - dotR - 2 - i * dotR * 2.1), dotR, Paint()..color = AppColors.ink);
      }
      _text(canvas, '${AveragesSim.outlierValue}', Offset(ox, axisY + 16), 11, AppColors.ink);
      _text(canvas, '⋯', Offset((right + ox) / 2, axisY), 14, AppColors.muted);
    }

    if (sim.count == 0) return;

    // Markers under the axis.
    final markers = <(String, double, Color)>[
      ('mean', sim.mean, AppColors.pink),
      ('median', sim.median, AppColors.violet),
      if (sim.mode != null) ('mode', sim.mode!.toDouble(), AppColors.cyan),
    ];
    for (var i = 0; i < markers.length; i++) {
      final (name, value, color) = markers[i];
      final shown = value.clamp(0, AveragesSim.maxValue + (sim.outliers > 0 ? 1.8 : 0)).toDouble();
      final x = xFor(shown);
      final y = axisY + 34 + i * 22;
      canvas.drawLine(
        Offset(x, axisY + 2),
        Offset(x, y - 6),
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..strokeWidth = 2,
      );
      final path = Path()
        ..moveTo(x, y - 8)
        ..lineTo(x - 7, y + 4)
        ..lineTo(x + 7, y + 4)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      final label = '$name ${value.toStringAsFixed(name == 'mode' ? 0 : 1)}';
      final onRight = x < w * 0.6;
      _text(canvas, label, Offset(x + (onRight ? 12 : -12), y - 1), 12, color,
          align: onRight ? TextAlign.left : TextAlign.right);
    }
  }

  void _text(Canvas canvas, String text, Offset anchor, double size, Color color,
      {TextAlign align = TextAlign.center}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.left => 0.0,
      TextAlign.right => tp.width,
      _ => tp.width / 2,
    };
    tp.paint(canvas, anchor - Offset(dx, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant AveragesPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec averagesLesson = LessonSpec(
  id: 'averages',
  chapterLabel: 'Ch 1 · Data & averages',
  title: const [
    TitlePart('Three '),
    TitlePart('averages', AppColors.pink),
    TitlePart(', three '),
    TitlePart('different', AppColors.violet),
    TitlePart(' answers'),
  ],
  subtitle: 'Mean, median & mode · 2-minute animated lesson',
  createSim: () => AveragesSim(),
  visualAspectRatio: AveragesPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: AveragesPainter(sim as AveragesSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final a = sim as AveragesSim;
    return [
      StatChip('values', '${a.count}', AppColors.yellow),
      StatChip('mean', a.mean.toStringAsFixed(1), AppColors.pink),
      StatChip('median', a.median.toStringAsFixed(1), AppColors.violet),
    ];
  },
  bigIdea: 'The mean adds everything up and shares it equally, so one huge value '
      'drags it along. The median is just the middle value once sorted, so it '
      'barely notices. The mode is the most common value. When data has a long '
      'tail, like salaries, the median tells you what is typical.',
  formula: (sim) {
    final a = sim as AveragesSim;
    return 'mean = sum / n = ${(a.mean * a.count).round()} / ${a.count} = ${a.mean.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: add a billionaire',
  buildTryIt: (sim) => _AveragesControls(sim: sim as AveragesSim),
  quiz: const [
    QuizQuestion(
      prompt: 'Five friends earn 3, 4, 4, 5 and 4 lakh. One more joins earning 100 lakh. '
          'Which average changes the most?',
      options: ['The mean', 'The median', 'The mode', 'None of them'],
      answer: 0,
      explanation: 'The mean jumps from 4 to 20 lakh. The median and mode stay at 4, '
          'which still describes a typical friend.',
    ),
    QuizQuestion(
      prompt: 'Data with a long tail to the right usually has…',
      options: ['mean < median', 'mean = median', 'mean > median', 'no median'],
      answer: 2,
      explanation: 'The few big values in the tail pull the mean to the right of the '
          'median.',
    ),
    QuizQuestion(
      prompt: 'Which average can you use for data like "favourite colour"?',
      options: ['Mean', 'Median', 'Mode', 'Any of them'],
      answer: 2,
      explanation: 'Colours cannot be added or sorted, but you can still count which '
          'one is the most common.',
    ),
  ],
);

class _AveragesControls extends StatelessWidget {
  const _AveragesControls({required this.sim});
  final AveragesSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<DataShape>(
            segments: const [
              ButtonSegment(value: DataShape.symmetric, label: Text('Symmetric')),
              ButtonSegment(value: DataShape.skewed, label: Text('Long tail')),
            ],
            selected: {sim.shape},
            onSelectionChanged: (s) => sim.setShape(s.first),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: sim.addOutlier,
            icon: const Icon(Icons.diamond_rounded),
            label: Text(
              sim.outliers == 0 ? 'Add a value of ${AveragesSim.outlierValue}' : 'Add another (${sim.outliers} so far)',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Watch the pink mean race to the right while the purple median hardly moves.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ===== lib/lessons/bar_pie.dart =====
const List<String> kFruits = ['Mango', 'Apple', 'Banana', 'Grapes', 'Guava'];
const List<double> _fruitWeights = [0.34, 0.22, 0.18, 0.15, 0.11];
const List<Color> _fruitColors = [
  AppColors.orange,
  AppColors.pink,
  AppColors.yellow,
  AppColors.violet,
  AppColors.green
];

class BarPieSim extends TickSim {
  BarPieSim({super.rng});

  List<int> votes = List.filled(kFruits.length, 0);

  /// Index of the latest vote, for a highlight pulse.
  int last = -1;

  int get total => votes.fold(0, (a, b) => a + b);
  int get leader => total == 0 ? 0 : votes.indexOf(votes.reduce(math.max));

  @override
  double get interval => total < 15 ? 0.4 : 0.15;

  @override
  void tick() {
    if (total >= 300) return;
    var r = rng.nextDouble();
    var i = 0;
    while (i < kFruits.length - 1 && r > _fruitWeights[i]) {
      r -= _fruitWeights[i];
      i++;
    }
    vote(i, notify: false);
  }

  void vote(int i, {bool notify = true}) {
    votes[i]++;
    last = i;
    if (notify) notifyListeners();
  }

  @override
  void restart() {
    votes = List.filled(kFruits.length, 0);
    last = -1;
  }
}

void _paintBarPie(Canvas canvas, Size size, BarPieSim sim) {
  final w = size.width;
  final h = size.height;
  final total = math.max(1, sim.total);

  // --- Bar chart (top) ---
  const left = 16.0;
  final right = w - 16;
  final baseline = h * 0.46;
  const top = 26.0;
  final slot = (right - left) / kFruits.length;
  final maxV = math.max(5, sim.votes.reduce(math.max));
  label(canvas, 'Bar chart: compare sizes', Offset(left, 12), size: 11, color: AppColors.muted, align: TextAlign.left);
  for (var i = 0; i < kFruits.length; i++) {
    final x = left + slot * (i + 0.5);
    bar(canvas, x, slot * 0.62, baseline, (baseline - top - 14) * sim.votes[i] / maxV, _fruitColors[i]);
    label(canvas, '${sim.votes[i]}', Offset(x, baseline - (baseline - top - 14) * sim.votes[i] / maxV - 9), size: 11);
    label(canvas, kFruits[i], Offset(x, baseline + 10), size: 10, color: AppColors.muted);
  }
  line(canvas, Offset(left, baseline), Offset(right, baseline), AppColors.peg);

  // --- Pie chart (bottom) ---
  final pieTop = baseline + 30;
  label(canvas, 'Pie chart: parts of a whole', Offset(left, pieTop),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  final r = math.min((h - pieTop - 22) / 2, w * 0.22);
  final c = Offset(left + r + 8, pieTop + 14 + r);
  var start = -math.pi / 2;
  for (var i = 0; i < kFruits.length; i++) {
    final sweep = sim.votes[i] / total * 2 * math.pi;
    if (sweep <= 0) continue;
    final rr = i == sim.last ? r + 4 : r;
    canvas.drawArc(Rect.fromCircle(center: c, radius: rr), start, sweep, true, Paint()..color = _fruitColors[i]);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: rr),
      start,
      sweep,
      true,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    start += sweep;
  }
  if (sim.total == 0) ring(canvas, c, r, AppColors.peg);

  // Legend with percentages.
  final lx = c.dx + r + 22;
  for (var i = 0; i < kFruits.length; i++) {
    final y = pieTop + 22 + i * ((2 * r) / kFruits.length);
    canvas.drawCircle(Offset(lx, y), 6, Paint()..color = _fruitColors[i]);
    label(canvas, '${kFruits[i]} ${(sim.votes[i] / total * 100).round()}%', Offset(lx + 12, y),
        size: 12, align: TextAlign.left);
  }
}

final LessonSpec barPieLesson = LessonSpec(
  id: 'bar_pie',
  chapterLabel: 'Ch 2 · Seeing data',
  title: const [
    TitlePart('Same votes, two '),
    TitlePart('pictures', AppColors.orange),
  ],
  subtitle: 'Bar & pie charts · 2-minute animated lesson',
  createSim: () => BarPieSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<BarPieSim>(sim, _paintBarPie),
  stats: (sim) {
    final b = sim as BarPieSim;
    return [
      StatChip('votes', '${b.total}', AppColors.yellow),
      StatChip('leader', b.total == 0 ? '…' : kFruits[b.leader], AppColors.orange),
      StatChip('its share', b.total == 0 ? '…' : '${(b.votes[b.leader] / b.total * 100).round()}%', AppColors.pink),
    ];
  },
  bigIdea: 'Bars are best for comparing categories: our eyes judge lengths on a '
      'shared baseline very accurately. Pies show parts of one whole, but angles '
      'are hard to compare, so close slices look the same. Use a pie only for a '
      'few categories that add up to 100%.',
  formula: (sim) {
    final b = sim as BarPieSim;
    final t = math.max(1, b.total);
    return 'slice angle = share × 360° → ${kFruits[b.leader]}: '
        '${b.votes[b.leader]}/$t × 360° = ${(b.votes[b.leader] / t * 360).round()}°';
  },
  tryItTitle: 'Try it: cast your own votes',
  buildTryIt: (sim) {
    final b = sim as BarPieSim;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < kFruits.length; i++)
              ActionChip(
                avatar: CircleAvatar(backgroundColor: _fruitColors[i], radius: 8),
                label: Text(kFruits[i], style: const TextStyle(fontWeight: FontWeight.w800)),
                onPressed: () => b.vote(i),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const TryNote('Pause the animation, then vote for Guava ten times. Which chart shows the change more clearly?'),
      ],
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'You want to compare sales of 12 different phone models. Best chart?',
      options: ['Pie chart', 'Bar chart', 'A single number', 'Either is equally good'],
      answer: 1,
      explanation: 'Twelve thin pie slices are impossible to compare. Bars on a common '
          'baseline make small differences visible.',
    ),
    QuizQuestion(
      prompt: 'A slice is 25% of a pie. What angle is it?',
      options: ['25°', '45°', '90°', '180°'],
      answer: 2,
      explanation: '0.25 × 360° = 90°, a right angle.',
    ),
    QuizQuestion(
      prompt: 'When is a pie chart a reasonable choice?',
      options: [
        'Showing change over 10 years',
        'A few parts that add up to one whole',
        'Comparing two unrelated totals',
        'Showing averages',
      ],
      answer: 1,
      explanation: 'Pies show how one whole splits up. They need the parts to sum to '
          '100% and work best with 2–5 slices.',
    ),
  ],
);

// ===== lib/lessons/bayes_test.dart =====
// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

/// 1,000 people take a medical test. Counts are exact for the chosen rates;
/// only who is who is shuffled.
class BayesSim extends LessonSim {
  BayesSim({int seed = 7}) : _seed = seed {
    _build();
  }

  static const int people = 1000;
  static const int cols = 40;
  static const int rows = people ~/ cols;

  /// Choices offered by the sliders.
  static const List<double> prevalences = [0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5];
  static const List<double> falsePositiveRates = [0.01, 0.02, 0.05, 0.09, 0.2];

  /// Chance a sick person tests positive.
  static const double sensitivity = 0.9;

  int _seed;
  double prevalence = 0.01;
  double falsePositiveRate = 0.09;

  late List<bool> sick;
  late List<bool> positive;

  /// People tested so far (fractional while animating).
  double tested = 0;

  /// 0 → 1 fade of negative results once everyone is tested.
  double focus = 0;

  int get sickCount => (people * prevalence).round();
  int get truePositives => (sickCount * sensitivity).round();
  int get falsePositives => ((people - sickCount) * falsePositiveRate).round();
  int get positives => truePositives + falsePositives;

  /// P(sick | positive test), from the counts.
  double get sickGivenPositive => positives == 0 ? 0 : truePositives / positives;

  int get testedCount => tested.floor().clamp(0, people);

  /// Results visible so far.
  int get positivesSoFar {
    var n = 0;
    for (var i = 0; i < testedCount; i++) {
      if (positive[i]) n++;
    }
    return n;
  }

  void _build() {
    final order = List<int>.generate(people, (i) => i)..shuffle(math.Random(_seed));
    sick = List<bool>.filled(people, false);
    positive = List<bool>.filled(people, false);
    final s = sickCount;
    for (var k = 0; k < s; k++) {
      sick[order[k]] = true;
      if (k < truePositives) positive[order[k]] = true;
    }
    for (var k = 0; k < falsePositives; k++) {
      positive[order[s + k]] = true;
    }
  }

  @override
  void advance(double dt) {
    if (tested < people) {
      // Slow for the first row so each test is visible, then fast.
      final rate = tested < cols ? 20 : 220;
      tested = math.min(people.toDouble(), tested + dt * rate);
    } else if (focus < 1) {
      focus = math.min(1, focus + dt * 1.2);
    }
    notifyListeners();
  }

  void setRates({double? prevalence, double? falsePositiveRate}) {
    this.prevalence = prevalence ?? this.prevalence;
    this.falsePositiveRate = falsePositiveRate ?? this.falsePositiveRate;
    _seed++;
    _build();
    // Jump straight to the result so the effect of the slider is instant.
    tested = people.toDouble();
    focus = 1;
    notifyListeners();
  }

  @override
  void step() {
    if (tested < people) {
      tested = math.min(people.toDouble(), (tested / cols).floor() * cols + cols.toDouble());
    } else {
      focus = 1;
    }
    notifyListeners();
  }

  @override
  void reset() {
    tested = 0;
    focus = 0;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class BayesPainter extends CustomPainter {
  BayesPainter(this.sim) : super(repaint: sim);

  final BayesSim sim;

  static const double aspectRatio = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const pad = 12.0;
    final cell = (w - pad * 2) / BayesSim.cols;
    final gridTop = 26.0;
    final dotR = cell * 0.34;
    final done = sim.testedCount;

    _text(canvas, '1,000 people · ${sim.sickCount} sick (pink) · ring = tested positive', Offset(w / 2, 13), 11,
        AppColors.muted);

    for (var i = 0; i < BayesSim.people; i++) {
      final c = Offset(pad + (i % BayesSim.cols + 0.5) * cell, gridTop + (i ~/ BayesSim.cols + 0.5) * cell);
      final isTested = i < done;
      final isPos = sim.positive[i];
      final fade = isTested && !isPos ? 1 - sim.focus * 0.75 : 1.0;
      // Sick people are always shown, so the learner sees how few there are.
      if (sim.sick[i]) {
        canvas.drawCircle(c, dotR * 1.45, Paint()..color = AppColors.pink.withValues(alpha: fade));
      } else {
        canvas.drawCircle(c, dotR, Paint()..color = AppColors.peg.withValues(alpha: (isTested ? 0.9 : 0.35) * fade));
      }
      if (isTested && isPos) {
        canvas.drawCircle(
          c,
          dotR + cell * 0.12,
          Paint()
            ..color = AppColors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.2, cell * 0.12),
        );
      }
    }

    // Result bar: everyone who tested positive, split by who is really sick.
    final barTop = gridTop + BayesSim.rows * cell + 22;
    final barH = math.max(18.0, math.min(34.0, h - barTop - 30));
    final barW = w - pad * 2;
    final tp = sim.truePositives;
    final fp = sim.falsePositives;
    final shown = sim.focus;
    _text(canvas, 'Everyone who tested positive (${sim.positives})', Offset(w / 2, barTop - 10), 12, AppColors.ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(pad, barTop, barW, barH), const Radius.circular(10)),
      Paint()..color = Colors.white,
    );
    if (sim.positives > 0 && shown > 0) {
      final sickW = barW * tp / sim.positives * shown;
      final healthyW = barW * fp / sim.positives * shown;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(pad, barTop, sickW, barH), const Radius.circular(10)),
        Paint()..color = AppColors.pink,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(pad + barW - healthyW, barTop, healthyW, barH), const Radius.circular(10)),
        Paint()..color = AppColors.peg,
      );
      if (shown >= 1) {
        _text(canvas, '$tp sick', Offset(pad + 34, barTop + barH + 14), 12, AppColors.pink);
        _text(canvas, '$fp healthy', Offset(w - pad - 44, barTop + barH + 14), 12, AppColors.muted);
        _text(canvas, '${(sim.sickGivenPositive * 100).toStringAsFixed(0)}% are really sick',
            Offset(w / 2, barTop + barH / 2), 13, AppColors.ink);
      }
    }
  }

  void _text(Canvas canvas, String text, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant BayesPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

String _pct(double v) => v < 0.01 ? '${(v * 100).toStringAsFixed(1)}%' : '${(v * 100).round()}%';

final LessonSpec bayesLesson = LessonSpec(
  id: 'bayes',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('You tested '),
    TitlePart('positive', AppColors.pink),
    TitlePart('. Are you '),
    TitlePart('really', AppColors.violet),
    TitlePart(' sick?'),
  ],
  subtitle: "Bayes' theorem: the medical test · 3-minute animated lesson",
  createSim: () => BayesSim(),
  visualAspectRatio: BayesPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: BayesPainter(sim as BayesSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final b = sim as BayesSim;
    return [
      StatChip('tested', '${b.testedCount}', AppColors.yellow),
      StatChip('positive', '${b.positivesSoFar}', AppColors.violet),
      StatChip('sick if +', b.focus > 0 ? _pct(b.sickGivenPositive) : '…', AppColors.pink),
    ];
  },
  bigIdea: 'The test catches 90% of sick people and wrongly flags 9% of healthy '
      'ones. That sounds accurate, but healthy people vastly outnumber sick ones, '
      'so 9% of a huge group beats 90% of a tiny one. Most positive results come '
      'from healthy people. How rare the disease is (the base rate) matters as '
      'much as how good the test is.',
  formula: (sim) {
    final b = sim as BayesSim;
    return 'P(sick | +) = true + / all +\n= ${b.truePositives} / (${b.truePositives} + ${b.falsePositives}) '
        '= ${_pct(b.sickGivenPositive)}';
  },
  tryItTitle: 'Try it: change how rare the disease is',
  buildTryIt: (sim) => _BayesControls(sim: sim as BayesSim),
  quiz: const [
    QuizQuestion(
      prompt: 'A disease affects 1 in 100 people. A test catches 90% of cases and '
          'falsely flags 9% of healthy people. You test positive. Roughly how likely '
          'are you to be sick?',
      options: ['About 90%', 'About 50%', 'About 10%', 'About 1%'],
      answer: 2,
      explanation: 'Out of 1,000 people: 9 sick people test positive and about 89 '
          'healthy people do too. 9 / 98 ≈ 9%.',
    ),
    QuizQuestion(
      prompt: 'The disease becomes much more common (20% of people). Your positive '
          'result now means…',
      options: [
        'You are more likely to be sick',
        'You are less likely to be sick',
        'Nothing changes',
        'The test is broken',
      ],
      answer: 0,
      explanation: 'With more sick people, true positives grow and false positives '
          'shrink. The same test result becomes much more convincing.',
    ),
    QuizQuestion(
      prompt: 'What is the best next step after one positive result for a rare disease?',
      options: [
        'Assume you are sick',
        'Ignore it completely',
        'Take a second, independent test',
        'Take the same test less often',
      ],
      answer: 2,
      explanation: 'A second positive from an independent test multiplies the '
          'evidence. That is why doctors confirm screening results.',
    ),
  ],
);

class _BayesControls extends StatelessWidget {
  const _BayesControls({required this.sim});
  final BayesSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) {
        final pi = BayesSim.prevalences.indexOf(sim.prevalence);
        final fi = BayesSim.falsePositiveRates.indexOf(sim.falsePositiveRate);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Disease affects ${_pct(sim.prevalence)} of people',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Slider(
              value: pi.toDouble(),
              min: 0,
              max: BayesSim.prevalences.length - 1.0,
              divisions: BayesSim.prevalences.length - 1,
              label: _pct(sim.prevalence),
              onChanged: (v) => sim.setRates(prevalence: BayesSim.prevalences[v.round()]),
            ),
            Text('Test wrongly flags ${_pct(sim.falsePositiveRate)} of healthy people',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Slider(
              value: fi.toDouble(),
              min: 0,
              max: BayesSim.falsePositiveRates.length - 1.0,
              divisions: BayesSim.falsePositiveRates.length - 1,
              label: _pct(sim.falsePositiveRate),
              onChanged: (v) => sim.setRates(falsePositiveRate: BayesSim.falsePositiveRates[v.round()]),
            ),
            const Text(
              'Rare disease + a few false alarms = most positives are healthy. '
              'Make the disease common and watch the pink share grow.',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        );
      },
    );
  }
}

// ===== lib/lessons/birthday.dart =====
/// People walk into a room one by one; does anyone share a birthday?
class BirthdaySim extends TickSim {
  BirthdaySim({super.rng});

  int people = 23;

  /// Birthdays (day 0–364) of people in the current room.
  List<int> room = [];

  /// Day of the first shared birthday in this room, if any.
  int? match;

  int rooms = 0;
  int roomsWithMatch = 0;
  int _hold = 0;

  bool get full => room.length >= people;

  double get theory => birthdayChance(people);

  @override
  double get interval => rooms < 2 ? 0.12 : 0.03;

  @override
  void tick() {
    if (!full) {
      final day = rng.nextInt(365);
      if (match == null && room.contains(day)) match = day;
      room.add(day);
      if (full) {
        rooms++;
        if (match != null) roomsWithMatch++;
      }
    } else if (++_hold > (rooms < 3 ? 25 : 8)) {
      _hold = 0;
      room = [];
      match = null;
    }
  }

  @override
  void restart() {
    room = [];
    match = null;
    rooms = 0;
    roomsWithMatch = 0;
    _hold = 0;
  }
}

/// P(at least two of n people share a birthday), ignoring leap years.
double birthdayChance(int n) {
  var none = 1.0;
  for (var k = 0; k < n; k++) {
    none *= (365 - k) / 365;
  }
  return 1 - none;
}

void _paintBirthday(Canvas canvas, Size size, BirthdaySim sim) {
  final w = size.width;
  final h = size.height;

  // A year as a 21 × 18 grid of days (365 cells, last row partly empty).
  const cols = 21;
  final cell = (w - 20) / cols;
  const top = 20.0;
  label(canvas, 'every day of the year', Offset(w / 2, 8), size: 10, color: AppColors.muted);
  final taken = <int, int>{};
  for (final d in sim.room) {
    taken[d] = (taken[d] ?? 0) + 1;
  }
  for (var d = 0; d < 365; d++) {
    final c = Offset(10 + (d % cols + 0.5) * cell, top + (d ~/ cols + 0.5) * cell);
    final n = taken[d] ?? 0;
    if (n >= 2) {
      canvas.drawCircle(c, cell * 0.62, Paint()..color = AppColors.pink);
      ring(canvas, c, cell * 0.9, AppColors.pink, width: 2);
    } else if (n == 1) {
      canvas.drawCircle(c, cell * 0.38, Paint()..color = AppColors.blue);
    } else {
      canvas.drawCircle(c, cell * 0.14, Paint()..color = AppColors.peg.withValues(alpha: 0.5));
    }
  }

  final y = top + 18 * cell + 18;
  label(canvas, '${sim.room.length} of ${sim.people} people in the room', Offset(w / 2, y), size: 13);
  label(canvas, sim.match != null ? 'Shared birthday found!' : (sim.full ? 'No shared birthday this time' : ''),
      Offset(w / 2, y + 22),
      size: 15, color: sim.match != null ? AppColors.pink : AppColors.muted);
  label(canvas, 'Rooms with a match: ${sim.roomsWithMatch} of ${sim.rooms}', Offset(w / 2, h - 12),
      size: 12, color: AppColors.muted);
}

final LessonSpec birthdayLesson = LessonSpec(
  id: 'birthday',
  chapterLabel: 'Ch 4 · Counting',
  title: const [
    TitlePart('Just '),
    TitlePart('23 people', AppColors.blue),
    TitlePart(' for a 50% chance of a '),
    TitlePart('shared birthday', AppColors.pink),
  ],
  subtitle: 'The birthday paradox · 2-minute animated lesson',
  createSim: () => BirthdaySim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<BirthdaySim>(sim, _paintBirthday),
  stats: (sim) {
    final b = sim as BirthdaySim;
    return [
      StatChip('rooms', '${b.rooms}', AppColors.yellow),
      StatChip('with a match', b.rooms == 0 ? '…' : '${(b.roomsWithMatch / b.rooms * 100).round()}%', AppColors.pink),
      StatChip('theory', '${(b.theory * 100).round()}%', AppColors.violet),
    ];
  },
  bigIdea: 'It feels like you\'d need about 180 people, but you aren\'t looking for '
      'someone who shares your birthday: any pair will do. 23 people make 253 '
      'different pairs, and each pair is another chance for a match. Count the '
      'opposite instead: everyone different means each new person must miss all '
      'the days already taken.',
  formula: (sim) {
    final b = sim as BirthdaySim;
    return 'P(match) = 1 − (365/365 × 364/365 × … × ${365 - b.people + 1}/365) = ${b.theory.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: change the room size',
  buildTryIt: (sim) {
    final b = sim as BirthdaySim;
    return watch(
      b,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '5',
            right: '70',
            value: b.people.toDouble(),
            min: 5,
            max: 70,
            divisions: 65,
            label: '${b.people} people',
            onChanged: (v) => b.change(() => b.people = v.round()),
          ),
          ControlRow(children: [
            ValueTag('${b.people} people → ${(b.theory * 100).toStringAsFixed(1)}%'),
            ActionButton('Fill 100 rooms', () => b.runMany(100 * (b.people + 10))),
          ]),
          const SizedBox(height: 8),
          const TryNote('At 50 people a shared birthday is 97% likely; at 70 it is 99.9%.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Roughly how many people do you need for a 50% chance that two share a birthday?',
      options: ['23', '50', '183', '366'],
      answer: 0,
      explanation: 'With 23 people there are 253 pairs, and the chance passes 50%.',
    ),
    QuizQuestion(
      prompt: 'Why is the answer so much smaller than people expect?',
      options: [
        'Birthdays cluster in summer',
        'Any pair counts, and pairs grow fast as people are added',
        'Leap years',
        'It is a trick question',
      ],
      answer: 1,
      explanation: 'n people make n(n − 1)/2 pairs. 23 people already make 253.',
    ),
    QuizQuestion(
      prompt: 'How many people guarantee a shared birthday (ignoring 29 Feb)?',
      options: ['183', '365', '366', '730'],
      answer: 2,
      explanation: 'The pigeonhole principle: 366 people, 365 days.',
    ),
  ],
);

// ===== lib/lessons/box_plots.dart =====
/// Marks of two classes: dots first, then each box plot is built in stages.
class BoxPlotSim extends TickSim {
  BoxPlotSim({super.rng});

  static const int perGroup = 20;

  final List<double> a = [];
  final List<double> b = [];

  /// Spread of class B (class A is fixed).
  double spreadB = 18;

  /// 0 = dots only, 1 median, 2 box, 3 whiskers.
  int stage = 0;

  bool get full => a.length >= perGroup && b.length >= perGroup;

  @override
  double get interval => full ? 0.8 : 0.1;

  double _draw(double mean, double sd) => (mean + normalDraw(rng) * sd).clamp(0, 100).toDouble();

  @override
  void tick() {
    if (!full) {
      if (a.length <= b.length) {
        a.add(_draw(62, 8));
      } else {
        b.add(_draw(58, spreadB));
      }
    } else if (stage < 3) {
      stage++;
    }
  }

  @override
  void restart() {
    a.clear();
    b.clear();
    stage = 0;
  }
}

void _paintBoxes(Canvas canvas, Size size, BoxPlotSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 16.0;
  final right = w - 16;
  double xFor(double v) => left + v / 100 * (right - left);

  void group(List<double> data, double y, Color color, String name) {
    label(canvas, name, Offset(left, y - 50), size: 13, color: color, align: TextAlign.left);
    for (var i = 0; i < data.length; i++) {
      canvas.drawCircle(
          Offset(xFor(data[i]), y - 26 + (i % 4) * 5.0), 4.5, Paint()..color = color.withValues(alpha: 0.6));
    }
    if (data.length < 4 || sim.stage == 0) return;
    final q1 = quantileOf(data, .25), med = quantileOf(data, .5), q3 = quantileOf(data, .75);
    final lo = data.reduce(math.min), hi = data.reduce(math.max);
    final boxTop = y + 6, boxBottom = y + 40, mid = (boxTop + boxBottom) / 2;
    if (sim.stage >= 3) {
      line(canvas, Offset(xFor(lo), mid), Offset(xFor(q1), mid), AppColors.ink);
      line(canvas, Offset(xFor(q3), mid), Offset(xFor(hi), mid), AppColors.ink);
      line(canvas, Offset(xFor(lo), mid - 8), Offset(xFor(lo), mid + 8), AppColors.ink);
      line(canvas, Offset(xFor(hi), mid - 8), Offset(xFor(hi), mid + 8), AppColors.ink);
      label(canvas, 'min', Offset(xFor(lo), boxBottom + 10), size: 10, color: AppColors.muted);
      label(canvas, 'max', Offset(xFor(hi), boxBottom + 10), size: 10, color: AppColors.muted);
    }
    if (sim.stage >= 2) {
      roundRect(canvas, Rect.fromLTRB(xFor(q1), boxTop, xFor(q3), boxBottom), color.withValues(alpha: 0.35), radius: 6);
      label(canvas, 'Q1', Offset(xFor(q1), boxTop - 8), size: 10, color: AppColors.muted);
      label(canvas, 'Q3', Offset(xFor(q3), boxTop - 8), size: 10, color: AppColors.muted);
    }
    line(canvas, Offset(xFor(med), boxTop - 2), Offset(xFor(med), boxBottom + 2), AppColors.ink, width: 3.5);
  }

  group(sim.a, h * 0.28, AppColors.blue, 'Class A');
  group(sim.b, h * 0.68, AppColors.pink, 'Class B');

  final axisY = h - 14;
  for (var v = 0; v <= 100; v += 20) {
    label(canvas, '$v', Offset(xFor(v.toDouble()), axisY), size: 10, color: AppColors.muted);
  }
}

final LessonSpec boxPlotsLesson = LessonSpec(
  id: 'box_plots',
  chapterLabel: 'Ch 2 · Seeing data',
  title: const [
    TitlePart('Five numbers that '),
    TitlePart('summarise', AppColors.blue),
    TitlePart(' a whole class'),
  ],
  subtitle: 'Box plots · 2-minute animated lesson',
  createSim: () => BoxPlotSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<BoxPlotSim>(sim, _paintBoxes),
  stats: (sim) {
    final s = sim as BoxPlotSim;
    String med(List<double> d) => d.isEmpty ? '…' : quantileOf(d, .5).toStringAsFixed(0);
    String iqr(List<double> d) => d.length < 4 ? '…' : (quantileOf(d, .75) - quantileOf(d, .25)).toStringAsFixed(0);
    return [
      StatChip('median A', med(s.a), AppColors.blue),
      StatChip('median B', med(s.b), AppColors.pink),
      StatChip('IQR A / B', '${iqr(s.a)} / ${iqr(s.b)}', AppColors.yellow),
    ];
  },
  bigIdea: 'A box plot squeezes data into five numbers: min, Q1, median, Q3, max. The '
      'box holds the middle half of the values and the thick line is the median. '
      'Stacking two box plots shows at a glance which group is higher and which '
      'is more spread out, even when their averages are close.',
  formula: (_) => 'min · Q1 · median · Q3 · max     IQR = Q3 − Q1',
  tryItTitle: 'Try it: change how spread out class B is',
  buildTryIt: (sim) {
    final s = sim as BoxPlotSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'tight',
            right: 'wide',
            value: s.spreadB,
            min: 4,
            max: 24,
            divisions: 5,
            onChanged: (v) => s.change(() => s.spreadB = v),
          ),
          const TryNote('A long box and long whiskers mean the class has very mixed marks.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'What does the box in a box plot contain?',
      options: ['All the data', 'The middle 50% of the data', 'Only outliers', 'The top 25%'],
      answer: 1,
      explanation: 'From Q1 to Q3: the middle half of the values.',
    ),
    QuizQuestion(
      prompt: 'Two box plots have the same median, but one box is much longer. That group…',
      options: ['Scored higher', 'Is more spread out', 'Is smaller', 'Has no outliers'],
      answer: 1,
      explanation: 'A longer box means a bigger IQR: the middle half of the values '
          'are spread over a wider range.',
    ),
    QuizQuestion(
      prompt: 'Which value does a box plot NOT show directly?',
      options: ['Median', 'Mean', 'Q1', 'Maximum'],
      answer: 1,
      explanation: 'The five-number summary uses the median, quartiles and extremes. '
          'The mean isn\'t one of them.',
    ),
  ],
);

// ===== lib/lessons/ch07_discrete.dart =====
// Chapter 7 · Discrete distributions (the Galton board lives in galton_board.dart).

// ===========================================================================
// Bernoulli trials
// ===========================================================================

class BernoulliSim extends TickSim {
  BernoulliSim({super.rng});

  double p = 0.3;
  final List<bool> recent = [];
  int successes = 0, trials = 0;

  double get rate => trials == 0 ? 0 : successes / trials;

  @override
  double get interval => trials < 10 ? 0.5 : 0.06;

  @override
  void tick() {
    final s = rng.nextDouble() < p;
    trials++;
    if (s) successes++;
    recent.add(s);
    if (recent.length > 120) recent.removeAt(0);
  }

  @override
  void restart() {
    recent.clear();
    successes = trials = 0;
  }
}

void _paintBernoulli(Canvas canvas, Size size, BernoulliSim sim) {
  final w = size.width;
  final h = size.height;
  label(canvas, 'Each square is one trial: success (1) or failure (0)', Offset(w / 2, 12),
      size: 11, color: AppColors.muted);
  const cols = 15;
  final cell = (w - 30) / cols;
  for (var i = 0; i < sim.recent.length; i++) {
    final r = Rect.fromLTWH(15 + (i % cols) * cell + 1, 26 + (i ~/ cols) * cell + 1, cell - 2, cell - 2);
    final isNew = i == sim.recent.length - 1;
    roundRect(canvas, r, sim.recent[i] ? AppColors.green : AppColors.peg.withValues(alpha: 0.45), radius: 4);
    if (isNew) ring(canvas, r.center, cell * 0.55, AppColors.ink, width: 2);
  }
  final plot = Plot(Rect.fromLTWH(w * 0.25, 26 + 8 * cell + 30, w * 0.5, h - (26 + 8 * cell + 30) - 28),
      x0: -0.6, x1: 1.6, y1: 1);
  final obs = [1 - sim.rate, sim.rate];
  plot.intBars(canvas, sim.trials == 0 ? [0, 0] : obs, 0, (k) => k == 1 ? AppColors.green : AppColors.peg);
  plot.intDots(canvas, [1 - sim.p, sim.p], 0, AppColors.pink);
  plot.axis(canvas, [0, 1], format: (v) => v == 0 ? '0 fail' : '1 success');
  label(canvas, '● theory', Offset(w * 0.78, plot.rect.top + 8),
      size: 11, color: AppColors.pink, align: TextAlign.left);
}

final LessonSpec bernoulliLesson = LessonSpec(
  id: 'bernoulli',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('Yes', AppColors.green),
    TitlePart(' or '),
    TitlePart('no', AppColors.muted),
    TitlePart(': the atom of probability'),
  ],
  subtitle: 'Bernoulli trials · 2-minute animated lesson',
  createSim: () => BernoulliSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<BernoulliSim>(sim, _paintBernoulli),
  stats: (sim) {
    final b = sim as BernoulliSim;
    return [
      StatChip('trials', '${b.trials}', AppColors.yellow),
      StatChip('successes', '${b.successes}', AppColors.green),
      StatChip('rate', b.rate.toStringAsFixed(3), AppColors.pink),
    ];
  },
  bigIdea: 'A Bernoulli trial has exactly two results: success (1) with chance p, or '
      'failure (0). A free throw, a coin flip, whether a customer buys. It is the '
      'building block of most distributions in this chapter: count successes in n '
      'trials and you get the binomial; count trials until the first success and '
      'you get the geometric.',
  formula: (sim) {
    final b = sim as BernoulliSim;
    return 'P(X = 1) = p = ${b.p.toStringAsFixed(2)} · E[X] = p · Var(X) = p(1 − p) = '
        '${(b.p * (1 - b.p)).toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: change the success chance',
  buildTryIt: (sim) {
    final b = sim as BernoulliSim;
    return watch(
      b,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'p 0.05',
            right: '0.95',
            value: b.p,
            min: 0.05,
            max: 0.95,
            divisions: 18,
            label: 'p = ${b.p.toStringAsFixed(2)}',
            onChanged: (v) => b.change(() => b.p = v),
          ),
          const TryNote('Variance p(1 − p) is largest at p = 0.5, when the result is hardest to predict.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Which is a Bernoulli trial?',
      options: [
        'Rolling a die and noting the number',
        'Whether a penalty kick scores',
        'Measuring height',
        'Counting cars'
      ],
      answer: 1,
      explanation: 'Exactly two outcomes: goal or no goal.',
    ),
    QuizQuestion(
      prompt: 'A Bernoulli variable has p = 0.2. What is its expected value?',
      options: ['0', '0.2', '0.5', '0.8'],
      answer: 1,
      explanation: 'E[X] = 1 × 0.2 + 0 × 0.8 = 0.2.',
    ),
    QuizQuestion(
      prompt: 'For which p is a Bernoulli trial most unpredictable (largest variance)?',
      options: ['0.1', '0.5', '0.9', '1'],
      answer: 1,
      explanation: 'p(1 − p) peaks at 0.25 when p = 0.5.',
    ),
  ],
);

// ===========================================================================
// Waiting for successes: geometric (r = 1) and negative binomial
// ===========================================================================

class WaitSim extends TickSim {
  WaitSim({this.r = 1, super.rng});

  int r;
  double p = 0.3;
  List<bool> run = [];
  int _hold = 0;
  List<int> counts = List.filled(80, 0);
  int runs = 0;

  int get successesInRun => run.where((s) => s).length;
  bool get runDone => successesInRun >= r;

  double pmf(int k) => k < r ? 0 : binomPmf(k - 1, r - 1, p) * p;

  double get mean => r / p;

  double get observedMean {
    var s = 0;
    for (var k = 0; k < counts.length; k++) {
      s += k * counts[k];
    }
    return runs == 0 ? 0 : s / runs;
  }

  @override
  double get interval => runs < 3 ? 0.3 : 0.03;

  @override
  void tick() {
    if (!runDone) {
      run.add(rng.nextDouble() < p);
      if (runDone) {
        runs++;
        counts[math.min(run.length, counts.length - 1)]++;
      }
    } else if (++_hold > (runs < 3 ? 6 : 0)) {
      _hold = 0;
      run = [];
    }
  }

  @override
  void restart() {
    run = [];
    counts = List.filled(80, 0);
    runs = 0;
    _hold = 0;
  }
}

void _paintWait(Canvas canvas, Size size, WaitSim sim) {
  final w = size.width;
  final h = size.height;
  final need = sim.r == 1 ? 'the first success' : '${sim.r} successes';
  label(canvas, 'Trials until $need', Offset(15, 12), size: 12, align: TextAlign.left);
  const perRow = 20;
  final d = (w - 30) / perRow;
  for (var i = 0; i < math.min(sim.run.length, 60); i++) {
    final c = Offset(15 + d * (i % perRow + 0.5), 32 + (i ~/ perRow) * d);
    canvas.drawCircle(
        c, d * 0.36, Paint()..color = sim.run[i] ? AppColors.green : AppColors.peg.withValues(alpha: 0.5));
  }
  if (sim.runDone) {
    label(canvas, 'took ${sim.run.length} trials', Offset(w - 15, 12),
        size: 12, color: AppColors.green, align: TextAlign.right);
  }
  final maxK = sim.r + (sim.r * 3 / sim.p).round().clamp(10, 45);
  final top = 32 + 3 * d + 10;
  final total = math.max(1, sim.runs);
  final obs = [for (var k = sim.r; k <= maxK; k++) sim.counts[k] / total];
  final theory = [for (var k = sim.r; k <= maxK; k++) sim.pmf(k)];
  final yMax = math.max(theory.reduce(math.max), obs.reduce(math.max)) * 1.15;
  final plot = Plot(Rect.fromLTRB(15, top + 10, w - 15, h - 28), x0: sim.r - 0.6, x1: maxK + 0.6, y1: yMax);
  if (sim.runs > 0) plot.intBars(canvas, obs, sim.r, (_) => AppColors.cyan.withValues(alpha: 0.8), widthFrac: 0.8);
  plot.intDots(canvas, theory, sim.r, AppColors.pink);
  final step = ((maxK - sim.r) / 6).ceil().toDouble();
  plot.axis(canvas, [for (var k = sim.r.toDouble(); k <= maxK; k += step) k], title: 'trials needed');
  label(canvas, 'bars: seen · dots: theory', Offset(w - 15, top),
      size: 10, color: AppColors.muted, align: TextAlign.right);
}

Widget _waitControls(WaitSim s, {required bool showR}) => watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'p 0.1',
            right: '0.7',
            value: s.p,
            min: 0.1,
            max: 0.7,
            divisions: 12,
            label: 'p = ${s.p.toStringAsFixed(2)}',
            onChanged: (v) => s.change(() => s.p = v),
          ),
          if (showR)
            LabeledSlider(
              left: 'r = ${s.r}',
              right: '5',
              value: s.r.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) => s.change(() => s.r = v.round()),
            ),
          ControlRow(children: [
            ValueTag('average ${s.observedMean.toStringAsFixed(2)} vs r/p = ${s.mean.toStringAsFixed(2)}'),
            ActionButton('500 more runs', () => s.runMany(500 * (s.mean.ceil() + 2))),
          ]),
        ],
      ),
    );

final LessonSpec geometricLesson = LessonSpec(
  id: 'geometric',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('How long until the '),
    TitlePart('first success', AppColors.green),
    TitlePart('?'),
  ],
  subtitle: 'The geometric distribution · 2-minute animated lesson',
  createSim: () => WaitSim(r: 1),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<WaitSim>(sim, _paintWait),
  stats: (sim) {
    final s = sim as WaitSim;
    return [
      StatChip('runs', '${s.runs}', AppColors.yellow),
      StatChip('average wait', s.observedMean.toStringAsFixed(2), AppColors.cyan),
      StatChip('1/p', s.mean.toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'Keep trying until the first success: shooting until you score, calling '
      'until someone answers. Needing exactly k tries means k − 1 failures then a '
      'success, so each extra try multiplies the chance by (1 − p). The bars always '
      'fall away to the right, and on average you wait 1/p tries. Past failures '
      'don\'t make success "due": the wait starts afresh every time.',
  formula: (sim) {
    final s = sim as WaitSim;
    return 'P(X = k) = (1 − p)^(k−1) · p   E[X] = 1/p = ${s.mean.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: change the success chance',
  buildTryIt: (sim) => _waitControls(sim as WaitSim, showR: false),
  quiz: const [
    QuizQuestion(
      prompt: 'You roll a die until you get a 6. On average, how many rolls?',
      options: ['3', '3.5', '6', '36'],
      answer: 2,
      explanation: 'p = 1/6, so the expected wait is 1/p = 6 rolls.',
    ),
    QuizQuestion(
      prompt: 'Which single number of trials is the most likely for the first success?',
      options: ['1', 'Exactly 1/p', 'It depends on luck', 'The largest one'],
      answer: 0,
      explanation: 'P(X = 1) = p is the tallest bar; each later bar is (1 − p) times the one before.',
    ),
    QuizQuestion(
      prompt: 'p = 0.5. What is P(first success on try 3)?',
      options: ['1/2', '1/4', '1/8', '3/8'],
      answer: 2,
      explanation: 'Fail, fail, succeed: 0.5 × 0.5 × 0.5 = 1/8.',
    ),
  ],
);

final LessonSpec negativeBinomialLesson = LessonSpec(
  id: 'negative_binomial',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('Waiting for the '),
    TitlePart('r-th', AppColors.green),
    TitlePart(' success'),
  ],
  subtitle: 'The negative binomial distribution · 2-minute animated lesson',
  createSim: () => WaitSim(r: 3),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<WaitSim>(sim, _paintWait),
  stats: (sim) {
    final s = sim as WaitSim;
    return [
      StatChip('runs', '${s.runs}', AppColors.yellow),
      StatChip('average', s.observedMean.toStringAsFixed(2), AppColors.cyan),
      StatChip('r/p', s.mean.toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'Now keep going until r successes. A salesperson needs 3 sales; how many '
      'calls will it take? The last trial must be the r-th success, and the '
      'other r − 1 successes can be anywhere among the earlier k − 1 trials. '
      'It\'s really r geometric waits added together, so the average is r/p and '
      'the shape becomes more bell-like as r grows.',
  formula: (sim) {
    final s = sim as WaitSim;
    return 'P(X = k) = C(k−1, r−1) p^r (1−p)^(k−r)   E[X] = r/p = ${s.r}/${s.p.toStringAsFixed(2)} = '
        '${s.mean.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: need more successes',
  buildTryIt: (sim) => _waitControls(sim as WaitSim, showR: true),
  quiz: const [
    QuizQuestion(
      prompt: 'Each call makes a sale with p = 0.2. Expected calls for 3 sales?',
      options: ['3', '6', '15', '0.6'],
      answer: 2,
      explanation: 'r / p = 3 / 0.2 = 15 calls.',
    ),
    QuizQuestion(
      prompt: 'The negative binomial with r = 1 is the…',
      options: ['Binomial', 'Geometric', 'Poisson', 'Uniform'],
      answer: 1,
      explanation: 'Waiting for one success is exactly the geometric distribution.',
    ),
    QuizQuestion(
      prompt: 'Why must the last trial be a success?',
      options: [
        'Because trials are independent',
        'Because we stop the moment the r-th success arrives',
        'Because p > 0.5',
        'It doesn\'t have to be',
      ],
      answer: 1,
      explanation: 'The count ends on the r-th success, so it is always the final trial.',
    ),
  ],
);

// ===========================================================================
// Hypergeometric
// ===========================================================================

class HyperSim extends TickSim {
  HyperSim({super.rng}) {
    tick();
    draws = 0;
    counts = List.filled(n + 1, 0);
  }

  static const int total = 20, n = 5;
  int red = 8;
  List<int> drawn = [];
  int draws = 0;
  List<int> counts = List.filled(n + 1, 0);

  double pmf(int k) => k > red || n - k > total - red
      ? 0
      : combinations(red, k) * combinations(total - red, n - k) / combinations(total, n);

  @override
  double get interval => draws < 6 ? 1.0 : 0.08;

  @override
  void tick() {
    final order = List<int>.generate(total, (i) => i)..shuffle(rng);
    drawn = order.take(n).toList();
    draws++;
    counts[drawn.where((i) => i < red).length]++;
  }

  @override
  void restart() {
    draws = 0;
    counts = List.filled(n + 1, 0);
    drawn = [];
  }
}

void _paintHyper(Canvas canvas, Size size, HyperSim sim) {
  final w = size.width;
  final h = size.height;
  label(canvas, 'Bag of ${HyperSim.total}: ${sim.red} red · draw ${HyperSim.n} without putting back', Offset(w / 2, 12),
      size: 11, color: AppColors.muted);
  const cols = 10;
  final d = (w - 40) / cols;
  for (var i = 0; i < HyperSim.total; i++) {
    final c = Offset(20 + d * (i % cols + 0.5), 34 + (i ~/ cols) * d);
    final picked = sim.drawn.contains(i);
    canvas.drawCircle(c, d * 0.36,
        Paint()..color = (i < sim.red ? AppColors.pink : AppColors.blue).withValues(alpha: picked ? 1 : 0.3));
    if (picked) ring(canvas, c, d * 0.48, AppColors.ink, width: 2.5);
  }
  final redDrawn = sim.drawn.where((i) => i < sim.red).length;
  if (sim.drawn.isNotEmpty) {
    label(canvas, '$redDrawn red in this draw', Offset(w / 2, 34 + 2 * d), size: 13, color: AppColors.pink);
  }
  final top = 34 + 2 * d + 24;
  final obs = [for (var k = 0; k <= HyperSim.n; k++) sim.draws == 0 ? 0.0 : sim.counts[k] / sim.draws];
  final theory = [for (var k = 0; k <= HyperSim.n; k++) sim.pmf(k)];
  final binom = [for (var k = 0; k <= HyperSim.n; k++) binomPmf(HyperSim.n, k, sim.red / HyperSim.total)];
  final plot = Plot(Rect.fromLTRB(20, top, w - 20, h - 28),
      x0: -0.6, x1: HyperSim.n + 0.6, y1: math.max(theory.reduce(math.max), binom.reduce(math.max)) * 1.2);
  plot.intBars(canvas, obs, 0, (_) => AppColors.pink.withValues(alpha: 0.7));
  plot.intDots(canvas, binom, 0, AppColors.peg);
  plot.intDots(canvas, theory, 0, AppColors.ink);
  plot.axis(canvas, [for (var k = 0; k <= HyperSim.n; k++) k.toDouble()], title: 'red balls drawn');
  label(canvas, '● without replacement  ● with', Offset(w - 20, top),
      size: 10, color: AppColors.muted, align: TextAlign.right);
}

final LessonSpec hypergeometricLesson = LessonSpec(
  id: 'hypergeometric',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('Drawing '),
    TitlePart('without', AppColors.pink),
    TitlePart(' putting back'),
  ],
  subtitle: 'The hypergeometric distribution · 2-minute animated lesson',
  createSim: () => HyperSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<HyperSim>(sim, _paintHyper),
  stats: (sim) {
    final s = sim as HyperSim;
    return [
      StatChip('draws', '${s.draws}', AppColors.yellow),
      StatChip('mean red', (HyperSim.n * s.red / HyperSim.total).toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'Pick 5 balls from a bag of 20 and keep them out. Each red you take '
      'leaves fewer reds for the next pick, so the draws aren\'t independent and '
      'it isn\'t binomial. Count ways instead: choose which reds and which blues. '
      'The average is the same as with replacement, but the spread is smaller, '
      'because you can never draw the same ball twice. Card games and quality '
      'checks work like this.',
  formula: (sim) {
    final s = sim as HyperSim;
    return 'P(k red) = C(${s.red}, k) · C(${HyperSim.total - s.red}, 5 − k) / C(20, 5)';
  },
  tryItTitle: 'Try it: change how many are red',
  buildTryIt: (sim) {
    final s = sim as HyperSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'red ${s.red}',
            right: '15',
            value: s.red.toDouble(),
            min: 2,
            max: 15,
            divisions: 13,
            onChanged: (v) => s.change(() => s.red = v.round()),
          ),
          ControlRow(children: [ActionButton('Draw 500 times', () => s.runMany(500))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Which situation is hypergeometric, not binomial?',
      options: [
        'Flipping a coin 10 times',
        'Dealing 5 cards and counting hearts',
        'Rolling a die 6 times',
        'Asking 100 random people a question, with replacement',
      ],
      answer: 1,
      explanation: 'Dealt cards are not put back, so each draw changes the deck.',
    ),
    QuizQuestion(
      prompt: 'A box has 4 faulty and 6 good bulbs. You test 2 without replacement. P(both faulty)?',
      options: ['16/100', '12/90', '4/10', '2/10'],
      answer: 1,
      explanation: '4/10 × 3/9 = 12/90 = 2/15.',
    ),
    QuizQuestion(
      prompt: 'Compared with drawing WITH replacement, the hypergeometric spread is…',
      options: ['Larger', 'Smaller', 'The same', 'Zero'],
      answer: 1,
      explanation: 'Removing balls pushes the bag back towards balance, so extreme counts are rarer.',
    ),
  ],
);

// ===========================================================================
// Poisson
// ===========================================================================

class PoissonSim extends TickSim {
  PoissonSim({super.rng});

  double lambda = 3;

  /// Event times (fractions of a minute) for the last 8 minutes, newest last.
  final List<List<double>> minutes = [];
  List<int> counts = List.filled(20, 0);
  int observed = 0;

  double get mean {
    var s = 0;
    for (var k = 0; k < counts.length; k++) {
      s += k * counts[k];
    }
    return observed == 0 ? 0 : s / observed;
  }

  @override
  double get interval => observed < 6 ? 1.0 : 0.1;

  @override
  void tick() {
    final k = poissonDraw(rng, lambda);
    minutes.add(List.generate(k, (_) => rng.nextDouble()));
    if (minutes.length > 8) minutes.removeAt(0);
    counts[math.min(k, 19)]++;
    observed++;
  }

  @override
  void restart() {
    minutes.clear();
    counts = List.filled(20, 0);
    observed = 0;
  }
}

void _paintPoisson(Canvas canvas, Size size, PoissonSim sim) {
  final w = size.width;
  final h = size.height;
  label(canvas, 'Customers arriving · each box is one minute', Offset(15, 12),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  final boxW = (w - 30) / 8;
  for (var i = 0; i < sim.minutes.length; i++) {
    final r = Rect.fromLTWH(15 + i * boxW + 2, 26, boxW - 4, 56);
    final isNew = i == sim.minutes.length - 1;
    roundRect(canvas, r, isNew ? AppColors.yellow.withValues(alpha: 0.35) : Colors.white, radius: 8);
    final ev = sim.minutes[i];
    for (var j = 0; j < ev.length; j++) {
      canvas.drawCircle(Offset(r.left + 6 + ev[j] * (r.width - 12), r.top + 12 + (j % 4) * 10.0), 4,
          Paint()..color = AppColors.orange);
    }
    label(canvas, '${ev.length}', Offset(r.center.dx, r.bottom + 10),
        size: 12, color: isNew ? AppColors.ink : AppColors.muted);
  }
  final maxK = (sim.lambda * 2.6 + 4).ceil().clamp(6, 19);
  final obs = [for (var k = 0; k <= maxK; k++) sim.observed == 0 ? 0.0 : sim.counts[k] / sim.observed];
  final theory = [for (var k = 0; k <= maxK; k++) poissonPmf(sim.lambda, k)];
  final plot = Plot(Rect.fromLTRB(15, 120, w - 15, h - 28),
      x0: -0.6, x1: maxK + 0.6, y1: math.max(theory.reduce(math.max), obs.reduce(math.max)) * 1.15);
  plot.intBars(canvas, obs, 0, (_) => AppColors.orange.withValues(alpha: 0.75), widthFrac: 0.8);
  plot.intDots(canvas, theory, 0, AppColors.ink);
  plot.axis(canvas, [for (var k = 0; k <= maxK; k += maxK > 12 ? 2 : 1) k.toDouble()], title: 'customers in a minute');
}

final LessonSpec poissonLesson = LessonSpec(
  id: 'poisson',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('Counting '),
    TitlePart('random arrivals', AppColors.orange),
  ],
  subtitle: 'The Poisson distribution · 2-minute animated lesson',
  createSim: () => PoissonSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<PoissonSim>(sim, _paintPoisson),
  stats: (sim) {
    final s = sim as PoissonSim;
    return [
      StatChip('minutes', '${s.observed}', AppColors.yellow),
      StatChip('average', s.mean.toStringAsFixed(2), AppColors.orange),
      StatChip('λ', s.lambda.toStringAsFixed(1), AppColors.pink),
    ];
  },
  bigIdea: 'When events happen independently at a steady average rate (customers, '
      'calls, typos on a page), the number in a fixed window follows a Poisson '
      'distribution. One number describes it: λ, the average count. The variance is '
      'also λ. It\'s the binomial with a huge number of tiny chances: many people '
      'who each might, rarely, walk in.',
  formula: (sim) {
    final s = sim as PoissonSim;
    return 'P(X = k) = λ^k e^(−λ) / k!   P(0) = e^(−${s.lambda.toStringAsFixed(1)}) = '
        '${poissonPmf(s.lambda, 0).toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: change the arrival rate λ',
  buildTryIt: (sim) {
    final s = sim as PoissonSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'λ 0.5',
            right: '8',
            value: s.lambda,
            min: 0.5,
            max: 8,
            divisions: 15,
            label: 'λ = ${s.lambda}',
            onChanged: (v) => s.change(() => s.lambda = v),
          ),
          ControlRow(children: [ActionButton('Watch 1,000 minutes', () => s.runMany(1000))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A shop averages 2 customers a minute. What is P(no customers in a minute)?',
      options: ['0', 'e^(−2) ≈ 0.135', '0.5', '2/60'],
      answer: 1,
      explanation: 'P(0) = λ⁰e^(−λ)/0! = e^(−2).',
    ),
    QuizQuestion(
      prompt: 'A Poisson distribution has mean 5. Its variance is…',
      options: ['√5', '5', '25', '2.5'],
      answer: 1,
      explanation: 'For a Poisson, the variance equals the mean λ.',
    ),
    QuizQuestion(
      prompt: 'Which is best modelled by a Poisson distribution?',
      options: [
        'Heights of students',
        'Number of emails arriving in an hour',
        'Heads in 10 coin flips',
        'Time until a bulb fails',
      ],
      answer: 1,
      explanation: 'Independent arrivals counted in a fixed window. Heads in 10 flips is binomial.',
    ),
  ],
);

// ===========================================================================
// Discrete uniform
// ===========================================================================

class DiscreteUniformSim extends TickSim {
  DiscreteUniformSim({super.rng});

  int faces = 6;
  List<int> counts = List.filled(13, 0);
  int rolls = 0;
  int last = 1;

  @override
  double get interval => rolls < 8 ? 0.6 : 0.04;

  @override
  void tick() {
    last = 1 + rng.nextInt(faces);
    counts[last]++;
    rolls++;
  }

  @override
  void restart() {
    counts = List.filled(13, 0);
    rolls = 0;
  }
}

void _paintDU(Canvas canvas, Size size, DiscreteUniformSim sim) {
  final w = size.width;
  final h = size.height;
  // A spinner with n equal sectors.
  final c = Offset(w / 2, 62);
  const r = 48.0;
  for (var i = 0; i < sim.faces; i++) {
    final a0 = -math.pi / 2 + 2 * math.pi * i / sim.faces;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, 2 * math.pi / sim.faces, true,
        Paint()..color = AppColors.rainbow[i % 7].withValues(alpha: i + 1 == sim.last && sim.rolls > 0 ? 1 : 0.45));
    final mid = a0 + math.pi / sim.faces;
    label(canvas, '${i + 1}', c + Offset(math.cos(mid), math.sin(mid)) * r * 0.7, size: 10, color: AppColors.ink);
  }
  ring(canvas, c, r, Colors.white, width: 2);
  final obs = [for (var k = 1; k <= sim.faces; k++) sim.rolls == 0 ? 0.0 : sim.counts[k] / sim.rolls];
  final plot =
      Plot(Rect.fromLTRB(15, 130, w - 15, h - 28), x0: 0.4, x1: sim.faces + 0.6, y1: math.max(1.6 / sim.faces, 0.2));
  plot.intBars(canvas, obs, 1, (k) => AppColors.rainbow[(k - 1) % 7].withValues(alpha: 0.8), widthFrac: 0.75);
  dashedLine(canvas, plot.at(0.4, 1 / sim.faces), plot.at(sim.faces + 0.6, 1 / sim.faces), AppColors.ink);
  label(canvas, '1/${sim.faces}', plot.at(sim.faces + 0.6, 1 / sim.faces).translate(-2, -10),
      size: 11, align: TextAlign.right);
  plot.axis(canvas, [for (var k = 1; k <= sim.faces; k++) k.toDouble()]);
}

final LessonSpec discreteUniformLesson = LessonSpec(
  id: 'discrete_uniform',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('Every value '),
    TitlePart('equally likely', AppColors.violet),
  ],
  subtitle: 'The discrete uniform distribution · 2-minute animated lesson',
  createSim: () => DiscreteUniformSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<DiscreteUniformSim>(sim, _paintDU),
  stats: (sim) {
    final s = sim as DiscreteUniformSim;
    final mean =
        s.rolls == 0 ? 0 : [for (var k = 1; k <= s.faces; k++) k * s.counts[k]].reduce((a, b) => a + b) / s.rolls;
    return [
      StatChip('spins', '${s.rolls}', AppColors.yellow),
      StatChip('average', mean.toStringAsFixed(2), AppColors.violet),
      StatChip('(n+1)/2', ((s.faces + 1) / 2).toStringAsFixed(1), AppColors.pink),
    ];
  },
  bigIdea: 'A fair die, a lottery ball, a random seat: n outcomes, each with chance '
      '1/n. The bars are flat. The average sits in the middle at (n + 1)/2, and '
      'the variance (n² − 1)/12 grows quickly as more values are added, because '
      'the outer values are just as likely as the middle ones.',
  formula: (sim) {
    final s = sim as DiscreteUniformSim;
    final n = s.faces;
    return 'P(X = k) = 1/$n   E[X] = ${((n + 1) / 2).toStringAsFixed(1)}   Var = (n² − 1)/12 = '
        '${((n * n - 1) / 12).toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: more sectors',
  buildTryIt: (sim) {
    final s = sim as DiscreteUniformSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'n = ${s.faces}',
            right: '12',
            value: s.faces.toDouble(),
            min: 2,
            max: 12,
            divisions: 10,
            onChanged: (v) => s.change(() => s.faces = v.round()),
          ),
          ControlRow(children: [ActionButton('Spin 1,000 times', () => s.runMany(1000))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A spinner has 8 equal sectors numbered 1–8. P(landing on 3)?',
      options: ['1/3', '1/8', '3/8', '1/2'],
      answer: 1,
      explanation: 'Eight equally likely outcomes: 1/8 each.',
    ),
    QuizQuestion(
      prompt: 'What is the expected value of a fair 10-sided die (1–10)?',
      options: ['5', '5.5', '10', '1'],
      answer: 1,
      explanation: '(n + 1)/2 = 11/2 = 5.5.',
    ),
    QuizQuestion(
      prompt: 'Is the sum of two dice uniformly distributed?',
      options: ['Yes', 'No: middle totals are more likely', 'Only for fair dice', 'Only for 6-sided dice'],
      answer: 1,
      explanation: 'Each die is uniform, but more combinations make 7 than 2 or 12.',
    ),
  ],
);

// ===== lib/lessons/ch08_continuous.dart =====
// Chapter 8 · Continuous distributions.

/// A sim that keeps drawing values into a list (capped) for a density histogram.
abstract class SampleSim extends TickSim {
  SampleSim({super.rng});

  final List<double> values = [];
  static const int cap = 6000;

  double draw();

  @override
  double get interval => values.length < 30 ? 0.12 : 0.012;

  @override
  void tick() {
    if (values.length < cap) values.add(draw());
  }

  @override
  void restart() => values.clear();
}

// ===========================================================================
// Continuous uniform
// ===========================================================================

class UniformWaitSim extends SampleSim {
  UniformWaitSim({super.rng});

  /// Buses come every 10 minutes; you turn up at a random moment.
  static const double gap = 10;
  double threshold = 3;

  @override
  double draw() => rng.nextDouble() * gap;

  double get observed => values.isEmpty ? 0 : values.where((v) => v <= threshold).length / values.length;

  void setThreshold(double t) {
    threshold = t;
    notifyListeners();
  }
}

void _paintUniform(Canvas canvas, Size size, UniformWaitSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(20, 40, w - 20, h - 40), x0: 0, x1: 10, y1: 0.16);
  label(canvas, 'Your wait for the bus (minutes)', Offset(w / 2, 14), size: 12);
  final shade = Rect.fromLTRB(plot.x(0), plot.y(0.1), plot.x(sim.threshold), plot.y(0));
  canvas.drawRect(shade, Paint()..color = AppColors.pink.withValues(alpha: 0.18));
  plot.densityBars(canvas, binCounts(sim.values, 0, 10, 20), 0, 10, AppColors.cyan.withValues(alpha: 0.7));
  line(canvas, plot.at(0, 0.1), plot.at(10, 0.1), AppColors.ink, width: 3);
  label(canvas, 'density = 1/10', plot.at(10, 0.1).translate(-4, -12), size: 11, align: TextAlign.right);
  line(canvas, plot.at(sim.threshold, 0), plot.at(sim.threshold, 0.13), AppColors.pink, width: 2.5);
  label(canvas, 'wait ≤ ${sim.threshold.toStringAsFixed(1)} min', plot.at(sim.threshold, 0.14),
      size: 12, color: AppColors.pink);
  if (sim.values.isNotEmpty) {
    final last = sim.values.last;
    canvas.drawCircle(plot.at(last, 0.003), 6, Paint()..color = AppColors.orange);
  }
  plot.axis(canvas, [0, 2, 4, 6, 8, 10]);
}

final LessonSpec continuousUniformLesson = LessonSpec(
  id: 'continuous_uniform',
  chapterLabel: 'Ch 8 · Continuous distributions',
  title: const [
    TitlePart('Probability as '),
    TitlePart('area', AppColors.pink),
    TitlePart(' under a flat line'),
  ],
  subtitle: 'The continuous uniform distribution · 2-minute animated lesson',
  createSim: () => UniformWaitSim(),
  visualAspectRatio: 1.15,
  buildVisual: (sim) => simCanvas<UniformWaitSim>(sim, _paintUniform),
  stats: (sim) {
    final s = sim as UniformWaitSim;
    return [
      StatChip('arrivals', '${s.values.length}', AppColors.yellow),
      StatChip('seen', s.observed.toStringAsFixed(3), AppColors.cyan),
      StatChip('theory', (s.threshold / 10).toStringAsFixed(3), AppColors.pink),
    ];
  },
  bigIdea: 'Buses leave every 10 minutes and you arrive at a random moment, so any wait '
      'from 0 to 10 minutes is equally likely. For a continuous variable we draw a '
      'density curve, and probability is the area under it. Here the curve is flat '
      'at height 1/10, so the chance of waiting at most t minutes is just the '
      'rectangle t × 1/10.',
  formula: (sim) {
    final s = sim as UniformWaitSim;
    return 'P(X ≤ t) = (t − a)/(b − a) = ${s.threshold.toStringAsFixed(1)}/10 = ${(s.threshold / 10).toStringAsFixed(2)}'
        '   E[X] = (a + b)/2 = 5';
  },
  tryItTitle: 'Try it: how long are you willing to wait?',
  buildTryIt: (sim) {
    final s = sim as UniformWaitSim;
    return watch(
      s,
      () => LabeledSlider(
        left: '0 min',
        right: '10',
        value: s.threshold,
        min: 0.5,
        max: 10,
        divisions: 19,
        label: '${s.threshold.toStringAsFixed(1)} min',
        onChanged: s.setThreshold,
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'X is uniform on 0–20. What is P(5 ≤ X ≤ 9)?',
      options: ['4/20', '5/20', '9/20', '1/4'],
      answer: 0,
      explanation: 'Width of the interval over the total width: 4/20 = 0.2.',
    ),
    QuizQuestion(
      prompt: 'A uniform density on 0–4 has what height?',
      options: ['1', '4', '1/4', '1/2'],
      answer: 2,
      explanation: 'The total area must be 1: width 4 × height 1/4.',
    ),
    QuizQuestion(
      prompt: 'For a continuous variable, probability is…',
      options: ['The height of the curve', 'The area under the curve', 'Always 1/n', 'The slope'],
      answer: 1,
      explanation: 'Heights are densities; areas over intervals are probabilities.',
    ),
  ],
);

// ===========================================================================
// The normal curve
// ===========================================================================

class NormalCurveSim extends SampleSim {
  NormalCurveSim({super.rng});

  double mu = 0;
  double sd = 1.5;

  @override
  double draw() => mu + sd * normalDraw(rng);
}

void _paintNormal(Canvas canvas, Size size, NormalCurveSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(16, 24, w - 16, h - 34), x0: -8, x1: 8, y1: 0.85);
  plot.densityBars(canvas, binCounts(sim.values, -8, 8, 48), -8, 8, AppColors.violet.withValues(alpha: 0.45),
      total: sim.values.length);
  plot.curve(canvas, (x) => normalPdf(x, sim.mu, sim.sd), AppColors.pink, width: 3);
  dashedLine(canvas, plot.at(sim.mu, 0), plot.at(sim.mu, normalPdf(sim.mu, sim.mu, sim.sd)), AppColors.ink);
  label(canvas, 'μ', plot.at(sim.mu, 0).translate(0, -10), size: 13);
  final y = plot.y(normalPdf(sim.mu + sim.sd, sim.mu, sim.sd));
  line(canvas, Offset(plot.x(sim.mu), y), Offset(plot.x(sim.mu + sim.sd), y), AppColors.orange, width: 2.5);
  label(canvas, 'σ', Offset(plot.x(sim.mu + sim.sd / 2), y - 10), size: 13, color: AppColors.orange);
  plot.axis(canvas, [-8, -6, -4, -2, 0, 2, 4, 6, 8]);
}

final LessonSpec normalCurveLesson = LessonSpec(
  id: 'normal_curve',
  chapterLabel: 'Ch 8 · Continuous distributions',
  title: const [
    TitlePart('The '),
    TitlePart('bell curve', AppColors.pink),
    TitlePart(': two numbers set its shape'),
  ],
  subtitle: 'The normal distribution · 2-minute animated lesson',
  createSim: () => NormalCurveSim(),
  visualAspectRatio: 1.15,
  buildVisual: (sim) => simCanvas<NormalCurveSim>(sim, _paintNormal),
  stats: (sim) {
    final s = sim as NormalCurveSim;
    return [
      StatChip('samples', '${s.values.length}', AppColors.yellow),
      StatChip('mean', meanOf(s.values).toStringAsFixed(2), AppColors.pink),
      StatChip('sd', sdOf(s.values).toStringAsFixed(2), AppColors.orange),
    ];
  },
  bigIdea: 'Heights, measurement errors, test scores: anything built from many small '
      'independent nudges tends to pile into a bell. The mean μ says where the '
      'peak is; the standard deviation σ says how wide it is. A wider bell must '
      'be shorter, because the total area is always 1.',
  formula: (sim) {
    final s = sim as NormalCurveSim;
    return 'f(x) = e^(−(x−μ)²/2σ²) / (σ√(2π))   peak = ${normalPdf(s.mu, s.mu, s.sd).toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: move and stretch the bell',
  buildTryIt: (sim) {
    final s = sim as NormalCurveSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'μ ${s.mu.toStringAsFixed(1)}',
            right: '',
            value: s.mu,
            min: -3,
            max: 3,
            divisions: 12,
            onChanged: (v) => s.change(() => s.mu = v),
          ),
          LabeledSlider(
            left: 'σ ${s.sd.toStringAsFixed(1)}',
            right: '',
            value: s.sd,
            min: 0.5,
            max: 2.5,
            divisions: 8,
            onChanged: (v) => s.change(() => s.sd = v),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Two normal curves have the same mean; one has a larger σ. It is…',
      options: ['Taller and narrower', 'Shorter and wider', 'Shifted right', 'Identical'],
      answer: 1,
      explanation: 'The area stays 1, so spreading out must lower the peak.',
    ),
    QuizQuestion(
      prompt: 'In a normal distribution, the mean, median and mode are…',
      options: ['All different', 'All equal', 'Mean > median', 'Undefined'],
      answer: 1,
      explanation: 'The bell is symmetric with one peak, so all three sit at the centre.',
    ),
    QuizQuestion(
      prompt: 'Which quantity is most likely to be roughly normal?',
      options: ['Household incomes', 'Adult heights of one sex', 'Waiting times', 'Number of children'],
      answer: 1,
      explanation: 'Heights come from many small genetic and environmental effects. Incomes are skewed.',
    ),
  ],
);

// ===========================================================================
// Standard normal & z-tables
// ===========================================================================

class StandardNormalSim extends LessonSim {
  double t = 0;
  double? manual;

  double get z => manual ?? -3 + 6 * ((math.sin(t * 0.6 - math.pi / 2) + 1) / 2);

  @override
  void advance(double dt) {
    if (manual == null) t += dt;
    notifyListeners();
  }

  @override
  void step() {
    manual = ((z * 2).round() + 1) / 2;
    if (manual! > 3) manual = -3;
    notifyListeners();
  }

  @override
  void reset() {
    manual = null;
    t = 0;
    notifyListeners();
  }

  void setZ(double v) {
    manual = v;
    notifyListeners();
  }
}

void _paintStdNormal(Canvas canvas, Size size, StandardNormalSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(16, 26, w - 16, h * 0.62), x0: -3.6, x1: 3.6, y1: 0.45);
  plot.curve(canvas, normalPdf, AppColors.blue, fill: true, from: -3.6, to: sim.z);
  plot.curve(canvas, normalPdf, AppColors.ink, width: 2.5);
  line(canvas, plot.at(sim.z, 0), plot.at(sim.z, normalPdf(sim.z) + 0.04), AppColors.pink, width: 2.5);
  label(canvas, 'z = ${sim.z.toStringAsFixed(2)}', plot.at(sim.z, normalPdf(sim.z) + 0.06),
      size: 12, color: AppColors.pink);
  label(canvas, 'Φ(z) = ${normalCdf(sim.z).toStringAsFixed(4)}', plot.at(-3.4, 0.38),
      size: 14, color: AppColors.blue, align: TextAlign.left);
  plot.axis(canvas, [-3, -2, -1, 0, 1, 2, 3]);

  // A slice of the z-table around the current z.
  final top = h * 0.62 + 34;
  label(canvas, 'z-table (area to the left)', Offset(w / 2, top), size: 11, color: AppColors.muted);
  final base = (sim.z * 10).round() / 10;
  final rowH = (h - top - 14) / 5;
  for (var i = -2; i <= 2; i++) {
    final zz = base + i * 0.1;
    final y = top + 14 + (i + 2.5) * rowH;
    if (i == 0) {
      roundRect(
          canvas, Rect.fromLTWH(w * 0.2, y - rowH / 2 + 1, w * 0.6, rowH - 2), AppColors.yellow.withValues(alpha: 0.4));
    }
    label(canvas, zz.toStringAsFixed(1), Offset(w * 0.33, y),
        size: 12, color: i == 0 ? AppColors.ink : AppColors.muted);
    label(canvas, normalCdf(zz).toStringAsFixed(4), Offset(w * 0.62, y),
        size: 12, color: i == 0 ? AppColors.ink : AppColors.muted);
  }
}

final LessonSpec standardNormalLesson = LessonSpec(
  id: 'standard_normal',
  chapterLabel: 'Ch 8 · Continuous distributions',
  title: const [
    TitlePart('One bell to '),
    TitlePart('look them all up', AppColors.blue),
  ],
  subtitle: 'Standard normal & z-tables · 2-minute animated lesson',
  createSim: () => StandardNormalSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<StandardNormalSim>(sim, _paintStdNormal),
  stats: (sim) {
    final s = sim as StandardNormalSim;
    return [
      StatChip('z', s.z.toStringAsFixed(2), AppColors.pink),
      StatChip('left of z', normalCdf(s.z).toStringAsFixed(3), AppColors.blue),
      StatChip('right of z', (1 - normalCdf(s.z)).toStringAsFixed(3), AppColors.orange),
    ];
  },
  bigIdea: 'The standard normal has mean 0 and sd 1. Any normal value can be turned into '
      'a z-score, z = (x − μ)/σ, and then every question becomes a question about '
      'this one curve. The z-table lists Φ(z), the area to the left of z: the '
      'chance of a value at or below it. Right-hand areas are 1 − Φ(z).',
  formula: (sim) {
    final s = sim as StandardNormalSim;
    return 'P(Z ≤ ${s.z.toStringAsFixed(2)}) = Φ(${s.z.toStringAsFixed(2)}) = ${normalCdf(s.z).toStringAsFixed(4)}';
  },
  tryItTitle: 'Try it: pick a z-score',
  buildTryIt: (sim) {
    final s = sim as StandardNormalSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '−3',
            right: '+3',
            value: s.z,
            min: -3,
            max: 3,
            divisions: 60,
            label: 'z = ${s.z.toStringAsFixed(1)}',
            onChanged: s.setZ,
          ),
          const TryNote('Try z = 1.96: 97.5% is to the left, leaving 2.5% in the right tail.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Φ(0) equals…',
      options: ['0', '0.5', '1', '0.68'],
      answer: 1,
      explanation: 'Half the symmetric curve lies left of its centre.',
    ),
    QuizQuestion(
      prompt: 'Φ(1.5) = 0.933. What is P(Z > 1.5)?',
      options: ['0.933', '0.067', '0.5', '1.5'],
      answer: 1,
      explanation: '1 − 0.933 = 0.067.',
    ),
    QuizQuestion(
      prompt: 'Heights: μ = 160 cm, σ = 8 cm. Which z-score does 172 cm have?',
      options: ['1.2', '1.5', '12', '0.67'],
      answer: 1,
      explanation: '(172 − 160)/8 = 1.5.',
    ),
  ],
);

// ===========================================================================
// 68-95-99.7 rule
// ===========================================================================

class RuleSim extends SampleSim {
  RuleSim({super.rng});

  @override
  double draw() => normalDraw(rng);

  double within(int k) => values.isEmpty ? 0 : values.where((v) => v.abs() <= k).length / values.length;

  /// Band highlighted by the animation (1–3).
  int get band => 1 + (values.length ~/ 400) % 3;
}

void _paintRule(Canvas canvas, Size size, RuleSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(16, 20, w - 16, h - 96), x0: -4, x1: 4, y1: 0.45);
  const colors = [AppColors.green, AppColors.cyan, AppColors.violet];
  for (var k = 3; k >= 1; k--) {
    plot.curve(canvas, normalPdf, colors[k - 1].withValues(alpha: sim.band == k ? 1 : 0.5),
        fill: true, from: -k.toDouble(), to: k.toDouble(), width: 0.5);
  }
  plot.densityBars(canvas, binCounts(sim.values, -4, 4, 40), -4, 4, AppColors.ink.withValues(alpha: 0.18));
  plot.curve(canvas, normalPdf, AppColors.ink, width: 2);
  plot.axis(canvas, [-3, -2, -1, 0, 1, 2, 3], format: (v) => v == 0 ? 'μ' : '${v > 0 ? '+' : ''}${v.round()}σ');
  for (var k = 1; k <= 3; k++) {
    final y = h - 76 + (k - 1) * 24.0;
    roundRect(canvas, Rect.fromLTWH(16, y - 8, 16, 16), colors[k - 1], radius: 4);
    final theory = 2 * normalCdf(k.toDouble()) - 1;
    label(
        canvas,
        'within $kσ: ${(sim.within(k) * 100).toStringAsFixed(1)}%   (rule: ${(theory * 100).toStringAsFixed(1)}%)',
        Offset(40, y),
        size: 13,
        align: TextAlign.left,
        color: sim.band == k ? AppColors.ink : AppColors.muted);
  }
}

final LessonSpec ruleLesson = LessonSpec(
  id: 'rule_68_95',
  chapterLabel: 'Ch 8 · Continuous distributions',
  title: const [
    TitlePart('68', AppColors.green),
    TitlePart(' · '),
    TitlePart('95', AppColors.cyan),
    TitlePart(' · '),
    TitlePart('99.7', AppColors.violet),
  ],
  subtitle: 'The 68-95-99.7 rule · 2-minute animated lesson',
  createSim: () => RuleSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<RuleSim>(sim, _paintRule),
  stats: (sim) {
    final s = sim as RuleSim;
    return [
      StatChip('samples', '${s.values.length}', AppColors.yellow),
      StatChip('within 1σ', '${(s.within(1) * 100).toStringAsFixed(0)}%', AppColors.green),
      StatChip('within 2σ', '${(s.within(2) * 100).toStringAsFixed(0)}%', AppColors.cyan),
    ];
  },
  bigIdea: 'For any normal distribution, about 68% of values fall within one standard '
      'deviation of the mean, 95% within two, and 99.7% within three. It\'s a quick '
      'mental check: if adult height has mean 165 cm and sd 7 cm, almost everyone is '
      'between 144 and 186 cm, and anyone outside that is genuinely rare.',
  formula: (_) => 'P(|Z| ≤ 1) ≈ 0.683 · P(|Z| ≤ 2) ≈ 0.954 · P(|Z| ≤ 3) ≈ 0.997',
  tryItTitle: 'Try it: sample faster',
  buildTryIt: (sim) {
    final s = sim as RuleSim;
    return ControlRow(children: [
      ActionButton('Add 2,000 values', () => s.runMany(2000)),
      ActionButton('Start over', s.reset),
    ]);
  },
  quiz: const [
    QuizQuestion(
      prompt: 'IQ scores: mean 100, sd 15. About what share of people score between 70 and 130?',
      options: ['68%', '95%', '99.7%', '50%'],
      answer: 1,
      explanation: '70 and 130 are 2 sd either side of the mean.',
    ),
    QuizQuestion(
      prompt: 'About what share of a normal distribution lies more than 1 sd ABOVE the mean?',
      options: ['32%', '16%', '5%', '2.5%'],
      answer: 1,
      explanation: '32% lies outside ±1 sd, split equally between the two tails.',
    ),
    QuizQuestion(
      prompt: 'A value is 3.5 sd from the mean. It is…',
      options: ['Typical', 'Fairly common', 'Very unusual', 'Impossible'],
      answer: 2,
      explanation: 'Fewer than 0.3% of values are beyond 3 sd.',
    ),
  ],
);

// ===========================================================================
// Exponential
// ===========================================================================

class ExponentialSim extends SampleSim {
  ExponentialSim({super.rng});

  double rate = 1;

  /// Arrival times on the visible timeline.
  final List<double> arrivals = [];
  double clock = 0;

  @override
  double draw() {
    final gap = expDraw(rng, rate);
    clock += gap;
    arrivals.add(clock);
    if (arrivals.length > 14) arrivals.removeAt(0);
    return gap;
  }

  @override
  void restart() {
    super.restart();
    arrivals.clear();
    clock = 0;
  }
}

void _paintExponential(Canvas canvas, Size size, ExponentialSim sim) {
  final w = size.width;
  final h = size.height;
  // Timeline of the latest arrivals.
  label(canvas, 'Arrivals (gaps between them are the waits)', Offset(16, 12),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  if (sim.arrivals.isNotEmpty) {
    final end = sim.arrivals.last;
    final start = sim.arrivals.first;
    final span = math.max(1e-6, end - start);
    line(canvas, const Offset(16, 40), Offset(w - 16, 40), AppColors.peg);
    for (var i = 0; i < sim.arrivals.length; i++) {
      final x = 16 + (sim.arrivals[i] - start) / span * (w - 32);
      canvas.drawCircle(
          Offset(x, 40), 6, Paint()..color = i == sim.arrivals.length - 1 ? AppColors.pink : AppColors.orange);
    }
  }
  final xmax = 5 / sim.rate;
  final plot = Plot(Rect.fromLTRB(16, 70, w - 16, h - 34), x0: 0, x1: xmax, y1: sim.rate * 1.1);
  plot.densityBars(canvas, binCounts(sim.values, 0, xmax, 30), 0, xmax, AppColors.orange.withValues(alpha: 0.55),
      total: sim.values.length);
  plot.curve(canvas, (x) => sim.rate * math.exp(-sim.rate * x), AppColors.ink);
  dashedLine(canvas, plot.at(1 / sim.rate, 0), plot.at(1 / sim.rate, sim.rate * 0.9), AppColors.pink);
  label(canvas, 'mean 1/λ', plot.at(1 / sim.rate, sim.rate * 0.95), size: 11, color: AppColors.pink);
  plot.axis(canvas, [for (var i = 0; i <= 5; i++) i / sim.rate], title: 'wait');
}

final LessonSpec exponentialLesson = LessonSpec(
  id: 'exponential',
  chapterLabel: 'Ch 8 · Continuous distributions',
  title: const [
    TitlePart('The time '),
    TitlePart('between', AppColors.orange),
    TitlePart(' random events'),
  ],
  subtitle: 'The exponential distribution · 2-minute animated lesson',
  createSim: () => ExponentialSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<ExponentialSim>(sim, _paintExponential),
  stats: (sim) {
    final s = sim as ExponentialSim;
    return [
      StatChip('waits', '${s.values.length}', AppColors.yellow),
      StatChip('average', meanOf(s.values).toStringAsFixed(2), AppColors.orange),
      StatChip('1/λ', (1 / s.rate).toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'If events arrive at random with rate λ (a Poisson process), the waits '
      'between them follow an exponential curve: short waits are most common, long '
      'ones rarer and rarer. The average wait is 1/λ. It is memoryless: having waited '
      '10 minutes already doesn\'t bring the next arrival any closer.',
  formula: (sim) {
    final s = sim as ExponentialSim;
    return 'f(x) = λe^(−λx)   P(X > t) = e^(−λt)   P(X > 1) = ${math.exp(-s.rate).toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: change the arrival rate λ',
  buildTryIt: (sim) {
    final s = sim as ExponentialSim;
    return watch(
      s,
      () => LabeledSlider(
        left: 'λ ${s.rate.toStringAsFixed(1)}',
        right: '4',
        value: s.rate,
        min: 0.5,
        max: 4,
        divisions: 7,
        onChanged: (v) => s.change(() => s.rate = v),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Calls arrive at 4 per hour on average. Average time between calls?',
      options: ['4 hours', '15 minutes', '4 minutes', '1 hour'],
      answer: 1,
      explanation: '1/λ = 1/4 hour = 15 minutes.',
    ),
    QuizQuestion(
      prompt: 'You\'ve waited 10 minutes for the next random arrival. The expected extra wait is…',
      options: ['Shorter than usual', 'The same as from the start', 'Longer', 'Zero'],
      answer: 1,
      explanation: 'The exponential is memoryless: the past wait tells you nothing.',
    ),
    QuizQuestion(
      prompt: 'Which wait is most likely to fall in a short interval?',
      options: ['Near 0', 'Near the mean', 'Far beyond the mean', 'All equal'],
      answer: 0,
      explanation: 'The density is highest at 0 and falls away.',
    ),
  ],
);

// ===========================================================================
// Gamma & Beta
// ===========================================================================

enum GammaBeta { gamma, beta }

class GammaBetaSim extends SampleSim {
  GammaBetaSim({super.rng});

  GammaBeta kind = GammaBeta.gamma;
  int a = 3;
  int b = 2;

  double _gamma(int shape) {
    var s = 0.0;
    for (var i = 0; i < shape; i++) {
      s += expDraw(rng, 1);
    }
    return s;
  }

  @override
  double draw() {
    if (kind == GammaBeta.gamma) return _gamma(a);
    final x = _gamma(a), y = _gamma(b);
    return x / (x + y);
  }
}

void _paintGammaBeta(Canvas canvas, Size size, GammaBetaSim sim) {
  final w = size.width;
  final h = size.height;
  final isGamma = sim.kind == GammaBeta.gamma;
  final lo = 0.0, hi = isGamma ? math.max(10.0, sim.a * 3.0) : 1.0;
  double pdf(double x) => isGamma ? gammaPdf(x, sim.a.toDouble()) : betaPdf(x, sim.a.toDouble(), sim.b.toDouble());
  var peak = 0.0;
  for (var i = 1; i < 200; i++) {
    peak = math.max(peak, pdf(lo + (hi - lo) * i / 200));
  }
  final plot = Plot(Rect.fromLTRB(16, 34, w - 16, h - 34), x0: lo, x1: hi, y1: math.min(peak * 1.25, 6));
  label(
    canvas,
    isGamma ? 'Total wait for ${sim.a} random arrivals (rate 1)' : 'Share X/(X+Y): ${sim.a} vs ${sim.b} arrivals',
    Offset(w / 2, 14),
    size: 12,
  );
  plot.densityBars(canvas, binCounts(sim.values, lo, hi, 40), lo, hi,
      (isGamma ? AppColors.orange : AppColors.green).withValues(alpha: 0.5),
      total: sim.values.length);
  plot.curve(canvas, pdf, AppColors.ink);
  plot.axis(canvas, isGamma ? [for (var t = 0.0; t <= hi; t += hi > 20 ? 5 : 2) t] : [0, 0.25, 0.5, 0.75, 1]);
}

final LessonSpec gammaBetaLesson = LessonSpec(
  id: 'gamma_beta',
  chapterLabel: 'Ch 8 · Continuous distributions',
  title: const [
    TitlePart('Gamma', AppColors.orange),
    TitlePart(' adds up waits, '),
    TitlePart('Beta', AppColors.green),
    TitlePart(' describes shares'),
  ],
  subtitle: 'Gamma & Beta distributions · 3-minute animated lesson',
  createSim: () => GammaBetaSim(),
  visualAspectRatio: 1.1,
  buildVisual: (sim) => simCanvas<GammaBetaSim>(sim, _paintGammaBeta),
  stats: (sim) {
    final s = sim as GammaBetaSim;
    final mean = s.kind == GammaBeta.gamma ? s.a.toDouble() : s.a / (s.a + s.b);
    return [
      StatChip('samples', '${s.values.length}', AppColors.yellow),
      StatChip('average', meanOf(s.values).toStringAsFixed(2), AppColors.violet),
      StatChip('theory', mean.toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'Gamma: add up the waits for k random arrivals and you get a Gamma(k) '
      'distribution, skewed for small k and more bell-like as k grows. Beta: take '
      'two Gamma totals X and Y and ask what share X/(X + Y) is. That share always '
      'lies between 0 and 1, which is why the Beta is the go-to model for unknown '
      'proportions, like a click-through rate, in Bayesian statistics.',
  formula: (sim) {
    final s = sim as GammaBetaSim;
    return s.kind == GammaBeta.gamma
        ? 'Gamma(k = ${s.a}): mean k = ${s.a}, variance k = ${s.a}'
        : 'Beta(a = ${s.a}, b = ${s.b}): mean a/(a+b) = ${(s.a / (s.a + s.b)).toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: switch and reshape',
  buildTryIt: (sim) {
    final s = sim as GammaBetaSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<GammaBeta>(
            options: const {GammaBeta.gamma: 'Gamma', GammaBeta.beta: 'Beta'},
            selected: s.kind,
            onSelected: (v) => s.change(() => s.kind = v),
          ),
          LabeledSlider(
            left: s.kind == GammaBeta.gamma ? 'k = ${s.a}' : 'a = ${s.a}',
            right: '8',
            value: s.a.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            onChanged: (v) => s.change(() => s.a = v.round()),
          ),
          if (s.kind == GammaBeta.beta)
            LabeledSlider(
              left: 'b = ${s.b}',
              right: '8',
              value: s.b.toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              onChanged: (v) => s.change(() => s.b = v.round()),
            ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Gamma with k = 1 is the same as which distribution?',
      options: ['Normal', 'Exponential', 'Uniform', 'Poisson'],
      answer: 1,
      explanation: 'The wait for a single arrival is exponential.',
    ),
    QuizQuestion(
      prompt: 'Which values can a Beta-distributed variable take?',
      options: ['Any real number', 'Only 0 or 1', 'Between 0 and 1', 'Positive integers'],
      answer: 2,
      explanation: 'It models proportions, so it lives on 0–1.',
    ),
    QuizQuestion(
      prompt: 'Beta(1, 1) is…',
      options: ['A spike at 0.5', 'Flat (uniform) on 0–1', 'Bell-shaped', 'Skewed right'],
      answer: 1,
      explanation: 'With a = b = 1 every share is equally likely.',
    ),
  ],
);

// ===========================================================================
// t, chi-square & F
// ===========================================================================

enum SamplingDist { t, chi2, f }

class TChiFSim extends SampleSim {
  TChiFSim({super.rng});

  SamplingDist kind = SamplingDist.t;
  int df = 4;

  double _chi2(int k) {
    var s = 0.0;
    for (var i = 0; i < k; i++) {
      final z = normalDraw(rng);
      s += z * z;
    }
    return s;
  }

  @override
  double draw() => switch (kind) {
        SamplingDist.t => normalDraw(rng) / math.sqrt(_chi2(df) / df),
        SamplingDist.chi2 => _chi2(df),
        SamplingDist.f => (_chi2(df) / df) / (_chi2(df) / df),
      };

  (double, double) get range => switch (kind) {
        SamplingDist.t => (-5.0, 5.0),
        SamplingDist.chi2 => (0.0, math.max(12.0, df * 2.6)),
        SamplingDist.f => (0.0, 5.0),
      };

  double pdf(double x) => switch (kind) {
        SamplingDist.t => tPdf(x, df.toDouble()),
        SamplingDist.chi2 => chi2Pdf(x, df.toDouble()),
        SamplingDist.f => fPdf(x, df.toDouble(), df.toDouble()),
      };
}

void _paintTChiF(Canvas canvas, Size size, TChiFSim sim) {
  final w = size.width;
  final h = size.height;
  final (lo, hi) = sim.range;
  var peak = 0.0;
  for (var i = 1; i < 200; i++) {
    peak = math.max(peak, sim.pdf(lo + (hi - lo) * i / 200));
  }
  if (sim.kind == SamplingDist.t) peak = math.max(peak, normalPdf(0));
  final plot = Plot(Rect.fromLTRB(16, 34, w - 16, h - 34), x0: lo, x1: hi, y1: math.min(peak * 1.2, 1.5));
  final title = switch (sim.kind) {
    SamplingDist.t => 'Z ÷ √(χ²/df): the t statistic',
    SamplingDist.chi2 => 'Sum of ${sim.df} squared normals',
    SamplingDist.f => 'Ratio of two (χ²/df) values',
  };
  label(canvas, title, Offset(w / 2, 14), size: 12);
  plot.densityBars(canvas, binCounts(sim.values, lo, hi, 50), lo, hi, AppColors.violet.withValues(alpha: 0.4),
      total: sim.values.length);
  if (sim.kind == SamplingDist.t) {
    plot.curve(canvas, normalPdf, AppColors.peg, width: 2);
    label(canvas, 'grey: normal', Offset(w - 18, 34), size: 10, color: AppColors.muted, align: TextAlign.right);
  }
  plot.curve(canvas, sim.pdf, AppColors.pink);
  plot.axis(
      canvas,
      sim.kind == SamplingDist.t
          ? [-4, -2, 0, 2, 4]
          : [for (var t = 0.0; t <= hi; t += hi > 20 ? 10 : (hi > 6 ? 4 : 1)) t]);
}

final LessonSpec tChiFLesson = LessonSpec(
  id: 't_chi_f',
  chapterLabel: 'Ch 8 · Continuous distributions',
  title: const [
    TitlePart('The three '),
    TitlePart('testing', AppColors.violet),
    TitlePart(' distributions'),
  ],
  subtitle: 't, chi-square & F · 3-minute animated lesson',
  createSim: () => TChiFSim(),
  visualAspectRatio: 1.1,
  buildVisual: (sim) => simCanvas<TChiFSim>(sim, _paintTChiF),
  stats: (sim) {
    final s = sim as TChiFSim;
    return [
      StatChip('samples', '${s.values.length}', AppColors.yellow),
      StatChip('df', '${s.df}', AppColors.violet),
    ];
  },
  bigIdea: 'All three are built from normal random numbers. Square and add df of them '
      'and you get chi-square, used to test counts and variances. Divide a normal by '
      'the square root of an averaged chi-square and you get t: a bell with heavier '
      'tails, because small samples estimate the sd badly. Divide two averaged '
      'chi-squares and you get F, used to compare variances in ANOVA. More degrees '
      'of freedom means more data: t turns into the normal curve.',
  formula: (sim) {
    final s = sim as TChiFSim;
    return switch (s.kind) {
      SamplingDist.t => 't = Z / √(χ²_df / df), df = ${s.df}',
      SamplingDist.chi2 => 'χ²_df = Z₁² + … + Z_df², mean = df = ${s.df}',
      SamplingDist.f => 'F = (χ²₁/d₁) / (χ²₂/d₂), d₁ = d₂ = ${s.df}',
    };
  },
  tryItTitle: 'Try it: pick a distribution and its degrees of freedom',
  buildTryIt: (sim) {
    final s = sim as TChiFSim;
    return watch(
      s,
      () => Column(
        children: [
          ChoiceRow<SamplingDist>(
            options: const {SamplingDist.t: 't', SamplingDist.chi2: 'Chi-square', SamplingDist.f: 'F'},
            selected: s.kind,
            onSelected: (v) => s.change(() => s.kind = v),
          ),
          LabeledSlider(
            left: 'df ${s.df}',
            right: '30',
            value: s.df.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: (v) => s.change(() => s.df = v.round()),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'As the degrees of freedom grow, the t distribution…',
      options: ['Gets wider', 'Approaches the normal curve', 'Becomes skewed', 'Becomes uniform'],
      answer: 1,
      explanation: 'With more data the sd estimate is reliable, so t behaves like z.',
    ),
    QuizQuestion(
      prompt: 'Can a chi-square value be negative?',
      options: ['Yes', 'No, it is a sum of squares', 'Only with small df', 'Only for t'],
      answer: 1,
      explanation: 'Squares are never negative, so neither is their sum.',
    ),
    QuizQuestion(
      prompt: 'Why does t have heavier tails than the normal?',
      options: [
        'Because data is skewed',
        'Because the sd is estimated from a small sample',
        'Because df is always 1',
        'It doesn\'t',
      ],
      answer: 1,
      explanation: 'The extra uncertainty in the sd makes extreme t values more likely.',
    ),
  ],
);

// ===== lib/lessons/ch09_two_variables.dart =====
// Chapter 9 · Two variables together, and Chapter 10 · Chebyshev.

/// Sample covariance of paired data.
double covariance(List<Offset> pts) {
  if (pts.length < 2) return 0;
  final mx = meanOf(pts.map((p) => p.dx));
  final my = meanOf(pts.map((p) => p.dy));
  var s = 0.0;
  for (final p in pts) {
    s += (p.dx - mx) * (p.dy - my);
  }
  return s / (pts.length - 1);
}

// ===========================================================================
// Joint & marginal distributions
// ===========================================================================

/// Roll a die (X), then flip X coins (Y = heads).
class JointSim extends TickSim {
  JointSim({super.rng});

  List<List<int>> counts = List.generate(7, (_) => List.filled(7, 0));
  int trials = 0;
  (int, int)? last;

  double theory(int x, int y) => binomPmf(x, y, 0.5) / 6;

  @override
  double get interval => trials < 8 ? 0.7 : 0.03;

  @override
  void tick() {
    final x = 1 + rng.nextInt(6);
    var y = 0;
    for (var i = 0; i < x; i++) {
      if (rng.nextBool()) y++;
    }
    counts[x][y]++;
    trials++;
    last = (x, y);
  }

  @override
  void restart() {
    counts = List.generate(7, (_) => List.filled(7, 0));
    trials = 0;
    last = null;
  }

  int rowTotal(int x) => counts[x].fold(0, (a, b) => a + b);
  int colTotal(int y) => [for (var x = 1; x <= 6; x++) counts[x][y]].fold(0, (a, b) => a + b);
}

void _paintJoint(Canvas canvas, Size size, JointSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 46.0, top = 26.0;
  final gridW = w - left - 70;
  final cellW = gridW / 7;
  final cellH = math.min(cellW, (h - top - 70) / 6);
  label(canvas, 'Y = heads →', Offset(left + gridW / 2, 12), size: 11, color: AppColors.muted);
  var maxC = 1;
  for (var x = 1; x <= 6; x++) {
    for (var y = 0; y <= 6; y++) {
      maxC = math.max(maxC, sim.counts[x][y]);
    }
  }
  for (var y = 0; y <= 6; y++) {
    label(canvas, '$y', Offset(left + cellW * (y + 0.5), top + 6 * cellH + 10), size: 10, color: AppColors.muted);
  }
  final maxRow = [for (var x = 1; x <= 6; x++) sim.rowTotal(x)].reduce(math.max);
  final maxCol = [for (var y = 0; y <= 6; y++) sim.colTotal(y)].reduce(math.max);
  for (var x = 1; x <= 6; x++) {
    label(canvas, 'X=$x', Offset(left - 6, top + cellH * (x - 0.5)),
        size: 10, color: AppColors.muted, align: TextAlign.right);
    for (var y = 0; y <= 6; y++) {
      final r = Rect.fromLTWH(left + cellW * y + 1, top + cellH * (x - 1) + 1, cellW - 2, cellH - 2);
      if (y > x) {
        roundRect(canvas, r, AppColors.chip.withValues(alpha: 0.4), radius: 4);
        continue;
      }
      final c = sim.counts[x][y];
      roundRect(canvas, r, AppColors.violet.withValues(alpha: 0.08 + 0.85 * c / maxC), radius: 4);
      if (sim.last == (x, y)) ring(canvas, r.center, cellW * 0.42, AppColors.pink, width: 2.5);
    }
    // Row marginal: P(X = x).
    final rw = maxRow == 0 ? 0.0 : sim.rowTotal(x) / maxRow;
    roundRect(canvas, Rect.fromLTWH(left + gridW + 8, top + cellH * (x - 1) + 3, rw * 56, cellH - 6), AppColors.orange);
  }
  label(canvas, 'P(X)', Offset(left + gridW + 30, top - 10), size: 10, color: AppColors.orange);
  // Column marginal: P(Y = y).
  final colTop = top + 6 * cellH + 24;
  for (var y = 0; y <= 6; y++) {
    final p = maxCol == 0 ? 0.0 : sim.colTotal(y) / maxCol;
    roundRect(
        canvas,
        Rect.fromLTWH(left + cellW * y + 3, colTop, cellW - 6, p * math.min(60.0, math.max(0.0, h - colTop - 4))),
        AppColors.cyan);
  }
  label(canvas, 'P(Y)', Offset(left - 8, colTop + 10), size: 10, color: AppColors.cyan, align: TextAlign.right);
}

final LessonSpec jointMarginalLesson = LessonSpec(
  id: 'joint_marginal',
  chapterLabel: 'Ch 9 · Two variables together',
  title: const [
    TitlePart('A table of '),
    TitlePart('pairs', AppColors.violet),
    TitlePart(', and its '),
    TitlePart('edges', AppColors.orange),
  ],
  subtitle: 'Joint & marginal distributions · 2-minute animated lesson',
  createSim: () => JointSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<JointSim>(sim, _paintJoint),
  stats: (sim) {
    final s = sim as JointSim;
    return [
      StatChip('trials', '${s.trials}', AppColors.yellow),
      StatChip(
          'P(X=4, Y=2) seen', s.trials == 0 ? '…' : (s.counts[4][2] / s.trials).toStringAsFixed(3), AppColors.violet),
      StatChip('theory', s.theory(4, 2).toStringAsFixed(3), AppColors.pink),
    ];
  },
  bigIdea: 'Roll a die to get X, then flip X coins and count heads Y. The joint '
      'distribution gives the chance of every pair (X, Y): each square of the grid. '
      'Add along a row and you get the marginal distribution of X alone (the '
      'orange bars: flat, it\'s a die). Add down a column for Y alone. The grey '
      'squares are impossible: you can\'t get 5 heads from 3 coins.',
  formula: (sim) {
    final s = sim as JointSim;
    return 'P(X=x, Y=y) = 1/6 × C(x, y)/2^x   P(Y=y) = Σₓ P(X=x, Y=y) · P(X=4,Y=2) = ${s.theory(4, 2).toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: run more trials',
  buildTryIt: (sim) {
    final s = sim as JointSim;
    return ControlRow(children: [
      ActionButton('Roll & flip 2,000 times', () => s.runMany(2000)),
      ActionButton('Start over', s.reset),
    ]);
  },
  quiz: const [
    QuizQuestion(
      prompt: 'How do you get the marginal distribution of X from a joint table?',
      options: ['Read one cell', 'Add each row across all Y values', 'Multiply rows', 'Take the diagonal'],
      answer: 1,
      explanation: 'P(X = x) collects every pair that has that x.',
    ),
    QuizQuestion(
      prompt: 'Roll a die to get X, then flip X coins; Y = heads. What is P(X = 2, Y = 2)?',
      options: ['1/6', '1/24', '1/4', '1/36'],
      answer: 1,
      explanation: 'P(X=2) = 1/6, then both coins heads = 1/4: 1/24.',
    ),
    QuizQuestion(
      prompt: 'All the joint probabilities in a table must add up to…',
      options: ['0', 'The number of rows', '1', 'It depends'],
      answer: 2,
      explanation: 'Every possible pair is listed exactly once.',
    ),
  ],
);

// ===========================================================================
// Covariance
// ===========================================================================

class CovarianceSim extends TickSim {
  CovarianceSim({super.rng});

  double strength = 0.6;
  final List<Offset> points = [];
  static const int target = 30;

  @override
  double get interval => points.length < 10 ? 0.5 : 0.15;

  @override
  void tick() {
    if (points.length >= target) return;
    final zx = normalDraw(rng);
    final zy = strength * zx + math.sqrt(1 - strength * strength) * normalDraw(rng);
    points.add(Offset((5 + zx * 1.6).clamp(0.2, 9.8), (60 + zy * 12).clamp(22, 98)));
  }

  @override
  void restart() => points.clear();
}

void _paintCovariance(Canvas canvas, Size size, CovarianceSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(36, 16, w - 12, h - 34), x0: 0, x1: 10, y0: 20, y1: 100);
  plot.axis(canvas, [0, 2, 4, 6, 8, 10], title: 'hours studied');
  if (sim.points.length < 2) return;
  final mx = meanOf(sim.points.map((p) => p.dx));
  final my = meanOf(sim.points.map((p) => p.dy));
  // Each point's rectangle to the mean: green adds to covariance, pink subtracts.
  for (final p in sim.points) {
    final positive = (p.dx - mx) * (p.dy - my) > 0;
    final r = Rect.fromPoints(plot.at(mx, my), plot.at(p.dx, p.dy));
    canvas.drawRect(r, Paint()..color = (positive ? AppColors.green : AppColors.pink).withValues(alpha: 0.13));
  }
  dashedLine(canvas, plot.at(mx, 20), plot.at(mx, 100), AppColors.ink, width: 1.5);
  dashedLine(canvas, plot.at(0, my), plot.at(10, my), AppColors.ink, width: 1.5);
  label(canvas, 'x̄', plot.at(mx, 100).translate(8, 6), size: 12);
  label(canvas, 'ȳ', plot.at(10, my).translate(-8, -10), size: 12);
  for (final p in sim.points) {
    final positive = (p.dx - mx) * (p.dy - my) > 0;
    canvas.drawCircle(plot.at(p.dx, p.dy), 5, Paint()..color = positive ? AppColors.green : AppColors.pink);
  }
  for (final (q, text) in [((7.5, 92.0), '+'), ((2.5, 92.0), '−'), ((2.5, 28.0), '+'), ((7.5, 28.0), '−')]) {
    label(canvas, text, plot.at(q.$1, q.$2), size: 22, color: text == '+' ? AppColors.green : AppColors.pink);
  }
}

final LessonSpec covarianceLesson = LessonSpec(
  id: 'covariance',
  chapterLabel: 'Ch 9 · Two variables together',
  title: const [
    TitlePart('Add up the '),
    TitlePart('rectangles', AppColors.green),
  ],
  subtitle: 'Covariance · 2-minute animated lesson',
  createSim: () => CovarianceSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<CovarianceSim>(sim, _paintCovariance),
  stats: (sim) {
    final s = sim as CovarianceSim;
    final pos = s.points.length < 2
        ? 0
        : s.points.where((p) {
            final mx = meanOf(s.points.map((q) => q.dx)), my = meanOf(s.points.map((q) => q.dy));
            return (p.dx - mx) * (p.dy - my) > 0;
          }).length;
    return [
      StatChip('points', '${s.points.length}', AppColors.yellow),
      StatChip('+ / −', '$pos / ${s.points.length - pos}', AppColors.green),
      StatChip('cov', covariance(s.points).toStringAsFixed(1), AppColors.pink),
    ];
  },
  bigIdea: 'Draw a cross through the averages. Each student makes a rectangle from the '
      'cross to their dot. Above-average hours with above-average marks (or below '
      'with below) gives a positive area; mixed gives negative. Covariance is the '
      'average signed area. Positive means the two tend to move together. Its size '
      'depends on the units, which is why we usually look at correlation instead.',
  formula: (sim) {
    final s = sim as CovarianceSim;
    return 'cov(X, Y) = Σ(x − x̄)(y − ȳ) / (n − 1) = ${covariance(s.points).toStringAsFixed(2)} hour·marks';
  },
  tryItTitle: 'Try it: change how the two are linked',
  buildTryIt: (sim) {
    final s = sim as CovarianceSim;
    return watch(
      s,
      () => LabeledSlider(
        left: 'opposite',
        right: 'together',
        value: s.strength,
        min: -0.9,
        max: 0.9,
        divisions: 18,
        label: s.strength.toStringAsFixed(1),
        onChanged: (v) => s.change(() => s.strength = v),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Most points are in the top-left and bottom-right of the mean cross. Covariance is…',
      options: ['Positive', 'Negative', 'Zero', 'Undefined'],
      answer: 1,
      explanation: 'Those quadrants give negative rectangles.',
    ),
    QuizQuestion(
      prompt: 'You measure heights in cm instead of m. The covariance with weight…',
      options: ['Stays the same', 'Is multiplied by 100', 'Is divided by 100', 'Becomes 1'],
      answer: 1,
      explanation: 'Every x-distance is 100 times bigger, so every rectangle is too.',
    ),
    QuizQuestion(
      prompt: 'cov(X, X) equals…',
      options: ['0', '1', 'Var(X)', 'The mean'],
      answer: 2,
      explanation: 'Σ(x − x̄)(x − x̄)/(n − 1) is the variance formula.',
    ),
  ],
);

// ===========================================================================
// Correlation
// ===========================================================================

enum CorrCase { linear, rescaled, curve, outlier }

class CorrelationSim extends TickSim {
  CorrelationSim({super.rng});

  CorrCase mode = CorrCase.linear;
  final List<Offset> points = [];
  static const int target = 40;

  /// x-axis unit multiplier for the rescaled case.
  double get scale => mode == CorrCase.rescaled ? 100 : 1;

  @override
  double get interval => points.length < 10 ? 0.25 : 0.08;

  @override
  void tick() {
    if (points.length >= target) return;
    final x = rng.nextDouble() * 2 - 1;
    final p = switch (mode) {
      CorrCase.linear || CorrCase.rescaled => Offset(x, 0.7 * x + normalDraw(rng) * 0.25),
      CorrCase.curve => Offset(x, x * x * 1.6 - 0.6 + normalDraw(rng) * 0.08),
      CorrCase.outlier =>
        points.length == target - 1 ? const Offset(0.95, 0.95) : Offset(x * 0.3 - 0.5, normalDraw(rng) * 0.15 - 0.5),
    };
    points.add(Offset(p.dx * scale, p.dy));
  }

  @override
  void restart() => points.clear();
}

void _paintCorrelation(Canvas canvas, Size size, CorrelationSim sim) {
  final w = size.width;
  final h = size.height;
  final s = sim.scale;
  final plot = Plot(Rect.fromLTRB(16, 16, w - 16, h - 34), x0: -1.05 * s, x1: 1.05 * s, y0: -1.05, y1: 1.05);
  plot.axis(canvas, [-s, 0, s], title: sim.mode == CorrCase.rescaled ? 'x in cm (×100)' : 'x in m');
  line(canvas, plot.at(0, -1.05), plot.at(0, 1.05), AppColors.peg.withValues(alpha: 0.5));
  for (var i = 0; i < sim.points.length; i++) {
    final p = sim.points[i];
    final odd = sim.mode == CorrCase.outlier && i == CorrelationSim.target - 1;
    canvas.drawCircle(plot.at(p.dx, p.dy), odd ? 8 : 5,
        Paint()..color = odd ? AppColors.pink : AppColors.blue.withValues(alpha: 0.75));
  }
  if (sim.points.length > 3) {
    label(canvas, 'r = ${correlation(sim.points).toStringAsFixed(2)}', Offset(24, 28),
        size: 18, color: AppColors.pink, align: TextAlign.left);
    label(canvas, 'cov = ${covariance(sim.points).toStringAsFixed(2)}', Offset(24, 52),
        size: 13, color: AppColors.muted, align: TextAlign.left);
  }
}

final LessonSpec correlationLesson = LessonSpec(
  id: 'correlation',
  chapterLabel: 'Ch 9 · Two variables together',
  title: const [
    TitlePart('Covariance with the '),
    TitlePart('units', AppColors.pink),
    TitlePart(' taken out'),
  ],
  subtitle: 'Correlation · 2-minute animated lesson',
  createSim: () => CorrelationSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<CorrelationSim>(sim, _paintCorrelation),
  stats: (sim) {
    final s = sim as CorrelationSim;
    return [
      StatChip('points', '${s.points.length}', AppColors.yellow),
      StatChip('r', s.points.length < 3 ? '…' : correlation(s.points).toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'Correlation r is covariance divided by both standard deviations, so it has '
      'no units and always lies between −1 and +1. Change metres to centimetres and '
      'the covariance jumps 100×, but r doesn\'t move. Two warnings: r only measures '
      'straight-line patterns (a perfect U-shape can have r ≈ 0), and one extreme '
      'point can create a strong r on its own. Always look at the plot.',
  formula: (sim) {
    final s = sim as CorrelationSim;
    final sx = sdOf(s.points.map((p) => p.dx).toList()), sy = sdOf(s.points.map((p) => p.dy).toList());
    return 'r = cov / (sₓ · s_y) = ${covariance(s.points).toStringAsFixed(2)} / (${sx.toStringAsFixed(2)} × '
        '${sy.toStringAsFixed(2)}) = ${correlation(s.points).toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: four kinds of data',
  buildTryIt: (sim) {
    final s = sim as CorrelationSim;
    return watch(
      s,
      () => ChoiceRow<CorrCase>(
        options: const {
          CorrCase.linear: 'Straight line',
          CorrCase.rescaled: 'Same, in cm',
          CorrCase.curve: 'U-shape',
          CorrCase.outlier: 'One outlier',
        },
        selected: s.mode,
        onSelected: (v) => s.change(() => s.mode = v),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'You convert temperatures from °C to °F. The correlation with ice-cream sales…',
      options: ['Changes sign', 'Stays exactly the same', 'Gets 1.8× bigger', 'Becomes 0'],
      answer: 1,
      explanation: 'r is unit-free: shifting and stretching an axis (by a positive factor) leaves it unchanged.',
    ),
    QuizQuestion(
      prompt: 'Points form a perfect U shape. r is probably…',
      options: ['Close to +1', 'Close to −1', 'Close to 0', 'Exactly 1'],
      answer: 2,
      explanation: 'The left half slopes down and the right half up; the linear trends cancel.',
    ),
    QuizQuestion(
      prompt: 'r = 0.9 for 20 points, but 19 are a shapeless blob and one is far away. The strong r is…',
      options: ['Trustworthy', 'Mostly caused by the outlier', 'Proof of causation', 'Impossible'],
      answer: 1,
      explanation: 'A single extreme point can drag r a long way. Check the scatter plot.',
    ),
  ],
);

// ===========================================================================
// Correlation vs causation
// ===========================================================================

class CausationSim extends TickSim {
  CausationSim({super.rng});

  /// (temperature 15–40 °C, ice creams sold, pool accidents).
  final List<(double, double, double)> days = [];
  bool split = false;
  static const int target = 60;

  @override
  double get interval => days.length < 10 ? 0.3 : 0.08;

  @override
  void tick() {
    if (days.length >= target) return;
    final t = 15 + rng.nextDouble() * 25;
    days.add(
        (t, (40 + 6 * t + normalDraw(rng) * 18).clamp(0, 400), (0.4 + 0.12 * t + normalDraw(rng) * 0.7).clamp(0, 9)));
  }

  @override
  void restart() => days.clear();

  void setSplit(bool v) {
    split = v;
    notifyListeners();
  }

  List<Offset> pointsIn(double lo, double hi) => [
        for (final d in days)
          if (d.$1 >= lo && d.$1 < hi) Offset(d.$2, d.$3),
      ];

  double get overallR => correlation(pointsIn(0, 100));

  static const bands = [(15.0, 23.0), (23.0, 31.0), (31.0, 40.1)];

  double get withinR {
    final rs = [for (final b in bands) correlation(pointsIn(b.$1, b.$2))];
    return meanOf(rs);
  }
}

Color _tempColor(double t) => Color.lerp(AppColors.blue, AppColors.orange, ((t - 15) / 25).clamp(0, 1))!;

void _paintCausation(Canvas canvas, Size size, CausationSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(30, 30, w - 14, h - 34), x0: 100, x1: 330, y0: 0, y1: 7.5);
  plot.axis(canvas, [100, 150, 200, 250, 300], title: 'ice creams sold');
  label(canvas, 'pool accidents ↑', Offset(30, 14), size: 11, color: AppColors.muted, align: TextAlign.left);
  label(canvas, 'colour = temperature', Offset(w - 14, 14), size: 11, color: AppColors.orange, align: TextAlign.right);
  for (final d in sim.days) {
    canvas.drawCircle(plot.at(d.$2.clamp(100, 330), d.$3.clamp(0, 7.5)), 5, Paint()..color = _tempColor(d.$1));
  }
  void fit(List<Offset> pts, Color color) {
    if (pts.length < 4) return;
    final mx = meanOf(pts.map((p) => p.dx)), my = meanOf(pts.map((p) => p.dy));
    final b = covariance(pts) / math.pow(sdOf(pts.map((p) => p.dx).toList()), 2);
    final xs = pts.map((p) => p.dx);
    final x0 = xs.reduce(math.min), x1 = xs.reduce(math.max);
    line(canvas, plot.at(x0, my + b * (x0 - mx)), plot.at(x1, my + b * (x1 - mx)), color, width: 3);
  }

  if (sim.split) {
    for (final band in CausationSim.bands) {
      fit(sim.pointsIn(band.$1, band.$2), _tempColor((band.$1 + band.$2) / 2));
    }
  } else {
    fit(sim.pointsIn(0, 100), AppColors.ink);
  }
}

final LessonSpec causationLesson = LessonSpec(
  id: 'correlation_causation',
  chapterLabel: 'Ch 9 · Two variables together',
  title: const [
    TitlePart('Does ice cream '),
    TitlePart('cause', AppColors.pink),
    TitlePart(' pool accidents?'),
  ],
  subtitle: 'Correlation vs causation · 2-minute animated lesson',
  createSim: () => CausationSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<CausationSim>(sim, _paintCausation),
  stats: (sim) {
    final s = sim as CausationSim;
    return [
      StatChip('days', '${s.days.length}', AppColors.yellow),
      StatChip('r overall', s.days.length < 5 ? '…' : s.overallR.toStringAsFixed(2), AppColors.pink),
      StatChip('r same temp', s.days.length < 20 ? '…' : s.withinR.toStringAsFixed(2), AppColors.blue),
    ];
  },
  bigIdea: 'On hot days people buy more ice cream and more people swim, so both numbers '
      'rise together: a strong correlation. But neither causes the other; temperature '
      'drives both. Compare only days with similar temperatures (split the data) '
      'and the link almost vanishes. A hidden third variable like this is called a '
      'confounder. Only an experiment, or careful control, shows cause.',
  formula: (sim) {
    final s = sim as CausationSim;
    return 'r(ice cream, accidents) = ${s.overallR.toStringAsFixed(2)}   within a temperature band ≈ '
        '${s.withinR.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: control for temperature',
  buildTryIt: (sim) {
    final s = sim as CausationSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<bool>(
            options: const {false: 'All days together', true: 'Split by temperature'},
            selected: s.split,
            onSelected: s.setSplit,
          ),
          const SizedBox(height: 8),
          const TryNote('Within each colour band, the lines go almost flat.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Countries that eat more chocolate win more Nobel prizes. The most likely explanation?',
      options: [
        'Chocolate makes people smarter',
        'A confounder like national wealth',
        'Pure chance only',
        'Nobel winners buy chocolate'
      ],
      answer: 1,
      explanation: 'Richer countries can afford both more chocolate and more research.',
    ),
    QuizQuestion(
      prompt: 'What is a confounding variable?',
      options: [
        'A variable measured wrongly',
        'A hidden variable that affects both things being compared',
        'The outcome variable',
        'A variable with no effect',
      ],
      answer: 1,
      explanation: 'It creates a correlation between two things that don\'t cause each other.',
    ),
    QuizQuestion(
      prompt: 'What is the best way to show that a new drug causes recovery?',
      options: ['Survey patients', 'A randomised controlled experiment', 'Find a strong correlation', 'Ask doctors'],
      answer: 1,
      explanation: 'Random assignment balances confounders between the groups.',
    ),
  ],
);

// ===========================================================================
// Chebyshev's inequality (chapter 10)
// ===========================================================================

enum ChebShape { normal, uniform, skewed, twoHumps }

class ChebyshevSim extends TickSim {
  ChebyshevSim({super.rng});

  ChebShape shape = ChebShape.skewed;
  double k = 2;
  final List<double> values = [];

  @override
  double get interval => values.length < 40 ? 0.05 : 0.01;

  double _draw() => switch (shape) {
        ChebShape.normal => normalDraw(rng),
        ChebShape.uniform => rng.nextDouble(),
        ChebShape.skewed => expDraw(rng, 1),
        ChebShape.twoHumps => (rng.nextBool() ? -1.0 : 1.0) + normalDraw(rng) * 0.2,
      };

  @override
  void tick() {
    if (values.length < 4000) values.add(_draw());
  }

  @override
  void restart() => values.clear();

  double get within {
    if (values.length < 2) return 0;
    final m = meanOf(values), sd = sdOf(values);
    return values.where((v) => (v - m).abs() < k * sd).length / values.length;
  }

  double get bound => 1 - 1 / (k * k);

  void setK(double v) {
    k = v;
    notifyListeners();
  }
}

void _paintChebyshev(Canvas canvas, Size size, ChebyshevSim sim) {
  final w = size.width;
  final h = size.height;
  if (sim.values.length < 2) return;
  final m = meanOf(sim.values), sd = sdOf(sim.values);
  final z = [for (final v in sim.values) (v - m) / sd];
  final plot = Plot(Rect.fromLTRB(16, 20, w - 16, h - 96), x0: -5, x1: 5, y1: 1);
  final counts = binCounts(z, -5, 5, 50);
  final peak = counts.reduce(math.max) / (z.length * 0.2);
  final p2 = Plot(plot.rect, x0: -5, x1: 5, y1: peak * 1.15);
  canvas.drawRect(Rect.fromLTRB(p2.x(-sim.k), p2.rect.top, p2.x(sim.k), p2.rect.bottom),
      Paint()..color = AppColors.green.withValues(alpha: 0.15));
  p2.densityBars(canvas, counts, -5, 5, AppColors.violet.withValues(alpha: 0.6), total: z.length);
  for (final s in [-sim.k, sim.k]) {
    line(canvas, p2.at(s, 0), Offset(p2.x(s), p2.rect.top), AppColors.green, width: 2.5);
  }
  p2.axis(canvas, [-4, -2, 0, 2, 4], format: (v) => v == 0 ? 'mean' : '${v > 0 ? '+' : ''}${v.round()} sd');
  final barW = w - 32;
  for (final (i, name, v, color) in [
    (0, 'actually within ${sim.k.toStringAsFixed(1)} sd', sim.within, AppColors.violet),
    (1, 'Chebyshev guarantees at least', math.max(0.0, sim.bound), AppColors.green),
  ]) {
    final y = h - 70 + i * 32.0;
    label(canvas, '$name: ${(v * 100).toStringAsFixed(1)}%', Offset(16, y), size: 12, align: TextAlign.left);
    roundRect(canvas, Rect.fromLTWH(16, y + 9, barW, 10), AppColors.chip, radius: 5);
    roundRect(canvas, Rect.fromLTWH(16, y + 9, barW * v, 10), color, radius: 5);
  }
}

final LessonSpec chebyshevLesson = LessonSpec(
  id: 'chebyshev',
  chapterLabel: 'Ch 10 · The big theorems',
  title: const [
    TitlePart('A guarantee for '),
    TitlePart('any', AppColors.green),
    TitlePart(' shape of data'),
  ],
  subtitle: "Chebyshev's inequality · 2-minute animated lesson",
  createSim: () => ChebyshevSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<ChebyshevSim>(sim, _paintChebyshev),
  stats: (sim) {
    final s = sim as ChebyshevSim;
    return [
      StatChip('k', s.k.toStringAsFixed(1), AppColors.yellow),
      StatChip('within k sd', '${(s.within * 100).toStringAsFixed(1)}%', AppColors.violet),
      StatChip('guaranteed', '≥ ${(math.max(0, s.bound) * 100).toStringAsFixed(1)}%', AppColors.green),
    ];
  },
  bigIdea: 'The 68-95-99.7 rule only works for bell curves. Chebyshev\'s inequality works '
      'for every distribution: at least 1 − 1/k² of the values lie within k standard '
      'deviations of the mean. At least 75% within 2 sd, at least 89% within 3 sd. '
      'It\'s a cautious floor; real data usually beats it comfortably, but it can '
      'never do worse.',
  formula: (sim) {
    final s = sim as ChebyshevSim;
    return 'P(|X − μ| < kσ) ≥ 1 − 1/k² = 1 − 1/${(s.k * s.k).toStringAsFixed(2)} = ${s.bound.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: any shape, any k',
  buildTryIt: (sim) {
    final s = sim as ChebyshevSim;
    return watch(
      s,
      () => Column(
        children: [
          ChoiceRow<ChebShape>(
            options: const {
              ChebShape.normal: 'Bell',
              ChebShape.uniform: 'Flat',
              ChebShape.skewed: 'Skewed',
              ChebShape.twoHumps: 'Two humps',
            },
            selected: s.shape,
            onSelected: (v) => s.change(() => s.shape = v),
          ),
          LabeledSlider(
            left: 'k 1.2',
            right: '4',
            value: s.k,
            min: 1.2,
            max: 4,
            divisions: 14,
            label: 'k = ${s.k.toStringAsFixed(1)}',
            onChanged: s.setK,
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'By Chebyshev, at least what share of ANY data lies within 2 sd of the mean?',
      options: ['50%', '75%', '95%', '68%'],
      answer: 1,
      explanation: '1 − 1/2² = 0.75.',
    ),
    QuizQuestion(
      prompt: 'Why is Chebyshev\'s bound usually lower than the 68-95-99.7 numbers?',
      options: [
        'It is wrong',
        'It must hold for every shape, including awkward ones',
        'It uses the median',
        'It only works for small data',
      ],
      answer: 1,
      explanation: 'A guarantee for all distributions has to cover the worst case.',
    ),
    QuizQuestion(
      prompt: 'What does Chebyshev say for k = 1?',
      options: ['At least 0% within 1 sd: nothing useful', '68%', '50%', '100%'],
      answer: 0,
      explanation: '1 − 1/1 = 0. The bound only bites for k > 1.',
    ),
  ],
);

// ===== lib/lessons/ch11_sampling.dart =====
// Chapter 11 · Sampling.

/// A 20 × 20 town where each person answers yes or no.
class Town {
  Town(double Function(int row, int col) yesRate, {int seed = 11}) {
    final rng = math.Random(seed);
    yes = List.generate(size * size, (i) => rng.nextDouble() < yesRate(i ~/ size, i % size));
  }

  static const int size = 20;
  late final List<bool> yes;

  double get truth => yes.where((y) => y).length / yes.length;
  double shareYes(Iterable<int> people) => people.isEmpty ? 0 : people.where((i) => yes[i]).length / people.length;
}

/// Draws the town; [picked] people are highlighted.
void paintTown(Canvas canvas, Rect area, Town town, Set<int> picked, {Color Function(int i)? tint}) {
  final cell = area.width / Town.size;
  for (var i = 0; i < Town.size * Town.size; i++) {
    final c = Offset(area.left + cell * (i % Town.size + 0.5), area.top + cell * (i ~/ Town.size + 0.5));
    final isPicked = picked.contains(i);
    final base = town.yes[i] ? AppColors.green : AppColors.pink;
    if (tint != null) {
      canvas.drawRect(Rect.fromCenter(center: c, width: cell, height: cell), Paint()..color = tint(i));
    }
    canvas.drawCircle(c, cell * (isPicked ? 0.42 : 0.26), Paint()..color = base.withValues(alpha: isPicked ? 1 : 0.3));
    if (isPicked) ring(canvas, c, cell * 0.48, AppColors.ink, width: 1.2);
  }
}

/// Dot strip of recent estimates around the true value.
void paintEstimates(Canvas canvas, Rect area, List<double> estimates, double truth, {String unit = '%'}) {
  final plot = Plot(area, x0: 0, x1: 1, y1: 1);
  line(canvas, Offset(area.left, area.center.dy), Offset(area.right, area.center.dy), AppColors.peg);
  for (var i = 0; i < estimates.length; i++) {
    final isNew = i == estimates.length - 1;
    canvas.drawCircle(Offset(plot.x(estimates[i]), area.center.dy + ((i * 7) % 9 - 4) * 2.0), isNew ? 6 : 4,
        Paint()..color = isNew ? AppColors.orange : AppColors.blue.withValues(alpha: 0.5));
  }
  line(canvas, Offset(plot.x(truth), area.top), Offset(plot.x(truth), area.bottom), AppColors.ink, width: 2.5);
  label(canvas, 'truth ${(truth * 100).toStringAsFixed(0)}$unit', Offset(plot.x(truth), area.top - 8), size: 10);
  for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
    label(canvas, '${(t * 100).round()}', Offset(plot.x(t), area.bottom + 8), size: 9, color: AppColors.muted);
  }
}

/// Shared shell: a town, a way to pick a sample, and the estimates it gives.
abstract class TownSampleSim extends TickSim {
  TownSampleSim({super.rng});

  Town get town;
  Set<int> picked = {};
  final List<double> estimates = [];

  Set<int> pick();

  @override
  double get interval => estimates.length < 5 ? 1.2 : 0.3;

  @override
  void tick() {
    picked = pick();
    estimates.add(town.shareYes(picked));
    if (estimates.length > 60) estimates.removeAt(0);
  }

  @override
  void restart() {
    picked = {};
    estimates.clear();
  }

  Set<int> randomPeople(int n, [List<int>? from]) {
    final pool = [...(from ?? List<int>.generate(Town.size * Town.size, (i) => i))]..shuffle(rng);
    return pool.take(n).toSet();
  }

  double get spread => sdOf(estimates);
}

// ===========================================================================
// Population vs sample
// ===========================================================================

class PopulationSim extends TownSampleSim {
  PopulationSim({super.rng});

  @override
  final Town town = Town((r, c) => 0.62);
  int n = 25;

  @override
  Set<int> pick() => randomPeople(n);
}

void _paintPopulation(Canvas canvas, Size size, TownSampleSim sim) {
  final w = size.width;
  final h = size.height;
  final side = math.min(w - 32, h - 110);
  final area = Rect.fromLTWH((w - side) / 2, 18, side, side);
  label(canvas, 'Population: all ${Town.size * Town.size} people · green = yes', Offset(w / 2, 8),
      size: 11, color: AppColors.muted);
  paintTown(canvas, area, sim.town, sim.picked);
  if (sim.picked.isNotEmpty) {
    label(
        canvas,
        'This sample of ${sim.picked.length}: ${(sim.town.shareYes(sim.picked) * 100).toStringAsFixed(0)}% yes',
        Offset(w / 2, area.bottom + 14),
        size: 13,
        color: AppColors.orange);
  }
  paintEstimates(canvas, Rect.fromLTRB(20, area.bottom + 40, w - 20, h - 14), sim.estimates, sim.town.truth);
}

final LessonSpec populationSampleLesson = LessonSpec(
  id: 'population_sample',
  chapterLabel: 'Ch 11 · Sampling',
  title: const [
    TitlePart('Ask a '),
    TitlePart('few', AppColors.orange),
    TitlePart(', learn about '),
    TitlePart('everyone', AppColors.green),
  ],
  subtitle: 'Population vs sample · 2-minute animated lesson',
  createSim: () => PopulationSim(),
  visualAspectRatio: 0.8,
  buildVisual: (sim) => simCanvas<TownSampleSim>(sim, _paintPopulation),
  stats: (sim) {
    final s = sim as PopulationSim;
    return [
      StatChip('true yes', '${(s.town.truth * 100).toStringAsFixed(1)}%', AppColors.green),
      StatChip('samples', '${s.estimates.length}', AppColors.yellow),
      StatChip('typical miss', '±${(s.spread * 100).toStringAsFixed(1)}%', AppColors.orange),
    ];
  },
  bigIdea: 'The population is everyone you care about; usually you can\'t ask them all. '
      'A sample is the few you do ask. The population\'s true share is a fixed '
      'number (a parameter); each sample gives a slightly different estimate (a '
      'statistic). Random samples scatter around the truth, and bigger samples '
      'scatter less.',
  formula: (sim) {
    final s = sim as PopulationSim;
    return 'parameter p = ${s.town.truth.toStringAsFixed(3)}   statistic p̂ = yes in sample / ${s.n}';
  },
  tryItTitle: 'Try it: change the sample size',
  buildTryIt: (sim) {
    final s = sim as PopulationSim;
    return watch(
      s,
      () => LabeledSlider(
        left: 'n = ${s.n}',
        right: '200',
        value: s.n.toDouble(),
        min: 5,
        max: 200,
        divisions: 39,
        onChanged: (v) => s.change(() => s.n = v.round()),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A school surveys 50 of its 900 students about lunch. The 900 students are the…',
      options: ['Sample', 'Population', 'Statistic', 'Parameter'],
      answer: 1,
      explanation: 'The population is the whole group you want to learn about.',
    ),
    QuizQuestion(
      prompt: '"38% of the 50 surveyed liked lunch." This 38% is a…',
      options: ['Parameter', 'Statistic', 'Population', 'Guarantee'],
      answer: 1,
      explanation: 'A number calculated from a sample is a statistic.',
    ),
    QuizQuestion(
      prompt: 'Why do two random samples from the same population give different results?',
      options: [
        'Someone made a mistake',
        'Sampling variation: different people get picked',
        'The population changed',
        'They shouldn\'t'
      ],
      answer: 1,
      explanation: 'Chance decides who is in each sample, so estimates wobble.',
    ),
  ],
);

// ===========================================================================
// Sampling methods
// ===========================================================================

enum SampleMethod { random, systematic, stratified, cluster }

const Map<SampleMethod, String> kMethodNames = {
  SampleMethod.random: 'Simple random',
  SampleMethod.systematic: 'Systematic',
  SampleMethod.stratified: 'Stratified',
  SampleMethod.cluster: 'Cluster',
};

class MethodsSim extends TownSampleSim {
  MethodsSim({super.rng});

  /// Four neighbourhoods (5 rows each) with different opinions.
  static const rates = [0.85, 0.65, 0.45, 0.25];

  @override
  final Town town = Town((r, c) => rates[r ~/ 5], seed: 21);

  SampleMethod method = SampleMethod.stratified;
  static const int n = 24;

  @override
  Set<int> pick() {
    const all = Town.size * Town.size;
    switch (method) {
      case SampleMethod.random:
        return randomPeople(n);
      case SampleMethod.systematic:
        final step = all ~/ n;
        final start = rng.nextInt(step);
        return {for (var k = 0; k < n; k++) start + k * step};
      case SampleMethod.stratified:
        return {
          for (var s = 0; s < 4; s++) ...randomPeople(n ~/ 4, [for (var i = s * 100; i < (s + 1) * 100; i++) i]),
        };
      case SampleMethod.cluster:
        // One random 5 × 5 block (25 people).
        final br = rng.nextInt(4), bc = rng.nextInt(4);
        return {
          for (var r = br * 5; r < br * 5 + 5; r++)
            for (var c = bc * 5; c < bc * 5 + 5; c++) r * Town.size + c,
        };
    }
  }
}

void _paintMethods(Canvas canvas, Size size, MethodsSim sim) {
  final w = size.width;
  final h = size.height;
  final side = math.min(w - 60, h - 110);
  final area = Rect.fromLTWH((w - side) / 2 + 16, 18, side, side);
  label(canvas, '4 neighbourhoods with different views', Offset(w / 2, 8), size: 11, color: AppColors.muted);
  const tints = [AppColors.yellow, AppColors.cyan, AppColors.violet, AppColors.orange];
  paintTown(canvas, area, sim.town, sim.picked, tint: (i) => tints[(i ~/ Town.size) ~/ 5].withValues(alpha: 0.1));
  for (var s = 0; s < 4; s++) {
    label(canvas, '${(MethodsSim.rates[s] * 100).round()}%', Offset(area.left - 18, area.top + side * (s + 0.5) / 4),
        size: 10, color: AppColors.muted);
  }
  if (sim.picked.isNotEmpty) {
    label(canvas, '${kMethodNames[sim.method]}: ${(sim.town.shareYes(sim.picked) * 100).toStringAsFixed(0)}% yes',
        Offset(w / 2, area.bottom + 14),
        size: 13, color: AppColors.orange);
  }
  paintEstimates(canvas, Rect.fromLTRB(20, area.bottom + 40, w - 20, h - 14), sim.estimates, sim.town.truth);
}

final LessonSpec samplingMethodsLesson = LessonSpec(
  id: 'sampling_methods',
  chapterLabel: 'Ch 11 · Sampling',
  title: const [
    TitlePart('Four ways to '),
    TitlePart('pick', AppColors.orange),
    TitlePart(' who to ask'),
  ],
  subtitle: 'Sampling methods · 3-minute animated lesson',
  createSim: () => MethodsSim(),
  visualAspectRatio: 0.8,
  buildVisual: (sim) => simCanvas<MethodsSim>(sim, _paintMethods),
  stats: (sim) {
    final s = sim as MethodsSim;
    return [
      StatChip('samples', '${s.estimates.length}', AppColors.yellow),
      StatChip(
          'typical miss', s.estimates.length < 3 ? '…' : '±${(s.spread * 100).toStringAsFixed(1)}%', AppColors.orange),
    ];
  },
  bigIdea: 'Simple random: everyone equally likely. Systematic: every k-th person on a '
      'list. Stratified: split into groups (here, neighbourhoods) and sample each '
      'one in proportion, which guarantees every group is represented and gives '
      'the tightest estimates. Cluster: pick whole blocks at random; cheap, but '
      'people in one block think alike, so estimates swing wildly. Each sample '
      'here has about 24 people.',
  formula: (sim) {
    final s = sim as MethodsSim;
    return '${kMethodNames[s.method]} · spread of estimates (sd) = ${(s.spread * 100).toStringAsFixed(1)} points';
  },
  tryItTitle: 'Try it: compare the methods',
  buildTryIt: (sim) {
    final s = sim as MethodsSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<SampleMethod>(
              options: kMethodNames, selected: s.method, onSelected: (v) => s.change(() => s.method = v)),
          const SizedBox(height: 8),
          ControlRow(children: [ActionButton('Take 50 samples', () => s.runMany(50))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A school picks 10 students from each year group at random. This is…',
      options: ['Cluster sampling', 'Stratified sampling', 'Systematic sampling', 'Convenience sampling'],
      answer: 1,
      explanation: 'The year groups are strata, each sampled separately.',
    ),
    QuizQuestion(
      prompt: 'Why do cluster samples often vary more?',
      options: [
        'They are always smaller',
        'People in the same cluster tend to be similar',
        'Clusters are chosen by hand',
        'They don\'t',
      ],
      answer: 1,
      explanation: 'One cluster gives less variety than the same number of people spread out.',
    ),
    QuizQuestion(
      prompt: 'A factory checks every 50th item off the line. This is…',
      options: ['Systematic sampling', 'Stratified sampling', 'Simple random sampling', 'A census'],
      answer: 0,
      explanation: 'A fixed step through an ordered list.',
    ),
  ],
);

// ===========================================================================
// Sampling bias
// ===========================================================================

class BiasSim extends TownSampleSim {
  BiasSim({super.rng});

  /// People near the mall (top-left quarter) love the new mall.
  @override
  final Town town = Town((r, c) => r < 10 && c < 10 ? 0.9 : 0.4, seed: 31);

  bool convenience = true;
  int n = 30;

  static final List<int> nearMall = [
    for (var r = 0; r < 10; r++)
      for (var c = 0; c < 10; c++) r * Town.size + c,
  ];

  @override
  Set<int> pick() => randomPeople(n, convenience ? nearMall : null);
}

void _paintBias(Canvas canvas, Size size, BiasSim sim) {
  final w = size.width;
  final h = size.height;
  final side = math.min(w - 32, h - 110);
  final area = Rect.fromLTWH((w - side) / 2, 18, side, side);
  label(canvas, 'Should the town build a second mall?', Offset(w / 2, 8), size: 11, color: AppColors.muted);
  paintTown(canvas, area, sim.town, sim.picked,
      tint: (i) => BiasSim.nearMall.contains(i) ? AppColors.yellow.withValues(alpha: 0.2) : Colors.transparent);
  label(canvas, '🛍 mall', Offset(area.left + side * 0.25, area.top + side * 0.25), size: 14);
  paintEstimates(canvas, Rect.fromLTRB(20, area.bottom + 40, w - 20, h - 14), sim.estimates, sim.town.truth);
  if (sim.estimates.isNotEmpty) {
    label(canvas, 'average estimate ${(meanOf(sim.estimates) * 100).toStringAsFixed(0)}%',
        Offset(w / 2, area.bottom + 14),
        size: 13, color: AppColors.orange);
  }
}

final LessonSpec samplingBiasLesson = LessonSpec(
  id: 'sampling_bias',
  chapterLabel: 'Ch 11 · Sampling',
  title: const [
    TitlePart('Asking '),
    TitlePart('more', AppColors.orange),
    TitlePart(' of the '),
    TitlePart('wrong', AppColors.pink),
    TitlePart(' people'),
  ],
  subtitle: 'Sampling bias · 2-minute animated lesson',
  createSim: () => BiasSim(),
  visualAspectRatio: 0.8,
  buildVisual: (sim) => simCanvas<BiasSim>(sim, _paintBias),
  stats: (sim) {
    final s = sim as BiasSim;
    return [
      StatChip('true yes', '${(s.town.truth * 100).toStringAsFixed(0)}%', AppColors.green),
      StatChip('avg estimate', s.estimates.isEmpty ? '…' : '${(meanOf(s.estimates) * 100).toStringAsFixed(0)}%',
          AppColors.orange),
    ];
  },
  bigIdea: 'Standing outside the mall and asking shoppers is easy, but shoppers near the '
      'mall love malls. That convenience sample is biased: every estimate lands '
      'far from the truth, in the same direction. Asking more shoppers only makes '
      'you more confident in the wrong answer. Random sampling from the whole town '
      'removes the bias; size then reduces the wobble.',
  formula: (sim) {
    final s = sim as BiasSim;
    return 'bias = average estimate − truth = ${((meanOf(s.estimates) - s.town.truth) * 100).toStringAsFixed(1)} points';
  },
  tryItTitle: 'Try it: bigger sample vs better sample',
  buildTryIt: (sim) {
    final s = sim as BiasSim;
    return watch(
      s,
      () => Column(
        children: [
          ChoiceRow<bool>(
            options: const {true: 'Ask shoppers at the mall', false: 'Random people in town'},
            selected: s.convenience,
            onSelected: (v) => s.change(() => s.convenience = v),
          ),
          LabeledSlider(
            left: 'n = ${s.n}',
            right: '100',
            value: s.n.toDouble(),
            min: 10,
            max: 100,
            divisions: 9,
            onChanged: (v) => s.change(() => s.n = v.round()),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'An online poll about internet use only reaches internet users. This is an example of…',
      options: ['Random error', 'Selection bias', 'A census', 'Stratified sampling'],
      answer: 1,
      explanation: 'Who could answer was decided by the very thing being measured.',
    ),
    QuizQuestion(
      prompt: 'A biased sample gets 10 times bigger. The bias…',
      options: ['Disappears', 'Shrinks a lot', 'Stays about the same', 'Doubles'],
      answer: 2,
      explanation: 'More of the same kind of people just narrows the scatter around the wrong value.',
    ),
    QuizQuestion(
      prompt: 'Only 20% of people mailed a survey return it. The main risk is…',
      options: ['Non-response bias', 'Too much data', 'Rounding errors', 'None'],
      answer: 0,
      explanation: 'People who reply may differ from those who don\'t.',
    ),
  ],
);

// ===========================================================================
// Sampling distributions
// ===========================================================================

enum Statistic { mean, median, max }

class SamplingDistSim extends TickSim {
  SamplingDistSim({super.rng});

  Statistic stat = Statistic.mean;
  int n = 10;
  List<double> sample = [];
  final List<double> results = [];

  /// Skewed population (like incomes, mean 1).
  double _person() => expDraw(rng, 1);

  @override
  double get interval => results.length < 6 ? 0.9 : 0.05;

  @override
  void tick() {
    sample = List.generate(n, (_) => _person());
    final v = switch (stat) {
      Statistic.mean => meanOf(sample),
      Statistic.median => quantileOf(sample, 0.5),
      Statistic.max => sample.reduce(math.max),
    };
    if (results.length < 4000) results.add(v);
  }

  @override
  void restart() {
    sample = [];
    results.clear();
  }
}

void _paintSamplingDist(Canvas canvas, Size size, SamplingDistSim sim) {
  final w = size.width;
  final h = size.height;
  // Population shape.
  final pop = Plot(Rect.fromLTRB(16, 24, w - 16, h * 0.3), x0: 0, x1: 6, y1: 1.05);
  label(canvas, 'Population (skewed, mean 1)', Offset(16, 10), size: 11, color: AppColors.muted, align: TextAlign.left);
  pop.curve(canvas, (x) => math.exp(-x), AppColors.peg, fill: true, width: 2);
  for (final v in sim.sample) {
    canvas.drawCircle(pop.at(v.clamp(0, 6), 0.05), 4, Paint()..color = AppColors.orange);
  }
  pop.axis(canvas, [0, 1, 2, 3, 4, 5, 6]);
  // Distribution of the statistic.
  final name =
      switch (sim.stat) { Statistic.mean => 'means', Statistic.median => 'medians', Statistic.max => 'maximums' };
  final hi = sim.stat == Statistic.max ? 8.0 : 3.0;
  final counts = binCounts(sim.results, 0, hi, 40);
  final peak = sim.results.isEmpty ? 1.0 : counts.reduce(math.max) / (sim.results.length * hi / 40);
  final plot = Plot(Rect.fromLTRB(16, h * 0.3 + 46, w - 16, h - 30), x0: 0, x1: hi, y1: math.max(peak * 1.15, 0.5));
  label(canvas, 'Sampling distribution: ${sim.results.length} sample $name (n = ${sim.n})', Offset(16, h * 0.3 + 32),
      size: 12, align: TextAlign.left);
  plot.densityBars(canvas, counts, 0, hi, AppColors.violet.withValues(alpha: 0.6), total: sim.results.length);
  if (sim.stat == Statistic.mean && sim.results.length > 30) {
    plot.curve(canvas, (x) => normalPdf(x, 1, 1 / math.sqrt(sim.n)), AppColors.pink);
  }
  plot.axis(canvas, [for (var t = 0.0; t <= hi; t += 1) t]);
}

final LessonSpec samplingDistributionsLesson = LessonSpec(
  id: 'sampling_distributions',
  chapterLabel: 'Ch 11 · Sampling',
  title: const [
    TitlePart('The distribution of a '),
    TitlePart('statistic', AppColors.violet),
  ],
  subtitle: 'Sampling distributions · 3-minute animated lesson',
  createSim: () => SamplingDistSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<SamplingDistSim>(sim, _paintSamplingDist),
  stats: (sim) {
    final s = sim as SamplingDistSim;
    return [
      StatChip('samples', '${s.results.length}', AppColors.yellow),
      StatChip('centre', meanOf(s.results).toStringAsFixed(2), AppColors.violet),
      StatChip('spread', sdOf(s.results).toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'Take a sample, compute a number from it (the mean, median, or maximum), and '
      'write it down. Do it thousands of times and those numbers form their own '
      'distribution: the sampling distribution. It tells you how much a statistic '
      'wobbles from sample to sample. For the mean it\'s centred on the truth and '
      'turns into a bell, even though the population is skewed (the CLT). The '
      'maximum is skewed and sits above the typical value.',
  formula: (sim) {
    final s = sim as SamplingDistSim;
    return s.stat == Statistic.mean
        ? 'mean of x̄ = μ = 1   sd of x̄ = σ/√n = 1/√${s.n} = ${(1 / math.sqrt(s.n)).toStringAsFixed(2)}'
        : 'each sample of ${s.n} → one value; repeat → its distribution';
  },
  tryItTitle: 'Try it: change the statistic and n',
  buildTryIt: (sim) {
    final s = sim as SamplingDistSim;
    return watch(
      s,
      () => Column(
        children: [
          ChoiceRow<Statistic>(
            options: const {Statistic.mean: 'Mean', Statistic.median: 'Median', Statistic.max: 'Maximum'},
            selected: s.stat,
            onSelected: (v) => s.change(() => s.stat = v),
          ),
          LabeledSlider(
            left: 'n = ${s.n}',
            right: '50',
            value: s.n.toDouble(),
            min: 2,
            max: 50,
            divisions: 48,
            onChanged: (v) => s.change(() => s.n = v.round()),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A sampling distribution describes…',
      options: [
        'The values in one sample',
        'How a statistic varies across many samples',
        'The population itself',
        'The sampling method',
      ],
      answer: 1,
      explanation: 'It is the distribution of the statistic, sample after sample.',
    ),
    QuizQuestion(
      prompt: 'The population is skewed. The sampling distribution of the mean for n = 40 is…',
      options: ['Equally skewed', 'Roughly normal', 'Flat', 'Bimodal'],
      answer: 1,
      explanation: 'The Central Limit Theorem: means of large samples are close to normal.',
    ),
    QuizQuestion(
      prompt: 'As n grows, the sampling distribution of the mean gets…',
      options: ['Wider', 'Narrower', 'Further from μ', 'More skewed'],
      answer: 1,
      explanation: 'Its sd is σ/√n, which shrinks as n grows.',
    ),
  ],
);

// ===========================================================================
// Standard error
// ===========================================================================

class StandardErrorSim extends TickSim {
  StandardErrorSim({super.rng});

  static const List<int> sizes = [4, 9, 16, 25, 36, 49, 64, 81, 100];
  static const double sigma = 10;
  static const int reps = 300;

  /// Observed sd of sample means for each size done so far.
  final List<double> observed = [];
  List<double> lastMeans = [];

  @override
  double get interval => 0.9;

  @override
  void tick() {
    if (observed.length >= sizes.length) {
      restart();
      return;
    }
    final n = sizes[observed.length];
    lastMeans = List.generate(reps, (_) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += 50 + sigma * normalDraw(rng);
      }
      return s / n;
    });
    observed.add(sdOf(lastMeans));
  }

  @override
  void restart() {
    observed.clear();
    lastMeans = [];
  }
}

void _paintSE(Canvas canvas, Size size, StandardErrorSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(36, 20, w - 16, h * 0.62), x0: 0, x1: 105, y1: 6);
  label(canvas, 'standard error ↑', Offset(36, 8), size: 11, color: AppColors.muted, align: TextAlign.left);
  plot.curve(canvas, (n) => n < 2 ? 6 : StandardErrorSim.sigma / math.sqrt(n), AppColors.pink, from: 2.8, to: 105);
  label(canvas, 'σ/√n', plot.at(14, 10 / math.sqrt(14)).translate(26, -4), size: 13, color: AppColors.pink);
  for (var i = 0; i < sim.observed.length; i++) {
    canvas.drawCircle(
        plot.at(StandardErrorSim.sizes[i].toDouble(), sim.observed[i]), 6, Paint()..color = AppColors.violet);
  }
  for (final t in [1.0, 2.0, 3.0, 4.0, 5.0]) {
    label(canvas, '${t.round()}', Offset(28, plot.y(t)), size: 9, color: AppColors.muted, align: TextAlign.right);
  }
  plot.axis(canvas, [4, 25, 49, 64, 100], title: 'sample size n');
  // The 300 means for the latest n.
  if (sim.lastMeans.isNotEmpty) {
    final n = StandardErrorSim.sizes[sim.observed.length - 1];
    final strip = Plot(Rect.fromLTRB(16, h * 0.62 + 46, w - 16, h - 24), x0: 35, x1: 65, y1: 1);
    label(canvas, '300 sample means with n = $n', Offset(16, h * 0.62 + 34), size: 11, align: TextAlign.left);
    for (var i = 0; i < sim.lastMeans.length; i++) {
      canvas.drawCircle(strip.at(sim.lastMeans[i].clamp(35, 65), (i % 9) / 9 + 0.05), 2.4,
          Paint()..color = AppColors.violet.withValues(alpha: 0.5));
    }
    strip.axis(canvas, [35, 40, 45, 50, 55, 60, 65]);
  }
}

final LessonSpec standardErrorLesson = LessonSpec(
  id: 'standard_error',
  chapterLabel: 'Ch 11 · Sampling',
  title: const [
    TitlePart('Four times the data, '),
    TitlePart('half', AppColors.pink),
    TitlePart(' the error'),
  ],
  subtitle: 'Standard error · 2-minute animated lesson',
  createSim: () => StandardErrorSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<StandardErrorSim>(sim, _paintSE),
  stats: (sim) {
    final s = sim as StandardErrorSim;
    final i = s.observed.length - 1;
    return [
      StatChip('n', i < 0 ? '…' : '${StandardErrorSim.sizes[i]}', AppColors.yellow),
      StatChip('SE seen', i < 0 ? '…' : s.observed[i].toStringAsFixed(2), AppColors.violet),
      StatChip('σ/√n', i < 0 ? '…' : (10 / math.sqrt(StandardErrorSim.sizes[i])).toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'The standard error is the standard deviation of an estimate: how far a '
      'sample mean typically lands from the true mean. It equals σ/√n. The square '
      'root is the catch: to halve the error you need four times as many people, '
      'and to cut it to a tenth you need a hundred times as many. That\'s why '
      'polls rarely go beyond a few thousand people.',
  formula: (sim) {
    final s = sim as StandardErrorSim;
    final i = s.observed.length - 1;
    return i < 0
        ? 'SE = σ / √n'
        : 'SE = 10 / √${StandardErrorSim.sizes[i]} = ${(10 / math.sqrt(StandardErrorSim.sizes[i])).toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: run all sizes at once',
  buildTryIt: (sim) {
    final s = sim as StandardErrorSim;
    return ControlRow(children: [
      ActionButton('Simulate every n', () {
        s.reset();
        s.runMany(StandardErrorSim.sizes.length);
      }),
    ]);
  },
  quiz: const [
    QuizQuestion(
      prompt: 'σ = 20 and n = 100. What is the standard error of the mean?',
      options: ['0.2', '2', '20', '200'],
      answer: 1,
      explanation: '20 / √100 = 20 / 10 = 2.',
    ),
    QuizQuestion(
      prompt: 'To halve the standard error, you need…',
      options: ['Twice the sample', 'Four times the sample', 'Half the sample', '√2 times the sample'],
      answer: 1,
      explanation: 'SE ∝ 1/√n, so n must grow by 2² = 4.',
    ),
    QuizQuestion(
      prompt: 'Standard deviation vs standard error: the SE describes…',
      options: [
        'Spread of individual values',
        'Spread of an estimate like the sample mean',
        'The population size',
        'The same thing',
      ],
      answer: 1,
      explanation: 'The sd is about people; the SE is about how much the average wobbles.',
    ),
  ],
);

// ===== lib/lessons/ch12_estimation.dart =====
// Chapter 12 · Estimation.

/// z values for common confidence levels.
const Map<int, double> kZFor = {80: 1.2816, 90: 1.6449, 95: 1.96, 99: 2.5758};

// ===========================================================================
// Point estimates (biased vs unbiased variance)
// ===========================================================================

class PointEstimateSim extends TickSim {
  PointEstimateSim({super.rng});

  static const double trueVar = 100; // sd 10
  int n = 4;
  final List<double> divN = [];
  final List<double> divN1 = [];

  @override
  double get interval => divN.length < 6 ? 0.8 : 0.03;

  @override
  void tick() {
    final xs = List.generate(n, (_) => 50 + 10 * normalDraw(rng));
    final m = meanOf(xs);
    final ss = xs.fold(0.0, (a, x) => a + (x - m) * (x - m));
    divN.add(ss / n);
    divN1.add(ss / (n - 1));
    if (divN.length > 3000) {
      divN.removeAt(0);
      divN1.removeAt(0);
    }
  }

  @override
  void restart() {
    divN.clear();
    divN1.clear();
  }
}

void _paintPointEstimate(Canvas canvas, Size size, PointEstimateSim sim) {
  final w = size.width;
  final h = size.height;
  const hi = 300.0;
  void row(String name, List<double> xs, double top, Color color) {
    final plot = Plot(Rect.fromLTRB(16, top + 32, w - 16, top + 100), x0: 0, x1: hi, y1: 1);
    label(canvas, name, Offset(16, top + 8), size: 12, color: color, align: TextAlign.left);
    final recent = xs.length > 200 ? xs.sublist(xs.length - 200) : xs;
    for (var i = 0; i < recent.length; i++) {
      canvas.drawCircle(
          plot.at(recent[i].clamp(0, hi), 0.15 + (i % 13) / 16), 2.6, Paint()..color = color.withValues(alpha: 0.4));
    }
    line(canvas, plot.at(PointEstimateSim.trueVar, 0), plot.at(PointEstimateSim.trueVar, 1), AppColors.ink, width: 2.5);
    if (xs.isNotEmpty) {
      final avg = meanOf(xs);
      final p = plot.at(avg.clamp(0, hi), 1);
      final tri = Path()
        ..moveTo(p.dx, p.dy + 2)
        ..lineTo(p.dx - 8, p.dy - 10)
        ..lineTo(p.dx + 8, p.dy - 10)
        ..close();
      canvas.drawPath(tri, Paint()..color = color);
      label(canvas, 'average ${avg.toStringAsFixed(1)}', Offset(w - 16, top + 8),
          size: 12, color: color, align: TextAlign.right);
    }
    plot.axis(canvas, [0, 100, 200, 300]);
  }

  label(canvas, 'True variance = 100 (black line)', Offset(w / 2, 10), size: 12);
  row('Divide by n', sim.divN, 24, AppColors.pink);
  row('Divide by n − 1', sim.divN1, h / 2 + 6, AppColors.green);
}

final LessonSpec pointEstimatesLesson = LessonSpec(
  id: 'point_estimates',
  chapterLabel: 'Ch 12 · Estimation',
  title: const [
    TitlePart('Why divide by '),
    TitlePart('n − 1', AppColors.green),
    TitlePart('?'),
  ],
  subtitle: 'Point estimates & bias · 2-minute animated lesson',
  createSim: () => PointEstimateSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<PointEstimateSim>(sim, _paintPointEstimate),
  stats: (sim) {
    final s = sim as PointEstimateSim;
    return [
      StatChip('samples', '${s.divN.length}', AppColors.yellow),
      StatChip('÷n avg', meanOf(s.divN).toStringAsFixed(1), AppColors.pink),
      StatChip('÷(n−1) avg', meanOf(s.divN1).toStringAsFixed(1), AppColors.green),
    ];
  },
  bigIdea: 'A point estimate is a single best guess for an unknown number, like using a '
      'sample\'s variance to estimate the population\'s. A good estimator is '
      'unbiased: right on average. Measuring spread around the sample\'s own mean '
      'always underestimates the true spread a little, because that mean sits in '
      'the middle of the sample. Dividing by n − 1 instead of n exactly corrects it.',
  formula: (sim) {
    final s = sim as PointEstimateSim;
    return 'E[÷n] = σ²(n − 1)/n = 100 × ${s.n - 1}/${s.n} = ${(100 * (s.n - 1) / s.n).toStringAsFixed(1)}   E[÷(n−1)] = 100';
  },
  tryItTitle: 'Try it: change the sample size',
  buildTryIt: (sim) {
    final s = sim as PointEstimateSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'n = ${s.n}',
            right: '20',
            value: s.n.toDouble(),
            min: 2,
            max: 20,
            divisions: 18,
            onChanged: (v) => s.change(() => s.n = v.round()),
          ),
          const TryNote('With tiny samples (n = 2) dividing by n is off by half. With big n the two barely differ.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'An estimator is "unbiased" if…',
      options: [
        'It is always exactly right',
        'Its average over many samples equals the true value',
        'It has no variance',
        'It uses n − 1'
      ],
      answer: 1,
      explanation: 'Individual estimates still wobble; they just don\'t lean one way.',
    ),
    QuizQuestion(
      prompt: 'Dividing the sum of squares by n tends to…',
      options: ['Overestimate the variance', 'Underestimate the variance', 'Be exact', 'Give the mean'],
      answer: 1,
      explanation: 'Distances from the sample\'s own mean are a little too small.',
    ),
    QuizQuestion(
      prompt: 'Which is a point estimate?',
      options: ['"Between 40% and 48%"', '"44%"', '"Probably"', '"n = 500"'],
      answer: 1,
      explanation: 'A single number. A range is an interval estimate.',
    ),
  ],
);

// ===========================================================================
// Maximum likelihood
// ===========================================================================

class MleSim extends TickSim {
  MleSim({super.rng});

  /// The coin's real bias, hidden from the learner until the end.
  static const double hidden = 0.7;
  int heads = 0, tails = 0;

  int get n => heads + tails;
  double get mle => n == 0 ? 0.5 : heads / n;

  /// Log-likelihood, shifted so its maximum is 0.
  double logL(double p) {
    if (n == 0) return 0;
    double ll(double q) => (heads == 0 ? 0 : heads * math.log(q)) + (tails == 0 ? 0 : tails * math.log(1 - q));
    return ll(p.clamp(1e-9, 1 - 1e-9)) - ll(mle.clamp(1e-9, 1 - 1e-9));
  }

  @override
  double get interval => n < 10 ? 0.8 : 0.3;

  @override
  void tick() {
    if (n >= 80) return;
    if (rng.nextDouble() < hidden) {
      heads++;
    } else {
      tails++;
    }
  }

  void add(bool h) {
    if (h) {
      heads++;
    } else {
      tails++;
    }
    notifyListeners();
  }

  @override
  void restart() => heads = tails = 0;
}

void _paintMle(Canvas canvas, Size size, MleSim sim) {
  final w = size.width;
  final h = size.height;
  label(canvas, '${sim.heads} heads, ${sim.tails} tails', Offset(w / 2, 12), size: 14);
  final plot = Plot(Rect.fromLTRB(16, 56, w - 16, h - 34), x0: 0, x1: 1, y1: 1.08);
  plot.curve(canvas, (p) => math.exp(sim.logL(p)), AppColors.blue, fill: true);
  dashedLine(canvas, plot.at(sim.mle, 0), plot.at(sim.mle, 1.04), AppColors.pink, width: 2.5);
  label(canvas, 'best p = ${sim.mle.toStringAsFixed(2)}', plot.at(sim.mle, 1.06), size: 12, color: AppColors.pink);
  plot.axis(canvas, [0, 0.25, 0.5, 0.75, 1], title: 'possible p (chance of heads)');
  label(canvas, 'how well each p explains the flips ↑', Offset(16, 28),
      size: 10, color: AppColors.muted, align: TextAlign.left);
}

final LessonSpec mleLesson = LessonSpec(
  id: 'mle',
  chapterLabel: 'Ch 12 · Estimation',
  title: const [
    TitlePart('Pick the value that makes the data '),
    TitlePart('most likely', AppColors.blue),
  ],
  subtitle: 'Maximum likelihood · 2-minute animated lesson',
  createSim: () => MleSim(),
  visualAspectRatio: 1.15,
  buildVisual: (sim) => simCanvas<MleSim>(sim, _paintMle),
  stats: (sim) {
    final s = sim as MleSim;
    return [
      StatChip('flips', '${s.n}', AppColors.yellow),
      StatChip('MLE', s.mle.toStringAsFixed(2), AppColors.pink),
      StatChip('hidden p', s.n >= 80 ? '0.70' : '?', AppColors.blue),
    ];
  },
  bigIdea: 'A coin of unknown bias p gives some heads and tails. For every possible p, '
      'ask: how likely would these exact flips be? That curve is the likelihood. '
      'Its peak, the maximum likelihood estimate, is the p that best explains the '
      'data, and for a coin it\'s simply heads ÷ flips. More flips make the curve '
      'narrower: the data rules out more values.',
  formula: (sim) {
    final s = sim as MleSim;
    return 'L(p) = p^${s.heads} (1 − p)^${s.tails}   peak at p̂ = ${s.heads}/${s.n} = ${s.mle.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: add flips yourself',
  buildTryIt: (sim) {
    final s = sim as MleSim;
    return ControlRow(children: [
      ActionButton('+ Heads', () => s.add(true)),
      ActionButton('+ Tails', () => s.add(false)),
      ActionButton('Clear', s.reset),
    ]);
  },
  quiz: const [
    QuizQuestion(
      prompt: 'You flip a coin 20 times and get 14 heads. The MLE of p is…',
      options: ['0.5', '0.7', '14', '0.14'],
      answer: 1,
      explanation: '14 / 20 = 0.7 makes the observed flips most likely.',
    ),
    QuizQuestion(
      prompt: 'What happens to the likelihood curve with more data?',
      options: ['It gets wider', 'It gets narrower', 'It becomes flat', 'Its peak moves to 0.5'],
      answer: 1,
      explanation: 'More data rules out more values of p.',
    ),
    QuizQuestion(
      prompt: 'The likelihood of p is…',
      options: [
        'The probability that p is true',
        'How probable the observed data would be if p were true',
        'Always 0.5',
        'The sample mean',
      ],
      answer: 1,
      explanation: 'It scores each p by how well it predicts what actually happened.',
    ),
  ],
);

// ===========================================================================
// Confidence intervals
// ===========================================================================

class ConfidenceSim extends TickSim {
  ConfidenceSim({super.rng});

  static const double mu = 50, sigma = 10;
  int n = 25;
  int level = 95;
  final List<(double, double)> intervals = [];
  int made = 0, covered = 0;

  double get halfWidth => kZFor[level]! * sigma / math.sqrt(n);

  @override
  double get interval => made < 8 ? 0.6 : 0.15;

  @override
  void tick() {
    var s = 0.0;
    for (var i = 0; i < n; i++) {
      s += mu + sigma * normalDraw(rng);
    }
    final m = s / n;
    final ci = (m - halfWidth, m + halfWidth);
    intervals.add(ci);
    if (intervals.length > 30) intervals.removeAt(0);
    made++;
    if (ci.$1 <= mu && mu <= ci.$2) covered++;
  }

  @override
  void restart() {
    intervals.clear();
    made = covered = 0;
  }
}

void _paintConfidence(Canvas canvas, Size size, ConfidenceSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(16, 20, w - 16, h - 34), x0: 40, x1: 60, y1: 30);
  line(canvas, plot.at(ConfidenceSim.mu, 0), plot.at(ConfidenceSim.mu, 30), AppColors.ink, width: 2.5);
  label(canvas, 'true mean 50', plot.at(ConfidenceSim.mu, 30).translate(0, -10), size: 11);
  for (var i = 0; i < sim.intervals.length; i++) {
    final (lo, hi) = sim.intervals[i];
    final hit = lo <= ConfidenceSim.mu && ConfidenceSim.mu <= hi;
    final y = 29.2 - i.toDouble();
    final color = hit ? AppColors.blue : AppColors.pink;
    line(canvas, plot.at(lo.clamp(40, 60), y), plot.at(hi.clamp(40, 60), y), color, width: hit ? 3 : 4);
    canvas.drawCircle(plot.at(((lo + hi) / 2).clamp(40, 60), y), 3.5, Paint()..color = color);
  }
  plot.axis(canvas, [40, 45, 50, 55, 60]);
}

final LessonSpec confidenceIntervalsLesson = LessonSpec(
  id: 'confidence_intervals',
  chapterLabel: 'Ch 12 · Estimation',
  title: const [
    TitlePart('What "95% '),
    TitlePart('confident', AppColors.blue),
    TitlePart('" really means'),
  ],
  subtitle: 'Confidence intervals · 3-minute animated lesson',
  createSim: () => ConfidenceSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<ConfidenceSim>(sim, _paintConfidence),
  stats: (sim) {
    final s = sim as ConfidenceSim;
    return [
      StatChip('intervals', '${s.made}', AppColors.yellow),
      StatChip('caught μ', s.made == 0 ? '…' : '${(s.covered / s.made * 100).toStringAsFixed(1)}%', AppColors.blue),
      StatChip('missed', '${s.made - s.covered}', AppColors.pink),
    ];
  },
  bigIdea: 'Each line is one sample\'s interval: its mean ± a margin. The true mean '
      'never moves; the intervals do. A 95% procedure produces intervals that catch '
      'the truth 95% of the time. The pink ones missed. For any one interval you '
      'can\'t know whether it\'s a hit, so "95% confident" describes the method, not '
      'a 95% chance about one fixed interval. Higher confidence means wider '
      'intervals; more data means narrower ones.',
  formula: (sim) {
    final s = sim as ConfidenceSim;
    return 'x̄ ± z·σ/√n = x̄ ± ${kZFor[s.level]!.toStringAsFixed(2)} × 10/√${s.n} = x̄ ± ${s.halfWidth.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: confidence level and sample size',
  buildTryIt: (sim) {
    final s = sim as ConfidenceSim;
    return watch(
      s,
      () => Column(
        children: [
          ChoiceRow<int>(
            options: const {80: '80%', 90: '90%', 95: '95%', 99: '99%'},
            selected: s.level,
            onSelected: (v) => s.change(() => s.level = v),
          ),
          LabeledSlider(
            left: 'n = ${s.n}',
            right: '100',
            value: s.n.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            onChanged: (v) => s.change(() => s.n = v.round()),
          ),
          ControlRow(children: [ActionButton('Make 500 intervals', () => s.runMany(500))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'You make 100 different 95% confidence intervals. About how many miss the true value?',
      options: ['0', '5', '50', '95'],
      answer: 1,
      explanation: '95% catch it, so about 5 miss.',
    ),
    QuizQuestion(
      prompt: 'Going from 95% to 99% confidence makes the interval…',
      options: ['Narrower', 'Wider', 'The same', 'Shift right'],
      answer: 1,
      explanation: 'To catch the truth more often, the net has to be wider.',
    ),
    QuizQuestion(
      prompt: 'How can you get a narrower interval at the same confidence level?',
      options: ['Collect more data', 'Lower the sample size', 'Use 99%', 'Round the mean'],
      answer: 0,
      explanation: 'The margin shrinks like 1/√n.',
    ),
  ],
);

// ===========================================================================
// Margin of error
// ===========================================================================

class MarginSim extends TickSim {
  MarginSim({super.rng});

  static const double truth = 0.52;
  int n = 400;
  final List<double> polls = [];

  double moe(double p) => 1.96 * math.sqrt(p * (1 - p) / n);

  @override
  double get interval => polls.length < 6 ? 0.8 : 0.25;

  @override
  void tick() {
    var yes = 0;
    for (var i = 0; i < n; i++) {
      if (rng.nextDouble() < truth) yes++;
    }
    polls.add(yes / n);
    if (polls.length > 12) polls.removeAt(0);
  }

  @override
  void restart() => polls.clear();
}

void _paintMargin(Canvas canvas, Size size, MarginSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(16, 22, w - 16, h * 0.52), x0: 0.38, x1: 0.66, y1: 12.5);
  line(canvas, plot.at(MarginSim.truth, 0), plot.at(MarginSim.truth, 12.5), AppColors.ink, width: 2);
  dashedLine(canvas, plot.at(0.5, 0), plot.at(0.5, 12.5), AppColors.peg);
  label(canvas, 'true support 52%', plot.at(MarginSim.truth, 12.5).translate(0, -10), size: 11);
  for (var i = 0; i < sim.polls.length; i++) {
    final p = sim.polls[i];
    final m = sim.moe(p);
    final y = 11.5 - i.toDouble();
    line(canvas, plot.at((p - m).clamp(0.38, 0.66), y), plot.at((p + m).clamp(0.38, 0.66), y), AppColors.orange,
        width: 3);
    canvas.drawCircle(plot.at(p.clamp(0.38, 0.66), y), 4.5, Paint()..color = AppColors.ink);
  }
  plot.axis(canvas, [0.4, 0.45, 0.5, 0.55, 0.6, 0.65], format: (v) => '${(v * 100).round()}%');
  // Margin of error vs n.
  final curve = Plot(Rect.fromLTRB(40, h * 0.52 + 44, w - 16, h - 30), x0: 0, x1: 3000, y1: 0.1);
  label(canvas, 'margin of error ↑', Offset(40, h * 0.52 + 32),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  curve.curve(canvas, (n) => n < 50 ? 0.14 : 1.96 * math.sqrt(0.25 / n), AppColors.orange, from: 100, to: 3000);
  canvas.drawCircle(curve.at(sim.n.toDouble(), 1.96 * math.sqrt(0.25 / sim.n)), 7, Paint()..color = AppColors.pink);
  for (final t in [0.02, 0.05, 0.08]) {
    label(canvas, '${(t * 100).round()}%', Offset(34, curve.y(t)),
        size: 9, color: AppColors.muted, align: TextAlign.right);
  }
  curve.axis(canvas, [0, 1000, 2000, 3000], title: 'people polled');
}

final LessonSpec marginOfErrorLesson = LessonSpec(
  id: 'margin_of_error',
  chapterLabel: 'Ch 12 · Estimation',
  title: const [
    TitlePart('"52%, give or take '),
    TitlePart('3', AppColors.orange),
    TitlePart('"'),
  ],
  subtitle: 'Margin of error · 2-minute animated lesson',
  createSim: () => MarginSim(),
  visualAspectRatio: 0.85,
  buildVisual: (sim) => simCanvas<MarginSim>(sim, _paintMargin),
  stats: (sim) {
    final s = sim as MarginSim;
    return [
      StatChip('polled', '${s.n}', AppColors.yellow),
      StatChip('margin', '±${(s.moe(0.5) * 100).toStringAsFixed(1)}%', AppColors.orange),
    ];
  },
  bigIdea: 'A poll of n people gives an estimate, say 52%, plus a margin of error: the '
      'half-width of a 95% confidence interval. Each orange bar is a different poll. '
      'With 1,000 people the margin is about ±3 points, so a 52–48 race is too '
      'close to call. Quadrupling the sample only halves the margin.',
  formula: (sim) {
    final s = sim as MarginSim;
    return 'MoE = 1.96 × √(p̂(1 − p̂)/n) ≈ 1.96 × √(0.25/${s.n}) = ${(s.moe(0.5) * 100).toStringAsFixed(1)} points';
  },
  tryItTitle: 'Try it: poll more people',
  buildTryIt: (sim) {
    final s = sim as MarginSim;
    return watch(
      s,
      () => LabeledSlider(
        left: 'n = ${s.n}',
        right: '3000',
        value: s.n.toDouble(),
        min: 100,
        max: 3000,
        divisions: 29,
        onChanged: (v) => s.change(() => s.n = v.round()),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A poll of 1,000 people has a margin of error of about…',
      options: ['±0.3%', '±3%', '±10%', '±30%'],
      answer: 1,
      explanation: '1.96 × √(0.25/1000) ≈ 0.031.',
    ),
    QuizQuestion(
      prompt: 'Candidate A polls 51%, B 49%, margin ±3%. You can conclude…',
      options: ['A is winning', 'B is winning', 'The race is too close to call', 'The poll is wrong'],
      answer: 2,
      explanation: 'The intervals overlap heavily.',
    ),
    QuizQuestion(
      prompt: 'Does the margin of error cover bias from a badly chosen sample?',
      options: ['Yes', 'No, only random sampling error', 'Only for big polls', 'Only for online polls'],
      answer: 1,
      explanation: 'The formula assumes a random sample; it says nothing about bias.',
    ),
  ],
);

// ===========================================================================
// Choosing a sample size
// ===========================================================================

class SampleSizeSim extends LessonSim {
  double t = 0;
  double? manual;
  int level = 95;

  /// Desired margin (as a proportion) — sweeps 1%–10% until set.
  double get margin => manual ?? 0.01 + 0.09 * ((math.sin(t * 0.5 - math.pi / 2) + 1) / 2);

  int get needed => (math.pow(kZFor[level]! * 0.5 / margin, 2)).ceil();

  @override
  void advance(double dt) {
    if (manual == null) t += dt;
    notifyListeners();
  }

  @override
  void step() {
    manual = ((margin * 100).round() + 1).clamp(1, 10) / 100;
    notifyListeners();
  }

  @override
  void reset() {
    manual = null;
    t = 0;
    notifyListeners();
  }

  void setMargin(double m) {
    manual = m;
    notifyListeners();
  }

  void setLevel(int l) {
    level = l;
    notifyListeners();
  }
}

void _paintSampleSize(Canvas canvas, Size size, SampleSizeSim sim) {
  final w = size.width;
  final h = size.height;
  final z = kZFor[sim.level]!;
  final plot = Plot(Rect.fromLTRB(48, 30, w - 16, h - 60), x0: 0.01, x1: 0.1, y1: 17000);
  label(canvas, 'people needed ↑', Offset(48, 14), size: 11, color: AppColors.muted, align: TextAlign.left);
  plot.curve(canvas, (e) => math.pow(z * 0.5 / e, 2).toDouble(), AppColors.violet, fill: true);
  final p = plot.at(sim.margin, sim.needed.toDouble().clamp(0, 17000));
  dashedLine(canvas, Offset(p.dx, plot.rect.bottom), p, AppColors.pink);
  dashedLine(canvas, Offset(plot.rect.left, p.dy), p, AppColors.pink);
  canvas.drawCircle(p, 7, Paint()..color = AppColors.pink);
  for (final t in [5000.0, 10000.0, 15000.0]) {
    label(canvas, '${(t / 1000).round()}k', Offset(42, plot.y(t)),
        size: 9, color: AppColors.muted, align: TextAlign.right);
  }
  plot.axis(canvas, [0.01, 0.02, 0.04, 0.06, 0.08, 0.1],
      format: (v) => '±${(v * 100).round()}%', title: 'margin you want');
  label(
      canvas, '±${(sim.margin * 100).toStringAsFixed(1)}% at ${sim.level}% → n = ${sim.needed}', Offset(w / 2, h - 16),
      size: 15, color: AppColors.pink);
}

final LessonSpec sampleSizeLesson = LessonSpec(
  id: 'sample_size',
  chapterLabel: 'Ch 12 · Estimation',
  title: const [
    TitlePart('How many people do I '),
    TitlePart('need', AppColors.violet),
    TitlePart(' to ask?'),
  ],
  subtitle: 'Choosing a sample size · 2-minute animated lesson',
  createSim: () => SampleSizeSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<SampleSizeSim>(sim, _paintSampleSize),
  stats: (sim) {
    final s = sim as SampleSizeSim;
    return [
      StatChip('margin', '±${(s.margin * 100).toStringAsFixed(1)}%', AppColors.pink),
      StatChip('confidence', '${s.level}%', AppColors.yellow),
      StatChip('n needed', '${s.needed}', AppColors.violet),
    ];
  },
  bigIdea: 'Plan before you collect. Decide how precise you need to be (the margin E) '
      'and how confident, then solve the margin formula for n. For a proportion, '
      'p = 0.5 is the worst case, so it\'s the safe choice. Because n depends on 1/E², '
      'halving the margin quadruples the sample: precision gets expensive fast.',
  formula: (sim) {
    final s = sim as SampleSizeSim;
    return 'n = (z × 0.5 / E)² = (${kZFor[s.level]!.toStringAsFixed(2)} × 0.5 / ${s.margin.toStringAsFixed(3)})² '
        '= ${s.needed}';
  },
  tryItTitle: 'Try it: pick your precision',
  buildTryIt: (sim) {
    final s = sim as SampleSizeSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: '±1%',
            right: '±10%',
            value: s.margin,
            min: 0.01,
            max: 0.1,
            divisions: 18,
            label: '±${(s.margin * 100).toStringAsFixed(1)}%',
            onChanged: s.setMargin,
          ),
          ChoiceRow<int>(
            options: const {90: '90%', 95: '95%', 99: '99%'},
            selected: s.level,
            onSelected: s.setLevel,
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'You want ±5% at 95% confidence for a proportion. Roughly how many people?',
      options: ['100', '385', '1,000', '10,000'],
      answer: 1,
      explanation: '(1.96 × 0.5 / 0.05)² ≈ 384.2, so round up to 385.',
    ),
    QuizQuestion(
      prompt: 'You want to halve your margin of error. The sample must be…',
      options: ['Doubled', 'Quadrupled', 'Halved', '√2 times bigger'],
      answer: 1,
      explanation: 'n ∝ 1/E², so halving E multiplies n by 4.',
    ),
    QuizQuestion(
      prompt: 'Why use p = 0.5 when planning a poll?',
      options: [
        'Polls are always 50-50',
        'It gives the largest needed n, so the plan is safe',
        'It is the smallest',
        'It is required by law',
      ],
      answer: 1,
      explanation: 'p(1 − p) is largest at 0.5, so the margin is never worse than planned.',
    ),
  ],
);

// ===== lib/lessons/ch13_testing.dart =====
// Chapter 13 · Hypothesis testing.

/// Two-sided p-value for k heads in n fair flips.
double binomTwoSidedP(int n, int k) {
  final d = (k - n / 2).abs();
  var p = 0.0;
  for (var j = 0; j <= n; j++) {
    if ((j - n / 2).abs() >= d - 1e-9) p += binomPmf(n, j, 0.5);
  }
  return math.min(1, p);
}

/// Repeated experiments with a running count of rejections.
abstract class ExperimentSim extends TickSim {
  ExperimentSim({super.rng});

  int experiments = 0, rejections = 0;
  double get rejectRate => experiments == 0 ? 0 : rejections / experiments;

  /// Runs one experiment; returns whether H₀ was rejected.
  bool experiment();

  @override
  double get interval => experiments < 5 ? 1.4 : 0.35;

  @override
  void tick() {
    experiments++;
    if (experiment()) rejections++;
  }

  @override
  void restart() => experiments = rejections = 0;
}

Widget _rejectTag(ExperimentSim s, String name) =>
    ValueTag('$name: ${s.rejections}/${s.experiments} rejected (${(s.rejectRate * 100).toStringAsFixed(0)}%)');

// ===========================================================================
// Null vs alternative
// ===========================================================================

class CoinTrialSim extends ExperimentSim {
  CoinTrialSim({super.rng});

  static const int flips = 20;

  /// Reject "fair" when heads ≤ 5 or ≥ 15 (α ≈ 0.041).
  static bool rejects(int k) => k <= 5 || k >= 15;

  double trueP = 0.5;
  int heads = 0;

  @override
  bool experiment() {
    heads = 0;
    for (var i = 0; i < flips; i++) {
      if (rng.nextDouble() < trueP) heads++;
    }
    return rejects(heads);
  }
}

void _paintNullAlt(Canvas canvas, Size size, CoinTrialSim sim) {
  final w = size.width;
  final h = size.height;
  label(canvas, 'If H₀ is true (fair coin), heads in 20 flips look like this:', Offset(w / 2, 12),
      size: 11, color: AppColors.muted);
  final probs = [for (var k = 0; k <= 20; k++) binomPmf(20, k, 0.5)];
  final plot = Plot(Rect.fromLTRB(16, 30, w - 16, h - 74), x0: -0.6, x1: 20.6, y1: 0.2);
  plot.intBars(
      canvas, probs, 0, (k) => CoinTrialSim.rejects(k) ? AppColors.pink : AppColors.blue.withValues(alpha: 0.6),
      widthFrac: 0.8);
  plot.axis(canvas, [0, 5, 10, 15, 20], title: 'heads');
  if (sim.experiments > 0) {
    final p = plot.at(sim.heads.toDouble(), probs[sim.heads] + 0.02);
    canvas.drawCircle(p, 8, Paint()..color = AppColors.ink);
    label(canvas, '${sim.heads}', p, size: 10, color: Colors.white);
    final rej = CoinTrialSim.rejects(sim.heads);
    label(canvas, rej ? 'Too surprising if fair: reject H₀' : 'Consistent with fair: don\'t reject H₀',
        Offset(w / 2, h - 46),
        size: 14, color: rej ? AppColors.pink : AppColors.blue);
  }
  label(canvas, 'pink = "too surprising" zone (≤ 5 or ≥ 15)', Offset(w / 2, h - 18), size: 11, color: AppColors.muted);
}

final LessonSpec nullAlternativeLesson = LessonSpec(
  id: 'null_alternative',
  chapterLabel: 'Ch 13 · Hypothesis testing',
  title: const [
    TitlePart('Innocent', AppColors.blue),
    TitlePart(' until proven '),
    TitlePart('guilty', AppColors.pink),
  ],
  subtitle: 'Null vs alternative hypotheses · 2-minute animated lesson',
  createSim: () => CoinTrialSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<CoinTrialSim>(sim, _paintNullAlt),
  stats: (sim) {
    final s = sim as CoinTrialSim;
    return [
      StatChip('trials', '${s.experiments}', AppColors.yellow),
      StatChip('rejected H₀', '${(s.rejectRate * 100).toStringAsFixed(0)}%', AppColors.pink),
      StatChip('real p', s.trueP.toStringAsFixed(2), AppColors.blue),
    ];
  },
  bigIdea: 'A test starts from a default claim, the null hypothesis H₀: "the coin is '
      'fair". The alternative H₁ is what you suspect: "it isn\'t". Like a court, '
      'H₀ stands unless the evidence would be really surprising if it were true. '
      'Not rejecting H₀ doesn\'t prove it; it just means the evidence wasn\'t '
      'strong enough. Make the coin truly biased and watch how often the test catches it.',
  formula: (_) => 'H₀: p = 0.5   H₁: p ≠ 0.5   reject if heads ≤ 5 or ≥ 15 (α ≈ 0.041)',
  tryItTitle: 'Try it: secretly bias the coin',
  buildTryIt: (sim) {
    final s = sim as CoinTrialSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'p 0.2',
            right: '0.8',
            value: s.trueP,
            min: 0.2,
            max: 0.8,
            divisions: 12,
            label: 'real p = ${s.trueP.toStringAsFixed(2)}',
            onChanged: (v) => s.change(() => s.trueP = v),
          ),
          ControlRow(children: [_rejectTag(s, 'trials'), ActionButton('Run 200 trials', () => s.runMany(200))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A new drug is tested. The null hypothesis is usually…',
      options: ['The drug works', 'The drug has no effect', 'The drug is dangerous', 'The trial is biased'],
      answer: 1,
      explanation: 'H₀ is the "nothing special is going on" default.',
    ),
    QuizQuestion(
      prompt: 'A test does not reject H₀. This means…',
      options: ['H₀ is proven true', 'There wasn\'t enough evidence against H₀', 'H₁ is true', 'The test failed'],
      answer: 1,
      explanation: '"Not guilty" isn\'t the same as "innocent".',
    ),
    QuizQuestion(
      prompt:
          'A fair coin is tested by rejecting "fair" when 20 flips give ≤ 5 or ≥ 15 heads. How often is H₀ wrongly rejected?',
      options: ['Never', 'About 4% of the time', 'About 50%', 'Always'],
      answer: 1,
      explanation: 'The pink zone holds about 4.1% of the fair-coin probability.',
    ),
  ],
);

// ===========================================================================
// p-values
// ===========================================================================

class PValueSim extends ExperimentSim {
  PValueSim({super.rng});

  static const int flips = 30;
  double trueP = 0.5;
  int heads = 15;
  double pValue = 1;
  final List<double> pValues = [];

  @override
  bool experiment() {
    heads = 0;
    for (var i = 0; i < flips; i++) {
      if (rng.nextDouble() < trueP) heads++;
    }
    pValue = binomTwoSidedP(flips, heads);
    if (pValues.length < 2000) pValues.add(pValue);
    return pValue < 0.05;
  }

  @override
  void restart() {
    super.restart();
    pValues.clear();
  }
}

void _paintPValue(Canvas canvas, Size size, PValueSim sim) {
  final w = size.width;
  final h = size.height;
  final probs = [for (var k = 0; k <= 30; k++) binomPmf(30, k, 0.5)];
  final d = (sim.heads - 15).abs();
  final plot = Plot(Rect.fromLTRB(16, 26, w - 16, h * 0.5), x0: -0.6, x1: 30.6, y1: 0.16);
  label(canvas, '${sim.heads} heads in 30: shaded = at least this far from 15', Offset(w / 2, 10), size: 11);
  plot.intBars(canvas, probs, 0, (k) => (k - 15).abs() >= d ? AppColors.pink : AppColors.peg.withValues(alpha: 0.5),
      widthFrac: 0.8);
  plot.axis(canvas, [0, 5, 10, 15, 20, 25, 30]);
  label(canvas, 'p-value = ${sim.pValue.toStringAsFixed(3)}', Offset(w - 16, 34),
      size: 15, color: sim.pValue < 0.05 ? AppColors.pink : AppColors.ink, align: TextAlign.right);
  // Histogram of p-values over many experiments.
  final ph = Plot(Rect.fromLTRB(16, h * 0.5 + 46, w - 16, h - 28), x0: 0, x1: 1, y1: 1);
  label(canvas, 'p-values from ${sim.pValues.length} experiments', Offset(16, h * 0.5 + 32),
      size: 11, align: TextAlign.left);
  final counts = binCounts(sim.pValues, 0, 1.0001, 20);
  final maxC = math.max(1, counts.reduce(math.max));
  for (var i = 0; i < 20; i++) {
    final r = Rect.fromLTRB(ph.x(i / 20) + 1, ph.y(counts[i] / maxC), ph.x((i + 1) / 20) - 1, ph.y(0));
    canvas.drawRect(r, Paint()..color = i == 0 ? AppColors.pink : AppColors.violet.withValues(alpha: 0.55));
  }
  ph.axis(canvas, [0, 0.05, 0.5, 1]);
}

final LessonSpec pValuesLesson = LessonSpec(
  id: 'p_values',
  chapterLabel: 'Ch 13 · Hypothesis testing',
  title: const [
    TitlePart('How '),
    TitlePart('surprising', AppColors.pink),
    TitlePart(' is your result?'),
  ],
  subtitle: 'p-values · 3-minute animated lesson',
  createSim: () => PValueSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<PValueSim>(sim, _paintPValue),
  stats: (sim) {
    final s = sim as PValueSim;
    return [
      StatChip('p-value', s.pValue.toStringAsFixed(3), AppColors.pink),
      StatChip('p < 0.05', '${(s.rejectRate * 100).toStringAsFixed(0)}%', AppColors.violet),
    ];
  },
  bigIdea: 'The p-value is the chance of a result at least as extreme as yours if H₀ '
      'were true: the shaded bars. A small p-value (below 0.05, say) means your data '
      'would be rare under H₀. It is NOT the chance that H₀ is true. Run many '
      'experiments with a fair coin and the p-values spread out evenly; bias the '
      'coin and they pile up near 0.',
  formula: (sim) {
    final s = sim as PValueSim;
    return 'p = P(|X − 15| ≥ ${(s.heads - 15).abs()} | fair coin) = ${s.pValue.toStringAsFixed(4)}';
  },
  tryItTitle: 'Try it: fair coin vs biased coin',
  buildTryIt: (sim) {
    final s = sim as PValueSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'p 0.3',
            right: '0.8',
            value: s.trueP,
            min: 0.3,
            max: 0.8,
            divisions: 10,
            label: 'real p = ${s.trueP.toStringAsFixed(2)}',
            onChanged: (v) => s.change(() => s.trueP = v),
          ),
          ControlRow(children: [ActionButton('Run 500 experiments', () => s.runMany(500))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'p = 0.03 means…',
      options: [
        'There is a 3% chance H₀ is true',
        'If H₀ were true, results this extreme would happen about 3% of the time',
        'The effect is 3% big',
        'The test is 97% accurate',
      ],
      answer: 1,
      explanation: 'It is a probability about the data, assuming H₀.',
    ),
    QuizQuestion(
      prompt: 'A smaller p-value means…',
      options: [
        'Weaker evidence against H₀',
        'Stronger evidence against H₀',
        'A bigger effect, always',
        'A bigger sample'
      ],
      answer: 1,
      explanation: 'The data would be more surprising if H₀ held.',
    ),
    QuizQuestion(
      prompt: 'H₀ is true and you test at α = 0.05 many times. What share of p-values fall below 0.05?',
      options: ['0%', 'About 5%', 'About 50%', '95%'],
      answer: 1,
      explanation: 'That is exactly what α controls (for continuous tests; discrete ones land at or below it).',
    ),
  ],
);

// ===========================================================================
// Type I & Type II errors
// ===========================================================================

class ErrorsSim extends TickSim {
  ErrorsSim({super.rng});

  double cutoff = 1.645;
  double effect = 2;
  final List<(bool, double)> recent = []; // (H₁ true?, value)
  final List<int> tally = [0, 0, 0, 0]; // correct keep, type I, type II, correct reject

  double get alpha => 1 - normalCdf(cutoff);
  double get beta => normalCdf(cutoff - effect);

  @override
  double get interval => recent.length < 6 ? 0.8 : 0.12;

  @override
  void tick() {
    final h1 = rng.nextBool();
    final v = normalDraw(rng) + (h1 ? effect : 0);
    recent.add((h1, v));
    if (recent.length > 40) recent.removeAt(0);
    final reject = v > cutoff;
    tally[h1 ? (reject ? 3 : 2) : (reject ? 1 : 0)]++;
  }

  @override
  void restart() {
    recent.clear();
    tally.setAll(0, [0, 0, 0, 0]);
  }

  void adjust({double? cut, double? eff}) {
    cutoff = cut ?? cutoff;
    effect = eff ?? effect;
    notifyListeners();
  }
}

void _paintErrors(Canvas canvas, Size size, ErrorsSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(16, 30, w - 16, h - 108), x0: -3.5, x1: 6.5, y1: 0.45);
  plot.curve(canvas, normalPdf, AppColors.pink, fill: true, from: sim.cutoff, to: 6.5, width: 0.5);
  plot.curve(canvas, (x) => normalPdf(x, sim.effect), AppColors.orange,
      fill: true, from: -3.5, to: sim.cutoff, width: 0.5);
  plot.curve(canvas, normalPdf, AppColors.blue);
  plot.curve(canvas, (x) => normalPdf(x, sim.effect), AppColors.green);
  line(canvas, plot.at(sim.cutoff, 0), plot.at(sim.cutoff, 0.44), AppColors.ink, width: 2.5);
  label(canvas, 'H₀ true', plot.at(0, 0.42), size: 12, color: AppColors.blue);
  label(canvas, 'H₁ true', plot.at(sim.effect, 0.42), size: 12, color: AppColors.green);
  label(canvas, 'reject →', plot.at(sim.cutoff, 0.44).translate(30, 0), size: 11);
  for (final (h1, v) in sim.recent) {
    canvas.drawCircle(plot.at(v.clamp(-3.4, 6.4), 0.012), 3, Paint()..color = h1 ? AppColors.green : AppColors.blue);
  }
  plot.axis(canvas, [-2, 0, 2, 4, 6]);
  final names = ['Correct: kept H₀', 'Type I: false alarm', 'Type II: missed it', 'Correct: caught it'];
  const colors = [AppColors.blue, AppColors.pink, AppColors.orange, AppColors.green];
  for (var i = 0; i < 4; i++) {
    final x = 16 + (i % 2) * (w - 32) / 2;
    final y = h - 70 + (i ~/ 2) * 26.0;
    roundRect(canvas, Rect.fromLTWH(x, y - 7, 14, 14), colors[i], radius: 3);
    label(canvas, '${names[i]}: ${sim.tally[i]}', Offset(x + 20, y), size: 11, align: TextAlign.left);
  }
}

final LessonSpec typeErrorsLesson = LessonSpec(
  id: 'type_errors',
  chapterLabel: 'Ch 13 · Hypothesis testing',
  title: const [
    TitlePart('False alarms', AppColors.pink),
    TitlePart(' vs '),
    TitlePart('missed signals', AppColors.orange),
  ],
  subtitle: 'Type I & Type II errors · 3-minute animated lesson',
  createSim: () => ErrorsSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<ErrorsSim>(sim, _paintErrors),
  stats: (sim) {
    final s = sim as ErrorsSim;
    return [
      StatChip('α (type I)', s.alpha.toStringAsFixed(3), AppColors.pink),
      StatChip('β (type II)', s.beta.toStringAsFixed(3), AppColors.orange),
      StatChip('power', (1 - s.beta).toStringAsFixed(3), AppColors.green),
    ];
  },
  bigIdea: 'Every test can go wrong two ways. A Type I error rejects a true H₀: a false '
      'alarm, like convicting an innocent person (pink area, chance α). A Type II '
      'error keeps a false H₀: a missed signal, like letting a guilty person go '
      '(orange area, chance β). Slide the cut-off right and false alarms drop but '
      'misses rise. The only way to cut both is a bigger effect or more data.',
  formula: (sim) {
    final s = sim as ErrorsSim;
    return 'α = P(reject | H₀) = ${s.alpha.toStringAsFixed(3)}   β = P(keep | H₁) = ${s.beta.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: move the cut-off and the effect',
  buildTryIt: (sim) {
    final s = sim as ErrorsSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'cut-off',
            right: '',
            value: s.cutoff,
            min: 0,
            max: 3,
            divisions: 30,
            label: s.cutoff.toStringAsFixed(2),
            onChanged: (v) => s.adjust(cut: v),
          ),
          LabeledSlider(
            left: 'effect',
            right: '',
            value: s.effect,
            min: 0.5,
            max: 4,
            divisions: 14,
            label: s.effect.toStringAsFixed(1),
            onChanged: (v) => s.adjust(eff: v),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A smoke alarm goes off while you make toast. That\'s a…',
      options: ['Type I error', 'Type II error', 'Correct decision', 'p-value'],
      answer: 0,
      explanation: 'An alarm when nothing is wrong: rejecting a true "no fire" H₀.',
    ),
    QuizQuestion(
      prompt: 'A test misses a disease that is really there. That\'s a…',
      options: ['Type I error', 'Type II error', 'False positive', 'Correct decision'],
      answer: 1,
      explanation: 'Failing to reject a false H₀ is a Type II error (false negative).',
    ),
    QuizQuestion(
      prompt: 'Lowering α from 0.05 to 0.01 (same data size) makes Type II errors…',
      options: ['Less likely', 'More likely', 'Impossible', 'Unchanged'],
      answer: 1,
      explanation: 'A stricter cut-off misses more real effects.',
    ),
  ],
);

// ===========================================================================
// Power
// ===========================================================================

class PowerSim extends ExperimentSim {
  PowerSim({super.rng});

  int n = 10;
  double effect = 0.5; // in sd units
  double lastMean = 0;

  double get se => 1 / math.sqrt(n);
  double get cutoff => 1.645 * se;
  double get power => 1 - normalCdf(1.645 - effect * math.sqrt(n));

  @override
  bool experiment() {
    var s = 0.0;
    for (var i = 0; i < n; i++) {
      s += effect + normalDraw(rng);
    }
    lastMean = s / n;
    return lastMean > cutoff;
  }

  @override
  double get interval => experiments < 5 ? 1.0 : 0.15;
}

void _paintPower(Canvas canvas, Size size, PowerSim sim) {
  final w = size.width;
  final h = size.height;
  final se = sim.se;
  final peak = normalPdf(0, 0, se);
  final plot = Plot(Rect.fromLTRB(16, 24, w - 16, h * 0.55), x0: -1.5, x1: 2.5, y1: peak * 1.15);
  label(canvas, 'Sample means if H₀ (blue) or the real effect (green)', Offset(w / 2, 10),
      size: 11, color: AppColors.muted);
  plot.curve(canvas, (x) => normalPdf(x, sim.effect, se), AppColors.green,
      fill: true, from: sim.cutoff, to: 2.5, width: 0.5);
  plot.curve(canvas, (x) => normalPdf(x, 0, se), AppColors.blue);
  plot.curve(canvas, (x) => normalPdf(x, sim.effect, se), AppColors.green);
  line(canvas, plot.at(sim.cutoff, 0), plot.at(sim.cutoff, peak * 1.1), AppColors.ink, width: 2);
  if (sim.experiments > 0) {
    canvas.drawCircle(plot.at(sim.lastMean.clamp(-1.5, 2.5), 0), 6, Paint()..color = AppColors.ink);
  }
  plot.axis(canvas, [-1, 0, 1, 2]);
  // Power curve against n.
  final pc = Plot(Rect.fromLTRB(40, h * 0.55 + 44, w - 16, h - 30), x0: 0, x1: 100, y1: 1);
  label(canvas, 'power ↑ (chance of catching the effect)', Offset(40, h * 0.55 + 32),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  pc.curve(canvas, (n) => n < 1 ? 0 : 1 - normalCdf(1.645 - sim.effect * math.sqrt(n)), AppColors.green, from: 1);
  dashedLine(canvas, pc.at(0, 0.8), pc.at(100, 0.8), AppColors.peg);
  label(canvas, '80%', Offset(34, pc.y(0.8)), size: 9, color: AppColors.muted, align: TextAlign.right);
  canvas.drawCircle(pc.at(sim.n.toDouble(), sim.power), 7, Paint()..color = AppColors.pink);
  pc.axis(canvas, [0, 25, 50, 75, 100], title: 'sample size n');
}

final LessonSpec powerLesson = LessonSpec(
  id: 'power',
  chapterLabel: 'Ch 13 · Hypothesis testing',
  title: const [
    TitlePart('Will your study '),
    TitlePart('catch', AppColors.green),
    TitlePart(' a real effect?'),
  ],
  subtitle: 'Statistical power · 3-minute animated lesson',
  createSim: () => PowerSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<PowerSim>(sim, _paintPower),
  stats: (sim) {
    final s = sim as PowerSim;
    return [
      StatChip('power', '${(s.power * 100).toStringAsFixed(0)}%', AppColors.green),
      StatChip('caught', s.experiments == 0 ? '…' : '${(s.rejectRate * 100).toStringAsFixed(0)}%', AppColors.pink),
    ];
  },
  bigIdea: 'Power is the chance a study detects an effect that really exists: 1 − β. It '
      'grows with the size of the effect and with the sample size, because more '
      'data narrows both bells so they overlap less. Studies are usually planned '
      'for 80% power. An underpowered study that finds "nothing" tells you very little.',
  formula: (sim) {
    final s = sim as PowerSim;
    return 'power = 1 − Φ(1.645 − d√n) = 1 − Φ(1.645 − ${s.effect.toStringAsFixed(1)}×√${s.n}) = ${s.power.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: sample size and effect size',
  buildTryIt: (sim) {
    final s = sim as PowerSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'n = ${s.n}',
            right: '100',
            value: s.n.toDouble(),
            min: 2,
            max: 100,
            divisions: 49,
            onChanged: (v) => s.change(() => s.n = v.round()),
          ),
          LabeledSlider(
            left: 'effect ${s.effect.toStringAsFixed(1)}',
            right: '',
            value: s.effect,
            min: 0.1,
            max: 1.5,
            divisions: 14,
            onChanged: (v) => s.change(() => s.effect = v),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Power is…',
      options: [
        'The chance of a Type I error',
        'The chance of detecting a real effect',
        'The p-value',
        'The sample size',
      ],
      answer: 1,
      explanation: 'Power = 1 − β = P(reject H₀ | H₁ true).',
    ),
    QuizQuestion(
      prompt: 'Which change increases power?',
      options: ['A smaller sample', 'A larger sample', 'A smaller effect', 'A stricter α'],
      answer: 1,
      explanation: 'More data shrinks the standard error so real effects stand out.',
    ),
    QuizQuestion(
      prompt: 'A tiny study finds "no significant effect". The best conclusion?',
      options: [
        'There is no effect',
        'The study may have been too small to tell',
        'The effect is negative',
        'H₁ is false'
      ],
      answer: 1,
      explanation: 'Low power means real effects are often missed.',
    ),
  ],
);

// ===========================================================================
// z-test
// ===========================================================================

class ZTestSim extends ExperimentSim {
  ZTestSim({super.rng});

  static const double claimed = 500, sigma = 10;
  static const int n = 25;
  double trueMean = 500;
  double z = 0;
  final List<double> recentZ = [];

  @override
  bool experiment() {
    var s = 0.0;
    for (var i = 0; i < n; i++) {
      s += trueMean + sigma * normalDraw(rng);
    }
    z = (s / n - claimed) / (sigma / math.sqrt(n));
    recentZ.add(z);
    if (recentZ.length > 25) recentZ.removeAt(0);
    return z.abs() > 1.96;
  }

  @override
  void restart() {
    super.restart();
    recentZ.clear();
  }
}

void _paintZTest(Canvas canvas, Size size, ZTestSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(16, 30, w - 16, h - 60), x0: -5, x1: 5, y1: 0.45);
  label(canvas, 'z if packets really average 500 g', Offset(w / 2, 12), size: 11, color: AppColors.muted);
  plot.curve(canvas, normalPdf, AppColors.pink, fill: true, from: -5, to: -1.96, width: 0.5);
  plot.curve(canvas, normalPdf, AppColors.pink, fill: true, from: 1.96, to: 5, width: 0.5);
  plot.curve(canvas, normalPdf, AppColors.ink);
  for (var i = 0; i < sim.recentZ.length; i++) {
    final v = sim.recentZ[i].clamp(-4.9, 4.9);
    final isNew = i == sim.recentZ.length - 1;
    canvas.drawCircle(plot.at(v, 0.02 + (i % 5) * 0.012), isNew ? 7 : 4,
        Paint()..color = isNew ? AppColors.orange : AppColors.blue.withValues(alpha: 0.5));
  }
  plot.axis(canvas, [-4, -1.96, 0, 1.96, 4]);
  if (sim.experiments > 0) {
    final rej = sim.z.abs() > 1.96;
    label(canvas, 'z = ${sim.z.toStringAsFixed(2)} → ${rej ? 'reject "500 g"' : 'claim stands'}', Offset(w / 2, h - 20),
        size: 14, color: rej ? AppColors.pink : AppColors.blue);
  }
}

final LessonSpec zTestLesson = LessonSpec(
  id: 'z_test',
  chapterLabel: 'Ch 13 · Hypothesis testing',
  title: const [
    TitlePart('Are these packets really '),
    TitlePart('500 g', AppColors.orange),
    TitlePart('?'),
  ],
  subtitle: 'The z-test · 2-minute animated lesson',
  createSim: () => ZTestSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<ZTestSim>(sim, _paintZTest),
  stats: (sim) {
    final s = sim as ZTestSim;
    return [
      StatChip('batches', '${s.experiments}', AppColors.yellow),
      StatChip('z', s.z.toStringAsFixed(2), AppColors.orange),
      StatChip('rejected', '${(s.rejectRate * 100).toStringAsFixed(0)}%', AppColors.pink),
    ];
  },
  bigIdea: 'A factory claims its packets weigh 500 g, with a known sd of 10 g. Weigh 25 '
      'packets. How many standard errors is their average from 500? That\'s z. If '
      'the claim is true, z follows the standard normal, so |z| > 1.96 happens only '
      '5% of the time: we reject the claim. Make the real average 497 g and watch '
      'z drift left.',
  formula: (sim) {
    final s = sim as ZTestSim;
    return 'z = (x̄ − 500) / (10/√25) = (x̄ − 500)/2 = ${s.z.toStringAsFixed(2)}   reject if |z| > 1.96';
  },
  tryItTitle: 'Try it: secretly change the real average',
  buildTryIt: (sim) {
    final s = sim as ZTestSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: '494 g',
            right: '506',
            value: s.trueMean,
            min: 494,
            max: 506,
            divisions: 12,
            label: '${s.trueMean.round()} g',
            onChanged: (v) => s.change(() => s.trueMean = v),
          ),
          ControlRow(children: [_rejectTag(s, 'batches'), ActionButton('Test 200 batches', () => s.runMany(200))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Claimed mean 100, σ = 15, n = 25, sample mean 106. What is z?',
      options: ['0.4', '2', '6', '1.96'],
      answer: 1,
      explanation: 'SE = 15/5 = 3, so z = 6/3 = 2.',
    ),
    QuizQuestion(
      prompt: 'At α = 0.05 (two-sided), z = 2 means you…',
      options: ['Reject H₀', 'Keep H₀', 'Need a t-test', 'Prove H₁'],
      answer: 0,
      explanation: '|2| > 1.96.',
    ),
    QuizQuestion(
      prompt: 'When is a z-test (rather than a t-test) appropriate?',
      options: [
        'When σ is known or n is large',
        'Only for small samples',
        'For counts in categories',
        'For three groups'
      ],
      answer: 0,
      explanation: 'With σ known, the standardised mean is exactly normal.',
    ),
  ],
);

// ===========================================================================
// t-tests
// ===========================================================================

class TTestSim extends ExperimentSim {
  TTestSim({super.rng});

  static const int n = 8;
  static const double sd = 4, critical = 2.145; // t(14), two-sided 5%
  double diff = 3;
  List<double> a = [], b = [];
  double t = 0;

  @override
  bool experiment() {
    a = List.generate(n, (_) => 20 + sd * normalDraw(rng));
    b = List.generate(n, (_) => 20 + diff + sd * normalDraw(rng));
    final sp = math.sqrt((math.pow(sdOf(a), 2) + math.pow(sdOf(b), 2)) / 2);
    t = (meanOf(b) - meanOf(a)) / (sp * math.sqrt(2 / n));
    return t.abs() > critical;
  }
}

void _paintTTest(Canvas canvas, Size size, TTestSim sim) {
  final w = size.width;
  final h = size.height;
  // Dot plots of the two groups.
  final dots = Plot(Rect.fromLTRB(70, 16, w - 16, h * 0.36), x0: 5, x1: 40, y1: 2);
  for (final (row, xs, name, color) in [
    (1.5, sim.a, 'Old diet', AppColors.blue),
    (0.5, sim.b, 'New diet', AppColors.green)
  ]) {
    label(canvas, name, Offset(64, dots.y(row)), size: 11, color: color, align: TextAlign.right);
    for (final x in xs) {
      canvas.drawCircle(dots.at(x.clamp(5, 40), row), 5, Paint()..color = color.withValues(alpha: 0.7));
    }
    if (xs.isNotEmpty) {
      final m = meanOf(xs);
      line(canvas, dots.at(m, row - 0.35), dots.at(m, row + 0.35), AppColors.ink, width: 3);
    }
  }
  dots.axis(canvas, [10, 20, 30, 40], title: 'weight gain (g)');
  // t distribution.
  final plot = Plot(Rect.fromLTRB(16, h * 0.36 + 40, w - 16, h - 34), x0: -6, x1: 6, y1: 0.42);
  plot.curve(canvas, (x) => tPdf(x, 14), AppColors.pink, fill: true, from: -6, to: -TTestSim.critical, width: 0.5);
  plot.curve(canvas, (x) => tPdf(x, 14), AppColors.pink, fill: true, from: TTestSim.critical, to: 6, width: 0.5);
  plot.curve(canvas, (x) => tPdf(x, 14), AppColors.ink);
  if (sim.experiments > 0) {
    final p = plot.at(sim.t.clamp(-5.9, 5.9), 0.03);
    canvas.drawCircle(p, 7, Paint()..color = AppColors.orange);
    label(canvas, 't = ${sim.t.toStringAsFixed(2)}', p.translate(0, -16), size: 12, color: AppColors.orange);
  }
  plot.axis(canvas, [-4, -2.145, 0, 2.145, 4],
      format: (v) => v.abs() == 2.145 ? (v > 0 ? '2.14' : '−2.14') : v.toStringAsFixed(0), title: 't with 14 df');
}

final LessonSpec tTestsLesson = LessonSpec(
  id: 't_tests',
  chapterLabel: 'Ch 13 · Hypothesis testing',
  title: const [
    TitlePart('Is the '),
    TitlePart('difference', AppColors.green),
    TitlePart(' between two groups real?'),
  ],
  subtitle: 't-tests · 3-minute animated lesson',
  createSim: () => TTestSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<TTestSim>(sim, _paintTTest),
  stats: (sim) {
    final s = sim as TTestSim;
    return [
      StatChip('t', s.t.toStringAsFixed(2), AppColors.orange),
      StatChip('significant', '${(s.rejectRate * 100).toStringAsFixed(0)}%', AppColors.pink),
    ];
  },
  bigIdea: 'Eight animals on each diet. Is the difference between the group averages '
      'bigger than you\'d expect from random variation? The t statistic divides the '
      'difference in means by its estimated standard error, using the spread inside '
      'the groups. With small samples that estimate is shaky, so we compare t to the '
      't distribution (heavier tails) instead of the normal: here |t| must pass 2.145.',
  formula: (sim) {
    final s = sim as TTestSim;
    return 't = (x̄_new − x̄_old) / (s_p √(2/n)) = ${s.t.toStringAsFixed(2)}   reject if |t| > 2.145 (df 14)';
  },
  tryItTitle: 'Try it: change the real difference',
  buildTryIt: (sim) {
    final s = sim as TTestSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'no effect',
            right: '+8 g',
            value: s.diff,
            min: 0,
            max: 8,
            divisions: 16,
            label: '+${s.diff.toStringAsFixed(1)} g',
            onChanged: (v) => s.change(() => s.diff = v),
          ),
          ControlRow(children: [_rejectTag(s, 'studies'), ActionButton('Run 200 studies', () => s.runMany(200))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Why use a t-test instead of a z-test for two groups of 8?',
      options: [
        'Because there are two groups',
        'The population sd is unknown and estimated from small samples',
        'Because the data is categorical',
        'z-tests need negative values',
      ],
      answer: 1,
      explanation: 'Estimating σ adds uncertainty that the t distribution accounts for.',
    ),
    QuizQuestion(
      prompt:
          'Two diets truly have the same effect. How often will a t-test at α = 0.05 call the difference significant?',
      options: ['Never', 'About 5% of the time', 'About 50%', 'Always'],
      answer: 1,
      explanation: 'That\'s the Type I error rate α = 0.05.',
    ),
    QuizQuestion(
      prompt: 'Two groups have the same difference in means, but group B data is much more spread out. t is…',
      options: ['Larger', 'Smaller', 'The same', 'Negative'],
      answer: 1,
      explanation: 'More spread means a bigger standard error in the denominator.',
    ),
  ],
);

// ===========================================================================
// Chi-square tests
// ===========================================================================

class ChiSquareSim extends ExperimentSim {
  ChiSquareSim({super.rng});

  static const int rolls = 60;
  static const double critical = 11.07; // χ²(5), 5%
  bool loaded = false;
  List<int> counts = List.filled(6, 0);
  double chi2 = 0;

  @override
  bool experiment() {
    counts = List.filled(6, 0);
    for (var i = 0; i < rolls; i++) {
      final face = loaded && rng.nextDouble() < 0.2 ? 5 : rng.nextInt(6);
      counts[face]++;
    }
    chi2 = counts.fold(0.0, (a, o) => a + (o - 10) * (o - 10) / 10);
    return chi2 > critical;
  }
}

void _paintChiSquare(Canvas canvas, Size size, ChiSquareSim sim) {
  final w = size.width;
  final h = size.height;
  final bars = Plot(Rect.fromLTRB(16, 22, w - 16, h * 0.45), x0: 0.4, x1: 6.6, y1: 22);
  label(canvas, '60 rolls · expected 10 of each face', Offset(w / 2, 8), size: 11, color: AppColors.muted);
  bars.intBars(
      canvas, [for (final c in sim.counts) c.toDouble()], 1, (k) => AppColors.rainbow[k - 1].withValues(alpha: 0.8));
  dashedLine(canvas, bars.at(0.4, 10), bars.at(6.6, 10), AppColors.ink);
  for (var f = 1; f <= 6; f++) {
    label(canvas, '${sim.counts[f - 1]}', bars.at(f.toDouble(), sim.counts[f - 1] + 1.6), size: 10);
  }
  bars.axis(canvas, [1, 2, 3, 4, 5, 6]);
  final plot = Plot(Rect.fromLTRB(16, h * 0.45 + 40, w - 16, h - 34), x0: 0, x1: 25, y1: 0.17);
  plot.curve(canvas, (x) => chi2Pdf(x, 5), AppColors.pink, fill: true, from: ChiSquareSim.critical, to: 25, width: 0.5);
  plot.curve(canvas, (x) => chi2Pdf(x, 5), AppColors.ink, from: 0.05);
  if (sim.experiments > 0) {
    final p = plot.at(sim.chi2.clamp(0, 24.8), 0.01);
    canvas.drawCircle(p, 7, Paint()..color = AppColors.orange);
    label(canvas, 'χ² = ${sim.chi2.toStringAsFixed(1)}', p.translate(0, -16), size: 12, color: AppColors.orange);
  }
  plot.axis(canvas, [0, 5, 11.07, 15, 20, 25],
      format: (v) => v == 11.07 ? '11.07' : v.toStringAsFixed(0), title: 'χ² with 5 df');
}

final LessonSpec chiSquareLesson = LessonSpec(
  id: 'chi_square',
  chapterLabel: 'Ch 13 · Hypothesis testing',
  title: const [
    TitlePart('Is this die '),
    TitlePart('loaded', AppColors.pink),
    TitlePart('?'),
  ],
  subtitle: 'Chi-square tests · 3-minute animated lesson',
  createSim: () => ChiSquareSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<ChiSquareSim>(sim, _paintChiSquare),
  stats: (sim) {
    final s = sim as ChiSquareSim;
    return [
      StatChip('χ²', s.chi2.toStringAsFixed(1), AppColors.orange),
      StatChip('rejected', '${(s.rejectRate * 100).toStringAsFixed(0)}%', AppColors.pink),
    ];
  },
  bigIdea: 'Roll a die 60 times; a fair die should give about 10 of each face. The '
      'chi-square statistic adds up (observed − expected)²/expected over the faces: '
      'one number for "how far are the counts from what we expected?". If the die '
      'is fair it follows a χ² curve with 5 degrees of freedom (six faces minus one), '
      'and values above 11.07 happen only 5% of the time.',
  formula: (sim) {
    final s = sim as ChiSquareSim;
    return 'χ² = Σ (O − E)² / E = ${s.chi2.toStringAsFixed(2)}   reject if > 11.07';
  },
  tryItTitle: 'Try it: load the die',
  buildTryIt: (sim) {
    final s = sim as ChiSquareSim;
    return watch(
      s,
      () => Column(
        children: [
          ChoiceRow<bool>(
            options: const {false: 'Fair die', true: 'Loaded towards 6'},
            selected: s.loaded,
            onSelected: (v) => s.change(() => s.loaded = v),
          ),
          ControlRow(children: [_rejectTag(s, 'tests'), ActionButton('Run 200 tests', () => s.runMany(200))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A chi-square goodness-of-fit test compares…',
      options: ['Two means', 'Observed counts with expected counts', 'Two variances', 'Correlations'],
      answer: 1,
      explanation: 'It measures how far category counts are from what H₀ predicts.',
    ),
    QuizQuestion(
      prompt: 'Testing a die with 6 faces, the degrees of freedom are…',
      options: ['6', '5', '60', '1'],
      answer: 1,
      explanation: 'Categories − 1: once five counts are known, the sixth is fixed.',
    ),
    QuizQuestion(
      prompt: 'Observed 14, expected 10 for one face. Its contribution to χ² is…',
      options: ['4', '1.6', '0.4', '16'],
      answer: 1,
      explanation: '(14 − 10)²/10 = 16/10 = 1.6.',
    ),
  ],
);

// ===========================================================================
// ANOVA
// ===========================================================================

class AnovaSim extends ExperimentSim {
  AnovaSim({super.rng});

  static const int n = 8;
  static const double sd = 5, critical = 3.47; // F(2, 21), 5%
  double separation = 3;
  List<List<double>> groups = [[], [], []];
  double f = 0;

  @override
  bool experiment() {
    groups = [
      for (var g = 0; g < 3; g++) List.generate(n, (_) => 50 + g * separation + sd * normalDraw(rng)),
    ];
    final all = groups.expand((g) => g).toList();
    final grand = meanOf(all);
    var ssb = 0.0, ssw = 0.0;
    for (final g in groups) {
      final m = meanOf(g);
      ssb += n * (m - grand) * (m - grand);
      for (final x in g) {
        ssw += (x - m) * (x - m);
      }
    }
    f = (ssb / 2) / (ssw / (3 * n - 3));
    return f > critical;
  }
}

void _paintAnova(Canvas canvas, Size size, AnovaSim sim) {
  final w = size.width;
  final h = size.height;
  const colors = [AppColors.blue, AppColors.green, AppColors.orange];
  final dots = Plot(Rect.fromLTRB(16, 20, w - 16, h * 0.48), x0: 0.4, x1: 3.6, y0: 30, y1: 80);
  if (sim.groups[0].isNotEmpty) {
    final grand = meanOf(sim.groups.expand((g) => g));
    dashedLine(canvas, dots.at(0.4, grand), dots.at(3.6, grand), AppColors.ink);
    label(canvas, 'overall mean', dots.at(3.6, grand).translate(-4, -10), size: 10, align: TextAlign.right);
    for (var g = 0; g < 3; g++) {
      for (var i = 0; i < sim.groups[g].length; i++) {
        canvas.drawCircle(dots.at(g + 1 + (i - 3.5) * 0.05, sim.groups[g][i].clamp(30, 80)), 4.5,
            Paint()..color = colors[g].withValues(alpha: 0.7));
      }
      final m = meanOf(sim.groups[g]);
      line(canvas, dots.at(g + 0.7, m), dots.at(g + 1.3, m), colors[g], width: 3.5);
    }
  }
  dots.axis(canvas, [1, 2, 3], format: (v) => 'Fertiliser ${'ABC'[v.round() - 1]}');
  final plot = Plot(Rect.fromLTRB(16, h * 0.48 + 40, w - 16, h - 34), x0: 0, x1: 10, y1: 1.05);
  plot.curve(canvas, (x) => fPdf(x, 2, 21), AppColors.pink, fill: true, from: AnovaSim.critical, to: 10, width: 0.5);
  plot.curve(canvas, (x) => fPdf(x, 2, 21), AppColors.ink, from: 0.02);
  if (sim.experiments > 0) {
    final p = plot.at(sim.f.clamp(0, 9.9), 0.05);
    canvas.drawCircle(p, 7, Paint()..color = AppColors.violet);
    label(canvas, 'F = ${sim.f.toStringAsFixed(2)}', p.translate(0, -16), size: 12, color: AppColors.violet);
  }
  plot.axis(canvas, [0, 2, 3.47, 6, 8, 10],
      format: (v) => v == 3.47 ? '3.47' : v.toStringAsFixed(0), title: 'F with (2, 21) df');
}

final LessonSpec anovaLesson = LessonSpec(
  id: 'anova',
  chapterLabel: 'Ch 13 · Hypothesis testing',
  title: const [
    TitlePart('Comparing '),
    TitlePart('three or more', AppColors.violet),
    TitlePart(' groups at once'),
  ],
  subtitle: 'ANOVA · 3-minute animated lesson',
  createSim: () => AnovaSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<AnovaSim>(sim, _paintAnova),
  stats: (sim) {
    final s = sim as AnovaSim;
    return [
      StatChip('F', s.f.toStringAsFixed(2), AppColors.violet),
      StatChip('significant', '${(s.rejectRate * 100).toStringAsFixed(0)}%', AppColors.pink),
    ];
  },
  bigIdea: 'Three fertilisers, eight plants each. Instead of three separate t-tests '
      '(which pile up false alarms), ANOVA asks one question: are the group means '
      'further apart than the scatter inside each group would explain? F is the '
      'between-group variation divided by the within-group variation. Near 1 means '
      'the groups look alike; large F means at least one group differs.',
  formula: (sim) {
    final s = sim as AnovaSim;
    return 'F = (between-group variance) / (within-group variance) = ${s.f.toStringAsFixed(2)}   reject if > 3.47';
  },
  tryItTitle: 'Try it: separate the groups',
  buildTryIt: (sim) {
    final s = sim as AnovaSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'same',
            right: 'far apart',
            value: s.separation,
            min: 0,
            max: 8,
            divisions: 16,
            label: '${s.separation.toStringAsFixed(1)} apart',
            onChanged: (v) => s.change(() => s.separation = v),
          ),
          ControlRow(children: [_rejectTag(s, 'trials'), ActionButton('Run 200 trials', () => s.runMany(200))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Why use ANOVA instead of many t-tests for 5 groups?',
      options: [
        'It\'s faster to type',
        'Many tests inflate the chance of a false alarm',
        't-tests need equal groups',
        'ANOVA needs less data',
      ],
      answer: 1,
      explanation: '10 pairwise tests at 5% each make at least one false positive likely.',
    ),
    QuizQuestion(
      prompt: 'An F statistic close to 1 suggests…',
      options: [
        'The groups differ a lot',
        'Group differences are about what noise would give',
        'An error',
        'Perfect correlation'
      ],
      answer: 1,
      explanation: 'Between- and within-group variation are similar.',
    ),
    QuizQuestion(
      prompt: 'ANOVA rejects H₀. What do you know?',
      options: ['All groups differ', 'At least one group mean differs', 'Group A is best', 'Nothing'],
      answer: 1,
      explanation: 'Follow-up tests are needed to find which groups differ.',
    ),
  ],
);

// ===== lib/lessons/ch14_regression.dart =====
// Chapter 14 · Regression.

/// Least-squares line y = a + b·x.
(double, double) fitLine(List<Offset> pts) {
  final mx = meanOf(pts.map((p) => p.dx)), my = meanOf(pts.map((p) => p.dy));
  var sxy = 0.0, sxx = 0.0;
  for (final p in pts) {
    sxy += (p.dx - mx) * (p.dy - my);
    sxx += (p.dx - mx) * (p.dx - mx);
  }
  final b = sxx == 0 ? 0.0 : sxy / sxx;
  return (my - b * mx, b);
}

double sse(List<Offset> pts, double a, double b) => pts.fold(0.0, (s, p) => s + math.pow(p.dy - (a + b * p.dx), 2));

// ===========================================================================
// Line of best fit
// ===========================================================================

class BestFitSim extends LessonSim {
  BestFitSim({math.Random? rng}) : _rng = rng ?? math.Random() {
    _make();
  }

  final math.Random _rng;
  List<Offset> points = [];
  double t = 0;
  double? manualSlope;

  void _make() {
    points = List.generate(12, (_) {
      final x = 1 + _rng.nextDouble() * 8;
      return Offset(x, 2 + 0.8 * x + normalDraw(_rng) * 1.1);
    });
  }

  (double, double) get best => fitLine(points);

  /// The candidate line always passes through (x̄, ȳ); only its slope changes.
  double get slope => manualSlope ?? best.$2 + 1.1 * math.cos(t * 0.7);

  double get intercept => meanOf(points.map((p) => p.dy)) - slope * meanOf(points.map((p) => p.dx));

  @override
  void advance(double dt) {
    if (manualSlope == null) t += dt;
    notifyListeners();
  }

  @override
  void step() {
    manualSlope = best.$2;
    notifyListeners();
  }

  @override
  void reset() {
    manualSlope = null;
    t = 0;
    _make();
    notifyListeners();
  }

  void setSlope(double s) {
    manualSlope = s;
    notifyListeners();
  }
}

void _paintBestFit(Canvas canvas, Size size, BestFitSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(30, 20, w - 14, h - 34), x0: 0, x1: 10, y0: 0, y1: 14);
  final a = sim.intercept, b = sim.slope;
  // Squared residuals as squares (side = residual, drawn in y units on both axes).
  final unit = plot.rect.height / 14;
  for (final p in sim.points) {
    final r = p.dy - (a + b * p.dx);
    final side = r.abs() * unit;
    final top = math.min(plot.y(p.dy), plot.y(a + b * p.dx));
    canvas.drawRect(
        Rect.fromLTWH(plot.x(p.dx), top, side, side), Paint()..color = AppColors.pink.withValues(alpha: 0.18));
    line(canvas, plot.at(p.dx, p.dy), plot.at(p.dx, a + b * p.dx), AppColors.pink, width: 1.5);
  }
  canvas.save();
  canvas.clipRect(plot.rect);
  line(canvas, plot.at(0, a), plot.at(10, a + b * 10), AppColors.ink, width: 3);
  canvas.restore();
  for (final p in sim.points) {
    canvas.drawCircle(plot.at(p.dx, p.dy), 5.5, Paint()..color = AppColors.blue);
  }
  plot.axis(canvas, [0, 2, 4, 6, 8, 10]);
  final e = sse(sim.points, a, b);
  final eBest = sse(sim.points, sim.best.$1, sim.best.$2);
  label(canvas, 'total squared error ${e.toStringAsFixed(1)}  (best ${eBest.toStringAsFixed(1)})', Offset(w / 2, 10),
      size: 12, color: (e - eBest) < 0.5 ? AppColors.green : AppColors.pink);
}

final LessonSpec lineOfBestFitLesson = LessonSpec(
  id: 'line_of_best_fit',
  chapterLabel: 'Ch 14 · Regression',
  title: const [
    TitlePart('The line with the '),
    TitlePart('least squares', AppColors.pink),
  ],
  subtitle: 'Line of best fit · 2-minute animated lesson',
  createSim: () => BestFitSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<BestFitSim>(sim, _paintBestFit),
  stats: (sim) {
    final s = sim as BestFitSim;
    return [
      StatChip('slope', s.slope.toStringAsFixed(2), AppColors.ink),
      StatChip('best slope', s.best.$2.toStringAsFixed(2), AppColors.green),
      StatChip('error', sse(s.points, s.intercept, s.slope).toStringAsFixed(1), AppColors.pink),
    ];
  },
  bigIdea: 'Many lines pass near the points; which is best? For each point, measure the '
      'vertical miss (the residual) and square it: the pink squares. The '
      '"least squares" line is the one whose squares add up to the smallest total. '
      'Squaring stops misses above and below from cancelling and punishes big '
      'misses most. The best line always passes through the point of averages (x̄, ȳ).',
  formula: (sim) {
    final s = sim as BestFitSim;
    final (a, b) = s.best;
    return 'best: ŷ = ${a.toStringAsFixed(2)} + ${b.toStringAsFixed(2)}x   b = Σ(x−x̄)(y−ȳ)/Σ(x−x̄)²';
  },
  tryItTitle: 'Try it: tilt the line yourself',
  buildTryIt: (sim) {
    final s = sim as BestFitSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'flat',
            right: 'steep',
            value: s.slope.clamp(-0.5, 2.5),
            min: -0.5,
            max: 2.5,
            divisions: 60,
            label: s.slope.toStringAsFixed(2),
            onChanged: s.setSlope,
          ),
          const TryNote('Find the slope where the pink squares shrink to their smallest. Step jumps straight to it.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'What does the least-squares line minimise?',
      options: [
        'The number of points off the line',
        'The sum of squared vertical distances',
        'The slope',
        'The largest distance'
      ],
      answer: 1,
      explanation: 'It minimises Σ(y − ŷ)², the sum of squared residuals.',
    ),
    QuizQuestion(
      prompt: 'The best-fit line always passes through…',
      options: ['The origin', '(x̄, ȳ)', 'The highest point', 'Every point'],
      answer: 1,
      explanation: 'The point of averages lies on the least-squares line.',
    ),
    QuizQuestion(
      prompt: 'ŷ = 10 + 2x. What is the prediction for x = 4?',
      options: ['12', '18', '24', '42'],
      answer: 1,
      explanation: '10 + 2 × 4 = 18.',
    ),
  ],
);

// ===========================================================================
// Residuals
// ===========================================================================

class ResidualSim extends TickSim {
  ResidualSim({super.rng});

  bool curved = false;
  final List<Offset> points = [];
  static const int target = 30;

  @override
  double get interval => points.length < 8 ? 0.3 : 0.1;

  @override
  void tick() {
    if (points.length >= target) return;
    final x = 0.5 + rng.nextDouble() * 9;
    final y = curved ? 1 + 0.13 * x * x + normalDraw(rng) * 0.5 : 1 + 1.0 * x + normalDraw(rng) * 0.8;
    points.add(Offset(x, y));
  }

  @override
  void restart() => points.clear();
}

void _paintResiduals(Canvas canvas, Size size, ResidualSim sim) {
  final w = size.width;
  final h = size.height;
  final top = Plot(Rect.fromLTRB(16, 16, w - 16, h * 0.52), x0: 0, x1: 10, y0: 0, y1: 13);
  final res = Plot(Rect.fromLTRB(16, h * 0.52 + 40, w - 16, h - 30), x0: 0, x1: 10, y0: -3.5, y1: 3.5);
  if (sim.points.length < 3) return;
  final (a, b) = fitLine(sim.points);
  canvas.save();
  canvas.clipRect(top.rect);
  line(canvas, top.at(0, a), top.at(10, a + 10 * b), AppColors.ink, width: 2.5);
  canvas.restore();
  label(canvas, 'residuals (data − line) ↓', Offset(16, h * 0.52 + 26),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  line(canvas, res.at(0, 0), res.at(10, 0), AppColors.ink, width: 2);
  for (final p in sim.points) {
    final r = p.dy - (a + b * p.dx);
    final color = r >= 0 ? AppColors.green : AppColors.pink;
    line(canvas, top.at(p.dx, p.dy), top.at(p.dx, a + b * p.dx), color.withValues(alpha: 0.6), width: 1.5);
    canvas.drawCircle(top.at(p.dx, p.dy.clamp(0, 13)), 4.5, Paint()..color = AppColors.blue);
    canvas.drawCircle(res.at(p.dx, r.clamp(-3.4, 3.4)), 4.5, Paint()..color = color);
  }
  top.axis(canvas, [0, 2, 4, 6, 8, 10]);
  res.axis(canvas, [0, 2, 4, 6, 8, 10], title: 'x');
}

final LessonSpec residualsLesson = LessonSpec(
  id: 'residuals',
  chapterLabel: 'Ch 14 · Regression',
  title: const [
    TitlePart('What the line '),
    TitlePart('misses', AppColors.pink),
    TitlePart(' tells you'),
  ],
  subtitle: 'Residuals · 2-minute animated lesson',
  createSim: () => ResidualSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<ResidualSim>(sim, _paintResiduals),
  stats: (sim) {
    final s = sim as ResidualSim;
    return [
      StatChip('points', '${s.points.length}', AppColors.yellow),
      StatChip('data', s.curved ? 'curved' : 'straight', AppColors.violet),
    ];
  },
  bigIdea: 'A residual is how far each point is above (+) or below (−) the line. Plot '
      'them against x. If a straight line fits, the residuals scatter randomly '
      'around zero with no pattern. If they form a U or a wave, the real '
      'relationship is curved and a straight line is the wrong model, even if r '
      'looks high.',
  formula: (sim) {
    final s = sim as ResidualSim;
    if (s.points.length < 3) return 'residual = y − ŷ';
    final (a, b) = fitLine(s.points);
    return 'residual = y − ŷ = y − (${a.toStringAsFixed(2)} + ${b.toStringAsFixed(2)}x)   Σ residuals = 0';
  },
  tryItTitle: 'Try it: straight or curved data',
  buildTryIt: (sim) {
    final s = sim as ResidualSim;
    return watch(
      s,
      () => ChoiceRow<bool>(
        options: const {false: 'Straight-line data', true: 'Curved data'},
        selected: s.curved,
        onSelected: (v) => s.change(() => s.curved = v),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A point is at y = 12 and the line predicts 9. Its residual is…',
      options: ['−3', '3', '21', '0.75'],
      answer: 1,
      explanation: 'Residual = observed − predicted = 12 − 9 = 3.',
    ),
    QuizQuestion(
      prompt: 'A residual plot shows a clear U shape. What does that suggest?',
      options: [
        'A good linear fit',
        'The relationship is curved',
        'An error in the data',
        'Strong negative correlation'
      ],
      answer: 1,
      explanation: 'A pattern in the residuals means the line missed structure.',
    ),
    QuizQuestion(
      prompt: 'For a least-squares line, the residuals always add up to…',
      options: ['1', '0', 'n', 'The slope'],
      answer: 1,
      explanation: 'Positive and negative misses balance exactly.',
    ),
  ],
);

// ===========================================================================
// R-squared
// ===========================================================================

class RSquaredSim extends TickSim {
  RSquaredSim({super.rng}) {
    _make();
  }

  double noise = 1.5;
  List<Offset> points = [];

  /// Alternates between showing distances to the mean line and to the fit.
  bool showFit = false;

  void _make() {
    points = List.generate(14, (_) {
      final x = 0.5 + rng.nextDouble() * 9;
      return Offset(x, 2 + 0.9 * x + normalDraw(rng) * noise);
    });
  }

  double get sst {
    final m = meanOf(points.map((p) => p.dy));
    return points.fold(0.0, (s, p) => s + (p.dy - m) * (p.dy - m));
  }

  double get sseFit {
    final (a, b) = fitLine(points);
    return sse(points, a, b);
  }

  double get r2 => 1 - sseFit / sst;

  @override
  double get interval => 2.2;

  @override
  void tick() => showFit = !showFit;

  @override
  void restart() {
    showFit = false;
    _make();
  }
}

void _paintR2(Canvas canvas, Size size, RSquaredSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(16, 26, w - 16, h - 96), x0: 0, x1: 10, y0: -2, y1: 15);
  final my = meanOf(sim.points.map((p) => p.dy));
  final (a, b) = fitLine(sim.points);
  dashedLine(canvas, plot.at(0, my), plot.at(10, my), AppColors.orange, width: 2);
  canvas.save();
  canvas.clipRect(plot.rect);
  line(canvas, plot.at(0, a), plot.at(10, a + 10 * b), AppColors.violet, width: 2.5);
  canvas.restore();
  for (final p in sim.points) {
    final target = sim.showFit ? a + b * p.dx : my;
    line(canvas, plot.at(p.dx, p.dy), plot.at(p.dx, target),
        (sim.showFit ? AppColors.violet : AppColors.orange).withValues(alpha: 0.7),
        width: 2);
    canvas.drawCircle(plot.at(p.dx, p.dy.clamp(-2, 15)), 5, Paint()..color = AppColors.blue);
  }
  label(canvas, sim.showFit ? 'Misses from the line (left over)' : 'Misses from the average (total)', Offset(w / 2, 10),
      size: 12, color: sim.showFit ? AppColors.violet : AppColors.orange);
  // Bars comparing the two totals.
  final barW = w - 140;
  for (final (i, name, v, color) in [
    (0, 'total SST', sim.sst, AppColors.orange),
    (1, 'left over SSE', sim.sseFit, AppColors.violet)
  ]) {
    final y = h - 76 + i * 30.0;
    label(canvas, name, Offset(110, y + 9), size: 11, align: TextAlign.right);
    roundRect(canvas, Rect.fromLTWH(118, y, barW * (v / sim.sst).clamp(0, 1), 18), color, radius: 5);
  }
  label(canvas, 'R² = 1 − SSE/SST = ${sim.r2.toStringAsFixed(2)}', Offset(w / 2, h - 12),
      size: 14, color: AppColors.pink);
}

final LessonSpec rSquaredLesson = LessonSpec(
  id: 'r_squared',
  chapterLabel: 'Ch 14 · Regression',
  title: const [
    TitlePart('How much does the line '),
    TitlePart('explain', AppColors.violet),
    TitlePart('?'),
  ],
  subtitle: 'R-squared · 2-minute animated lesson',
  createSim: () => RSquaredSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<RSquaredSim>(sim, _paintR2),
  stats: (sim) {
    final s = sim as RSquaredSim;
    return [
      StatChip('R²', s.r2.toStringAsFixed(2), AppColors.pink),
      StatChip('explained', '${(s.r2 * 100).toStringAsFixed(0)}%', AppColors.violet),
    ];
  },
  bigIdea: 'Without x, your best guess for every y is the average: the orange misses '
      'show the total variation. With the regression line, the misses shrink to '
      'the purple ones. R² is the share of the original variation the line '
      'removed. R² = 0.8 means 80% of the ups and downs in y are accounted for by '
      'x. For a single x it equals r².',
  formula: (sim) {
    final s = sim as RSquaredSim;
    return 'R² = 1 − ${s.sseFit.toStringAsFixed(1)}/${s.sst.toStringAsFixed(1)} = ${s.r2.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: add more noise',
  buildTryIt: (sim) {
    final s = sim as RSquaredSim;
    return watch(
      s,
      () => LabeledSlider(
        left: 'tidy',
        right: 'noisy',
        value: s.noise,
        min: 0.2,
        max: 4,
        divisions: 19,
        onChanged: (v) => s.change(() => s.noise = v),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'R² = 0.64 means…',
      options: [
        'The slope is 0.64',
        '64% of the variation in y is explained by the line',
        '64% of points are on the line',
        'r = 0.64',
      ],
      answer: 1,
      explanation: 'It\'s the proportion of variation removed by the model (and r = ±0.8).',
    ),
    QuizQuestion(
      prompt: 'The correlation is r = −0.9. What is R² for the simple regression?',
      options: ['−0.9', '0.81', '0.9', '−0.81'],
      answer: 1,
      explanation: 'R² = r² = 0.81; the sign disappears.',
    ),
    QuizQuestion(
      prompt: 'Does a high R² prove x causes y?',
      options: ['Yes', 'No', 'Only above 0.9', 'Only with many points'],
      answer: 1,
      explanation: 'It measures fit, not cause. A confounder can produce a high R².',
    ),
  ],
);

// ===========================================================================
// Multiple regression
// ===========================================================================

class MultiRegSim extends TickSim {
  MultiRegSim({super.rng});

  /// (size in 100 sq ft, bedrooms, price in lakh).
  final List<(double, int, double)> homes = [];
  bool useBedrooms = true;
  static const int target = 45;

  @override
  double get interval => homes.length < 10 ? 0.25 : 0.08;

  @override
  void tick() {
    if (homes.length >= target) return;
    final beds = 1 + rng.nextInt(3);
    // Bigger homes tend to have more bedrooms.
    final size = (4 + beds * 3 + normalDraw(rng) * 1.6).clamp(2.0, 18.0);
    final price = 10 + 3 * size + 12 * beds + normalDraw(rng) * 4;
    homes.add((size, beds, price));
  }

  @override
  void restart() => homes.clear();

  void setUseBedrooms(bool v) {
    useBedrooms = v;
    notifyListeners();
  }

  (double, double) get simple => fitLine([for (final h in homes) Offset(h.$1, h.$3)]);

  /// price = a + b·size + c·beds, by solving the normal equations.
  (double, double, double) get multiple {
    final n = homes.length.toDouble();
    double s(double Function((double, int, double)) f) => homes.fold(0.0, (t, h) => t + f(h));
    final sx = s((h) => h.$1), sb = s((h) => h.$2.toDouble()), sy = s((h) => h.$3);
    final sxx = s((h) => h.$1 * h.$1), sbb = s((h) => (h.$2 * h.$2).toDouble()), sxb = s((h) => h.$1 * h.$2);
    final sxy = s((h) => h.$1 * h.$3), sby = s((h) => h.$2 * h.$3);
    final m = [
      [n, sx, sb, sy],
      [sx, sxx, sxb, sxy],
      [sb, sxb, sbb, sby],
    ];
    // Gaussian elimination.
    for (var i = 0; i < 3; i++) {
      final p = m[i][i];
      if (p.abs() < 1e-9) return (0, 0, 0);
      for (var j = i; j < 4; j++) {
        m[i][j] /= p;
      }
      for (var k = 0; k < 3; k++) {
        if (k == i) continue;
        final f = m[k][i];
        for (var j = i; j < 4; j++) {
          m[k][j] -= f * m[i][j];
        }
      }
    }
    return (m[0][3], m[1][3], m[2][3]);
  }
}

void _paintMultiReg(Canvas canvas, Size size, MultiRegSim sim) {
  final w = size.width;
  final h = size.height;
  const bedColors = [AppColors.blue, AppColors.green, AppColors.orange];
  final plot = Plot(Rect.fromLTRB(34, 34, w - 14, h - 34), x0: 0, x1: 20, y0: 0, y1: 130);
  plot.axis(canvas, [0, 5, 10, 15, 20], title: 'size (100 sq ft)');
  label(canvas, 'price (lakh) ↑', Offset(34, 22), size: 10, color: AppColors.muted, align: TextAlign.left);
  for (var b = 1; b <= 3; b++) {
    label(canvas, '● $b bed', Offset(w - 14 - (3 - b) * 56, 14),
        size: 11, color: bedColors[b - 1], align: TextAlign.right);
  }
  for (final home in sim.homes) {
    canvas.drawCircle(plot.at(home.$1, home.$3.clamp(0, 130)), 5, Paint()..color = bedColors[home.$2 - 1]);
  }
  if (sim.homes.length < 8) return;
  canvas.save();
  canvas.clipRect(plot.rect);
  if (sim.useBedrooms) {
    final (a, b, c) = sim.multiple;
    for (var beds = 1; beds <= 3; beds++) {
      line(canvas, plot.at(0, a + c * beds), plot.at(20, a + b * 20 + c * beds), bedColors[beds - 1], width: 2.5);
    }
  } else {
    final (a, b) = sim.simple;
    line(canvas, plot.at(0, a), plot.at(20, a + b * 20), AppColors.ink, width: 3);
  }
  canvas.restore();
}

final LessonSpec multipleRegressionLesson = LessonSpec(
  id: 'multiple_regression',
  chapterLabel: 'Ch 14 · Regression',
  title: const [
    TitlePart('Size or '),
    TitlePart('bedrooms', AppColors.orange),
    TitlePart('? Separate their effects'),
  ],
  subtitle: 'Multiple regression · 3-minute animated lesson',
  createSim: () => MultiRegSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<MultiRegSim>(sim, _paintMultiReg),
  stats: (sim) {
    final s = sim as MultiRegSim;
    if (s.homes.length < 8) return [StatChip('homes', '${s.homes.length}', AppColors.yellow)];
    return [
      StatChip('size alone', '${s.simple.$2.toStringAsFixed(1)}/unit', AppColors.ink),
      StatChip('size | beds', '${s.multiple.$2.toStringAsFixed(1)}/unit', AppColors.green),
      StatChip('per bedroom', s.multiple.$3.toStringAsFixed(1), AppColors.orange),
    ];
  },
  bigIdea: 'Bigger homes cost more, but they also have more bedrooms, which cost more '
      'too. Fit price on size alone and the slope soaks up the bedroom effect, so it '
      'overstates what extra space is worth. Multiple regression uses both inputs '
      'at once: each coefficient is the effect of one input holding the others '
      'fixed. Here that gives three parallel lines, one per bedroom count. (True '
      'values: ₹3 lakh per 100 sq ft, ₹12 lakh per bedroom.)',
  formula: (sim) {
    final s = sim as MultiRegSim;
    if (s.homes.length < 8) return 'price = a + b·size + c·bedrooms';
    final (a, b, c) = s.multiple;
    return 'price = ${a.toStringAsFixed(1)} + ${b.toStringAsFixed(2)}·size + ${c.toStringAsFixed(1)}·bedrooms';
  },
  tryItTitle: 'Try it: include bedrooms or not',
  buildTryIt: (sim) {
    final s = sim as MultiRegSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<bool>(
            options: const {false: 'Size only', true: 'Size + bedrooms'},
            selected: s.useBedrooms,
            onSelected: s.setUseBedrooms,
          ),
          const SizedBox(height: 8),
          const TryNote('Compare the "size alone" slope with "size | beds": the first is inflated.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'In price = 10 + 3·size + 12·beds, what does 12 mean?',
      options: [
        'Price per bedroom ignoring size',
        'Extra price per bedroom for homes of the same size',
        'The average number of bedrooms',
        'The intercept',
      ],
      answer: 1,
      explanation: 'Each coefficient holds the other inputs fixed.',
    ),
    QuizQuestion(
      prompt: 'Why can the "size only" slope be misleading here?',
      options: [
        'Size is measured badly',
        'It also picks up the effect of bedrooms, which grow with size',
        'There are too many homes',
        'It isn\'t',
      ],
      answer: 1,
      explanation: 'Leaving out a related input biases the slope (omitted-variable bias).',
    ),
    QuizQuestion(
      prompt: 'A model has 3 inputs. How many slope coefficients does it estimate?',
      options: ['1', '3', '4', '9'],
      answer: 1,
      explanation: 'One slope per input (plus an intercept).',
    ),
  ],
);

// ===========================================================================
// Logistic regression
// ===========================================================================

class LogisticSim extends TickSim {
  LogisticSim({super.rng}) {
    _make();
  }

  double overlap = 1.5;
  List<Offset> data = []; // (hours, 0/1)
  double a = 0, b = 0; // P(pass) = σ(a + b·x)
  int steps = 0;

  static double sigmoid(double z) => 1 / (1 + math.exp(-z));

  void _make() {
    data = List.generate(40, (_) {
      final x = rng.nextDouble() * 10;
      final pass = rng.nextDouble() < sigmoid((x - 5) * 3 / overlap);
      return Offset(x, pass ? 1 : 0);
    });
    a = 0;
    b = 0;
    steps = 0;
  }

  /// Gradient ascent on the log-likelihood (inputs centred at 5).
  void _learn(int iterations) {
    for (var it = 0; it < iterations; it++) {
      var ga = 0.0, gb = 0.0;
      for (final d in data) {
        final err = d.dy - sigmoid(a + b * (d.dx - 5));
        ga += err;
        gb += err * (d.dx - 5);
      }
      a += 0.02 * ga / data.length * 10;
      b += 0.02 * gb / data.length * 10;
    }
    steps += iterations;
  }

  double prob(double x) => sigmoid(a + b * (x - 5));

  @override
  double get interval => 0.05;

  @override
  void tick() {
    if (steps < 4000) _learn(steps < 200 ? 4 : 40);
  }

  @override
  void restart() => _make();
}

void _paintLogistic(Canvas canvas, Size size, LogisticSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(30, 30, w - 14, h - 34), x0: 0, x1: 10, y0: -0.12, y1: 1.12);
  plot.axis(canvas, [0, 2, 4, 6, 8, 10], title: 'hours studied');
  for (final p in [0.0, 0.5, 1.0]) {
    dashedLine(canvas, plot.at(0, p), plot.at(10, p), AppColors.peg.withValues(alpha: 0.6), width: 1);
    label(canvas, p == 0.5 ? '50%' : (p == 1 ? 'pass' : 'fail'), Offset(26, plot.y(p)),
        size: 9, color: AppColors.muted, align: TextAlign.right);
  }
  for (var i = 0; i < sim.data.length; i++) {
    final d = sim.data[i];
    final y = d.dy + (d.dy == 1 ? -1 : 1) * ((i * 7) % 5) * 0.012;
    canvas.drawCircle(
        plot.at(d.dx, y), 5, Paint()..color = (d.dy == 1 ? AppColors.green : AppColors.pink).withValues(alpha: 0.75));
  }
  plot.curve(canvas, sim.prob, AppColors.violet, width: 3);
  if (sim.b.abs() > 1e-6) {
    final x50 = (5 - sim.a / sim.b).clamp(0.0, 10.0);
    dashedLine(canvas, plot.at(x50, -0.1), plot.at(x50, 0.5), AppColors.violet);
    label(canvas, '50% at ${x50.toStringAsFixed(1)} h', plot.at(x50, 0.62), size: 11, color: AppColors.violet);
  }
  label(canvas, 'learning… step ${sim.steps}', Offset(w - 14, 14),
      size: 10, color: AppColors.muted, align: TextAlign.right);
}

final LessonSpec logisticRegressionLesson = LessonSpec(
  id: 'logistic_regression',
  chapterLabel: 'Ch 14 · Regression',
  title: const [
    TitlePart('Predicting '),
    TitlePart('yes / no', AppColors.green),
    TitlePart(' with an S-curve'),
  ],
  subtitle: 'Logistic regression · 3-minute animated lesson',
  createSim: () => LogisticSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<LogisticSim>(sim, _paintLogistic),
  stats: (sim) {
    final s = sim as LogisticSim;
    return [
      StatChip('P(pass | 3 h)', s.prob(3).toStringAsFixed(2), AppColors.pink),
      StatChip('P(pass | 7 h)', s.prob(7).toStringAsFixed(2), AppColors.green),
    ];
  },
  bigIdea: 'Pass or fail can\'t sit on a straight line: a line would predict "130% chance" '
      'for big inputs. Logistic regression feeds a line through the S-shaped sigmoid '
      'function, which squeezes any number into a probability between 0 and 1. The '
      'curve is fitted by nudging it, step by step, to make the observed passes and '
      'fails as likely as possible (maximum likelihood). Watch it learn. This is '
      'also the basic unit inside neural networks.',
  formula: (sim) {
    final s = sim as LogisticSim;
    return 'P(pass) = 1 / (1 + e^−(${s.a.toStringAsFixed(2)} + ${s.b.toStringAsFixed(2)}·(hours − 5)))';
  },
  tryItTitle: 'Try it: make the groups overlap more',
  buildTryIt: (sim) {
    final s = sim as LogisticSim;
    return watch(
      s,
      () => LabeledSlider(
        left: 'clear cut',
        right: 'mixed',
        value: s.overlap,
        min: 0.3,
        max: 4,
        divisions: 37,
        onChanged: (v) => s.change(() => s.overlap = v),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Logistic regression predicts…',
      options: ['A number like price', 'A probability between 0 and 1', 'A category count', 'A straight line'],
      answer: 1,
      explanation: 'The sigmoid output is a probability, e.g. of passing.',
    ),
    QuizQuestion(
      prompt: 'Why not use ordinary linear regression for pass/fail?',
      options: [
        'It is too slow',
        'It can predict values below 0 or above 1',
        'It needs more data',
        'It only works for negative slopes',
      ],
      answer: 1,
      explanation: 'A straight line runs off past 0 and 1; the S-curve can\'t.',
    ),
    QuizQuestion(
      prompt: 'Where the curve crosses 50%, the model is…',
      options: ['Certain of a pass', 'Equally unsure either way', 'Certain of a fail', 'Broken'],
      answer: 1,
      explanation: 'That input is the decision boundary between predicting pass and fail.',
    ),
  ],
);

// ===== lib/lessons/ch15_bayesian.dart =====
// Chapter 15 · Bayesian thinking.

/// Quantile of Beta(a, b) by numerical integration on a fine grid.
double betaQuantile(double a, double b, double q) {
  const steps = 2000;
  var total = 0.0;
  final cdf = List<double>.filled(steps + 1, 0);
  for (var i = 1; i <= steps; i++) {
    final x = (i - 0.5) / steps;
    total += betaPdf(x, a, b) / steps;
    cdf[i] = total;
  }
  for (var i = 1; i <= steps; i++) {
    if (cdf[i] / total >= q) return i / steps;
  }
  return 1;
}

// ===========================================================================
// Prior to posterior
// ===========================================================================

enum Prior { flat, sceptical, optimistic }

const Map<Prior, (double, double)> kPriorParams = {
  Prior.flat: (1, 1),
  Prior.sceptical: (20, 20),
  Prior.optimistic: (8, 2),
};

const Map<Prior, String> kPriorNames = {
  Prior.flat: 'No idea (flat)',
  Prior.sceptical: 'Sure it\'s fair',
  Prior.optimistic: 'Expect heads',
};

class PosteriorSim extends TickSim {
  PosteriorSim({super.rng});

  static const double hidden = 0.7;
  Prior prior = Prior.flat;
  int heads = 0, tails = 0;

  double get a0 => kPriorParams[prior]!.$1;
  double get b0 => kPriorParams[prior]!.$2;
  double get a => a0 + heads;
  double get b => b0 + tails;
  double get postMean => a / (a + b);

  @override
  double get interval => heads + tails < 10 ? 0.7 : 0.2;

  @override
  void tick() {
    if (heads + tails >= 100) return;
    if (rng.nextDouble() < hidden) {
      heads++;
    } else {
      tails++;
    }
  }

  @override
  void restart() => heads = tails = 0;
}

void _paintPosterior(Canvas canvas, Size size, PosteriorSim sim) {
  final w = size.width;
  final h = size.height;
  var peak = 0.0;
  for (var i = 1; i < 200; i++) {
    final x = i / 200;
    peak = math.max(peak, math.max(betaPdf(x, sim.a, sim.b), betaPdf(x, sim.a0, sim.b0)));
  }
  final plot = Plot(Rect.fromLTRB(16, 34, w - 16, h - 34), x0: 0, x1: 1, y1: peak * 1.15);
  label(canvas, '${sim.heads} heads, ${sim.tails} tails so far', Offset(w / 2, 12), size: 13);
  plot.curve(canvas, (x) => betaPdf(x, sim.a0, sim.b0), AppColors.peg, width: 2.5);
  plot.curve(canvas, (x) => betaPdf(x, sim.a, sim.b), AppColors.violet, fill: true, width: 3);
  dashedLine(canvas, plot.at(sim.postMean, 0), plot.at(sim.postMean, peak), AppColors.violet);
  label(canvas, 'grey: prior · purple: posterior', Offset(w - 16, 30),
      size: 10, color: AppColors.muted, align: TextAlign.right);
  plot.axis(canvas, [0, 0.25, 0.5, 0.75, 1], title: 'chance of heads p');
}

final LessonSpec priorPosteriorLesson = LessonSpec(
  id: 'prior_posterior',
  chapterLabel: 'Ch 15 · Bayesian thinking',
  title: const [
    TitlePart('Start with a '),
    TitlePart('belief', AppColors.peg),
    TitlePart(', let data '),
    TitlePart('reshape', AppColors.violet),
    TitlePart(' it'),
  ],
  subtitle: 'Prior to posterior · 3-minute animated lesson',
  createSim: () => PosteriorSim(),
  visualAspectRatio: 1.1,
  buildVisual: (sim) => simCanvas<PosteriorSim>(sim, _paintPosterior),
  stats: (sim) {
    final s = sim as PosteriorSim;
    return [
      StatChip('flips', '${s.heads + s.tails}', AppColors.yellow),
      StatChip('best guess', s.postMean.toStringAsFixed(2), AppColors.violet),
      StatChip('real p', s.heads + s.tails >= 100 ? '0.70' : '?', AppColors.pink),
    ];
  },
  bigIdea: 'Bayesian statistics treats an unknown, like a coin\'s chance of heads, as '
      'something you hold beliefs about. The prior is your belief before data: '
      'flat if you have no idea, peaked at 0.5 if you\'re sure the coin is fair. '
      'Each flip updates it into the posterior. With little data the prior matters '
      'a lot; with lots of data, everyone\'s posterior ends up in the same place.',
  formula: (sim) {
    final s = sim as PosteriorSim;
    return 'Beta(${s.a0.round()}, ${s.b0.round()}) prior + ${s.heads}H, ${s.tails}T → Beta(${s.a.round()}, ${s.b.round()}) '
        'posterior, mean ${s.postMean.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: start from a different belief',
  buildTryIt: (sim) {
    final s = sim as PosteriorSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<Prior>(options: kPriorNames, selected: s.prior, onSelected: (v) => s.change(() => s.prior = v)),
          const SizedBox(height: 8),
          const TryNote('The sceptic needs many more flips before their belief moves to 0.7.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'In Bayesian statistics, the prior is…',
      options: ['The data', 'Your belief before seeing the data', 'The final answer', 'The p-value'],
      answer: 1,
      explanation: 'The posterior is the prior updated by the data.',
    ),
    QuizQuestion(
      prompt: 'Two people with different priors see a huge amount of the same data. Their posteriors…',
      options: ['Stay far apart', 'Become very similar', 'Swap', 'Become flat'],
      answer: 1,
      explanation: 'Enough data overwhelms the prior.',
    ),
    QuizQuestion(
      prompt: 'A flat prior, then 8 heads in 10 flips. Roughly where does the posterior peak?',
      options: ['0.5', '0.8', '0.2', '1'],
      answer: 1,
      explanation: 'With a flat prior the posterior peaks at the observed rate, 8/10.',
    ),
  ],
);

// ===========================================================================
// Updating with evidence
// ===========================================================================

class UpdatingSim extends TickSim {
  UpdatingSim({super.rng}) {
    restart();
  }

  /// Bag A is 70% red, bag B 30% red. One is picked at random each round.
  static const double redA = 0.7, redB = 0.3;
  double priorA = 0.5;
  late bool isA;
  final List<bool> draws = [];
  final List<double> history = [];
  int _hold = 0;

  double get current => history.last;

  @override
  double get interval => 0.6;

  @override
  void tick() {
    if (draws.length >= 15) {
      if (++_hold > 4) restart();
      return;
    }
    final red = rng.nextDouble() < (isA ? redA : redB);
    draws.add(red);
    final p = current;
    final la = red ? redA : 1 - redA, lb = red ? redB : 1 - redB;
    history.add(p * la / (p * la + (1 - p) * lb));
  }

  @override
  void restart() {
    isA = rng.nextBool();
    draws.clear();
    history
      ..clear()
      ..add(priorA);
    _hold = 0;
  }

  void setPrior(double v) {
    priorA = v;
    reset();
  }
}

void _paintUpdating(Canvas canvas, Size size, UpdatingSim sim) {
  final w = size.width;
  final h = size.height;
  // The drawn balls.
  label(canvas, 'Balls drawn (put back each time)', Offset(16, 12),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  final d = (w - 32) / 15;
  for (var i = 0; i < sim.draws.length; i++) {
    canvas.drawCircle(
        Offset(16 + d * (i + 0.5), 34), d * 0.38, Paint()..color = sim.draws[i] ? AppColors.pink : AppColors.blue);
  }
  final plot = Plot(Rect.fromLTRB(40, 70, w - 16, h - 40), x0: 0, x1: 15, y1: 1);
  for (final p in [0.0, 0.5, 1.0]) {
    dashedLine(canvas, plot.at(0, p), plot.at(15, p), AppColors.peg.withValues(alpha: 0.6), width: 1);
    label(canvas, '${(p * 100).round()}%', Offset(34, plot.y(p)),
        size: 9, color: AppColors.muted, align: TextAlign.right);
  }
  final path = Path()..moveTo(plot.x(0), plot.y(sim.history.first));
  for (var i = 1; i < sim.history.length; i++) {
    path.lineTo(plot.x(i.toDouble()), plot.y(sim.history[i]));
  }
  canvas.drawPath(
    path,
    Paint()
      ..color = AppColors.violet
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );
  for (var i = 0; i < sim.history.length; i++) {
    canvas.drawCircle(plot.at(i.toDouble(), sim.history[i]), 3.5, Paint()..color = AppColors.violet);
  }
  label(canvas, 'P(bag A) ↑', Offset(40, 60), size: 11, color: AppColors.violet, align: TextAlign.left);
  plot.axis(canvas, [0, 5, 10, 15], title: 'draws');
  if (sim.draws.length >= 15) {
    label(canvas, 'It was bag ${sim.isA ? 'A' : 'B'}!', Offset(w / 2, h - 12),
        size: 14, color: (sim.current > 0.5) == sim.isA ? AppColors.green : AppColors.pink);
  }
}

final LessonSpec updatingEvidenceLesson = LessonSpec(
  id: 'updating_evidence',
  chapterLabel: 'Ch 15 · Bayesian thinking',
  title: const [
    TitlePart('Which bag is it? '),
    TitlePart('Update', AppColors.violet),
    TitlePart(' after every ball'),
  ],
  subtitle: 'Updating with evidence · 2-minute animated lesson',
  createSim: () => UpdatingSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<UpdatingSim>(sim, _paintUpdating),
  stats: (sim) {
    final s = sim as UpdatingSim;
    return [
      StatChip('draws', '${s.draws.length}', AppColors.yellow),
      StatChip('P(bag A)', s.current.toStringAsFixed(2), AppColors.violet),
    ];
  },
  bigIdea: 'Bag A is 70% red, bag B is 30% red, and you don\'t know which you\'re '
      'drawing from. Each red ball is a little evidence for A; each blue one for B. '
      'Bayes\' rule turns each ball into an update: yesterday\'s posterior becomes '
      'today\'s prior. No single draw settles it, but the evidence piles up and the '
      'belief heads towards 0% or 100%.',
  formula: (sim) {
    final s = sim as UpdatingSim;
    return 'P(A | red) = P(A)·0.7 / (P(A)·0.7 + P(B)·0.3)   now ${s.current.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: start with a stronger hunch',
  buildTryIt: (sim) {
    final s = sim as UpdatingSim;
    return watch(
      s,
      () => LabeledSlider(
        left: 'prior A',
        right: '',
        value: s.priorA,
        min: 0.05,
        max: 0.95,
        divisions: 18,
        label: '${(s.priorA * 100).round()}%',
        onChanged: s.setPrior,
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'You start 50-50 between bags A (70% red) and B (30% red), then draw one red. P(A) becomes…',
      options: ['0.5', '0.7', '0.3', '1'],
      answer: 1,
      explanation: '0.5×0.7 / (0.5×0.7 + 0.5×0.3) = 0.35/0.5 = 0.7.',
    ),
    QuizQuestion(
      prompt: 'In sequential Bayesian updating, the posterior after one draw becomes…',
      options: ['The likelihood', 'The prior for the next draw', 'Zero', 'Irrelevant'],
      answer: 1,
      explanation: 'Each update builds on everything learned so far.',
    ),
    QuizQuestion(
      prompt: 'One red, then one blue. With a 50-50 start, P(A) is now…',
      options: ['0.5', '0.7', '0.3', '0.21'],
      answer: 0,
      explanation: 'The two pieces of evidence are equally strong and point opposite ways.',
    ),
  ],
);

// ===========================================================================
// Bayesian vs frequentist
// ===========================================================================

class BayesFreqSim extends TickSim {
  BayesFreqSim({super.rng});

  /// True click-through rate of a new advert.
  static const double hidden = 0.15;
  int clicks = 0, views = 0;

  double get pHat => views == 0 ? 0 : clicks / views;

  /// Frequentist 95% interval (Wald), clamped to 0–1.
  (double, double) get confidence {
    if (views == 0) return (0, 1);
    final m = 1.96 * math.sqrt(pHat * (1 - pHat) / views);
    return ((pHat - m).clamp(0.0, 1.0), (pHat + m).clamp(0.0, 1.0));
  }

  /// Bayesian 95% credible interval from a flat prior.
  (double, double) get credible => (
        betaQuantile(1.0 + clicks, 1.0 + views - clicks, 0.025),
        betaQuantile(1.0 + clicks, 1.0 + views - clicks, 0.975)
      );

  @override
  double get interval => views < 10 ? 0.6 : 0.25;

  @override
  void tick() {
    if (views >= 80) return;
    views++;
    if (rng.nextDouble() < hidden) clicks++;
  }

  @override
  void restart() => clicks = views = 0;
}

void _paintBayesFreq(Canvas canvas, Size size, BayesFreqSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(16, 40, w - 16, h * 0.58), x0: 0, x1: 0.6, y1: 1);
  label(canvas, '${sim.clicks} clicks out of ${sim.views} views', Offset(w / 2, 14), size: 13);
  var peak = 0.0;
  for (var i = 1; i < 200; i++) {
    peak = math.max(peak, betaPdf(0.6 * i / 200, 1.0 + sim.clicks, 1.0 + sim.views - sim.clicks));
  }
  final post = Plot(plot.rect, x0: 0, x1: 0.6, y1: math.max(peak * 1.1, 1));
  post.curve(canvas, (x) => betaPdf(x, 1.0 + sim.clicks, 1.0 + sim.views - sim.clicks), AppColors.violet, fill: true);
  label(canvas, 'posterior belief about the rate', Offset(w - 16, 34),
      size: 10, color: AppColors.violet, align: TextAlign.right);
  plot.axis(canvas, [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6], format: (v) => '${(v * 100).round()}%');
  void interval(double y, (double, double) ci, Color color, String name) {
    final (lo, hi) = ci;
    line(canvas, Offset(plot.x(lo.clamp(0, 0.6)), y), Offset(plot.x(hi.clamp(0, 0.6)), y), color, width: 6);
    label(canvas, '$name: ${(lo * 100).toStringAsFixed(0)}–${(hi * 100).toStringAsFixed(0)}%', Offset(16, y - 14),
        size: 12, color: color, align: TextAlign.left);
  }

  interval(h * 0.58 + 52, sim.confidence, AppColors.blue, '95% confidence interval');
  interval(h * 0.58 + 100, sim.credible, AppColors.violet, '95% credible interval');
  line(canvas, Offset(plot.x(BayesFreqSim.hidden), h * 0.58 + 30), Offset(plot.x(BayesFreqSim.hidden), h - 8),
      AppColors.ink.withValues(alpha: sim.views >= 80 ? 1 : 0),
      width: 2);
}

final LessonSpec bayesVsFrequentistLesson = LessonSpec(
  id: 'bayes_vs_frequentist',
  chapterLabel: 'Ch 15 · Bayesian thinking',
  title: const [
    TitlePart('Two schools, '),
    TitlePart('two kinds', AppColors.violet),
    TitlePart(' of interval'),
  ],
  subtitle: 'Bayesian vs frequentist · 3-minute animated lesson',
  createSim: () => BayesFreqSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<BayesFreqSim>(sim, _paintBayesFreq),
  stats: (sim) {
    final s = sim as BayesFreqSim;
    return [
      StatChip('views', '${s.views}', AppColors.yellow),
      StatChip('click rate', '${(s.pHat * 100).toStringAsFixed(1)}%', AppColors.pink),
    ];
  },
  bigIdea: 'A frequentist treats the true click rate as a fixed unknown number: a 95% '
      'confidence interval comes from a method that catches it 95% of the time. A '
      'Bayesian treats the rate as uncertain and gives a full belief curve: a 95% '
      'credible interval contains the rate with 95% probability, given the data and '
      'prior. With lots of data the two intervals nearly agree; with very little '
      'data they can differ, and the simple confidence interval can even be '
      'zero-width or run past 0%.',
  formula: (sim) {
    final s = sim as BayesFreqSim;
    return 'frequentist: p̂ ± 1.96√(p̂(1−p̂)/n)   Bayesian: Beta(1 + ${s.clicks}, 1 + ${s.views - s.clicks}) posterior';
  },
  tryItTitle: 'Try it: watch from the very first views',
  buildTryIt: (sim) {
    final s = sim as BayesFreqSim;
    return ControlRow(children: [
      ActionButton('Start over', s.reset),
      ActionButton('Show 80 views', () => s.runMany(80)),
    ]);
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Which statement fits a Bayesian 95% credible interval?',
      options: [
        'The method catches the truth 95% of the time',
        'Given the data and prior, the value lies inside with 95% probability',
        'It is always narrower',
        'It ignores the data',
      ],
      answer: 1,
      explanation: 'Bayesians put probabilities directly on the unknown value.',
    ),
    QuizQuestion(
      prompt: 'What does a Bayesian analysis need that a frequentist one doesn\'t?',
      options: ['Data', 'A prior distribution', 'A sample size', 'A computer'],
      answer: 1,
      explanation: 'The prior encodes belief before the data.',
    ),
    QuizQuestion(
      prompt: 'With a very large amount of data, Bayesian and frequentist intervals usually…',
      options: ['Disagree completely', 'Become nearly the same', 'Both become empty', 'Swap'],
      answer: 1,
      explanation: 'The data dominates any reasonable prior.',
    ),
  ],
);

// ===== lib/lessons/ch16_real_world.dart =====
// Chapter 16 · Stats in the real world.

// ===========================================================================
// A/B testing
// ===========================================================================

class AbTestSim extends TickSim {
  AbTestSim({super.rng});

  static const double baseRate = 0.10;
  static const int maxVisitors = 4000;
  double lift = 0.02;
  int nA = 0, nB = 0, cA = 0, cB = 0;
  final List<double> pHistory = [];

  double get rateA => nA == 0 ? 0 : cA / nA;
  double get rateB => nB == 0 ? 0 : cB / nB;

  double get pValue {
    if (nA < 20 || nB < 20) return 1;
    final pool = (cA + cB) / (nA + nB);
    final se = math.sqrt(pool * (1 - pool) * (1 / nA + 1 / nB));
    if (se == 0) return 1;
    final z = (rateB - rateA) / se;
    return 2 * (1 - normalCdf(z.abs()));
  }

  @override
  double get interval => 0.08;

  @override
  void tick() {
    if (nA + nB >= maxVisitors) return;
    for (var i = 0; i < 10; i++) {
      nA++;
      if (rng.nextDouble() < baseRate) cA++;
      nB++;
      if (rng.nextDouble() < baseRate + lift) cB++;
    }
    pHistory.add(pValue);
  }

  @override
  void restart() {
    nA = nB = cA = cB = 0;
    pHistory.clear();
  }
}

void _paintAb(Canvas canvas, Size size, AbTestSim sim) {
  final w = size.width;
  final h = size.height;
  // Conversion rates with 95% intervals.
  final rates = Plot(Rect.fromLTRB(70, 16, w - 16, 92), x0: 0.04, x1: 0.18, y1: 2);
  for (final (row, name, n, r, color) in [
    (1.5, 'Button A', sim.nA, sim.rateA, AppColors.blue),
    (0.5, 'Button B', sim.nB, sim.rateB, AppColors.green),
  ]) {
    label(canvas, name, Offset(64, rates.y(row)), size: 12, color: color, align: TextAlign.right);
    if (n > 0) {
      final m = 1.96 * math.sqrt(r * (1 - r) / n);
      line(canvas, rates.at((r - m).clamp(0.04, 0.18), row), rates.at((r + m).clamp(0.04, 0.18), row),
          color.withValues(alpha: 0.5),
          width: 8);
      canvas.drawCircle(rates.at(r.clamp(0.04, 0.18), row), 6, Paint()..color = color);
    }
  }
  rates.axis(canvas, [0.06, 0.1, 0.14, 0.18], format: (v) => '${(v * 100).round()}%');
  // p-value over time.
  final pp = Plot(Rect.fromLTRB(40, 140, w - 16, h - 34), x0: 0, x1: AbTestSim.maxVisitors / 20, y1: 1);
  label(canvas, 'p-value as visitors arrive ↓', Offset(40, 126),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  canvas.drawRect(Rect.fromLTRB(pp.rect.left, pp.y(0.05), pp.rect.right, pp.y(0)),
      Paint()..color = AppColors.pink.withValues(alpha: 0.18));
  label(canvas, 'p < 0.05', Offset(pp.rect.right - 4, pp.y(0.025)),
      size: 10, color: AppColors.pink, align: TextAlign.right);
  if (sim.pHistory.length > 1) {
    final path = Path()..moveTo(pp.x(0), pp.y(sim.pHistory.first));
    for (var i = 1; i < sim.pHistory.length; i++) {
      path.lineTo(pp.x(i.toDouble()), pp.y(sim.pHistory[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.violet
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
  for (final t in [0.5, 1.0]) {
    label(canvas, t.toStringAsFixed(1), Offset(34, pp.y(t)), size: 9, color: AppColors.muted, align: TextAlign.right);
  }
  pp.axis(canvas, [0, 50, 100, 150, 200], format: (v) => '${(v * 20).round()}', title: 'visitors');
}

final LessonSpec abTestingLesson = LessonSpec(
  id: 'ab_testing',
  chapterLabel: 'Ch 16 · Stats in the real world',
  title: const [
    TitlePart('Which '),
    TitlePart('button', AppColors.green),
    TitlePart(' gets more clicks?'),
  ],
  subtitle: 'A/B testing · 3-minute animated lesson',
  createSim: () => AbTestSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<AbTestSim>(sim, _paintAb),
  stats: (sim) {
    final s = sim as AbTestSim;
    return [
      StatChip('visitors', '${s.nA + s.nB}', AppColors.yellow),
      StatChip(
          'A / B', '${(s.rateA * 100).toStringAsFixed(1)}% / ${(s.rateB * 100).toStringAsFixed(1)}%', AppColors.green),
      StatChip('p', s.pValue.toStringAsFixed(3), AppColors.violet),
    ];
  },
  bigIdea: 'Show half your visitors button A and half button B, at random, and compare '
      'how many click. Randomising makes it a real experiment, so a difference '
      'means cause. The hard part is noise: early on the p-value swings wildly and '
      'can dip below 0.05 by luck. Decide the sample size in advance and look once '
      'at the end; "peeking" and stopping at the first good-looking p-value gives '
      'far more false winners.',
  formula: (sim) {
    final s = sim as AbTestSim;
    return 'two-proportion z-test: z = (p̂_B − p̂_A) / √(p̄(1−p̄)(1/n_A + 1/n_B))  →  p = ${s.pValue.toStringAsFixed(4)}';
  },
  tryItTitle: 'Try it: how much better is B really?',
  buildTryIt: (sim) {
    final s = sim as AbTestSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'same',
            right: '+5 pts',
            value: s.lift,
            min: 0,
            max: 0.05,
            divisions: 10,
            label: '+${(s.lift * 100).toStringAsFixed(1)} points',
            onChanged: (v) => s.change(() => s.lift = v),
          ),
          const TryNote('Set B equal to A and rerun a few times: the purple line still sometimes dips into pink.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Why must visitors be assigned to A or B at random?',
      options: [
        'To save money',
        'So the groups differ only by the button, not by who saw it',
        'Because servers are random',
        'It doesn\'t matter',
      ],
      answer: 1,
      explanation: 'Randomisation balances everything else, so differences can be blamed on the button.',
    ),
    QuizQuestion(
      prompt: 'You check the p-value after every 100 visitors and stop as soon as p < 0.05. The risk?',
      options: [
        'Too few false positives',
        'Many more false positives than 5%',
        'No risk',
        'The test becomes biased toward A'
      ],
      answer: 1,
      explanation: 'Many looks give many chances for noise to cross the line.',
    ),
    QuizQuestion(
      prompt: 'B converts at 10.4% vs A\'s 10.0% with p = 0.6. A sensible conclusion?',
      options: ['B is better', 'No clear evidence of a difference yet', 'A is better', 'The test is broken'],
      answer: 1,
      explanation: 'The gap is well within what chance produces.',
    ),
  ],
);

// ===========================================================================
// Monte Carlo
// ===========================================================================

class MonteCarloSim extends TickSim {
  MonteCarloSim({super.rng});

  final List<Offset> darts = [];
  int total = 0, inside = 0;
  final List<double> estimates = [];

  double get estimate => total == 0 ? 0 : 4 * inside / total;

  @override
  double get interval => total < 50 ? 0.04 : 0.01;

  @override
  void tick() {
    final batch = total < 200 ? 1 : 20;
    for (var i = 0; i < batch; i++) {
      final p = Offset(rng.nextDouble(), rng.nextDouble());
      total++;
      if (p.distanceSquared <= 1) inside++;
      if (darts.length < 1500) darts.add(p);
    }
    if (estimates.length < 2000) estimates.add(estimate);
  }

  @override
  void restart() {
    darts.clear();
    total = inside = 0;
    estimates.clear();
  }
}

void _paintMonteCarlo(Canvas canvas, Size size, MonteCarloSim sim) {
  final w = size.width;
  final h = size.height;
  final side = math.min(w * 0.55, h - 60);
  final o = Offset(16, 20);
  roundRect(canvas, o & Size(side, side), Colors.white, radius: 4);
  canvas.drawArc(Rect.fromCircle(center: o.translate(0, side), radius: side), -math.pi / 2, math.pi / 2, true,
      Paint()..color = AppColors.cyan.withValues(alpha: 0.15));
  for (final p in sim.darts) {
    canvas.drawCircle(o + Offset(p.dx * side, (1 - p.dy) * side), 1.8,
        Paint()..color = p.distanceSquared <= 1 ? AppColors.pink : AppColors.blue.withValues(alpha: 0.6));
  }
  label(canvas, 'π ≈ ${sim.estimate.toStringAsFixed(4)}', Offset(o.dx + side + 12, 34),
      size: 18, color: AppColors.pink, align: TextAlign.left);
  label(canvas, '${sim.total} darts', Offset(o.dx + side + 12, 60),
      size: 12, color: AppColors.muted, align: TextAlign.left);
  label(canvas, 'error ${(sim.estimate - math.pi).abs().toStringAsFixed(4)}', Offset(o.dx + side + 12, 82),
      size: 12, color: AppColors.muted, align: TextAlign.left);
  // Estimate over time.
  final plot = Plot(Rect.fromLTRB(16, side + 40, w - 16, h - 24),
      x0: 0, x1: math.max(100, sim.estimates.length).toDouble(), y0: 2.6, y1: 3.7);
  dashedLine(canvas, plot.at(0, math.pi), plot.at(plot.x1, math.pi), AppColors.ink);
  if (sim.estimates.length > 1) {
    final path = Path()..moveTo(plot.x(0), plot.y(sim.estimates.first.clamp(2.6, 3.7)));
    for (var i = 1; i < sim.estimates.length; i++) {
      path.lineTo(plot.x(i.toDouble()), plot.y(sim.estimates[i].clamp(2.6, 3.7)));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.pink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
  label(canvas, 'estimate over time (dashed = π)', Offset(16, side + 30),
      size: 10, color: AppColors.muted, align: TextAlign.left);
}

final LessonSpec monteCarloLesson = LessonSpec(
  id: 'monte_carlo',
  chapterLabel: 'Ch 16 · Stats in the real world',
  title: const [
    TitlePart('Finding '),
    TitlePart('π', AppColors.pink),
    TitlePart(' by throwing darts'),
  ],
  subtitle: 'Monte Carlo simulation · 2-minute animated lesson',
  createSim: () => MonteCarloSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<MonteCarloSim>(sim, _paintMonteCarlo),
  stats: (sim) {
    final s = sim as MonteCarloSim;
    return [
      StatChip('darts', '${s.total}', AppColors.yellow),
      StatChip('inside', '${s.inside}', AppColors.pink),
      StatChip('π ≈', s.estimate.toStringAsFixed(3), AppColors.violet),
    ];
  },
  bigIdea: 'Throw random darts at a square holding a quarter circle. The share that '
      'lands inside matches the share of area: π/4. So 4 × (inside ÷ total) '
      'estimates π. That\'s Monte Carlo: answer a hard question by simulating many '
      'random trials. It powers weather forecasts, finance and game AI. The catch: '
      'error shrinks like 1/√n, so each extra digit costs 100× more darts.',
  formula: (sim) {
    final s = sim as MonteCarloSim;
    return 'π ≈ 4 × ${s.inside}/${s.total} = ${s.estimate.toStringAsFixed(4)}';
  },
  tryItTitle: 'Try it: throw a lot more',
  buildTryIt: (sim) {
    final s = sim as MonteCarloSim;
    return ControlRow(children: [
      ActionButton('Throw 20,000', () => s.runMany(1000)),
      ActionButton('Start over', s.reset),
    ]);
  },
  quiz: const [
    QuizQuestion(
      prompt: '7,850 of 10,000 random darts land inside the quarter circle. Estimate of π?',
      options: ['3.14', '0.785', '7.85', '31.4'],
      answer: 0,
      explanation: '4 × 0.785 = 3.14.',
    ),
    QuizQuestion(
      prompt: 'To make a Monte Carlo estimate 10 times more precise, you need about…',
      options: ['10× more trials', '100× more trials', '2× more trials', 'The same'],
      answer: 1,
      explanation: 'Error ∝ 1/√n, so 10× precision needs 10² = 100× trials.',
    ),
    QuizQuestion(
      prompt: 'Monte Carlo methods work by…',
      options: ['Exact algebra', 'Repeated random simulation', 'Asking experts', 'Sorting data'],
      answer: 1,
      explanation: 'Simulate many random outcomes and average.',
    ),
  ],
);

// ===========================================================================
// Random walks
// ===========================================================================

class RandomWalkSim extends TickSim {
  RandomWalkSim({super.rng}) {
    restart();
  }

  static const int walkers = 30, maxSteps = 200;
  bool twoD = false;
  late List<List<Offset>> paths;

  int get steps => paths.first.length - 1;

  /// Root-mean-square distance from the start (in 1D, x is just the step counter).
  double get rmsDistance => math.sqrt(meanOf(paths.map((p) => twoD ? p.last.distanceSquared : p.last.dy * p.last.dy)));

  @override
  double get interval => 0.04;

  @override
  void tick() {
    if (steps >= maxSteps) {
      restart();
      return;
    }
    for (final p in paths) {
      final last = p.last;
      if (twoD) {
        final a = rng.nextDouble() * 2 * math.pi;
        p.add(last + Offset(math.cos(a), math.sin(a)));
      } else {
        p.add(Offset(last.dx + 1, last.dy + (rng.nextBool() ? 1 : -1)));
      }
    }
  }

  @override
  void restart() => paths = List.generate(twoD ? 8 : walkers, (_) => [Offset.zero]);
}

void _paintWalk(Canvas canvas, Size size, RandomWalkSim sim) {
  final w = size.width;
  final h = size.height;
  if (sim.twoD) {
    final c = Offset(w / 2, h / 2 - 10);
    final scale = (math.min(w, h) / 2 - 20) / 30;
    ring(canvas, c, math.sqrt(sim.steps.toDouble()) * scale, AppColors.pink, width: 2);
    for (var i = 0; i < sim.paths.length; i++) {
      final path = Path()..moveTo(c.dx, c.dy);
      for (final p in sim.paths[i]) {
        path.lineTo(c.dx + p.dx * scale, c.dy + p.dy * scale);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.rainbow[i % 7].withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
    canvas.drawCircle(c, 5, Paint()..color = AppColors.ink);
    label(canvas, 'pink circle: radius √steps', Offset(w / 2, h - 12), size: 11, color: AppColors.pink);
    return;
  }
  final plot =
      Plot(Rect.fromLTRB(36, 16, w - 16, h - 34), x0: 0, x1: RandomWalkSim.maxSteps.toDouble(), y0: -40, y1: 40);
  plot.curve(canvas, (x) => math.sqrt(x), AppColors.pink, width: 2);
  plot.curve(canvas, (x) => -math.sqrt(x), AppColors.pink, width: 2);
  for (var i = 0; i < sim.paths.length; i++) {
    final path = Path()..moveTo(plot.x(0), plot.y(0));
    for (final p in sim.paths[i]) {
      path.lineTo(plot.x(p.dx), plot.y(p.dy.clamp(-40, 40)));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.violet.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }
  for (final t in [-40.0, -20.0, 20.0, 40.0]) {
    label(canvas, t.round().toString(), Offset(30, plot.y(t)), size: 9, color: AppColors.muted, align: TextAlign.right);
  }
  plot.axis(canvas, [0, 50, 100, 150, 200], title: 'steps');
  label(canvas, 'pink: ±√steps', Offset(w - 16, 22), size: 11, color: AppColors.pink, align: TextAlign.right);
}

final LessonSpec randomWalksLesson = LessonSpec(
  id: 'random_walks',
  chapterLabel: 'Ch 16 · Stats in the real world',
  title: const [
    TitlePart('Random steps drift '),
    TitlePart('√n', AppColors.pink),
    TitlePart(' away'),
  ],
  subtitle: 'Random walks · 2-minute animated lesson',
  createSim: () => RandomWalkSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<RandomWalkSim>(sim, _paintWalk),
  stats: (sim) {
    final s = sim as RandomWalkSim;
    return [
      StatChip('steps', '${s.steps}', AppColors.yellow),
      StatChip('typical distance', s.rmsDistance.toStringAsFixed(1), AppColors.violet),
      StatChip('√steps', math.sqrt(s.steps.toDouble()).toStringAsFixed(1), AppColors.pink),
    ];
  },
  bigIdea: 'Each walker takes a random step left or right, again and again. On average '
      'they go nowhere: the mean position stays 0. But they spread out, and the '
      'typical distance from the start grows like √n, not n: after 100 steps, '
      'about 10 away. Random walks describe pollen jiggling in water, stock prices, '
      'and a gambler\'s bankroll.',
  formula: (sim) {
    final s = sim as RandomWalkSim;
    return 'E[position] = 0   typical distance = √n = √${s.steps} = ${math.sqrt(s.steps.toDouble()).toStringAsFixed(1)}';
  },
  tryItTitle: 'Try it: walk in a line or on a plane',
  buildTryIt: (sim) {
    final s = sim as RandomWalkSim;
    return watch(
      s,
      () => ChoiceRow<bool>(
        options: const {false: '1D: left / right', true: '2D: any direction'},
        selected: s.twoD,
        onSelected: (v) => s.change(() => s.twoD = v),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'After 400 random ±1 steps, how far from the start is a walker typically?',
      options: ['0', 'About 20', 'About 200', '400'],
      answer: 1,
      explanation: '√400 = 20.',
    ),
    QuizQuestion(
      prompt: 'Where is a random walker\'s expected position after many steps?',
      options: ['Far right', 'At the start', 'Far left', 'Undefined'],
      answer: 1,
      explanation: 'Left and right steps balance on average, even though each walker wanders.',
    ),
    QuizQuestion(
      prompt: 'Which is often modelled as a random walk?',
      options: ['A train timetable', 'Daily changes in a stock price', 'Shoe sizes', 'Exam marks'],
      answer: 1,
      explanation: 'Each day\'s price change is roughly a random step.',
    ),
  ],
);

// ===========================================================================
// Markov chains
// ===========================================================================

class MarkovSim extends TickSim {
  MarkovSim({super.rng});

  static const names = ['Sunny', 'Cloudy', 'Rainy'];
  static const colors = [AppColors.yellow, AppColors.peg, AppColors.blue];
  double stay = 0.6;
  int state = 0;
  int days = 0;
  List<int> visits = [0, 0, 0];

  List<List<double>> get matrix => [
        [stay, (1 - stay) * 0.6, (1 - stay) * 0.4],
        [0.3, 0.4, 0.3],
        [0.2, 0.4, 0.4],
      ];

  /// Long-run shares, by repeatedly applying the matrix.
  List<double> get stationary {
    var v = [1 / 3, 1 / 3, 1 / 3];
    final m = matrix;
    for (var k = 0; k < 200; k++) {
      v = [for (var j = 0; j < 3; j++) v[0] * m[0][j] + v[1] * m[1][j] + v[2] * m[2][j]];
    }
    return v;
  }

  @override
  double get interval => days < 10 ? 0.7 : 0.08;

  @override
  void tick() {
    var r = rng.nextDouble();
    final row = matrix[state];
    var next = 0;
    while (next < 2 && r > row[next]) {
      r -= row[next];
      next++;
    }
    state = next;
    visits[state]++;
    days++;
  }

  @override
  void restart() {
    state = 0;
    days = 0;
    visits = [0, 0, 0];
  }
}

void _paintMarkov(Canvas canvas, Size size, MarkovSim sim) {
  final w = size.width;
  final h = size.height;
  final centres = [Offset(w / 2, 50), Offset(w * 0.2, h * 0.5), Offset(w * 0.8, h * 0.5)];
  final m = sim.matrix;
  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 3; j++) {
      if (i == j) continue;
      final a = centres[i], b = centres[j];
      final dir = (b - a) / (b - a).distance;
      final normal = Offset(-dir.dy, dir.dx) * 7;
      line(canvas, a + dir * 32 + normal, b - dir * 32 + normal, AppColors.ink.withValues(alpha: 0.25 + m[i][j]),
          width: 1 + m[i][j] * 5);
      label(canvas, m[i][j].toStringAsFixed(2), (a + b) / 2 + normal * 2.4, size: 10, color: AppColors.muted);
    }
  }
  for (var i = 0; i < 3; i++) {
    final c = centres[i];
    canvas.drawCircle(c, 28, Paint()..color = MarkovSim.colors[i].withValues(alpha: 0.85));
    if (i == sim.state && sim.days > 0) ring(canvas, c, 34, AppColors.pink, width: 4);
    label(canvas, MarkovSim.names[i], c, size: 11);
    label(canvas, 'stay ${m[i][i].toStringAsFixed(2)}', c.translate(0, 42), size: 10, color: AppColors.muted);
  }
  // Visit shares vs long-run shares.
  final st = sim.stationary;
  final barTop = h * 0.5 + 64;
  final barW = (w - 48) / 3;
  final total = math.max(1, sim.days);
  for (var i = 0; i < 3; i++) {
    final x = 16 + i * (barW + 8);
    final maxH = h - barTop - 30;
    roundRect(canvas, Rect.fromLTWH(x, h - 24 - maxH * sim.visits[i] / total, barW, maxH * sim.visits[i] / total),
        MarkovSim.colors[i],
        radius: 6);
    final y = h - 24 - maxH * st[i];
    line(canvas, Offset(x - 2, y), Offset(x + barW + 2, y), AppColors.pink, width: 3);
    label(
        canvas,
        '${(sim.visits[i] / total * 100).toStringAsFixed(0)}% (long run ${(st[i] * 100).toStringAsFixed(0)}%)',
        Offset(x + barW / 2, h - 12),
        size: 9);
  }
}

final LessonSpec markovChainsLesson = LessonSpec(
  id: 'markov_chains',
  chapterLabel: 'Ch 16 · Stats in the real world',
  title: const [
    TitlePart('Tomorrow depends only on '),
    TitlePart('today', AppColors.yellow),
  ],
  subtitle: 'Markov chains · 3-minute animated lesson',
  createSim: () => MarkovSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<MarkovSim>(sim, _paintMarkov),
  stats: (sim) {
    final s = sim as MarkovSim;
    return [
      StatChip('days', '${s.days}', AppColors.yellow),
      StatChip('today', MarkovSim.names[s.state], AppColors.blue),
    ];
  },
  bigIdea: 'A Markov chain hops between states with fixed chances that depend only on '
      'where it is now, not on how it got there. Tomorrow\'s weather depends on '
      'today\'s. Run it for a long time and the share of days in each state settles '
      'to a long-run (stationary) distribution, whatever day you started on: the '
      'pink lines. Google\'s original PageRank and many text generators are Markov chains.',
  formula: (sim) {
    final s = sim as MarkovSim;
    final st = s.stationary;
    return 'long run π = πP: sunny ${st[0].toStringAsFixed(2)}, cloudy ${st[1].toStringAsFixed(2)}, '
        'rainy ${st[2].toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: make sunny spells last longer',
  buildTryIt: (sim) {
    final s = sim as MarkovSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'P(sunny → sunny)',
            right: '',
            value: s.stay,
            min: 0.1,
            max: 0.9,
            divisions: 8,
            label: s.stay.toStringAsFixed(1),
            onChanged: (v) => s.change(() => s.stay = v),
          ),
          ControlRow(children: [ActionButton('Simulate 2,000 days', () => s.runMany(2000))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'The Markov property says the next state depends on…',
      options: ['The whole history', 'Only the current state', 'Nothing', 'The first state'],
      answer: 1,
      explanation: 'The past matters only through where you are now.',
    ),
    QuizQuestion(
      prompt: 'Each row of a transition matrix must add up to…',
      options: ['0', '1', 'The number of states', 'Anything'],
      answer: 1,
      explanation: 'From any state, you must go somewhere next.',
    ),
    QuizQuestion(
      prompt: 'The stationary distribution describes…',
      options: [
        'The first day',
        'The long-run share of time in each state',
        'The most likely next state',
        'The transition chances',
      ],
      answer: 1,
      explanation: 'After many steps the chain spends these fractions of time in each state.',
    ),
  ],
);

// ===========================================================================
// Probability in AI & ML
// ===========================================================================

class NextWordSim extends TickSim {
  NextWordSim({super.rng});

  static const words = ['mat', 'sofa', 'floor', 'roof', 'moon'];
  static const scores = [3.0, 2.2, 2.0, 1.0, -0.5];
  double temperature = 1;
  List<int> counts = List.filled(5, 0);
  int last = 0;

  List<double> get probs {
    final e = [for (final s in scores) math.exp(s / temperature)];
    final total = e.reduce((a, b) => a + b);
    return [for (final x in e) x / total];
  }

  int get samples => counts.fold(0, (a, b) => a + b);

  @override
  double get interval => samples < 6 ? 0.9 : 0.12;

  @override
  void tick() {
    var r = rng.nextDouble();
    final p = probs;
    var i = 0;
    while (i < 4 && r > p[i]) {
      r -= p[i];
      i++;
    }
    last = i;
    counts[i]++;
  }

  @override
  void restart() => counts = List.filled(5, 0);
}

void _paintNextWord(Canvas canvas, Size size, NextWordSim sim) {
  final w = size.width;
  final h = size.height;
  label(canvas, 'The cat sat on the …', Offset(w / 2, 20), size: 18);
  if (sim.samples > 0) {
    label(canvas, NextWordSim.words[sim.last], Offset(w / 2, 46), size: 18, color: AppColors.pink);
  }
  final p = sim.probs;
  final rowH = (h - 90) / 5;
  final barW = w - 130;
  for (var i = 0; i < 5; i++) {
    final y = 76 + i * rowH;
    label(canvas, NextWordSim.words[i], Offset(70, y + rowH * 0.35), size: 13, align: TextAlign.right);
    roundRect(canvas, Rect.fromLTWH(78, y + 4, barW * p[i], rowH * 0.4), AppColors.violet, radius: 5);
    final seen = sim.samples == 0 ? 0 : sim.counts[i] / sim.samples;
    roundRect(
        canvas, Rect.fromLTWH(78, y + rowH * 0.48, barW * seen, rowH * 0.22), AppColors.pink.withValues(alpha: 0.7),
        radius: 4);
    label(canvas, '${(p[i] * 100).toStringAsFixed(0)}%', Offset(84 + barW * p[i], y + rowH * 0.24),
        size: 11, align: TextAlign.left);
  }
  label(canvas, 'purple: model probability · pink: how often it was picked', Offset(w / 2, h - 10),
      size: 10, color: AppColors.muted);
}

final LessonSpec aiMlLesson = LessonSpec(
  id: 'ai_ml',
  chapterLabel: 'Ch 16 · Stats in the real world',
  title: const [
    TitlePart('How a chatbot '),
    TitlePart('picks', AppColors.violet),
    TitlePart(' its next word'),
  ],
  subtitle: 'Probability in AI & ML · 3-minute animated lesson',
  createSim: () => NextWordSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<NextWordSim>(sim, _paintNextWord),
  stats: (sim) {
    final s = sim as NextWordSim;
    return [
      StatChip('temperature', s.temperature.toStringAsFixed(1), AppColors.orange),
      StatChip('samples', '${s.samples}', AppColors.yellow),
    ];
  },
  bigIdea: 'A language model scores every possible next word, then turns the scores into '
      'probabilities with the softmax function, and finally samples one word at '
      'random. Temperature controls how bold it is: low temperature sharpens the '
      'odds so it almost always picks "mat"; high temperature flattens them so '
      'rarer words like "moon" appear. Almost all of modern AI, from spam filters '
      'to image generators, is probability under the hood.',
  formula: (sim) {
    final s = sim as NextWordSim;
    return 'P(word) = e^(score/T) / Σ e^(score/T),   T = ${s.temperature.toStringAsFixed(1)}';
  },
  tryItTitle: 'Try it: turn the temperature up and down',
  buildTryIt: (sim) {
    final s = sim as NextWordSim;
    return watch(
      s,
      () => LabeledSlider(
        left: 'safe',
        right: 'wild',
        value: s.temperature,
        min: 0.2,
        max: 3,
        divisions: 14,
        label: 'T = ${s.temperature.toStringAsFixed(1)}',
        onChanged: (v) => s.change(() => s.temperature = v),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'What does the softmax function do?',
      options: [
        'Sorts words alphabetically',
        'Turns scores into probabilities that add up to 1',
        'Removes rare words',
        'Counts letters',
      ],
      answer: 1,
      explanation: 'Exponentiate each score and divide by the total.',
    ),
    QuizQuestion(
      prompt: 'Lowering the temperature makes a model\'s output…',
      options: ['More random', 'More predictable', 'Longer', 'Shorter'],
      answer: 1,
      explanation: 'The top choice gets an even bigger share of probability.',
    ),
    QuizQuestion(
      prompt: 'Why can the same prompt give different answers each time?',
      options: ['A bug', 'The next word is sampled at random from probabilities', 'The internet changes', 'It can\'t'],
      answer: 1,
      explanation: 'Sampling means less likely words are sometimes chosen.',
    ),
  ],
);

// ===== lib/lessons/ch17_paradoxes.dart =====
// Chapter 17 · Paradoxes & puzzles (Monty Hall, birthday and base-rate live elsewhere).

// ===========================================================================
// Simpson's paradox
// ===========================================================================

/// The classic kidney-stone study: (successes, patients).
const Map<String, Map<String, (int, int)>> kSimpson = {
  'A': {'small': (81, 87), 'large': (192, 263)},
  'B': {'small': (234, 270), 'large': (55, 80)},
};

class SimpsonSim extends LessonSim {
  double t = 0;
  bool? manualSplit;

  /// 0 = combined view, 1 = split by stone size.
  double get split {
    if (manualSplit != null) return manualSplit! ? 1 : 0;
    final s = t % 8;
    if (s < 3) return 0;
    if (s < 4) return Curves.easeInOut.transform(s - 3);
    if (s < 7) return 1;
    return 1 - Curves.easeInOut.transform(s - 7);
  }

  static double rate(String treatment, [String? group]) {
    final g = kSimpson[treatment]!;
    if (group != null) return g[group]!.$1 / g[group]!.$2;
    final s = g.values.fold(0, (a, b) => a + b.$1), n = g.values.fold(0, (a, b) => a + b.$2);
    return s / n;
  }

  @override
  void advance(double dt) {
    if (manualSplit == null) t += dt;
    notifyListeners();
  }

  @override
  void step() {
    manualSplit = !(split > 0.5);
    notifyListeners();
  }

  @override
  void reset() {
    manualSplit = null;
    t = 0;
    notifyListeners();
  }

  void choose(bool v) {
    manualSplit = v;
    notifyListeners();
  }
}

void _paintSimpson(Canvas canvas, Size size, SimpsonSim sim) {
  final w = size.width;
  final h = size.height;
  final s = sim.split;
  final plot = Plot(Rect.fromLTRB(16, 40, w - 16, h - 60), x0: 0, x1: 1, y0: 0.5, y1: 1);
  void barAt(double x, double width, double rate, Color color, String text) {
    final r = Rect.fromLTRB(plot.x(x - width / 2), plot.y(rate), plot.x(x + width / 2), plot.y(0.5));
    roundRect(canvas, r, color, radius: 6);
    label(canvas, '${(rate * 100).toStringAsFixed(0)}%', Offset(r.center.dx, r.top - 10), size: 12);
    label(canvas, text, Offset(r.center.dx, plot.rect.bottom + 12), size: 10, color: AppColors.muted);
  }

  // Combined bars fade out while grouped bars fade in.
  if (s < 0.99) {
    final a = 1 - s;
    barAt(0.3, 0.2, SimpsonSim.rate('A'), AppColors.blue.withValues(alpha: a), s < 0.5 ? 'A overall' : '');
    barAt(0.7, 0.2, SimpsonSim.rate('B'), AppColors.orange.withValues(alpha: a), s < 0.5 ? 'B overall' : '');
  }
  if (s > 0.01) {
    for (final (gx, group) in [(0.27, 'small'), (0.73, 'large')]) {
      barAt(gx - 0.1, 0.16, SimpsonSim.rate('A', group), AppColors.blue.withValues(alpha: s), s > 0.5 ? 'A' : '');
      barAt(gx + 0.1, 0.16, SimpsonSim.rate('B', group), AppColors.orange.withValues(alpha: s), s > 0.5 ? 'B' : '');
      if (s > 0.5) label(canvas, '$group stones', Offset(plot.x(gx), plot.rect.bottom + 28), size: 12);
    }
  }
  label(canvas, s < 0.5 ? 'All patients: B looks better' : 'Split by stone size: A wins both!', Offset(w / 2, 16),
      size: 15, color: s < 0.5 ? AppColors.orange : AppColors.blue);
}

final LessonSpec simpsonsLesson = LessonSpec(
  id: 'simpsons',
  chapterLabel: 'Ch 17 · Paradoxes & puzzles',
  title: const [
    TitlePart('Better in '),
    TitlePart('every', AppColors.blue),
    TitlePart(' group, worse '),
    TitlePart('overall', AppColors.orange),
  ],
  subtitle: "Simpson's paradox · 2-minute animated lesson",
  createSim: () => SimpsonSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<SimpsonSim>(sim, _paintSimpson),
  stats: (_) => [
    StatChip('A overall', '${(SimpsonSim.rate('A') * 100).toStringAsFixed(0)}%', AppColors.blue),
    StatChip('B overall', '${(SimpsonSim.rate('B') * 100).toStringAsFixed(0)}%', AppColors.orange),
  ],
  bigIdea: 'In a real kidney-stone study, treatment A beat B for small stones (93% vs 87%) '
      'and for large stones (73% vs 69%), yet B looked better overall (83% vs 78%). '
      'How? Doctors gave A mostly to the hard, large-stone cases and B mostly to easy '
      'small ones. Mixing groups of different difficulty in different proportions '
      'can flip a comparison. Always ask what was lumped together.',
  formula: (_) => 'A: 81/87 small, 192/263 large → 273/350 = 78%\nB: 234/270 small, 55/80 large → 289/350 = 83%',
  tryItTitle: 'Try it: combine or split',
  buildTryIt: (sim) {
    final s = sim as SimpsonSim;
    return watch(
      s,
      () => ChoiceRow<bool>(
        options: const {false: 'All patients', true: 'By stone size'},
        selected: s.split > 0.5,
        onSelected: s.choose,
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'What causes Simpson\'s paradox?',
      options: [
        'Rounding errors',
        'A lurking variable that is unevenly spread between groups',
        'Too little data',
        'Using percentages',
      ],
      answer: 1,
      explanation: 'Here stone size affects both the treatment choice and the outcome.',
    ),
    QuizQuestion(
      prompt: 'In the stone study, which treatment should a new patient with a small stone get?',
      options: ['A', 'B', 'Either', 'Neither'],
      answer: 0,
      explanation: 'Compare like with like: for small stones, A succeeds more often.',
    ),
    QuizQuestion(
      prompt: 'A school\'s overall pass rate fell, yet every class\'s pass rate rose. Is that possible?',
      options: ['No', 'Yes, if more students moved into harder classes', 'Only with a mistake', 'Only with one class'],
      answer: 1,
      explanation: 'A shift in the mix of groups can drag the overall rate down.',
    ),
  ],
);

// ===========================================================================
// Gambler's fallacy
// ===========================================================================

class GamblerSim extends TickSim {
  GamblerSim({super.rng});

  int streakLength = 4;
  final List<bool> spins = []; // true = red
  int streak = 0;
  bool? streakColour;
  int afterStreak = 0, continued = 0;

  @override
  double get interval => spins.length < 20 ? 0.4 : 0.01;

  @override
  void tick() {
    final red = rng.nextBool();
    if (streak >= streakLength) {
      afterStreak++;
      if (red == streakColour) continued++;
    }
    if (red == streakColour) {
      streak++;
    } else {
      streak = 1;
      streakColour = red;
    }
    spins.add(red);
    if (spins.length > 5000) spins.removeAt(0);
  }

  @override
  void restart() {
    spins.clear();
    streak = 0;
    streakColour = null;
    afterStreak = continued = 0;
  }
}

void _paintGambler(Canvas canvas, Size size, GamblerSim sim) {
  final w = size.width;
  final h = size.height;
  label(canvas, 'Latest spins', Offset(16, 12), size: 11, color: AppColors.muted, align: TextAlign.left);
  final recent = sim.spins.length > 40 ? sim.spins.sublist(sim.spins.length - 40) : sim.spins;
  final d = (w - 32) / 20;
  for (var i = 0; i < recent.length; i++) {
    final c = Offset(16 + d * (i % 20 + 0.5), 32 + (i ~/ 20) * d);
    final inStreak = i >= recent.length - sim.streak;
    canvas.drawCircle(c, d * 0.4, Paint()..color = recent[i] ? AppColors.pink : AppColors.ink);
    if (inStreak && sim.streak >= sim.streakLength) ring(canvas, c, d * 0.48, AppColors.yellow, width: 2.5);
  }
  final y = 32 + 2 * d + 20;
  label(canvas, 'After ${sim.streakLength}+ in a row of the same colour, the next spin…', Offset(16, y),
      size: 12, align: TextAlign.left);
  final share = sim.afterStreak == 0 ? 0.5 : sim.continued / sim.afterStreak;
  final barW = w - 32;
  roundRect(canvas, Rect.fromLTWH(16, y + 18, barW, 30), AppColors.chip, radius: 8);
  roundRect(canvas, Rect.fromLTWH(16, y + 18, barW * share, 30), AppColors.violet, radius: 8);
  line(canvas, Offset(16 + barW / 2, y + 12), Offset(16 + barW / 2, y + 54), AppColors.ink, width: 2);
  label(canvas, 'kept the streak going: ${(share * 100).toStringAsFixed(1)}%', Offset(16, y + 84),
      size: 12, color: AppColors.violet, align: TextAlign.left);
  label(canvas, '50%', Offset(16 + barW / 2, y + 64), size: 11);
  label(canvas, '${sim.afterStreak} streaks seen in ${sim.spins.length} spins', Offset(w / 2, h - 12),
      size: 11, color: AppColors.muted);
}

final LessonSpec gamblersFallacyLesson = LessonSpec(
  id: 'gamblers_fallacy',
  chapterLabel: 'Ch 17 · Paradoxes & puzzles',
  title: const [
    TitlePart('Black is '),
    TitlePart('not', AppColors.pink),
    TitlePart(' "due"'),
  ],
  subtitle: "The gambler's fallacy · 2-minute animated lesson",
  createSim: () => GamblerSim(),
  visualAspectRatio: 1.15,
  buildVisual: (sim) => simCanvas<GamblerSim>(sim, _paintGambler),
  stats: (sim) {
    final s = sim as GamblerSim;
    return [
      StatChip('spins', '${s.spins.length}', AppColors.yellow),
      StatChip('streak now', '${s.streak}', AppColors.pink),
    ];
  },
  bigIdea: 'In 1913 at Monte Carlo, black came up 26 times in a row and gamblers lost '
      'fortunes betting red was "due". A wheel has no memory: after any streak the '
      'next spin is still 50-50, and the bar sits on 50% however long the streak. '
      'Long-run averages even out because new spins dilute old ones, not because '
      'the wheel corrects itself.',
  formula: (sim) {
    final s = sim as GamblerSim;
    return 'P(red | ${s.streakLength} reds in a row) = P(red) = 1/2   (ignoring the green zero)';
  },
  tryItTitle: 'Try it: demand a longer streak',
  buildTryIt: (sim) {
    final s = sim as GamblerSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'streak ${s.streakLength}',
            right: '8',
            value: s.streakLength.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            onChanged: (v) => s.change(() => s.streakLength = v.round()),
          ),
          ControlRow(children: [ActionButton('Spin 20,000 times', () => s.runMany(20000))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A fair coin lands heads 6 times in a row. P(heads next)?',
      options: ['Less than 1/2', '1/2', 'More than 1/2', '1/64'],
      answer: 1,
      explanation: 'Each flip is independent of the ones before.',
    ),
    QuizQuestion(
      prompt: 'Why is a run of 6 heads in a row less surprising than it feels?',
      options: [
        'Coins are biased',
        'In many flips, some long runs are almost certain to appear somewhere',
        'It isn\'t possible',
        'Heads is more common',
      ],
      answer: 1,
      explanation: 'Over hundreds of flips, a run of 6 is expected to happen.',
    ),
    QuizQuestion(
      prompt: 'Which belief is the gambler\'s fallacy?',
      options: [
        '"Over many spins, about half will be red"',
        '"After five blacks, red is more likely next"',
        '"Each spin is independent"',
        '"The casino has an edge"',
      ],
      answer: 1,
      explanation: 'It assumes the wheel balances things out in the short run.',
    ),
  ],
);

// ===========================================================================
// St. Petersburg paradox
// ===========================================================================

class StPetersburgSim extends TickSim {
  StPetersburgSim({super.rng});

  int games = 0;
  double total = 0;
  int lastFlips = 1;
  List<int> byFlips = List.filled(41, 0);
  final List<double> averages = [];

  double get average => games == 0 ? 0 : total / games;

  @override
  double get interval => games < 8 ? 0.7 : 0.01;

  @override
  void tick() {
    // Flip until tails; the pot starts at ₹2 and doubles with each head.
    var flips = 1;
    while (rng.nextBool() && flips < 40) {
      flips++;
    }
    lastFlips = flips;
    total += math.pow(2, flips).toDouble();
    games++;
    byFlips[flips]++;
    if (averages.length < 4000) averages.add(average);
  }

  @override
  void restart() {
    games = 0;
    total = 0;
    byFlips = List.filled(41, 0);
    averages.clear();
  }
}

void _paintStPete(Canvas canvas, Size size, StPetersburgSim sim) {
  final w = size.width;
  final h = size.height;
  if (sim.games > 0) {
    label(
        canvas,
        'Last game: ${sim.lastFlips} flip${sim.lastFlips == 1 ? '' : 's'} → won ₹${math.pow(2, sim.lastFlips).round()}',
        Offset(w / 2, 14),
        size: 13);
  }
  // Payout table: chance × prize = ₹1 each row.
  final rows = Plot(Rect.fromLTRB(16, 36, w - 16, h * 0.45), x0: 0.4, x1: 10.6, y1: 0.55);
  rows.intBars(canvas, [for (var k = 1; k <= 10; k++) sim.games == 0 ? 0.0 : sim.byFlips[k] / sim.games], 1,
      (k) => AppColors.yellow.withValues(alpha: 0.8));
  rows.intDots(canvas, [for (var k = 1; k <= 10; k++) math.pow(0.5, k).toDouble()], 1, AppColors.ink);
  rows.axis(canvas, [for (var k = 1; k <= 10; k++) k.toDouble()],
      format: (v) => '₹${math.pow(2, v).round()}', title: 'prize');
  // Running average payout.
  final n = math.max(100, sim.averages.length).toDouble();
  final hi = math.max(20.0, (sim.averages.isEmpty ? 0 : sim.averages.reduce(math.max)) * 1.1);
  final plot = Plot(Rect.fromLTRB(40, h * 0.45 + 48, w - 16, h - 28), x0: 0, x1: n, y1: hi);
  label(canvas, 'average winnings per game ↑', Offset(40, h * 0.45 + 34),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  if (sim.averages.length > 1) {
    final path = Path()..moveTo(plot.x(0), plot.y(sim.averages.first.clamp(0, hi)));
    for (var i = 1; i < sim.averages.length; i++) {
      path.lineTo(plot.x(i.toDouble()), plot.y(sim.averages[i].clamp(0, hi)));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
  label(canvas, '₹${hi.round()}', Offset(34, plot.y(hi)), size: 9, color: AppColors.muted, align: TextAlign.right);
  plot.axis(canvas, [0, n / 2, n], format: (v) => '${v.round()}', title: 'games');
}

final LessonSpec stPetersburgLesson = LessonSpec(
  id: 'st_petersburg',
  chapterLabel: 'Ch 17 · Paradoxes & puzzles',
  title: const [
    TitlePart('A game worth '),
    TitlePart('infinity', AppColors.orange),
    TitlePart('… that nobody would pay ₹100 for'),
  ],
  subtitle: 'The St. Petersburg paradox · 3-minute animated lesson',
  createSim: () => StPetersburgSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<StPetersburgSim>(sim, _paintStPete),
  stats: (sim) {
    final s = sim as StPetersburgSim;
    return [
      StatChip('games', '${s.games}', AppColors.yellow),
      StatChip('average win', '₹${s.average.toStringAsFixed(1)}', AppColors.orange),
    ];
  },
  bigIdea: 'Flip a coin until it lands tails. The prize starts at ₹2 and doubles with every '
      'head. Each row of the table is worth chance × prize = ½ × 2 = ¼ × 4 = … = ₹1, '
      'and there are endless rows, so the expected value is infinite. Yet you\'d '
      'rarely pay even ₹20 to play: the huge prizes are so rare that the average '
      'creeps up only slowly (roughly with log₂ of the number of games). Expected '
      'value alone isn\'t everything; risk and a real banker\'s limited money matter.',
  formula: (_) => 'E[prize] = ½·2 + ¼·4 + ⅛·8 + … = 1 + 1 + 1 + … = ∞',
  tryItTitle: 'Try it: play a lot of games',
  buildTryIt: (sim) {
    final s = sim as StPetersburgSim;
    return ControlRow(children: [
      ActionButton('Play 4,000 games', () => s.runMany(4000)),
      ActionButton('Start over', s.reset),
    ]);
  },
  quiz: const [
    QuizQuestion(
      prompt: 'What is the chance the game ends on the 3rd flip (H, H, T)?',
      options: ['1/3', '1/8', '1/4', '1/2'],
      answer: 1,
      explanation: '½ × ½ × ½ = 1/8, and the prize is ₹8.',
    ),
    QuizQuestion(
      prompt: 'Why is the expected value infinite?',
      options: [
        'The prizes are large',
        'Every outcome contributes ₹1 to the sum, and there are infinitely many outcomes',
        'The coin is biased',
        'It isn\'t',
      ],
      answer: 1,
      explanation: '(½)ᵏ × 2ᵏ = 1 for every k.',
    ),
    QuizQuestion(
      prompt: 'Why won\'t people pay a huge amount to play?',
      options: [
        'They can\'t count',
        'Huge prizes are extremely rare and no bank can pay out infinitely',
        'The game is illegal',
        'The expected value is negative',
      ],
      answer: 1,
      explanation: 'Real-world limits and risk aversion matter more than an infinite average.',
    ),
  ],
);

// ===== lib/lessons/clt_dice.dart =====
/// Standard deviation of one fair die: √(35/12).
final double kDieSigma = math.sqrt(35 / 12);

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

class CltSim extends LessonSim {
  CltSim({this.dice = 1, math.Random? rng}) : _rng = rng ?? math.Random() {
    _resetCounts();
    _roll();
  }

  /// Dice averaged per sample (n).
  int dice;

  final math.Random _rng;

  /// counts[k] = samples whose dice total was dice + k (k = 0 … 5·dice).
  late List<int> counts;
  int samples = 0;
  double _sumOfMeans = 0;

  /// Faces of the sample currently on show.
  List<int> faces = [];

  /// 0 → 1 tumble of the dice on show.
  double t = 0;

  double get _rate => samples < 10 ? 2.5 : (samples < 60 ? 10 : 45);

  double get observedMean => samples == 0 ? 0 : _sumOfMeans / samples;

  double get expectedSd => kDieSigma / math.sqrt(dice);

  double get observedSd {
    if (samples < 2) return 0;
    final mu = observedMean;
    var ss = 0.0;
    for (var k = 0; k < counts.length; k++) {
      final mean = (dice + k) / dice;
      ss += counts[k] * (mean - mu) * (mean - mu);
    }
    return math.sqrt(ss / (samples - 1));
  }

  void _resetCounts() => counts = List<int>.filled(5 * dice + 1, 0);

  void _roll() => faces = List<int>.generate(dice, (_) => 1 + _rng.nextInt(6));

  void _land() {
    final total = faces.fold(0, (a, b) => a + b);
    counts[total - dice]++;
    samples++;
    _sumOfMeans += total / dice;
    _roll();
  }

  @override
  void advance(double dt) {
    t += dt * _rate;
    while (t >= 1) {
      t -= 1;
      _land();
    }
    notifyListeners();
  }

  void rollMany(int count) {
    for (var i = 0; i < count; i++) {
      _land();
    }
    notifyListeners();
  }

  @override
  void step() {
    t = 0;
    _land();
    notifyListeners();
  }

  @override
  void reset() {
    samples = 0;
    _sumOfMeans = 0;
    t = 0;
    _resetCounts();
    _roll();
    notifyListeners();
  }

  void setDice(int n) {
    dice = n;
    reset();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class CltPainter extends CustomPainter {
  CltPainter(this.sim) : super(repaint: sim);

  final CltSim sim;

  static const double aspectRatio = 0.85;

  static const _pips = <int, List<Offset>>{
    1: [Offset(0, 0)],
    2: [Offset(-1, -1), Offset(1, 1)],
    3: [Offset(-1, -1), Offset(0, 0), Offset(1, 1)],
    4: [Offset(-1, -1), Offset(1, -1), Offset(-1, 1), Offset(1, 1)],
    5: [Offset(-1, -1), Offset(1, -1), Offset(0, 0), Offset(-1, 1), Offset(1, 1)],
    6: [Offset(-1, -1), Offset(1, -1), Offset(-1, 0), Offset(1, 0), Offset(-1, 1), Offset(1, 1)],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final n = sim.dice;

    // --- Dice on show ------------------------------------------------------
    final dieS = math.min(w * 0.13, (w - 24) / (n * 1.25));
    final rowW = n * dieS * 1.25 - dieS * 0.25;
    final topY = h * 0.05;
    final tumble = math.sin(sim.t * math.pi);
    for (var i = 0; i < n; i++) {
      final cx = (w - rowW) / 2 + i * dieS * 1.25 + dieS / 2;
      final cy = topY + dieS / 2 + tumble * dieS * 0.12;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate((sim.t - 0.5) * 0.5 * (i.isEven ? 1 : -1));
      final rect = Rect.fromCenter(center: Offset.zero, width: dieS, height: dieS);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(dieS * 0.2)),
        Paint()..color = AppColors.rainbow[i % AppColors.rainbow.length],
      );
      final face = sim.faces[i];
      for (final p in _pips[face]!) {
        canvas.drawCircle(p * (dieS * 0.25), dieS * 0.085, Paint()..color = AppColors.ink);
      }
      canvas.restore();
    }
    final mean = sim.faces.fold(0, (a, b) => a + b) / n;
    _text(canvas, n == 1 ? 'roll = ${mean.toStringAsFixed(0)}' : 'average = ${mean.toStringAsFixed(2)}',
        Offset(w / 2, topY + dieS + 18), 14, AppColors.ink);

    // --- Histogram of sample means -----------------------------------------
    const left = 14.0;
    final right = w - 14;
    final top = topY + dieS + 44;
    final bottom = h - 26;
    final chartH = bottom - top;
    final slots = sim.counts.length; // 5n + 1 possible averages
    final slotW = (right - left) / slots;
    double xForMean(double m) => left + ((m - 1) / 5) * (right - left - slotW) + slotW / 2;

    final sd = sim.expectedSd;
    // Expected count in one slot ≈ samples × density × slot width (1/n).
    double expected(double m) =>
        sim.samples * math.exp(-math.pow(m - 3.5, 2) / (2 * sd * sd)) / (sd * math.sqrt(2 * math.pi)) / n;
    final peak = n == 1 ? sim.samples / 6 : expected(3.5);
    final maxCount = sim.counts.fold(0, math.max).toDouble();
    final scaleMax = math.max(8.0, math.max(maxCount, peak) * 1.1);

    final barW = math.max(1.5, slotW * 0.8);
    for (var k = 0; k < slots; k++) {
      final c = sim.counts[k];
      if (c == 0) continue;
      final m = (n + k) / n;
      final bh = c / scaleMax * chartH;
      final x = xForMean(m);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x - barW / 2, bottom - bh, barW, bh),
          topLeft: Radius.circular(barW * 0.3),
          topRight: Radius.circular(barW * 0.3),
        ),
        Paint()..color = AppColors.rainbow[((m - 1) / 5 * 6.99).floor()],
      );
    }

    // Normal curve predicted by the CLT (skip n = 1, where the truth is flat).
    if (n > 1 && sim.samples >= 30) {
      final path = Path();
      for (var i = 0; i <= 200; i++) {
        final m = 1 + 5 * i / 200;
        final y = bottom - expected(m) / scaleMax * chartH;
        i == 0 ? path.moveTo(xForMean(m), y) : path.lineTo(xForMean(m), y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    canvas.drawLine(
      Offset(left, bottom),
      Offset(right, bottom),
      Paint()
        ..color = AppColors.peg
        ..strokeWidth = 1.5,
    );
    for (var v = 1; v <= 6; v++) {
      _text(canvas, '$v', Offset(xForMean(v.toDouble()), h - 13), 11, AppColors.muted);
    }
  }

  void _text(Canvas canvas, String text, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CltPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec cltLesson = LessonSpec(
  id: 'clt_dice',
  chapterLabel: 'Ch 10 · The big theorems',
  title: const [
    TitlePart('Average '),
    TitlePart('flat', AppColors.green),
    TitlePart(' dice, get a '),
    TitlePart('bell', AppColors.violet),
  ],
  subtitle: 'The Central Limit Theorem · 3-minute animated lesson',
  createSim: () => CltSim(dice: 1),
  visualAspectRatio: CltPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: CltPainter(sim as CltSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final c = sim as CltSim;
    return [
      StatChip('samples', '${c.samples}', AppColors.yellow),
      StatChip('mean', c.observedMean.toStringAsFixed(2), AppColors.cyan),
      StatChip('spread (sd)', c.observedSd.toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'One die is flat: every face is equally likely. But average a few '
      'dice and extreme results need every die to be extreme at once, which '
      'is rare. The averages pile up around 3.5 in a bell, and the bell gets '
      'narrower as you average more dice. This works for almost any starting '
      'shape.',
  formula: (sim) {
    final c = sim as CltSim;
    return 'sd of average = σ/√n = 1.71/√${c.dice} = ${c.expectedSd.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: average more dice',
  buildTryIt: (sim) => _DiceControls(sim: sim as CltSim),
  quiz: const [
    QuizQuestion(
      prompt: 'You roll ONE die thousands of times. What shape is the histogram?',
      options: ['A bell', 'Flat: all six bars equal', 'Tall at 1 and 6', 'A U shape'],
      answer: 1,
      explanation: 'Each face has the same 1/6 chance. The bell only appears '
          'when you average several dice.',
    ),
    QuizQuestion(
      prompt: 'You switch from averaging 4 dice to averaging 16. The bell becomes…',
      options: ['Twice as wide', 'Half as wide', 'Four times narrower', 'Unchanged'],
      answer: 1,
      explanation: 'Spread is σ/√n. √16 / √4 = 2, so the bell is half as wide.',
    ),
    QuizQuestion(
      prompt: 'Where is the centre of the bell of averages?',
      options: ['1', '3', '3.5', '6'],
      answer: 2,
      explanation: 'The average of one die is (1+2+3+4+5+6)/6 = 3.5, and '
          'averaging more dice keeps the same centre.',
    ),
  ],
);

class _DiceControls extends StatelessWidget {
  const _DiceControls({required this.sim});
  final CltSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('1 die', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              Expanded(
                child: Slider(
                  value: sim.dice.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${sim.dice}',
                  onChanged: (v) => sim.setDice(v.round()),
                ),
              ),
              const Text('10', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ],
          ),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'n = ${sim.dice} ${sim.dice == 1 ? 'die' : 'dice'}',
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => sim.rollMany(500),
                child: const Text('Roll 500', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Start at 1 die (flat), then slide to 2, 5, 10 and watch the bell form and narrow.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ===== lib/lessons/coin_flips.dart =====
// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

class CoinFlipSim extends LessonSim {
  CoinFlipSim({math.Random? rng}) : _rng = rng ?? math.Random();

  /// Chance of heads on each flip.
  double p = 0.5;

  int flips = 0;
  int heads = 0;

  /// Running share of heads, sampled every [historyEvery] flips: entry i is
  /// the share after (i + 1) × [historyEvery] flips. Thinned as it grows so
  /// memory stays bounded however long the lesson runs.
  final List<double> history = [];
  int historyEvery = 1;

  /// Most recent results, newest last: true = heads.
  final List<bool> recent = [];

  /// 0 → 1 spin of the big coin for the flip in progress.
  double spin = 0;
  bool lastHeads = true;

  static const int maxHistory = 2000;
  static const int recentCount = 14;

  final math.Random _rng;

  /// Flips per second at 1×. Starts slow so single flips are visible, then
  /// speeds up so the long-run line appears within a minute.
  double get _rate => flips < 20 ? 3 : (flips < 100 ? 12 : 40);

  double get proportion => flips == 0 ? 0 : heads / flips;

  @override
  void advance(double dt) {
    spin += dt * _rate;
    while (spin >= 1) {
      spin -= 1;
      _flip();
    }
    notifyListeners();
  }

  void _flip() {
    final h = _rng.nextDouble() < p;
    flips++;
    if (h) heads++;
    lastHeads = h;
    recent.add(h);
    if (recent.length > recentCount) recent.removeAt(0);
    _record();
  }

  void _record() {
    if (flips % historyEvery != 0) return;
    history.add(proportion);
    if (history.length >= maxHistory) {
      // Keep entries at multiples of 2 × historyEvery.
      final thinned = [for (var i = 1; i < history.length; i += 2) history[i]];
      history
        ..clear()
        ..addAll(thinned);
      historyEvery *= 2;
    }
  }

  /// Instantly flips [count] coins (the "flip 100" button).
  void flipMany(int count) {
    for (var i = 0; i < count; i++) {
      _flip();
    }
    notifyListeners();
  }

  @override
  void step() {
    spin = 0;
    _flip();
    notifyListeners();
  }

  @override
  void reset() {
    flips = 0;
    heads = 0;
    spin = 0;
    history.clear();
    historyEvery = 1;
    recent.clear();
    notifyListeners();
  }

  void setP(double value) {
    p = value;
    reset();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class CoinFlipPainter extends CustomPainter {
  CoinFlipPainter(this.sim) : super(repaint: sim);

  final CoinFlipSim sim;

  static const double aspectRatio = 0.85;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Big spinning coin -------------------------------------------------
    final coinR = w * 0.12;
    final coinC = Offset(w * 0.2, h * 0.17);
    final squash = math.cos(sim.spin * math.pi * 2).abs().clamp(0.08, 1.0);
    final showHeads = sim.spin < 0.25 || sim.spin > 0.75 ? sim.lastHeads : !sim.lastHeads;
    final coinColor = showHeads ? AppColors.yellow : AppColors.cyan;
    canvas.save();
    canvas.translate(coinC.dx, coinC.dy - math.sin(sim.spin * math.pi) * coinR * 0.5);
    canvas.scale(1, squash);
    canvas.drawCircle(Offset.zero, coinR, Paint()..color = coinColor);
    canvas.drawCircle(
      Offset.zero,
      coinR * 0.8,
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.restore();
    if (squash > 0.35) {
      _text(canvas, showHeads ? 'H' : 'T', coinC.translate(0, -math.sin(sim.spin * math.pi) * coinR * 0.5),
          size: coinR * 0.9 * squash, color: AppColors.ink, weight: FontWeight.w900);
    }

    // --- Recent results strip ---------------------------------------------
    final stripLeft = w * 0.38;
    final dotR = math.min(w * 0.026, 9.0);
    final gap = (w - stripLeft - 12) / CoinFlipSim.recentCount;
    for (var i = 0; i < sim.recent.length; i++) {
      final isH = sim.recent[i];
      final c = Offset(stripLeft + gap * (i + 0.5), h * 0.13);
      canvas.drawCircle(c, dotR, Paint()..color = isH ? AppColors.yellow : AppColors.cyan);
      _text(canvas, isH ? 'H' : 'T', c, size: dotR * 1.1, color: AppColors.ink, weight: FontWeight.w900);
    }
    _text(canvas, 'last ${CoinFlipSim.recentCount} flips', Offset(stripLeft + (w - stripLeft) / 2, h * 0.22),
        size: 11, color: AppColors.muted);

    // --- Running proportion chart ------------------------------------------
    const left = 34.0;
    final top = h * 0.33;
    final right = w - 14;
    final bottom = h - 26;
    final chartH = bottom - top;
    double yFor(double v) => bottom - v * chartH;

    final grid = Paint()
      ..color = AppColors.peg.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (final v in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      canvas.drawLine(Offset(left, yFor(v)), Offset(right, yFor(v)), grid);
      _text(canvas, v.toStringAsFixed(v == 0 || v == 1 ? 0 : 2), Offset(left - 16, yFor(v)),
          size: 10, color: AppColors.muted);
    }

    // True probability line (dashed).
    final target = Paint()
      ..color = AppColors.pink
      ..strokeWidth = 2.5;
    for (var x = left; x < right; x += 10) {
      canvas.drawLine(Offset(x, yFor(sim.p)), Offset(math.min(x + 5, right), yFor(sim.p)), target);
    }

    final n = sim.history.length;
    if (n > 1) {
      // x axis grows with the data so early wobble stays visible.
      final span = math.max(50, sim.flips).toDouble();
      double xAt(int i) => left + ((i + 1) * sim.historyEvery / span) * (right - left);
      final path = Path()..moveTo(xAt(0), yFor(sim.history.first));
      final stride = math.max(1, n ~/ 400);
      for (var i = stride; i < n; i += stride) {
        path.lineTo(xAt(i), yFor(sim.history[i]));
      }
      path.lineTo(xAt(n - 1), yFor(sim.history.last));
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.violet
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );
      final tip = Offset(xAt(n - 1), yFor(sim.history.last));
      canvas.drawCircle(tip, 5, Paint()..color = AppColors.violet);
    }

    _text(canvas, 'share of heads →', Offset(left + 52, top - 10), size: 11, color: AppColors.muted);
    _text(canvas, 'number of flips →', Offset((left + right) / 2, h - 11), size: 11, color: AppColors.muted);
  }

  void _text(
    Canvas canvas,
    String text,
    Offset centre, {
    double size = 12,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w700,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CoinFlipPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec coinFlipsLesson = LessonSpec(
  id: 'coin_flips',
  chapterLabel: 'Ch 3 · Probability basics',
  title: const [
    TitlePart('Flip a coin '),
    TitlePart('enough', AppColors.orange),
    TitlePart(' times and the '),
    TitlePart('luck', AppColors.cyan),
    TitlePart(' washes out'),
  ],
  subtitle: 'Law of Large Numbers · 2-minute animated lesson',
  createSim: () => CoinFlipSim(),
  visualAspectRatio: CoinFlipPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: CoinFlipPainter(sim as CoinFlipSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final c = sim as CoinFlipSim;
    return [
      StatChip('flips', '${c.flips}', AppColors.yellow),
      StatChip('heads', '${c.heads}', AppColors.orange),
      StatChip('share', c.proportion.toStringAsFixed(3), AppColors.violet),
    ];
  },
  bigIdea: 'Ten flips can easily give 7 heads. But the more you flip, the '
      'closer the share of heads gets to the true chance. Each flip is still '
      'random; it is the average that settles down.',
  formula: (sim) {
    final c = sim as CoinFlipSim;
    return 'heads / flips = ${c.heads} / ${c.flips} → p = ${c.p.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: load the coin',
  buildTryIt: (sim) => _CoinControls(sim: sim as CoinFlipSim),
  quiz: const [
    QuizQuestion(
      prompt: 'You flip a fair coin 10 times and get 7 heads. What best describes this?',
      options: ['The coin must be unfair', 'Normal luck for only 10 flips', 'Tails is now "due"', 'Impossible'],
      answer: 1,
      explanation: 'With only 10 flips, 7 heads happens about 12% of the time. '
          'Small samples wobble a lot.',
    ),
    QuizQuestion(
      prompt: 'After 10,000 flips of a fair coin, the share of heads will most likely be…',
      options: ['Exactly 0.5000', 'Very close to 0.5', 'Anywhere from 0 to 1', 'Above 0.6'],
      answer: 1,
      explanation: 'The Law of Large Numbers: the average gets close to the true '
          'probability, though rarely exactly equal to it.',
    ),
    QuizQuestion(
      prompt: 'You just saw 5 tails in a row on a fair coin. Chance the next flip is heads?',
      options: ['Higher than 50%', 'Lower than 50%', 'Exactly 50%', 'It depends on the last 100 flips'],
      answer: 2,
      explanation: 'Coins have no memory. The long-run average evens out by '
          'drowning past streaks in new flips, not by "correcting" them.',
    ),
  ],
);

class _CoinControls extends StatelessWidget {
  const _CoinControls({required this.sim});
  final CoinFlipSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('tails', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              Expanded(
                child: Slider(
                  value: sim.p,
                  min: 0.1,
                  max: 0.9,
                  divisions: 16,
                  label: sim.p.toStringAsFixed(2),
                  onChanged: sim.setP,
                ),
              ),
              const Text('heads', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ],
          ),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'p(heads) = ${sim.p.toStringAsFixed(2)}',
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => sim.flipMany(100),
                child: const Text('Flip 100', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Load the coin and watch the purple line home in on the pink one.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ===== lib/lessons/combinations.dart =====
/// Every ordered pick of r people from n, sliding into columns by team.
class CombinationSim extends LessonSim {
  CombinationSim() {
    _build();
  }

  static const double cycle = 8;

  int n = 4;
  int r = 2;
  double t = 0;

  /// Ordered picks in dictionary order.
  late List<List<int>> ordered;

  /// Distinct teams (sorted picks) in dictionary order.
  late List<List<int>> teams;

  int get perms => ordered.length;
  int get combos => teams.length;

  void _build() {
    ordered = [];
    void go(List<int> prefix) {
      if (prefix.length == r) {
        ordered.add(prefix);
        return;
      }
      for (var i = 0; i < n; i++) {
        if (!prefix.contains(i)) go([...prefix, i]);
      }
    }

    go([]);
    final keys = <String>{};
    teams = [];
    for (final p in ordered) {
      final s = [...p]..sort();
      if (keys.add(s.join())) teams.add(s);
    }
    teams.sort((a, b) => a.join().compareTo(b.join()));
  }

  int teamOf(List<int> p) {
    final key = ([...p]..sort()).join();
    return teams.indexWhere((t) => t.join() == key);
  }

  /// 0 = arrangements in order, 1 = grouped into teams.
  double get grouping {
    final s = t % cycle;
    if (s < 2) return 0;
    if (s < 4) return Curves.easeInOutCubic.transform((s - 2) / 2);
    if (s < 6) return 1;
    return 1 - Curves.easeInOutCubic.transform((s - 6) / 2);
  }

  @override
  void advance(double dt) {
    t = (t + dt) % cycle;
    notifyListeners();
  }

  @override
  void step() {
    t = ((t ~/ 2) * 2 + 2.0) % cycle;
    notifyListeners();
  }

  @override
  void reset() {
    t = 0;
    notifyListeners();
  }

  void setSizes({int? n, int? r}) {
    this.n = n ?? this.n;
    this.r = math.min(r ?? this.r, this.n);
    _build();
    t = 0;
    notifyListeners();
  }
}

const _people = ['A', 'B', 'C', 'D', 'E'];

void _paintCombinations(Canvas canvas, Size size, CombinationSim sim) {
  final w = size.width;
  final h = size.height;
  final cols = sim.combos;
  final rows = sim.perms ~/ cols; // = r!
  const top = 30.0;
  final cellW = (w - 20) / cols;
  final cellH = math.min((h - top - 50) / rows, cellW * 1.6);
  final g = sim.grouping;

  final within = List.filled(cols, 0);
  for (var i = 0; i < sim.perms; i++) {
    final p = sim.ordered[i];
    final team = sim.teamOf(p);
    final from = Offset(10 + (i % cols + 0.5) * cellW, top + (i ~/ cols + 0.5) * cellH);
    final to = Offset(10 + (team + 0.5) * cellW, top + (within[team]++ + 0.5) * cellH);
    final c = Offset.lerp(from, to, g)!;
    final color = HSVColor.fromAHSV(1, 360 * team / cols, 0.55, 0.95).toColor();
    final rect = Rect.fromCenter(center: c, width: cellW - 4, height: cellH - 4);
    roundRect(canvas, rect, color.withValues(alpha: 0.35), radius: 6);
    // The people in pick order.
    final dot = math.min(rect.width / (sim.r * 1.25), rect.height * 0.7);
    final vertical = rect.height > rect.width * 1.3;
    for (var k = 0; k < sim.r; k++) {
      final off = (k - (sim.r - 1) / 2) * dot * 1.1;
      final pc = vertical ? c.translate(0, off) : c.translate(off, 0);
      canvas.drawCircle(pc, dot * 0.48, Paint()..color = AppColors.rainbow[p[k]]);
      label(canvas, _people[p[k]], pc, size: dot * 0.55, color: Colors.white);
    }
  }

  label(canvas, g < 0.5 ? 'All ${sim.perms} ordered picks' : '${sim.combos} teams, each listed $rows× (r! orders)',
      Offset(w / 2, 14),
      size: 13, color: g < 0.5 ? AppColors.ink : AppColors.violet);
  label(canvas, '${sim.perms} ÷ $rows = ${sim.combos} different teams', Offset(w / 2, h - 16),
      size: 14, color: AppColors.violet);
}

final LessonSpec combinationsLesson = LessonSpec(
  id: 'combinations',
  chapterLabel: 'Ch 4 · Counting',
  title: const [
    TitlePart('When order '),
    TitlePart('doesn\'t', AppColors.violet),
    TitlePart(' matter: picking a team'),
  ],
  subtitle: 'Combinations · 2-minute animated lesson',
  createSim: () => CombinationSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<CombinationSim>(sim, _paintCombinations),
  stats: (sim) {
    final c = sim as CombinationSim;
    return [
      StatChip('ordered nPr', '${c.perms}', AppColors.yellow),
      StatChip('orders each r!', '${factorial(c.r)}', AppColors.pink),
      StatChip('teams nCr', '${c.combos}', AppColors.violet),
    ];
  },
  bigIdea: 'Picking A then B, or B then A, gives the same team. Count the ordered '
      'picks first (a permutation), then notice every team appears once for each '
      'way of ordering its r members, which is r! times. Divide those repeats out '
      'and you get the number of combinations.',
  formula: (sim) {
    final c = sim as CombinationSim;
    return 'nCr = nPr / r! = ${c.perms} / ${factorial(c.r)} = ${c.combos}';
  },
  tryItTitle: 'Try it: change the group and team size',
  buildTryIt: (sim) {
    final c = sim as CombinationSim;
    return watch(
      c,
      () => Column(
        children: [
          LabeledSlider(
            left: 'people ${c.n}',
            right: '5',
            value: c.n.toDouble(),
            min: 3,
            max: 5,
            divisions: 2,
            onChanged: (v) => c.setSizes(n: v.round()),
          ),
          LabeledSlider(
            left: 'team ${c.r}',
            right: '3',
            value: c.r.toDouble(),
            min: 1,
            max: 3,
            divisions: 2,
            onChanged: (v) => c.setSizes(r: v.round()),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'How many ways can you choose 2 toppings from 6?',
      options: ['12', '15', '30', '36'],
      answer: 1,
      explanation: '6 × 5 = 30 ordered picks, but each pair is counted twice: 30 / 2 = 15.',
    ),
    QuizQuestion(
      prompt: 'Which situation is a combination, not a permutation?',
      options: [
        'Gold, silver and bronze medals',
        'A 4-digit PIN',
        'Choosing 3 friends to invite',
        'Seating people in a row',
      ],
      answer: 2,
      explanation: 'Inviting Asha, Ben and Chen is the same invitation in any order.',
    ),
    QuizQuestion(
      prompt: 'What is C(10, 3)?',
      options: ['30', '120', '720', '1,000'],
      answer: 1,
      explanation: '10 × 9 × 8 = 720 ordered picks, divided by 3! = 6 orders: 120.',
    ),
  ],
);

// ===== lib/lessons/complement.dart =====
/// Each trial rolls n dice: did at least one six turn up?
class ComplementSim extends TickSim {
  ComplementSim({super.rng}) {
    _roll();
  }

  int dice = 4;
  int trials = 0;
  int atLeastOne = 0;
  List<int> faces = [];

  /// Recent trial results, newest last (true = at least one six).
  final List<bool> recent = [];

  double get noSixTheory => math.pow(5 / 6, dice).toDouble();
  double get theory => 1 - noSixTheory;
  double get observed => trials == 0 ? 0 : atLeastOne / trials;

  @override
  double get interval => trials < 8 ? 0.8 : (trials < 40 ? 0.25 : 0.06);

  void _roll() => faces = List.generate(dice, (_) => 1 + rng.nextInt(6));

  @override
  void tick() {
    _roll();
    trials++;
    final hit = faces.contains(6);
    if (hit) atLeastOne++;
    recent.add(hit);
    if (recent.length > 60) recent.removeAt(0);
  }

  @override
  void restart() {
    trials = 0;
    atLeastOne = 0;
    recent.clear();
    _roll();
  }
}

void _paintComplement(Canvas canvas, Size size, ComplementSim sim) {
  final w = size.width;
  final h = size.height;

  // Current dice.
  final die = math.min(44.0, (w - 40) / sim.dice * 0.8);
  final rowW = sim.dice * die * 1.2;
  for (var i = 0; i < sim.dice; i++) {
    final f = sim.faces[i];
    paintDie(canvas, Offset((w - rowW) / 2 + die * 1.2 * (i + 0.5), 14 + die / 2), die, f,
        f == 6 ? AppColors.pink : AppColors.chip);
  }
  final hit = sim.faces.contains(6);
  label(canvas, sim.trials == 0 ? 'Roll ${sim.dice} dice…' : (hit ? 'At least one six ✓' : 'No six at all'),
      Offset(w / 2, 30 + die),
      size: 14, color: hit ? AppColors.pink : AppColors.muted);

  // Recent trials as a strip of squares.
  final stripY = 52 + die;
  final sq = (w - 40) / 30;
  for (var i = 0; i < sim.recent.length; i++) {
    final r = Rect.fromLTWH(20 + (i % 30) * sq + 1, stripY + (i ~/ 30) * sq + 1, sq - 2, sq - 2);
    roundRect(canvas, r, sim.recent[i] ? AppColors.pink : AppColors.peg.withValues(alpha: 0.6), radius: 3);
  }

  // Theory bar: split into "no six" (5/6)^n and the complement.
  final barY = stripY + sq * 2 + 40;
  final barW = w - 40;
  label(canvas, 'Every possible result of ${sim.dice} dice', Offset(20, barY - 14), size: 12, align: TextAlign.left);
  final noW = barW * sim.noSixTheory;
  roundRect(canvas, Rect.fromLTWH(20, barY, noW, 34), AppColors.peg, radius: 8);
  roundRect(canvas, Rect.fromLTWH(20 + noW, barY, barW - noW, 34), AppColors.pink, radius: 8);
  label(canvas, 'no six', Offset(20 + noW / 2, barY + 17), size: 12, color: Colors.white);
  if (barW - noW > 60) {
    label(canvas, 'at least one', Offset(20 + noW + (barW - noW) / 2, barY + 17), size: 12, color: Colors.white);
  }
  label(canvas, '(5/6)^${sim.dice} = ${sim.noSixTheory.toStringAsFixed(3)}', Offset(20 + noW / 2, barY + 48),
      size: 11, color: AppColors.muted);
  label(canvas, '1 − that = ${sim.theory.toStringAsFixed(3)}', Offset(w - 20, barY + 66),
      size: 12, color: AppColors.pink, align: TextAlign.right);
  label(canvas, 'seen: ${sim.observed.toStringAsFixed(3)} of ${sim.trials} trials', Offset(20, h - 12),
      size: 11, color: AppColors.muted, align: TextAlign.left);
}

final LessonSpec complementLesson = LessonSpec(
  id: 'complement',
  chapterLabel: 'Ch 3 · Probability basics',
  title: const [
    TitlePart('Hard to count? Count what '),
    TitlePart('didn\'t', AppColors.pink),
    TitlePart(' happen'),
  ],
  subtitle: 'The complement rule · 2-minute animated lesson',
  createSim: () => ComplementSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<ComplementSim>(sim, _paintComplement),
  stats: (sim) {
    final c = sim as ComplementSim;
    return [
      StatChip('trials', '${c.trials}', AppColors.yellow),
      StatChip('≥ one six', c.observed.toStringAsFixed(3), AppColors.pink),
      StatChip('theory', c.theory.toStringAsFixed(3), AppColors.violet),
    ];
  },
  bigIdea: '"At least one six" can happen in many ways: one six, two sixes, six '
      'on the first die or the third… Counting them all is painful. Its opposite, '
      '"no six at all", happens in just one way: every die misses, with chance '
      '5/6 each. Something either happens or it doesn\'t, so the two chances add '
      'up to 1.',
  formula: (sim) {
    final c = sim as ComplementSim;
    return 'P(at least one six) = 1 − P(no six) = 1 − (5/6)^${c.dice} = ${c.theory.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: roll more dice at once',
  buildTryIt: (sim) {
    final c = sim as ComplementSim;
    return watch(
      c,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '1 die',
            right: '10',
            value: c.dice.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '${c.dice}',
            onChanged: (v) => c.change(() => c.dice = v.round()),
          ),
          const TryNote('With 4 dice you already have better than even odds of a six (0.518).'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'P(rain tomorrow) = 0.3. What is P(no rain)?',
      options: ['0.3', '0.7', '1.3', 'Can\'t tell'],
      answer: 1,
      explanation: 'It either rains or it doesn\'t: 1 − 0.3 = 0.7.',
    ),
    QuizQuestion(
      prompt: 'Flip 3 coins. What is P(at least one head)?',
      options: ['1/8', '3/8', '1/2', '7/8'],
      answer: 3,
      explanation: 'P(no heads) = (1/2)³ = 1/8, so P(at least one) = 1 − 1/8 = 7/8.',
    ),
    QuizQuestion(
      prompt: 'Why use the complement for "at least one" questions?',
      options: [
        'It is always smaller',
        '"None" is one simple case; "at least one" is many cases',
        'It avoids decimals',
        'It only works for dice',
      ],
      answer: 1,
      explanation: 'Calculating the single "none" case and subtracting from 1 is far '
          'quicker than adding up every way to get one or more.',
    ),
  ],
);

// ===== lib/lessons/conditional.dart =====
enum CondView { everyone, givenGlasses, givenCricket }

const Map<CondView, String> kCondViewNames = {
  CondView.everyone: 'Everyone',
  CondView.givenGlasses: 'Given glasses',
  CondView.givenCricket: 'Given cricket',
};

/// 100 people: who wears glasses, who plays cricket. Conditioning zooms in.
class ConditionalSim extends TickSim {
  ConditionalSim({super.rng}) {
    _build();
  }

  static const int people = 100;
  static const int glassesCount = 40;
  static const int cricketCount = 30;

  /// People who do both (0–30).
  int both = 12;

  late List<bool> glasses;
  late List<bool> cricket;

  CondView view = CondView.everyone;

  /// Picked by the learner: stops the automatic cycling.
  bool manual = false;

  /// 0 → 1 fade towards the current view.
  double focus = 1;

  @override
  double get interval => 3;

  void _build() {
    final order = List<int>.generate(people, (i) => i)..shuffle(math.Random(3));
    glasses = List.filled(people, false);
    cricket = List.filled(people, false);
    for (var k = 0; k < glassesCount; k++) {
      glasses[order[k]] = true;
    }
    // The first `both` glasses-wearers play cricket, then non-wearers make up the rest.
    for (var k = 0; k < both; k++) {
      cricket[order[k]] = true;
    }
    for (var k = 0; k < cricketCount - both; k++) {
      cricket[order[glassesCount + k]] = true;
    }
  }

  bool inView(int i) => switch (view) {
        CondView.everyone => true,
        CondView.givenGlasses => glasses[i],
        CondView.givenCricket => cricket[i],
      };

  double get pCricket => cricketCount / people;
  double get pCricketGivenGlasses => both / glassesCount;
  double get pGlassesGivenCricket => both / cricketCount;

  @override
  void advance(double dt) {
    focus = math.min(1, focus + dt * 2.5);
    super.advance(dt);
  }

  @override
  void tick() {
    if (manual) return;
    view = CondView.values[(view.index + 1) % CondView.values.length];
    focus = 0;
  }

  void choose(CondView v) {
    manual = true;
    view = v;
    focus = 0;
    notifyListeners();
  }

  void setBoth(int v) {
    both = v;
    _build();
    notifyListeners();
  }

  @override
  void restart() {
    manual = false;
    view = CondView.everyone;
    focus = 1;
  }
}

void _paintConditional(Canvas canvas, Size size, ConditionalSim sim) {
  final w = size.width;
  final h = size.height;
  const cols = 10;
  final cell = (w - 40) / cols;
  const top = 34.0;

  final title = switch (sim.view) {
    CondView.everyone => 'All 100 people',
    CondView.givenGlasses => 'Only the 40 who wear glasses',
    CondView.givenCricket => 'Only the 30 who play cricket',
  };
  label(canvas, title, Offset(w / 2, 14), size: 14, color: AppColors.violet);

  for (var i = 0; i < ConditionalSim.people; i++) {
    final c = Offset(20 + (i % cols + 0.5) * cell, top + (i ~/ cols + 0.5) * cell);
    final visible = sim.inView(i);
    final a = visible ? 1.0 : 1 - 0.88 * sim.focus;
    canvas.drawCircle(
        c, cell * 0.32, Paint()..color = (sim.cricket[i] ? AppColors.orange : AppColors.peg).withValues(alpha: a));
    if (sim.glasses[i]) {
      // Two little lenses.
      for (final dx in [-0.13, 0.13]) {
        ring(canvas, c.translate(cell * dx, -cell * 0.04), cell * 0.1, AppColors.ink.withValues(alpha: a), width: 1.8);
      }
    }
  }

  final y = top + 10 * cell + 18;
  final (p, text) = switch (sim.view) {
    CondView.everyone => (sim.pCricket, 'P(cricket) = 30 / 100'),
    CondView.givenGlasses => (sim.pCricketGivenGlasses, 'P(cricket | glasses) = ${sim.both} / 40'),
    CondView.givenCricket => (sim.pGlassesGivenCricket, 'P(glasses | cricket) = ${sim.both} / 30'),
  };
  label(canvas, '$text = ${p.toStringAsFixed(2)}', Offset(w / 2, y), size: 15);
  label(canvas, '● plays cricket   ⚬⚬ wears glasses', Offset(w / 2, h - 12), size: 11, color: AppColors.muted);
}

final LessonSpec conditionalLesson = LessonSpec(
  id: 'conditional',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('"Given that…" '),
    TitlePart('shrinks', AppColors.violet),
    TitlePart(' the world'),
  ],
  subtitle: 'Conditional probability · 2-minute animated lesson',
  createSim: () => ConditionalSim(),
  visualAspectRatio: 0.84,
  buildVisual: (sim) => simCanvas<ConditionalSim>(sim, _paintConditional),
  stats: (sim) {
    final c = sim as ConditionalSim;
    return [
      StatChip('P(cricket)', c.pCricket.toStringAsFixed(2), AppColors.orange),
      StatChip('P(cricket | glasses)', c.pCricketGivenGlasses.toStringAsFixed(2), AppColors.violet),
    ];
  },
  bigIdea: 'P(A | B) reads "the chance of A given B". Knowing B happened throws '
      'away everyone outside B: the faded dots. Among the people left, count '
      'how many also have A. The order matters: the share of glasses-wearers who '
      'play cricket is not the share of cricketers who wear glasses.',
  formula: (sim) {
    final c = sim as ConditionalSim;
    return 'P(A | B) = P(A and B) / P(B)\n'
        'P(cricket | glasses) = ${c.both}/100 ÷ 40/100 = ${c.pCricketGivenGlasses.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: condition on a group',
  buildTryIt: (sim) {
    final c = sim as ConditionalSim;
    return watch(
      c,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<CondView>(options: kCondViewNames, selected: c.view, onSelected: c.choose),
          const SizedBox(height: 8),
          LabeledSlider(
            left: 'overlap 0',
            right: '30',
            value: c.both.toDouble(),
            min: 0,
            max: 30,
            divisions: 30,
            label: '${c.both} do both',
            onChanged: (v) => c.setBoth(v.round()),
          ),
          TryNote('${c.both} people wear glasses and play cricket.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'In a class of 30, 12 students take music and 4 of them also take art. '
          'What is P(art | music)?',
      options: ['4/30', '4/12', '12/30', '4/16'],
      answer: 1,
      explanation: 'Given music, only those 12 students count; 4 of them take art.',
    ),
    QuizQuestion(
      prompt: 'Is P(A | B) always equal to P(B | A)?',
      options: ['Yes, always', 'No, they can be very different', 'Only for coins', 'Only when both are 0'],
      answer: 1,
      explanation: 'P(rich | lottery winner) is high; P(lottery winner | rich) is tiny.',
    ),
    QuizQuestion(
      prompt: 'P(A and B) = 0.1 and P(B) = 0.4. What is P(A | B)?',
      options: ['0.04', '0.25', '0.4', '0.5'],
      answer: 1,
      explanation: '0.1 / 0.4 = 0.25.',
    ),
  ],
);

// ===== lib/lessons/discrete_continuous.dart =====
/// A die (discrete) next to a spinner (continuous), both recorded.
class DiscreteContinuousSim extends TickSim {
  DiscreteContinuousSim({super.rng});

  List<int> dieCounts = List.filled(6, 0);
  final List<double> spins = [];
  int lastDie = 1;
  double lastSpin = 0;

  /// Bins used for the spinner's histogram.
  int bins = 10;

  int get rolls => dieCounts.fold(0, (a, b) => a + b);

  @override
  double get interval => rolls < 8 ? 0.8 : 0.06;

  @override
  void tick() {
    lastDie = 1 + rng.nextInt(6);
    dieCounts[lastDie - 1]++;
    lastSpin = rng.nextDouble();
    if (spins.length < 5000) spins.add(lastSpin);
  }

  void setBins(int b) {
    bins = b;
    notifyListeners();
  }

  @override
  void restart() {
    dieCounts = List.filled(6, 0);
    spins.clear();
  }
}

void _paintDC(Canvas canvas, Size size, DiscreteContinuousSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 16.0;
  final right = w - 16;
  final half = h / 2;

  // --- Die: discrete ---
  label(canvas, 'DISCRETE: a die can only land on 1–6', Offset(left, 12),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  paintDie(canvas, Offset(right - 22, 38), 36, sim.lastDie, AppColors.yellow);
  final dBase = half - 30;
  const dTop = 34.0;
  final slot = (right - 70 - left) / 6;
  final maxD = math.max(4, sim.dieCounts.reduce(math.max));
  for (var f = 0; f < 6; f++) {
    final x = left + slot * (f + 0.5);
    // Thin spikes: probability sits exactly on whole numbers.
    bar(canvas, x, 8, dBase, (dBase - dTop) * sim.dieCounts[f] / maxD, AppColors.orange);
    label(canvas, '${f + 1}', Offset(x, dBase + 10), size: 11, color: AppColors.muted);
  }
  line(canvas, Offset(left, dBase), Offset(right - 70, dBase), AppColors.peg);

  // --- Spinner: continuous ---
  label(canvas, 'CONTINUOUS: a spinner can stop anywhere in 0–1', Offset(left, half + 6),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  final sc = Offset(right - 22, half + 36);
  canvas.drawCircle(sc, 20, Paint()..color = AppColors.cyan.withValues(alpha: 0.3));
  ring(canvas, sc, 20, AppColors.cyan);
  final ang = -math.pi / 2 + 2 * math.pi * sim.lastSpin;
  line(canvas, sc, sc + Offset(math.cos(ang), math.sin(ang)) * 18, AppColors.ink, width: 3);
  label(canvas, sim.lastSpin.toStringAsFixed(4), sc.translate(0, 30), size: 10);

  final cBase = h - 22;
  final cTop = half + 30;
  final counts = List.filled(sim.bins, 0);
  for (final s in sim.spins) {
    counts[(s * sim.bins).floor().clamp(0, sim.bins - 1)]++;
  }
  final maxC = math.max(4, counts.reduce(math.max));
  final binW = (right - 70 - left) / sim.bins;
  for (var b = 0; b < sim.bins; b++) {
    final bh = (cBase - cTop) * counts[b] / maxC;
    canvas.drawRect(
        Rect.fromLTWH(left + b * binW, cBase - bh, binW, bh), Paint()..color = AppColors.cyan.withValues(alpha: 0.8));
  }
  line(canvas, Offset(left, cBase), Offset(right - 70, cBase), AppColors.peg);
  label(canvas, '0', Offset(left, cBase + 10), size: 10, color: AppColors.muted);
  label(canvas, '1', Offset(right - 70, cBase + 10), size: 10, color: AppColors.muted);
  final exact = sim.spins.where((s) => s.toStringAsFixed(4) == '0.5000').length;
  label(canvas, 'spins of exactly 0.5000: $exact', Offset(right - 70, cTop - 12),
      size: 10, color: AppColors.pink, align: TextAlign.right);
}

final LessonSpec discreteContinuousLesson = LessonSpec(
  id: 'discrete_continuous',
  chapterLabel: 'Ch 6 · Random variables',
  title: const [
    TitlePart('Steps', AppColors.orange),
    TitlePart(' or a '),
    TitlePart('smooth line', AppColors.cyan),
    TitlePart('?'),
  ],
  subtitle: 'Discrete vs continuous random variables · 2-minute animated lesson',
  createSim: () => DiscreteContinuousSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<DiscreteContinuousSim>(sim, _paintDC),
  stats: (sim) {
    final s = sim as DiscreteContinuousSim;
    return [
      StatChip('rolls', '${s.rolls}', AppColors.orange),
      StatChip('spins', '${s.spins.length}', AppColors.cyan),
      StatChip('bins', '${s.bins}', AppColors.yellow),
    ];
  },
  bigIdea: 'A random variable turns an outcome into a number. A discrete one takes '
      'separate values you can list, like 1 to 6, and each has its own chance. A '
      'continuous one can take any value in a range, so any single exact value, '
      'like 0.5000000…, has chance zero. For continuous variables we ask about '
      'ranges instead: P(0.4 ≤ X ≤ 0.6).',
  formula: (sim) {
    final s = sim as DiscreteContinuousSim;
    return 'die: P(X = 3) = 1/6 · spinner: P(X = 0.5) = 0, P(0.4 ≤ X ≤ 0.6) = 0.2  '
        '(bin width ${(1 / s.bins).toStringAsFixed(3)})';
  },
  tryItTitle: 'Try it: zoom in on the spinner',
  buildTryIt: (sim) {
    final s = sim as DiscreteContinuousSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'wide bins',
            right: 'tiny',
            value: s.bins.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            label: '${s.bins} bins',
            onChanged: (v) => s.setBins(v.round()),
          ),
          ControlRow(children: [ActionButton('Roll & spin 1,000', () => s.runMany(1000))]),
          const SizedBox(height: 8),
          const TryNote(
              'Narrower bins catch fewer spins each: as the bin shrinks to a single point, its share heads to 0.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Which random variable is continuous?',
      options: [
        'Number of heads in 10 flips',
        'Number of customers in an hour',
        'Exact time until the next bus',
        'Score on a die',
      ],
      answer: 2,
      explanation: 'Time can be any value in a range. The others are counts.',
    ),
    QuizQuestion(
      prompt: 'For a continuous variable X, P(X = 2.5 exactly) is…',
      options: ['0.5', 'Depends on the data', '0', '1'],
      answer: 2,
      explanation: 'A single point has no width, so it holds no probability. Only '
          'ranges do.',
    ),
    QuizQuestion(
      prompt: 'A spinner lands uniformly on 0–1. What is P(0.2 ≤ X ≤ 0.5)?',
      options: ['0.2', '0.3', '0.5', '0.7'],
      answer: 1,
      explanation: 'For a uniform spinner, the chance is the width of the range: 0.5 − 0.2.',
    ),
  ],
);

// ===== lib/lessons/events.dart =====
enum DieEvent { even, overFour, prime, six }

const Map<DieEvent, String> kDieEventNames = {
  DieEvent.even: 'Even',
  DieEvent.overFour: 'More than 4',
  DieEvent.prime: 'Prime',
  DieEvent.six: 'A six',
};

const Map<DieEvent, Set<int>> kDieEventFaces = {
  DieEvent.even: {2, 4, 6},
  DieEvent.overFour: {5, 6},
  DieEvent.prime: {2, 3, 5},
  DieEvent.six: {6},
};

class EventsSim extends TickSim {
  EventsSim({super.rng});

  DieEvent event = DieEvent.even;
  int rolls = 0;
  int hits = 0;
  int last = 1;
  List<int> faceCounts = List.filled(7, 0);

  Set<int> get faces => kDieEventFaces[event]!;
  double get theory => faces.length / 6;
  double get freq => rolls == 0 ? 0 : hits / rolls;

  @override
  double get interval => rolls < 12 ? 0.6 : (rolls < 60 ? 0.15 : 0.04);

  @override
  void tick() {
    last = 1 + rng.nextInt(6);
    rolls++;
    faceCounts[last]++;
    if (faces.contains(last)) hits++;
  }

  @override
  void restart() {
    rolls = 0;
    hits = 0;
    faceCounts = List.filled(7, 0);
  }
}

void _paintEvents(Canvas canvas, Size size, EventsSim sim) {
  final w = size.width;
  final h = size.height;

  // Sample space: the six faces, event faces ringed.
  label(canvas, 'Sample space S: every possible outcome', Offset(w / 2, 14), size: 12, color: AppColors.muted);
  final die = (w - 40) / 6 * 0.72;
  for (var f = 1; f <= 6; f++) {
    final c = Offset(20 + (w - 40) / 6 * (f - 0.5), 34 + die / 2);
    final inEvent = sim.faces.contains(f);
    final isLast = sim.rolls > 0 && f == sim.last;
    if (inEvent) {
      roundRect(
          canvas, Rect.fromCenter(center: c, width: die + 10, height: die + 10), AppColors.pink.withValues(alpha: 0.18),
          radius: 12);
    }
    paintDie(canvas, c, die * (isLast ? 1.0 + (1 - sim.phase) * 0.15 : 1.0), f,
        isLast ? AppColors.yellow : (inEvent ? AppColors.pink : AppColors.chip));
    // Count of each face below.
    label(canvas, '${sim.faceCounts[f]}', c.translate(0, die / 2 + 14), size: 11, color: AppColors.muted);
  }
  label(canvas, 'Event E = ${kDieEventNames[sim.event]}: {${(sim.faces.toList()..sort()).join(', ')}}',
      Offset(w / 2, 34 + die + 44),
      size: 14, color: AppColors.pink);

  // Running frequency vs theory.
  final barTop = 34 + die + 76;
  final barW = w - 40;
  label(canvas, 'Share of rolls that landed in E', Offset(20, barTop), size: 12, align: TextAlign.left);
  final y = barTop + 18;
  roundRect(canvas, Rect.fromLTWH(20, y, barW, 28), Colors.white, radius: 10);
  roundRect(canvas, Rect.fromLTWH(20, y, barW * sim.freq, 28), AppColors.pink, radius: 10);
  final tx = 20 + barW * sim.theory;
  line(canvas, Offset(tx, y - 6), Offset(tx, y + 34), AppColors.ink, width: 3);
  label(canvas, 'theory ${sim.faces.length}/6', Offset(tx, y + 46), size: 11);
  label(canvas, '${(sim.freq * 100).toStringAsFixed(1)}%', Offset(26, y + 14),
      size: 12, color: Colors.white, align: TextAlign.left);
  label(canvas, '${sim.hits} of ${sim.rolls} rolls', Offset(w - 20, h - 12),
      size: 11, color: AppColors.muted, align: TextAlign.right);
}

final LessonSpec eventsLesson = LessonSpec(
  id: 'events',
  chapterLabel: 'Ch 3 · Probability basics',
  title: const [
    TitlePart('Outcomes', AppColors.yellow),
    TitlePart(', '),
    TitlePart('events', AppColors.pink),
    TitlePart(' and the chance of them'),
  ],
  subtitle: 'Experiments, outcomes & events · 2-minute animated lesson',
  createSim: () => EventsSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<EventsSim>(sim, _paintEvents),
  stats: (sim) {
    final e = sim as EventsSim;
    return [
      StatChip('rolls', '${e.rolls}', AppColors.yellow),
      StatChip('in E', '${e.hits}', AppColors.pink),
      StatChip('share', e.freq.toStringAsFixed(3), AppColors.violet),
    ];
  },
  bigIdea: 'An experiment (rolling a die) has outcomes (1 to 6); all of them '
      'together are the sample space. An event is any group of outcomes you care '
      'about, like "even". When every outcome is equally likely, the chance of '
      'an event is simply how many outcomes it contains divided by how many there '
      'are in total.',
  formula: (sim) {
    final e = sim as EventsSim;
    return 'P(E) = |E| / |S| = ${e.faces.length} / 6 = ${e.theory.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: choose a different event',
  buildTryIt: (sim) {
    final e = sim as EventsSim;
    return watch(
      e,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<DieEvent>(
            options: kDieEventNames,
            selected: e.event,
            onSelected: (v) => e.change(() => e.event = v),
          ),
          const SizedBox(height: 8),
          ControlRow(children: [ActionButton('Roll 600', () => e.runMany(600))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'You flip two coins. How many outcomes are in the sample space?',
      options: ['2', '3', '4', '6'],
      answer: 2,
      explanation: 'HH, HT, TH, TT. HT and TH are different outcomes.',
    ),
    QuizQuestion(
      prompt: 'Roll a die. What is P(a number less than 3)?',
      options: ['1/6', '1/3', '1/2', '2/3'],
      answer: 1,
      explanation: 'The event is {1, 2}: 2 outcomes out of 6, so 2/6 = 1/3.',
    ),
    QuizQuestion(
      prompt: 'Rolling a die, which event contains more than one outcome?',
      options: ['Rolling a 4', 'Rolling an odd number', 'Rolling a 6', 'Rolling a 1'],
      answer: 1,
      explanation: '"Odd" groups three outcomes: {1, 3, 5}.',
    ),
  ],
);

// ===== lib/lessons/expected_value.dart =====
/// A ₹10 ticket spins a prize wheel. Does the game pay on average?
class ExpectedValueSim extends TickSim {
  ExpectedValueSim({super.rng});

  static const double ticket = 10;
  static const List<double> prizes = [0, 10, 20, 100];
  static const List<Color> colors = [AppColors.peg, AppColors.cyan, AppColors.green, AppColors.yellow];

  /// Chance of the ₹100 jackpot (taken from the ₹0 slice).
  double jackpot = 0.05;

  List<double> get chances => [0.6 - (jackpot - 0.05), 0.25, 0.10, jackpot];

  /// Net win (prize − ticket) per outcome.
  List<double> get nets => [for (final p in prizes) p - ticket];

  double get expected {
    var e = 0.0;
    for (var i = 0; i < 4; i++) {
      e += chances[i] * nets[i];
    }
    return e;
  }

  int plays = 0;
  double totalNet = 0;
  int last = 0;
  final List<double> averages = [];

  double get average => plays == 0 ? 0 : totalNet / plays;

  @override
  double get interval => plays < 8 ? 0.9 : (plays < 60 ? 0.15 : 0.03);

  @override
  void tick() {
    var r = rng.nextDouble();
    var i = 0;
    while (i < 3 && r > chances[i]) {
      r -= chances[i];
      i++;
    }
    last = i;
    plays++;
    totalNet += nets[i];
    if (averages.length < 1500) averages.add(average);
  }

  @override
  void restart() {
    plays = 0;
    totalNet = 0;
    averages.clear();
  }
}

void _paintEV(Canvas canvas, Size size, ExpectedValueSim sim) {
  final w = size.width;
  final h = size.height;

  // Wheel.
  final r = math.min(w * 0.2, 70.0);
  final c = Offset(20 + r, 20 + r);
  var start = -math.pi / 2;
  final spin = sim.plays == 0 ? 0.0 : (1 - sim.phase) * 0.6;
  for (var i = 0; i < 4; i++) {
    final sweep = sim.chances[i] * 2 * math.pi;
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), start + spin, sweep, true, Paint()..color = ExpectedValueSim.colors[i]);
    start += sweep;
  }
  ring(canvas, c, r, Colors.white, width: 3);
  final tri = Path()
    ..moveTo(c.dx - 8, c.dy - r - 12)
    ..lineTo(c.dx + 8, c.dy - r - 12)
    ..lineTo(c.dx, c.dy - r + 2)
    ..close();
  canvas.drawPath(tri, Paint()..color = AppColors.ink);

  // Legend with nets.
  final lx = c.dx + r + 22;
  for (var i = 0; i < 4; i++) {
    final y = 30 + i * 26.0;
    canvas.drawCircle(Offset(lx, y), 7, Paint()..color = ExpectedValueSim.colors[i]);
    final net = sim.nets[i];
    label(
        canvas,
        '₹${ExpectedValueSim.prizes[i].round()} (${net >= 0 ? '+' : ''}${net.round()}) · ${(sim.chances[i] * 100).round()}%',
        Offset(lx + 14, y),
        size: 12,
        align: TextAlign.left,
        color: i == sim.last && sim.plays > 0 ? AppColors.pink : AppColors.ink);
  }

  // Running average vs expected value.
  const left = 40.0;
  final right = w - 14;
  final top = 2 * r + 50;
  final bottom = h - 24;
  const lo = -12.0, hi = 12.0;
  double yFor(double v) => bottom - (v.clamp(lo, hi) - lo) / (hi - lo) * (bottom - top);
  line(canvas, Offset(left, yFor(0)), Offset(right, yFor(0)), AppColors.peg);
  label(canvas, '₹0', Offset(left - 6, yFor(0)), size: 10, color: AppColors.muted, align: TextAlign.right);
  dashedLine(canvas, Offset(left, yFor(sim.expected)), Offset(right, yFor(sim.expected)), AppColors.pink, width: 2.5);
  label(canvas, 'E[X] = ₹${sim.expected.toStringAsFixed(2)}', Offset(right, yFor(sim.expected) - 10),
      size: 11, color: AppColors.pink, align: TextAlign.right);
  final n = sim.averages.length;
  if (n > 1) {
    final span = math.max(60, n).toDouble();
    final path = Path()..moveTo(left, yFor(sim.averages.first));
    for (var i = 1; i < n; i++) {
      path.lineTo(left + i / span * (right - left), yFor(sim.averages[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.violet
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }
  label(canvas, 'your average win per play →', Offset(left, bottom + 14),
      size: 10, color: AppColors.muted, align: TextAlign.left);
}

final LessonSpec expectedValueLesson = LessonSpec(
  id: 'expected_value',
  chapterLabel: 'Ch 6 · Random variables',
  title: const [
    TitlePart('Is this game '),
    TitlePart('worth playing', AppColors.green),
    TitlePart('?'),
  ],
  subtitle: 'Expected value · 2-minute animated lesson',
  createSim: () => ExpectedValueSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<ExpectedValueSim>(sim, _paintEV),
  stats: (sim) {
    final e = sim as ExpectedValueSim;
    return [
      StatChip('plays', '${e.plays}', AppColors.yellow),
      StatChip('avg win', '₹${e.average.toStringAsFixed(2)}', AppColors.violet),
      StatChip('E[X]', '₹${e.expected.toStringAsFixed(2)}', AppColors.pink),
    ];
  },
  bigIdea: 'The expected value is the long-run average result per play. Weight each '
      'possible outcome by its chance and add them up. One spin can win ₹90, but '
      'over hundreds of spins your average settles near the expected value. '
      'Casinos and lotteries set it below zero for players, which is why the '
      'house always wins in the end.',
  formula: (sim) {
    final e = sim as ExpectedValueSim;
    final terms = [for (var i = 0; i < 4; i++) '${e.chances[i].toStringAsFixed(2)}×${e.nets[i].round()}'].join(' + ');
    return 'E[X] = Σ x·p(x) = $terms = ${e.expected.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: change the jackpot chance',
  buildTryIt: (sim) {
    final e = sim as ExpectedValueSim;
    return watch(
      e,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '1%',
            right: '10%',
            value: e.jackpot,
            min: 0.01,
            max: 0.10,
            divisions: 9,
            label: '${(e.jackpot * 100).round()}% jackpot',
            onChanged: (v) => e.change(() => e.jackpot = v),
          ),
          ControlRow(children: [
            ValueTag(e.expected >= 0 ? 'Fair or better for you' : 'You lose on average'),
            ActionButton('Play 500 times', () => e.runMany(500)),
          ]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A game: win ₹10 with chance 0.3, lose ₹5 otherwise. Expected value?',
      options: ['+₹5', '−₹0.50', '+₹3', '−₹5'],
      answer: 1,
      explanation: '0.3 × 10 + 0.7 × (−5) = 3 − 3.5 = −0.5.',
    ),
    QuizQuestion(
      prompt: 'What is the expected value of one fair die roll?',
      options: ['3', '3.5', '4', '6'],
      answer: 1,
      explanation: '(1 + 2 + 3 + 4 + 5 + 6) / 6 = 3.5. It needn\'t be a possible roll.',
    ),
    QuizQuestion(
      prompt: 'A game has E[X] = −₹2. What happens if you play 1,000 times?',
      options: [
        'You lose exactly ₹2',
        'You lose about ₹2,000 in total',
        'You break even',
        'You must win eventually',
      ],
      answer: 1,
      explanation: 'The average per play settles near −₹2, so the total heads towards '
          '1,000 × −₹2.',
    ),
  ],
);

// ===== lib/lessons/galton_board.dart =====
// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

class GaltonBall {
  GaltonBall(this.path, this.color);

  /// One entry per row: true = bounced right.
  final List<bool> path;
  final Color color;

  /// Progress in rows (0 → rows). Fraction = position between rows.
  double t = 0;

  int rightsBefore(int row) {
    var count = 0;
    for (var i = 0; i < row && i < path.length; i++) {
      if (path[i]) count++;
    }
    return count;
  }
}

class GaltonSim extends LessonSim {
  GaltonSim({this.rows = 8}) : bins = List<int>.filled(rows + 1, 0);

  final int rows;

  /// Probability of bouncing right at each peg ("tilt").
  double p = 0.5;

  final List<GaltonBall> balls = [];
  List<int> bins;
  int landed = 0;

  static const double rowTime = 0.11; // seconds per row at 1×
  static const double spawnEvery = 0.16;

  final math.Random _rng = math.Random();
  double _spawnTimer = spawnEvery;
  int _colorIndex = 0;

  double get observedMean {
    if (landed == 0) return 0;
    var sum = 0;
    for (var b = 0; b < bins.length; b++) {
      sum += b * bins[b];
    }
    return sum / landed;
  }

  double get expectedMean => rows * p;

  @override
  void advance(double dt) {
    _spawnTimer += dt;
    while (_spawnTimer >= spawnEvery) {
      _spawnTimer -= spawnEvery;
      _spawn();
    }
    final rowsMoved = dt / rowTime;
    for (final ball in balls) {
      ball.t += rowsMoved;
    }
    balls.removeWhere((ball) {
      if (ball.t < rows) return false;
      bins[ball.rightsBefore(rows)]++;
      landed++;
      return true;
    });
    notifyListeners();
  }

  void _spawn() {
    final path = List<bool>.generate(rows, (_) => _rng.nextDouble() < p);
    final color = AppColors.rainbow[_colorIndex % AppColors.rainbow.length];
    _colorIndex++;
    balls.add(GaltonBall(path, color));
  }

  @override
  void step() => advance(rowTime);

  @override
  void reset() {
    balls.clear();
    bins = List<int>.filled(rows + 1, 0);
    landed = 0;
    _spawnTimer = spawnEvery;
    notifyListeners();
  }

  void setP(double value) {
    p = value;
    reset();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class GaltonPainter extends CustomPainter {
  GaltonPainter(this.sim) : super(repaint: sim);

  final GaltonSim sim;

  static const double aspectRatio = 0.80; // width / height

  @override
  void paint(Canvas canvas, Size size) {
    final n = sim.rows;
    final w = size.width;
    final h = size.height;
    final dx = w / (n + 2);
    final dy = dx * 0.78;
    final cx = w / 2;
    final boardTop = dx * 0.7;
    final boardBottom = boardTop + n * dy;
    final histTop = boardBottom + dx * 0.15;
    final histBottom = h - 24;
    final pegR = math.max(2.5, dx * 0.09);
    final ballR = math.max(4.0, dx * 0.19);

    double xFor(double unitsFromCentre) => cx + unitsFromCentre * dx;

    // Bin dividers (faint).
    final divider = Paint()
      ..color = AppColors.peg.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (var b = 0; b <= n + 1; b++) {
      final x = xFor(b - n / 2 - 0.5);
      canvas.drawLine(Offset(x, histTop), Offset(x, histBottom), divider);
    }

    // Pegs.
    final pegPaint = Paint()..color = AppColors.peg;
    for (var r = 0; r < n; r++) {
      for (var i = 0; i <= r; i++) {
        canvas.drawCircle(Offset(xFor(i - r / 2), boardTop + r * dy), pegR, pegPaint);
      }
    }

    // Histogram bars.
    var maxBin = 0;
    for (final c in sim.bins) {
      maxBin = math.max(maxBin, c);
    }
    final sigma = math.sqrt(n * sim.p * (1 - sim.p));
    final mu = n * sim.p;
    final curvePeak = sigma > 0.15 ? sim.landed / (sigma * math.sqrt(2 * math.pi)) : 0.0;
    final scaleMax = math.max(10.0, math.max(maxBin.toDouble(), curvePeak) * 1.08);
    final histH = histBottom - histTop;
    final barW = dx * 0.78;

    for (var b = 0; b <= n; b++) {
      final count = sim.bins[b];
      if (count == 0) continue;
      final barH = count / scaleMax * histH;
      final x = xFor(b - n / 2);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x - barW / 2, histBottom - barH, barW, barH),
        topLeft: Radius.circular(barW * 0.3),
        topRight: Radius.circular(barW * 0.3),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = AppColors.rainbow[b % AppColors.rainbow.length],
      );
    }

    // Expected bell curve once there's enough data.
    if (sim.landed >= 20 && sigma > 0.15) {
      final path = Path();
      var first = true;
      for (var x = -0.5; x <= n + 0.5; x += 0.05) {
        final density = math.exp(-math.pow(x - mu, 2) / (2 * sigma * sigma)) / (sigma * math.sqrt(2 * math.pi));
        final y = histBottom - sim.landed * density / scaleMax * histH;
        final px = xFor(x - n / 2);
        if (first) {
          path.moveTo(px, y);
          first = false;
        } else {
          path.lineTo(px, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Falling balls (with a little bounce between pegs).
    for (final ball in sim.balls) {
      final k = math.min(ball.t.floor(), n - 1);
      final f = (ball.t - k).clamp(0.0, 1.0);
      final eased = Curves.easeInOut.transform(f);
      final x0 = ball.rightsBefore(k) - k / 2;
      final x1 = ball.rightsBefore(k + 1) - (k + 1) / 2;
      final ux = x0 + (x1 - x0) * eased;
      final hop = math.sin(math.pi * f) * 0.35;
      final y = boardTop + (k + f - hop) * dy - pegR - ballR;
      final centre = Offset(xFor(ux), y);
      canvas.drawCircle(
        centre,
        ballR * 1.7,
        Paint()
          ..color = ball.color.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(centre, ballR, Paint()..color = ball.color);
    }

    // Axis labels.
    _label(canvas, '0 rights', Offset(xFor(-n / 2), h - 12));
    _label(canvas, '${n ~/ 2}', Offset(cx, h - 12));
    _label(canvas, '$n rights', Offset(xFor(n / 2), h - 12));
  }

  void _label(Canvas canvas, String text, Offset centre) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant GaltonPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec galtonLesson = LessonSpec(
  id: 'galton',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('Why does '),
    TitlePart('everything', AppColors.pink),
    TitlePart(' end up as a '),
    TitlePart('bell', AppColors.violet),
    TitlePart('?'),
  ],
  subtitle: 'The Galton board · 2-minute animated lesson',
  createSim: () => GaltonSim(),
  visualAspectRatio: GaltonPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: GaltonPainter(sim as GaltonSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final g = sim as GaltonSim;
    return [
      StatChip('balls landed', '${g.landed}', AppColors.yellow),
      StatChip('avg rights', g.observedMean.toStringAsFixed(2), AppColors.cyan),
      StatChip('rows', '${g.rows}', AppColors.pink),
    ];
  },
  bigIdea: 'Every ball makes 8 coin-flip choices: left or right. Getting all 8 '
      'the same way is rare, so most balls pile up in the middle. That pile '
      'is the binomial distribution, and it looks like a bell.',
  formula: (sim) {
    final g = sim as GaltonSim;
    return 'μ = n·p = ${g.rows} × ${g.p.toStringAsFixed(2)} = '
        '${g.expectedMean.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: tilt the board',
  buildTryIt: (sim) => _TiltControl(sim: sim as GaltonSim),
  quiz: const [
    QuizQuestion(
      prompt: 'Each ball bounces off 8 pegs, 50/50 left or right. '
          'Which bin collects the most balls?',
      options: ['The far-left bin', 'The middle bin (4 rights)', 'All bins equally', 'The far-right bin'],
      answer: 1,
      explanation: '70 different paths lead to 4 rights, but only 1 path leads '
          'to 0 rights. More paths means more balls.',
    ),
    QuizQuestion(
      prompt: 'You tilt the board so p(right) = 0.75. What happens to the bell?',
      options: ['It gets taller', 'It slides to the right', 'It becomes flat', 'Nothing changes'],
      answer: 1,
      explanation: 'The centre moves to μ = 8 × 0.75 = 6, so the pile shifts right.',
    ),
    QuizQuestion(
      prompt: 'How many different paths lead to the far-left bin (0 rights)?',
      options: ['0', '1', '8', '70'],
      answer: 1,
      explanation: 'All 8 bounces must go left. There is exactly one way to do '
          'that: C(8, 0) = 1.',
    ),
  ],
);

class _TiltControl extends StatelessWidget {
  const _TiltControl({required this.sim});
  final GaltonSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('left', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              Expanded(
                child: Slider(
                  value: sim.p,
                  min: 0.1,
                  max: 0.9,
                  divisions: 16,
                  label: sim.p.toStringAsFixed(2),
                  onChanged: sim.setP,
                ),
              ),
              const Text('right', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'p(right) = ${sim.p.toStringAsFixed(2)}',
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag it and watch the bell slide sideways.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ===== lib/lessons/graphs_lie.dart =====
/// Two nearly equal numbers, drawn with an axis that starts higher and higher.
class GraphsLieSim extends LessonSim {
  static const double a = 52, b = 55;
  static const double cycle = 8;

  double t = 0;

  /// Axis start chosen with the slider; null while animating on its own.
  double? manualStart;

  double get axisStart {
    if (manualStart != null) return manualStart!;
    // 0 → 50 → 0, holding at both ends.
    final s = (t % cycle) / cycle;
    final wave = (1 - math.cos(2 * math.pi * s)) / 2;
    return (wave * 1.2).clamp(0.0, 1.0) * 50;
  }

  /// How many times taller bar B looks than bar A.
  double get looksLike => (b - axisStart) / (a - axisStart);

  @override
  void advance(double dt) {
    if (manualStart == null) t += dt;
    notifyListeners();
  }

  @override
  void step() {
    manualStart = null;
    t = ((t / (cycle / 4)).floor() + 1) * (cycle / 4);
    notifyListeners();
  }

  @override
  void reset() {
    manualStart = null;
    t = 0;
    notifyListeners();
  }

  void setStart(double v) {
    manualStart = v;
    notifyListeners();
  }
}

void _paintLie(Canvas canvas, Size size, GraphsLieSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 46.0, top = 30.0;
  final right = w - 20, bottom = h - 60;
  final start = sim.axisStart;
  const end = 56.0;
  double yFor(double v) => bottom - (v - start) / (end - start) * (bottom - top);

  label(canvas, 'Sales this year (lakh)', Offset(w / 2, 12), size: 13);
  // Axis with ticks.
  line(canvas, Offset(left, top), Offset(left, bottom), AppColors.ink);
  line(canvas, Offset(left, bottom), Offset(right, bottom), AppColors.ink);
  final step = (end - start) > 20 ? 10.0 : ((end - start) > 8 ? 2.0 : 1.0);
  for (var v = (start / step).ceil() * step; v <= end; v += step) {
    line(canvas, Offset(left - 5, yFor(v)), Offset(left, yFor(v)), AppColors.ink);
    label(canvas, v.toStringAsFixed(0), Offset(left - 8, yFor(v)),
        size: 10, color: AppColors.muted, align: TextAlign.right);
  }
  if (start > 0.5) {
    // Axis-break mark: a warning sign of a cut axis.
    label(canvas, '≈', Offset(left, bottom - 6), size: 18, color: AppColors.pink);
  }

  final slot = (right - left) / 2;
  for (final (i, name, v, color) in [
    (0, 'Us', GraphsLieSim.a, AppColors.blue),
    (1, 'Rival', GraphsLieSim.b, AppColors.pink)
  ]) {
    final x = left + slot * (i + 0.5);
    bar(canvas, x, slot * 0.5, bottom, bottom - yFor(v), color);
    label(canvas, '${v.round()}', Offset(x, yFor(v) - 12), size: 14);
    label(canvas, name, Offset(x, bottom + 14), size: 12, color: AppColors.muted);
  }

  final looks = sim.looksLike;
  label(canvas, 'Rival\'s bar looks ${looks.toStringAsFixed(1)}× as tall', Offset(w / 2, h - 30),
      size: 14, color: looks > 1.5 ? AppColors.pink : AppColors.ink);
  label(
      canvas,
      'Really: ${(GraphsLieSim.b / GraphsLieSim.a).toStringAsFixed(2)}× · axis starts at ${start.toStringAsFixed(0)}',
      Offset(w / 2, h - 12),
      size: 11,
      color: AppColors.muted);
}

final LessonSpec graphsLieLesson = LessonSpec(
  id: 'graphs_lie',
  chapterLabel: 'Ch 2 · Seeing data',
  title: const [
    TitlePart('Same numbers, '),
    TitlePart('very different', AppColors.pink),
    TitlePart(' story'),
  ],
  subtitle: 'How graphs lie · 2-minute animated lesson',
  createSim: () => GraphsLieSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<GraphsLieSim>(sim, _paintLie),
  stats: (sim) {
    final g = sim as GraphsLieSim;
    return [
      StatChip('axis starts', g.axisStart.toStringAsFixed(0), AppColors.yellow),
      StatChip('looks', '${g.looksLike.toStringAsFixed(1)}×', AppColors.pink),
      StatChip('really', '${(GraphsLieSim.b / GraphsLieSim.a).toStringAsFixed(2)}×', AppColors.green),
    ];
  },
  bigIdea: 'Bar charts work because bar length is proportional to the value. Start '
      'the axis at 50 instead of 0 and a 6% difference looks like a landslide. '
      'Always read the axis: check where it starts, whether it\'s evenly spaced, '
      'and whether two charts you\'re comparing use the same scale.',
  formula: (sim) {
    final g = sim as GraphsLieSim;
    final s = g.axisStart.toStringAsFixed(0);
    return 'looks = (55 − $s) / (52 − $s) = ${g.looksLike.toStringAsFixed(2)}   really = 55 / 52 = 1.06';
  },
  tryItTitle: 'Try it: be the misleading designer',
  buildTryIt: (sim) {
    final g = sim as GraphsLieSim;
    return watch(
      g,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'from 0',
            right: 'from 51',
            value: g.axisStart,
            min: 0,
            max: 51,
            divisions: 51,
            label: 'axis starts at ${g.axisStart.round()}',
            onChanged: g.setStart,
          ),
          const TryNote('Moving the slider stops the animation; press reset to let it run again.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A bar chart\'s y-axis starts at 95 instead of 0. What is the risk?',
      options: [
        'Small differences look huge',
        'Big differences look small',
        'Bars become invisible',
        'There is no risk',
      ],
      answer: 0,
      explanation: 'Cutting off the bottom of every bar exaggerates the gaps between '
          'their tops.',
    ),
    QuizQuestion(
      prompt: 'Two news charts compare crime in two cities but use different y-axis scales. '
          'You should…',
      options: [
        'Compare bar heights directly',
        'Compare the actual numbers on the axes',
        'Trust the taller bar',
        'Ignore both',
      ],
      answer: 1,
      explanation: 'Heights only compare fairly when the scales match. Read the values.',
    ),
    QuizQuestion(
      prompt: 'When is starting a line chart\'s axis above zero acceptable?',
      options: [
        'Never',
        'When showing small changes over time, clearly labelled',
        'Only for bar charts',
        'When you want to win an argument',
      ],
      answer: 1,
      explanation: 'Line charts show change, not size, so a zoomed axis is fine if it '
          'is clearly marked. Bar charts should start at zero.',
    ),
  ],
);

// ===== lib/lessons/histograms.dart =====
/// Reaction times in milliseconds, binned with an adjustable bin count.
class HistogramSim extends TickSim {
  HistogramSim({super.rng});

  static const double lo = 150, hi = 450;
  static const int target = 150;

  final List<double> values = [];
  int bins = 10;

  @override
  double get interval => values.length < 12 ? 0.3 : 0.05;

  double get width => (hi - lo) / bins;

  List<int> get counts {
    final c = List.filled(bins, 0);
    for (final v in values) {
      c[((v - lo) / width).floor().clamp(0, bins - 1)]++;
    }
    return c;
  }

  @override
  void tick() {
    if (values.length >= target) return;
    // Right-skewed: most people react fast, a few are slow.
    final v = 200 + -math.log(1 - rng.nextDouble()) * 45 + normalDraw(rng) * 12;
    values.add(v.clamp(lo, hi - 0.01).toDouble());
  }

  void setBins(int n) {
    bins = n;
    notifyListeners();
  }

  @override
  void restart() => values.clear();
}

void _paintHistogram(Canvas canvas, Size size, HistogramSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 16.0;
  final right = w - 16;
  double xFor(double v) => left + (v - HistogramSim.lo) / (HistogramSim.hi - HistogramSim.lo) * (right - left);

  // Raw data strip.
  label(canvas, 'raw data: ${sim.values.length} reaction times', Offset(left, 12),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  final stripY = 36.0;
  for (var i = 0; i < sim.values.length; i++) {
    final v = sim.values[i];
    final isNew = i == sim.values.length - 1;
    canvas.drawCircle(Offset(xFor(v), stripY + ((i * 37) % 11) * 1.6), isNew ? 5 : 3,
        Paint()..color = (isNew ? AppColors.pink : AppColors.blue).withValues(alpha: isNew ? 1 : 0.45));
  }

  // Histogram.
  final baseline = h - 34;
  final top = stripY + 34;
  final counts = sim.counts;
  final maxC = math.max(4, counts.reduce(math.max));
  final binPx = (right - left) / sim.bins;
  for (var b = 0; b < sim.bins; b++) {
    final bh = (baseline - top) * counts[b] / maxC;
    // Bars touch: a histogram's bins are a continuous number line.
    final rect = Rect.fromLTWH(left + b * binPx, baseline - bh, binPx, bh);
    canvas.drawRect(rect, Paint()..color = AppColors.rainbow[(b * 7 ~/ sim.bins)].withValues(alpha: 0.85));
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
  line(canvas, Offset(left, baseline), Offset(right, baseline), AppColors.peg);
  for (var v = 150; v <= 450; v += 50) {
    label(canvas, '$v', Offset(xFor(v.toDouble()), baseline + 12), size: 10, color: AppColors.muted);
  }
  label(canvas, 'ms', Offset(right, baseline + 26), size: 10, color: AppColors.muted, align: TextAlign.right);
}

final LessonSpec histogramsLesson = LessonSpec(
  id: 'histograms',
  chapterLabel: 'Ch 2 · Seeing data',
  title: const [
    TitlePart('How many '),
    TitlePart('bins', AppColors.cyan),
    TitlePart(' should a histogram have?'),
  ],
  subtitle: 'Histograms · 2-minute animated lesson',
  createSim: () => HistogramSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<HistogramSim>(sim, _paintHistogram),
  stats: (sim) {
    final s = sim as HistogramSim;
    return [
      StatChip('values', '${s.values.length}', AppColors.yellow),
      StatChip('bins', '${s.bins}', AppColors.cyan),
      StatChip('bin width', '${s.width.round()} ms', AppColors.pink),
    ];
  },
  bigIdea: 'A histogram chops a number line into equal bins and counts how many '
      'values fall into each. Bars touch because the numbers are continuous. Too '
      'few bins hide the shape in a few blocks; too many turn it into noise. Pick '
      'enough bins to see the shape clearly, often around √n.',
  formula: (sim) {
    final s = sim as HistogramSim;
    return 'bin width = range / bins = 300 / ${s.bins} = ${s.width.toStringAsFixed(0)} ms · '
        '√n ≈ ${math.sqrt(math.max(1, s.values.length)).round()}';
  },
  tryItTitle: 'Try it: change the number of bins',
  buildTryIt: (sim) {
    final s = sim as HistogramSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '3',
            right: '40',
            value: s.bins.toDouble(),
            min: 3,
            max: 40,
            divisions: 37,
            label: '${s.bins} bins',
            onChanged: (v) => s.setBins(v.round()),
          ),
          const TryNote('Try 3 bins (one blob), then 40 (a comb of spikes), then about 12.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'How is a histogram different from a bar chart?',
      options: [
        'Histograms use colours',
        'Histogram bars show counts in ranges of a number, so they touch',
        'Histograms are always vertical',
        'There is no difference',
      ],
      answer: 1,
      explanation: 'Bar charts compare separate categories. Histograms slice one '
          'continuous number line into bins.',
    ),
    QuizQuestion(
      prompt: 'With far too many bins, a histogram usually looks…',
      options: ['Smooth', 'Spiky and noisy', 'Like a pie chart', 'Empty'],
      answer: 1,
      explanation: 'Each bin holds only a few values, so random variation dominates '
          'the picture.',
    ),
    QuizQuestion(
      prompt: 'Data from 0 to 100 split into 20 bins. How wide is each bin?',
      options: ['2', '5', '20', '100'],
      answer: 1,
      explanation: 'Width = range / bins = 100 / 20 = 5.',
    ),
  ],
);

// ===== lib/lessons/independence.dart =====
/// Two coins. A "sticky" second coin copies the first with some chance.
class IndependenceSim extends TickSim {
  IndependenceSim({super.rng});

  /// Chance the second coin just copies the first (0 = independent).
  double sticky = 0;

  bool first = true, second = true;

  /// counts[first ? 0 : 1][second ? 0 : 1]
  List<List<int>> counts = [
    [0, 0],
    [0, 0],
  ];

  int get flips => counts[0][0] + counts[0][1] + counts[1][0] + counts[1][1];

  double _rate(int row) {
    final n = counts[row][0] + counts[row][1];
    return n == 0 ? 0 : counts[row][0] / n;
  }

  /// P(second heads | first heads) and P(second heads | first tails).
  double get headsAfterHeads => _rate(0);
  double get headsAfterTails => _rate(1);

  @override
  double get interval => flips < 10 ? 0.6 : 0.06;

  @override
  void tick() {
    first = rng.nextBool();
    second = rng.nextDouble() < sticky ? first : rng.nextBool();
    counts[first ? 0 : 1][second ? 0 : 1]++;
  }

  @override
  void restart() {
    counts = [
      [0, 0],
      [0, 0],
    ];
  }
}

void _paintIndependence(Canvas canvas, Size size, IndependenceSim sim) {
  final w = size.width;
  final h = size.height;

  void coin(Offset c, bool heads, String name) {
    canvas.drawCircle(c, 26, Paint()..color = heads ? AppColors.yellow : AppColors.cyan);
    label(canvas, heads ? 'H' : 'T', c, size: 22);
    label(canvas, name, c.translate(0, 38), size: 11, color: AppColors.muted);
  }

  if (sim.flips > 0) {
    coin(Offset(w * 0.35, 40), sim.first, 'coin 1');
    coin(Offset(w * 0.65, 40), sim.second, 'coin 2');
  }

  // 2×2 table.
  const tableTop = 104.0;
  final cellW = (w - 110) / 2;
  const cellH = 44.0;
  label(canvas, 'coin 2: H', Offset(90 + cellW * 0.5, tableTop - 10), size: 11, color: AppColors.muted);
  label(canvas, 'coin 2: T', Offset(90 + cellW * 1.5, tableTop - 10), size: 11, color: AppColors.muted);
  for (var r = 0; r < 2; r++) {
    label(canvas, r == 0 ? 'coin 1: H' : 'coin 1: T', Offset(84, tableTop + cellH * (r + 0.5)),
        size: 11, color: AppColors.muted, align: TextAlign.right);
    for (var c = 0; c < 2; c++) {
      final rect = Rect.fromLTWH(90 + cellW * c + 2, tableTop + cellH * r + 2, cellW - 4, cellH - 4);
      final share = sim.flips == 0 ? 0.0 : sim.counts[r][c] / sim.flips;
      roundRect(canvas, rect, AppColors.violet.withValues(alpha: 0.1 + share * 1.6), radius: 8);
      label(canvas, '${sim.counts[r][c]}', rect.center, size: 15);
    }
  }

  // The test: does coin 1 change coin 2's chances?
  final y = tableTop + cellH * 2 + 30;
  final barW = w - 150;
  for (final (i, name, p, color) in [
    (0, 'H after H', sim.headsAfterHeads, AppColors.yellow),
    (1, 'H after T', sim.headsAfterTails, AppColors.cyan),
  ]) {
    final by = y + i * 36;
    label(canvas, name, Offset(116, by + 12), size: 12, align: TextAlign.right);
    roundRect(canvas, Rect.fromLTWH(126, by, barW, 24), Colors.white, radius: 8);
    roundRect(canvas, Rect.fromLTWH(126, by, barW * p, 24), color, radius: 8);
    label(canvas, p.toStringAsFixed(2), Offset(126 + barW + 4, by + 12), size: 12, align: TextAlign.left);
  }
  dashedLine(canvas, Offset(126 + barW / 2, y - 6), Offset(126 + barW / 2, y + 66), AppColors.ink);
  final gap = (sim.headsAfterHeads - sim.headsAfterTails).abs();
  label(
    canvas,
    sim.flips < 40
        ? 'Flipping…'
        : (gap < 0.06 ? 'Same chance either way: independent' : 'Coin 1 changes coin 2: dependent'),
    Offset(w / 2, h - 14),
    size: 13,
    color: gap < 0.06 ? AppColors.green : AppColors.pink,
  );
}

final LessonSpec independenceLesson = LessonSpec(
  id: 'independence',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('Does one result '),
    TitlePart('change', AppColors.pink),
    TitlePart(' the other?'),
  ],
  subtitle: 'Independence · 2-minute animated lesson',
  createSim: () => IndependenceSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<IndependenceSim>(sim, _paintIndependence),
  stats: (sim) {
    final s = sim as IndependenceSim;
    return [
      StatChip('pairs', '${s.flips}', AppColors.yellow),
      StatChip('H after H', s.headsAfterHeads.toStringAsFixed(2), AppColors.orange),
      StatChip('H after T', s.headsAfterTails.toStringAsFixed(2), AppColors.cyan),
    ];
  },
  bigIdea: 'Two events are independent when knowing one tells you nothing about the '
      'other. With fair coins, coin 2 lands heads half the time whether coin 1 was '
      'heads or tails: the bars match. Make coin 2 "sticky" and it copies coin 1, '
      'so the bars split apart. Only for independent events can you simply '
      'multiply: P(A and B) = P(A) × P(B).',
  formula: (sim) {
    final s = sim as IndependenceSim;
    final hh = s.flips == 0 ? 0 : s.counts[0][0] / s.flips;
    return 'independent ⇔ P(B | A) = P(B)\n'
        'P(H, H) seen ${hh.toStringAsFixed(3)} vs ½ × ½ = 0.250';
  },
  tryItTitle: 'Try it: make coin 2 sticky',
  buildTryIt: (sim) {
    final s = sim as IndependenceSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'fair',
            right: 'copycat',
            value: s.sticky,
            min: 0,
            max: 0.9,
            divisions: 9,
            label: '${(s.sticky * 100).round()}% copy',
            onChanged: (v) => s.change(() => s.sticky = v),
          ),
          ControlRow(children: [ActionButton('Flip 500 pairs', () => s.runMany(500))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Which pair of events is independent?',
      options: [
        'Raining today and carrying an umbrella',
        'Rolling a 6 and flipping heads',
        'Studying and passing',
        'Drawing two cards without putting the first back',
      ],
      answer: 1,
      explanation: 'The die and the coin have no way to affect each other.',
    ),
    QuizQuestion(
      prompt: 'P(A) = 0.5, P(B) = 0.4, and they are independent. What is P(A and B)?',
      options: ['0.9', '0.2', '0.1', '0.45'],
      answer: 1,
      explanation: '0.5 × 0.4 = 0.2.',
    ),
    QuizQuestion(
      prompt: 'P(B | A) = 0.7 but P(B) = 0.3. Are A and B independent?',
      options: ['Yes', 'No', 'Only if P(A) = 0.5', 'Can\'t tell'],
      answer: 1,
      explanation: 'Knowing A happened raises B\'s chance from 0.3 to 0.7, so they are dependent.',
    ),
  ],
);

// ===== lib/lessons/kit.dart =====
/// Shared building blocks for lessons: a sim that ticks at a fixed rate,
/// canvas helpers, and the small controls used in "Try it" cards.

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

/// A sim that does one discrete thing ([tick]) every [interval] seconds.
abstract class TickSim extends LessonSim {
  TickSim({math.Random? rng}) : rng = rng ?? math.Random();

  final math.Random rng;
  double _timer = 0;

  /// Seconds per tick at 1×. May change as the lesson goes on.
  double get interval;

  /// 0 → 1 progress towards the next tick, for easing animations.
  double get phase => (_timer / interval).clamp(0.0, 1.0);

  /// Advance the lesson by one discrete step.
  void tick();

  /// Back to the starting state (timer already cleared).
  void restart();

  @override
  void advance(double dt) {
    _timer += dt;
    var guard = 0;
    while (_timer >= interval && guard++ < 500) {
      _timer -= interval;
      tick();
    }
    notifyListeners();
  }

  @override
  void step() {
    _timer = 0;
    tick();
    notifyListeners();
  }

  @override
  void reset() {
    _timer = 0;
    restart();
    notifyListeners();
  }

  /// Runs [count] ticks at once (the "do 100" buttons).
  void runMany(int count) {
    for (var i = 0; i < count; i++) {
      tick();
    }
    notifyListeners();
  }

  /// Applies a settings change and starts over.
  void change(VoidCallback update) {
    update();
    reset();
  }
}

/// Sample statistics shared by several lessons.
double meanOf(Iterable<num> xs) => xs.isEmpty ? 0 : xs.fold<double>(0, (a, b) => a + b) / xs.length;

/// Quantile with linear interpolation (the spreadsheet / numpy default).
double quantileOf(List<num> xs, double q) {
  if (xs.isEmpty) return 0;
  final s = [...xs]..sort();
  final pos = q * (s.length - 1);
  final lo = pos.floor();
  final hi = pos.ceil();
  return s[lo] + (s[hi] - s[lo]) * (pos - lo);
}

double sdOf(List<num> xs) {
  if (xs.length < 2) return 0;
  final m = meanOf(xs);
  return math.sqrt(xs.fold<double>(0, (a, x) => a + (x - m) * (x - m)) / (xs.length - 1));
}

/// Standard normal draw (Box–Muller).
double normalDraw(math.Random rng) {
  final u1 = 1 - rng.nextDouble();
  final u2 = rng.nextDouble();
  return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
}

int factorial(int n) => n <= 1 ? 1 : n * factorial(n - 1);

int permutations(int n, int r) {
  var p = 1;
  for (var i = 0; i < r; i++) {
    p *= n - i;
  }
  return p;
}

int combinations(int n, int r) => permutations(n, r) ~/ factorial(r);

// ---------------------------------------------------------------------------
// Canvas helpers
// ---------------------------------------------------------------------------

/// Draws [text] anchored at [at]: centred by default, or starting / ending
/// there for [TextAlign.left] / [TextAlign.right].
void label(
  Canvas canvas,
  String text,
  Offset at, {
  double size = 12,
  Color color = AppColors.ink,
  FontWeight weight = FontWeight.w800,
  TextAlign align = TextAlign.center,
  double? maxWidth,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color)),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: maxWidth == null ? 1 : 3,
  )..layout(maxWidth: maxWidth ?? double.infinity);
  final dx = switch (align) {
    TextAlign.left => 0.0,
    TextAlign.right => tp.width,
    _ => tp.width / 2,
  };
  tp.paint(canvas, at - Offset(dx, tp.height / 2));
}

void roundRect(Canvas canvas, Rect rect, Color color, {double radius = 8}) {
  canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), Paint()..color = color);
}

/// A vertical bar standing on [baseline] with rounded top corners.
void bar(Canvas canvas, double centreX, double width, double baseline, double height, Color color) {
  if (height <= 0) return;
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      Rect.fromLTWH(centreX - width / 2, baseline - height, width, height),
      topLeft: Radius.circular(math.min(width * 0.3, 8)),
      topRight: Radius.circular(math.min(width * 0.3, 8)),
    ),
    Paint()..color = color,
  );
}

void line(Canvas canvas, Offset a, Offset b, Color color, {double width = 2}) {
  canvas.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );
}

void dashedLine(Canvas canvas, Offset a, Offset b, Color color, {double width = 2, double dash = 6}) {
  final total = (b - a).distance;
  if (total == 0) return;
  final dir = (b - a) / total;
  for (var d = 0.0; d < total; d += dash * 2) {
    line(canvas, a + dir * d, a + dir * math.min(d + dash, total), color, width: width);
  }
}

void ring(Canvas canvas, Offset c, double r, Color color, {double width = 2}) {
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width,
  );
}

/// Draws a die face centred at [c].
void paintDie(Canvas canvas, Offset c, double size, int face, Color color) {
  final rect = Rect.fromCenter(center: c, width: size, height: size);
  canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(size * 0.2)), Paint()..color = color);
  const pips = <int, List<Offset>>{
    1: [Offset(0, 0)],
    2: [Offset(-1, -1), Offset(1, 1)],
    3: [Offset(-1, -1), Offset(0, 0), Offset(1, 1)],
    4: [Offset(-1, -1), Offset(1, -1), Offset(-1, 1), Offset(1, 1)],
    5: [Offset(-1, -1), Offset(1, -1), Offset(0, 0), Offset(-1, 1), Offset(1, 1)],
    6: [Offset(-1, -1), Offset(1, -1), Offset(-1, 0), Offset(1, 0), Offset(-1, 1), Offset(1, 1)],
  };
  for (final p in pips[face]!) {
    canvas.drawCircle(c + p * (size * 0.25), size * 0.085, Paint()..color = AppColors.ink);
  }
}

/// A [CustomPainter] that repaints whenever [sim] changes and delegates
/// drawing to a function, so lessons don't need a painter class each.
class SimPainter<T extends LessonSim> extends CustomPainter {
  SimPainter(this.sim, this.draw) : super(repaint: sim);

  final T sim;
  final void Function(Canvas canvas, Size size, T sim) draw;

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size, sim);

  @override
  bool shouldRepaint(covariant SimPainter<T> oldDelegate) => oldDelegate.sim != sim;
}

/// The lesson stage for a sim drawn by [draw].
Widget simCanvas<T extends LessonSim>(LessonSim sim, void Function(Canvas, Size, T) draw) =>
    CustomPaint(painter: SimPainter<T>(sim as T, draw), child: const SizedBox.expand());

// ---------------------------------------------------------------------------
// Try-it controls
// ---------------------------------------------------------------------------

/// A slider with words at each end.
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.left,
    required this.right,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.label,
  });

  final String left;
  final String right;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700);
    return Row(
      children: [
        Text(left, style: style),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: onChanged,
          ),
        ),
        Text(right, style: style),
      ],
    );
  }
}

/// Yellow monospace pill showing the current setting.
class ValueTag extends StatelessWidget {
  const ValueTag(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800)),
    );
  }
}

/// Grey hint under the controls.
class TryNote extends StatelessWidget {
  const TryNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: AppColors.muted, height: 1.35));
}

/// A tonal action button for "do it many times".
class ActionButton extends StatelessWidget {
  const ActionButton(this.text, this.onPressed, {super.key});
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.tonal(
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      );
}

/// Single-choice chips that wrap on narrow screens.
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({super.key, required this.options, required this.selected, required this.onSelected});

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in options.entries)
          ChoiceChip(
            label: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w800)),
            selected: e.key == selected,
            selectedColor: AppColors.yellow,
            onSelected: (_) => onSelected(e.key),
          ),
      ],
    );
  }
}

/// Rebuilds [builder] whenever [sim] changes.
Widget watch(LessonSim sim, Widget Function() builder) =>
    ListenableBuilder(listenable: sim, builder: (_, __) => builder());

/// A tag and buttons side by side, wrapping onto two lines on narrow phones.
class ControlRow extends StatelessWidget {
  const ControlRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: children,
      );
}

// ---------------------------------------------------------------------------
// Distributions
// ---------------------------------------------------------------------------

/// log Γ(x) for x > 0 (Lanczos approximation).
double lgamma(double x) {
  if (x < 0.5) return math.log(math.pi / math.sin(math.pi * x)) - lgamma(1 - x);
  const g = 7.0;
  const c = [
    0.99999999999980993,
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
  ];
  x -= 1;
  var a = c[0];
  final t = x + g + 0.5;
  for (var i = 1; i < 9; i++) {
    a += c[i] / (x + i);
  }
  return 0.5 * math.log(2 * math.pi) + (x + 0.5) * math.log(t) - t + math.log(a);
}

double normalPdf(double x, [double mu = 0, double sd = 1]) =>
    math.exp(-0.5 * math.pow((x - mu) / sd, 2)) / (sd * math.sqrt(2 * math.pi));

/// Φ(z), accurate to about 1e-7 (Abramowitz & Stegun 7.1.26 on erf).
double normalCdf(double z) {
  final x = z.abs() / math.sqrt2;
  final t = 1 / (1 + 0.3275911 * x);
  final erf = 1 -
      (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) *
          t *
          math.exp(-x * x);
  return z >= 0 ? 0.5 * (1 + erf) : 0.5 * (1 - erf);
}

double binomPmf(int n, int k, double p) {
  if (k < 0 || k > n) return 0;
  final logC = lgamma(n + 1.0) - lgamma(k + 1.0) - lgamma(n - k + 1.0);
  if (p == 0) return k == 0 ? 1 : 0;
  if (p == 1) return k == n ? 1 : 0;
  return math.exp(logC + k * math.log(p) + (n - k) * math.log(1 - p));
}

double poissonPmf(double lambda, int k) => math.exp(k * math.log(lambda) - lambda - lgamma(k + 1.0));

double gammaPdf(double x, double shape, [double rate = 1]) =>
    x <= 0 ? 0 : math.exp(shape * math.log(rate) + (shape - 1) * math.log(x) - rate * x - lgamma(shape));

double betaPdf(double x, double a, double b) => x <= 0 || x >= 1
    ? 0
    : math.exp((a - 1) * math.log(x) + (b - 1) * math.log(1 - x) + lgamma(a + b) - lgamma(a) - lgamma(b));

double tPdf(double x, double df) => math.exp(
    lgamma((df + 1) / 2) - lgamma(df / 2) - 0.5 * math.log(df * math.pi) - (df + 1) / 2 * math.log(1 + x * x / df));

double chi2Pdf(double x, double df) => gammaPdf(x, df / 2, 0.5);

double fPdf(double x, double d1, double d2) => x <= 0
    ? 0
    : math.exp(0.5 * (d1 * math.log(d1 * x) + d2 * math.log(d2) - (d1 + d2) * math.log(d1 * x + d2)) -
        math.log(x) -
        (lgamma(d1 / 2) + lgamma(d2 / 2) - lgamma((d1 + d2) / 2)));

/// Exponential draw with the given rate.
double expDraw(math.Random rng, double rate) => -math.log(1 - rng.nextDouble()) / rate;

/// Poisson draw (Knuth's method; fine for small λ).
int poissonDraw(math.Random rng, double lambda) {
  final l = math.exp(-lambda);
  var k = 0;
  var p = 1.0;
  do {
    k++;
    p *= rng.nextDouble();
  } while (p > l);
  return k - 1;
}

/// Counts of [values] in [bins] equal bins over [lo, hi); out-of-range values are dropped.
List<int> binCounts(Iterable<double> values, double lo, double hi, int bins) {
  final c = List.filled(bins, 0);
  final w = (hi - lo) / bins;
  for (final v in values) {
    if (v < lo || v >= hi) continue;
    c[((v - lo) / w).floor().clamp(0, bins - 1)]++;
  }
  return c;
}

// ---------------------------------------------------------------------------
// Plotting
// ---------------------------------------------------------------------------

/// Maps data coordinates into a rectangle on the canvas.
class Plot {
  Plot(this.rect, {required this.x0, required this.x1, this.y0 = 0, required this.y1});

  final Rect rect;
  final double x0, x1, y0, y1;

  double x(double v) => rect.left + (v - x0) / (x1 - x0) * rect.width;
  double y(double v) => rect.bottom - (v - y0) / (y1 - y0) * rect.height;
  Offset at(double vx, double vy) => Offset(x(vx), y(vy));

  /// Baseline with tick labels under it.
  void axis(Canvas canvas, List<double> ticks, {String Function(double)? format, String? title}) {
    line(canvas, Offset(rect.left, rect.bottom), Offset(rect.right, rect.bottom), AppColors.peg);
    for (final t in ticks) {
      label(canvas, format?.call(t) ?? _trim(t), Offset(x(t), rect.bottom + 10), size: 10, color: AppColors.muted);
    }
    if (title != null) {
      label(canvas, title, Offset(rect.right, rect.bottom + 24),
          size: 10, color: AppColors.muted, align: TextAlign.right);
    }
  }

  /// y = f(x) across the plot; optional translucent fill under it.
  void curve(Canvas canvas, double Function(double) f, Color color,
      {double width = 2.5, bool fill = false, double? from, double? to, int steps = 160}) {
    final a = from ?? x0, b = to ?? x1;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final vx = a + (b - a) * i / steps;
      final vy = f(vx).clamp(y0, y1 * 1.2).toDouble();
      final p = Offset(x(vx), math.max(rect.top - 6, y(vy)));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    if (fill) {
      final area = Path.from(path)
        ..lineTo(x(b), y(y0))
        ..lineTo(x(a), y(y0))
        ..close();
      canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.25));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Histogram scaled as a density (area 1), so a pdf can be drawn on top.
  void densityBars(Canvas canvas, List<int> counts, double lo, double hi, Color color, {int? total}) {
    final n = total ?? counts.fold<int>(0, (a, b) => a + b);
    if (n == 0) return;
    final w = (hi - lo) / counts.length;
    for (var i = 0; i < counts.length; i++) {
      final d = counts[i] / (n * w);
      final top = math.max(rect.top, y(d));
      canvas.drawRect(
        Rect.fromLTRB(x(lo + i * w) + 0.5, top, x(lo + (i + 1) * w) - 0.5, y(y0)),
        Paint()..color = color,
      );
    }
  }

  /// Bars of height [values] centred on the integers [first], first + 1, …
  void intBars(Canvas canvas, List<double> values, int first, Color Function(int k) color, {double widthFrac = 0.7}) {
    final w = (x(1) - x(0)) * widthFrac;
    for (var i = 0; i < values.length; i++) {
      bar(canvas, x((first + i).toDouble()), w, y(y0), y(y0) - y(values[i].clamp(y0, y1)), color(first + i));
    }
  }

  /// Dots marking theoretical values on top of [intBars].
  void intDots(Canvas canvas, List<double> values, int first, Color color) {
    for (var i = 0; i < values.length; i++) {
      final c = at((first + i).toDouble(), values[i].clamp(y0, y1));
      canvas.drawCircle(c, 4, Paint()..color = color);
      ring(canvas, c, 4, Colors.white, width: 1.5);
    }
  }
}

String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

// ===== lib/lessons/linearity.dart =====
/// The hat-check puzzle: n hats handed back at random. How many people get
/// their own hat, on average?
class LinearitySim extends TickSim {
  LinearitySim({super.rng}) {
    _deal();
  }

  int n = 8;
  late List<int> hats; // hats[person] = whose hat they got
  int rounds = 0;
  int totalMatches = 0;
  List<int> matchCounts = List.filled(21, 0);

  int get matches => [
        for (var i = 0; i < n; i++)
          if (hats[i] == i) i
      ].length;
  double get average => rounds == 0 ? 0 : totalMatches / rounds;

  @override
  double get interval => rounds < 5 ? 1.2 : 0.08;

  void _deal() => hats = List.generate(n, (i) => i)..shuffle(rng);

  @override
  void tick() {
    _deal();
    rounds++;
    totalMatches += matches;
    matchCounts[matches]++;
  }

  @override
  void restart() {
    rounds = 0;
    totalMatches = 0;
    matchCounts = List.filled(21, 0);
    _deal();
  }
}

void _paintLinearity(Canvas canvas, Size size, LinearitySim sim) {
  final w = size.width;
  final h = size.height;

  // People in a row with the hat they got.
  final slot = (w - 20) / sim.n;
  final r = math.min(16.0, slot * 0.36);
  for (var i = 0; i < sim.n; i++) {
    final x = 10 + slot * (i + 0.5);
    final match = sim.hats[i] == i;
    canvas.drawCircle(Offset(x, 64), r, Paint()..color = AppColors.rainbow[i % 7].withValues(alpha: 0.85));
    label(canvas, '${i + 1}', Offset(x, 64), size: r * 0.8, color: Colors.white);
    // Hat on top, coloured by its owner.
    final hat = Rect.fromCenter(center: Offset(x, 64 - r - 8), width: r * 1.8, height: r * 0.8);
    roundRect(canvas, hat, AppColors.rainbow[sim.hats[i] % 7], radius: 4);
    label(canvas, '${sim.hats[i] + 1}', hat.center, size: r * 0.55, color: Colors.white);
    if (match) ring(canvas, Offset(x, 58), r + 14, AppColors.green, width: 3);
  }
  label(canvas, sim.rounds == 0 ? 'Hats handed back at random' : '${sim.matches} got their own hat', Offset(w / 2, 100),
      size: 14, color: sim.matches > 0 ? AppColors.green : AppColors.muted);

  // Histogram of matches per round.
  const left = 20.0;
  final right = w - 20;
  final baseline = h - 50;
  const top = 132.0;
  const maxShown = 6;
  final slotH = (right - left) / (maxShown + 1);
  final maxC = math.max(1, sim.matchCounts.take(maxShown + 1).reduce(math.max));
  for (var m = 0; m <= maxShown; m++) {
    bar(canvas, left + slotH * (m + 0.5), slotH * 0.7, baseline, (baseline - top) * sim.matchCounts[m] / maxC,
        m == 1 ? AppColors.green : AppColors.violet.withValues(alpha: 0.7));
    label(canvas, '$m', Offset(left + slotH * (m + 0.5), baseline + 10), size: 11, color: AppColors.muted);
  }
  label(canvas, 'own hats per round', Offset(w / 2, baseline + 24), size: 10, color: AppColors.muted);
  label(canvas, 'average so far: ${sim.average.toStringAsFixed(3)} (rounds: ${sim.rounds})', Offset(w / 2, h - 10),
      size: 13, color: AppColors.violet);
}

final LessonSpec linearityLesson = LessonSpec(
  id: 'linearity',
  chapterLabel: 'Ch 6 · Random variables',
  title: const [
    TitlePart('Any crowd, the answer is always '),
    TitlePart('1', AppColors.green),
  ],
  subtitle: 'Linearity of expectation · 2-minute animated lesson',
  createSim: () => LinearitySim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<LinearitySim>(sim, _paintLinearity),
  stats: (sim) {
    final l = sim as LinearitySim;
    return [
      StatChip('people', '${l.n}', AppColors.yellow),
      StatChip('rounds', '${l.rounds}', AppColors.violet),
      StatChip('avg own hats', l.average.toStringAsFixed(2), AppColors.green),
    ];
  },
  bigIdea: 'n people check their hats and get them back at random. Counting all the '
      'ways to match is hard, so don\'t. Give each person their own 0-or-1 score: '
      '1 if they got their hat. Each person gets their hat with chance 1/n, so '
      'each score averages 1/n. The expected total is the sum of the expected '
      'scores: n × 1/n = 1. This works even though the scores depend on each other.',
  formula: (sim) {
    final l = sim as LinearitySim;
    return 'E[X₁ + … + Xₙ] = E[X₁] + … + E[Xₙ] = ${l.n} × 1/${l.n} = 1';
  },
  tryItTitle: 'Try it: change the crowd size',
  buildTryIt: (sim) {
    final l = sim as LinearitySim;
    return watch(
      l,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '2',
            right: '20',
            value: l.n.toDouble(),
            min: 2,
            max: 20,
            divisions: 18,
            label: '${l.n} people',
            onChanged: (v) => l.change(() => l.n = v.round()),
          ),
          ControlRow(children: [ActionButton('Hand back 1,000 times', () => l.runMany(1000))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'E[X] = 3 and E[Y] = 5. What is E[X + Y]?',
      options: ['8', '15', 'Only 8 if independent', 'Can\'t tell'],
      answer: 0,
      explanation: 'Expectations always add, independent or not.',
    ),
    QuizQuestion(
      prompt: 'You roll 10 dice. What is the expected total?',
      options: ['10', '35', '60', '3.5'],
      answer: 1,
      explanation: 'Each die averages 3.5, so 10 × 3.5 = 35.',
    ),
    QuizQuestion(
      prompt: '100 letters are put into 100 addressed envelopes at random. Expected '
          'number in the right envelope?',
      options: ['0', '1', '10', '50'],
      answer: 1,
      explanation: 'Each letter is right with chance 1/100: 100 × 1/100 = 1.',
    ),
  ],
);

// ===== lib/lessons/monty_hall.dart =====
// ---------------------------------------------------------------------------
// Game logic (shared by the simulation and the play-it-yourself game)
// ---------------------------------------------------------------------------

/// One round of Monty Hall with three doors.
class MontyRound {
  MontyRound(math.Random rng, {int? pick})
      : car = rng.nextInt(3),
        pick = pick ?? rng.nextInt(3) {
    // The host opens a goat door that the player didn't pick.
    final choices = [
      for (var d = 0; d < 3; d++)
        if (d != this.pick && d != car) d
    ];
    opened = choices[rng.nextInt(choices.length)];
  }

  final int car;
  final int pick;
  late final int opened;

  /// The one door left to switch to.
  int get switchTo => 3 - pick - opened;

  bool get stayWins => pick == car;
  bool get switchWins => switchTo == car;
}

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

enum MontyPhase { pick, open, offer, reveal }

class MontyHallSim extends LessonSim {
  MontyHallSim({math.Random? rng}) : _rng = rng ?? math.Random() {
    round = MontyRound(_rng);
  }

  final math.Random _rng;
  late MontyRound round;

  int games = 0;
  int stayWins = 0;
  int switchWins = 0;

  /// Seconds into the current round.
  double t = 0;

  /// Phase start times within a round, at 1×.
  static const double openAt = 0.7;
  static const double offerAt = 1.4;
  static const double revealAt = 2.0;
  static const double roundTime = 2.9;

  /// The first rounds play slowly so each step can be followed, then the
  /// tally speeds up.
  double get _pace => games < 5 ? 1 : (games < 20 ? 3 : 12);

  MontyPhase get phase {
    if (t < openAt) return MontyPhase.pick;
    if (t < offerAt) return MontyPhase.open;
    if (t < revealAt) return MontyPhase.offer;
    return MontyPhase.reveal;
  }

  double get stayRate => games == 0 ? 0 : stayWins / games;
  double get switchRate => games == 0 ? 0 : switchWins / games;

  @override
  void advance(double dt) {
    t += dt * _pace;
    while (t >= roundTime) {
      t -= roundTime;
      _finishRound();
    }
    notifyListeners();
  }

  void _finishRound() {
    games++;
    if (round.stayWins) stayWins++;
    if (round.switchWins) switchWins++;
    round = MontyRound(_rng);
  }

  /// Plays [count] rounds instantly.
  void playMany(int count) {
    for (var i = 0; i < count; i++) {
      _finishRound();
    }
    t = 0;
    notifyListeners();
  }

  @override
  void step() {
    // Jump to the next phase boundary.
    const marks = [openAt, offerAt, revealAt, roundTime];
    final next = marks.firstWhere((m) => m > t + 1e-9);
    if (next >= roundTime) {
      t = 0;
      _finishRound();
    } else {
      t = next;
    }
    notifyListeners();
  }

  @override
  void reset() {
    games = 0;
    stayWins = 0;
    switchWins = 0;
    t = 0;
    round = MontyRound(_rng);
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Painting helpers (also used by the mini-game)
// ---------------------------------------------------------------------------

void paintDoor(
  Canvas canvas,
  Rect rect, {
  required int number,
  required bool open,
  required bool hasCar,
  bool picked = false,
  bool dimmed = false,
}) {
  final radius = Radius.circular(rect.width * 0.12);
  final frame = RRect.fromRectAndCorners(rect, topLeft: radius, topRight: radius);
  final doorColor = AppColors.rainbow[(number * 2) % AppColors.rainbow.length];

  if (open) {
    canvas.drawRRect(frame, Paint()..color = Colors.white);
    _emoji(canvas, hasCar ? '🚗' : '🐐', rect.center, rect.width * 0.5);
  } else {
    canvas.drawRRect(frame, Paint()..color = doorColor.withValues(alpha: dimmed ? 0.35 : 1));
    final inset = rect.deflate(rect.width * 0.14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, Radius.circular(rect.width * 0.06)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      Offset(rect.right - rect.width * 0.24, rect.center.dy),
      rect.width * 0.05,
      Paint()..color = AppColors.ink,
    );
    _label(canvas, '${number + 1}', rect.center.translate(0, -rect.height * 0.18), rect.width * 0.28, AppColors.ink);
  }

  if (picked) {
    canvas.drawRRect(
      frame.inflate(4),
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }
}

void _emoji(Canvas canvas, String e, Offset centre, double size) {
  final tp = TextPainter(
    text: TextSpan(text: e, style: TextStyle(fontSize: size)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
}

void _label(Canvas canvas, String text, Offset centre, double size, Color color,
    {FontWeight weight = FontWeight.w900}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
}

class MontyHallPainter extends CustomPainter {
  MontyHallPainter(this.sim) : super(repaint: sim);

  final MontyHallSim sim;

  static const double aspectRatio = 0.95;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = sim.round;
    final phase = sim.phase;

    // --- Doors ---------------------------------------------------------------
    final doorW = w * 0.24;
    final doorH = h * 0.36;
    final gap = (w - doorW * 3) / 4;
    final doorTop = h * 0.08;
    for (var d = 0; d < 3; d++) {
      final rect = Rect.fromLTWH(gap + d * (doorW + gap), doorTop, doorW, doorH);
      final open = phase == MontyPhase.reveal || (phase != MontyPhase.pick && d == r.opened);
      paintDoor(canvas, rect, number: d, open: open, hasCar: d == r.car, picked: d == r.pick, dimmed: d == r.opened);

      final under = Offset(rect.center.dx, rect.bottom + 16);
      if (d == r.pick) {
        _label(canvas, phase == MontyPhase.pick ? 'YOU' : 'STAY', under, 12, AppColors.blue);
      } else if (phase.index >= MontyPhase.offer.index && d == r.switchTo) {
        _label(canvas, 'SWITCH', under, 12, AppColors.pink);
      } else if (phase != MontyPhase.pick && d == r.opened) {
        _label(canvas, 'host opens', under, 11, AppColors.muted, weight: FontWeight.w700);
      }
    }

    // Caption for what is happening.
    final caption = switch (phase) {
      MontyPhase.pick => 'You pick door ${r.pick + 1}',
      MontyPhase.open => 'Host opens door ${r.opened + 1}: a goat',
      MontyPhase.offer => 'Stay on ${r.pick + 1} or switch to ${r.switchTo + 1}?',
      MontyPhase.reveal => r.switchWins ? 'Switching wins this one' : 'Staying wins this one',
    };
    _label(canvas, caption, Offset(w / 2, doorTop + doorH + 42), 15, AppColors.ink, weight: FontWeight.w800);

    // --- Win-rate bars -------------------------------------------------------
    final barLeft = w * 0.24;
    final barRight = w - 18;
    final barW = barRight - barLeft;
    final rows = [
      ('Stay', sim.stayRate, sim.stayWins, AppColors.blue),
      ('Switch', sim.switchRate, sim.switchWins, AppColors.pink),
    ];
    final firstBarY = h * 0.70;
    const barH = 26.0;
    for (var i = 0; i < rows.length; i++) {
      final (name, rate, wins, color) = rows[i];
      final y = firstBarY + i * (barH + 18);
      _label(canvas, name, Offset(barLeft / 2 + 4, y + barH / 2), 14, AppColors.ink);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barLeft, y, barW, barH), const Radius.circular(10)),
        Paint()..color = Colors.white,
      );
      if (rate > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(barLeft, y, barW * rate, barH), const Radius.circular(10)),
          Paint()..color = color,
        );
      }
      _label(canvas, '${(rate * 100).toStringAsFixed(0)}% · $wins wins', Offset(barLeft + barW * 0.5, y + barH / 2), 12,
          AppColors.ink);
    }
    // 1/3 and 2/3 reference ticks.
    final tick = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    for (final f in [1 / 3, 2 / 3]) {
      final x = barLeft + barW * f;
      canvas.drawLine(Offset(x, firstBarY - 6), Offset(x, firstBarY + 2 * barH + 24), tick);
      _label(canvas, f < 0.5 ? '⅓' : '⅔', Offset(x, firstBarY - 14), 12, AppColors.muted);
    }
  }

  @override
  bool shouldRepaint(covariant MontyHallPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec montyHallLesson = LessonSpec(
  id: 'monty_hall',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('Should you '),
    TitlePart('switch', AppColors.pink),
    TitlePart(' doors? '),
    TitlePart('Always.', AppColors.blue),
  ],
  subtitle: 'The Monty Hall puzzle · 3-minute animated lesson',
  createSim: () => MontyHallSim(),
  visualAspectRatio: MontyHallPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: MontyHallPainter(sim as MontyHallSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final m = sim as MontyHallSim;
    return [
      StatChip('games', '${m.games}', AppColors.yellow),
      StatChip('stay wins', '${(m.stayRate * 100).toStringAsFixed(0)}%', AppColors.blue),
      StatChip('switch wins', '${(m.switchRate * 100).toStringAsFixed(0)}%', AppColors.pink),
    ];
  },
  bigIdea: 'Your first pick is right only 1 time in 3, and the host opening a '
      'goat door cannot change that. So the other closed door holds the car '
      'the remaining 2 times in 3. The host knows where the car is, and that '
      'knowledge leaks into the door he leaves shut.',
  formula: (sim) {
    final m = sim as MontyHallSim;
    return 'P(win | switch) = 2/3 ≈ 0.667 · seen ${m.switchRate.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: play the game yourself',
  buildTryIt: (sim) => MontyGame(sim: sim as MontyHallSim),
  quiz: const [
    QuizQuestion(
      prompt: 'You pick door 1. The host opens door 3 and shows a goat. '
          'What is the chance the car is behind door 2?',
      options: ['1/3', '1/2', '2/3', '1'],
      answer: 2,
      explanation: 'Door 1 keeps its original 1/3. All of the remaining 2/3 '
          'now sits on door 2, the only other closed door.',
    ),
    QuizQuestion(
      prompt: 'Why is it not 50/50 once two doors are left?',
      options: [
        'Because the host knows where the car is and never reveals it',
        'Because door numbers matter',
        'Because cars are heavier than goats',
        'It actually is 50/50',
      ],
      answer: 0,
      explanation: 'The host\'s choice is forced by where the car is. A random '
          'host who might reveal the car would make it 50/50.',
    ),
    QuizQuestion(
      prompt: 'With 100 doors, you pick one, and the host opens 98 goat doors. '
          'Chance of winning if you switch?',
      options: ['1/100', '1/2', '98/100', '99/100'],
      answer: 3,
      explanation: 'Your pick is right 1 time in 100. Every other time, the car '
          'is behind the one door the host left closed.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Play-it-yourself mini-game
// ---------------------------------------------------------------------------

class MontyGame extends StatefulWidget {
  const MontyGame({super.key, required this.sim, this.rng});
  final MontyHallSim sim;
  final math.Random? rng;

  @override
  State<MontyGame> createState() => _MontyGameState();
}

enum _GameStep { pick, decide, done }

class _MontyGameState extends State<MontyGame> {
  late final math.Random _rng = widget.rng ?? math.Random();
  MontyRound? _round;
  _GameStep _step = _GameStep.pick;
  int? _final;

  int _switchPlays = 0, _switchWins = 0, _stayPlays = 0, _stayWins = 0;

  void _pick(int door) {
    if (_step != _GameStep.pick) return;
    setState(() {
      _round = MontyRound(_rng, pick: door);
      _step = _GameStep.decide;
    });
  }

  void _decide({required bool switched}) {
    final r = _round!;
    setState(() {
      _final = switched ? r.switchTo : r.pick;
      final won = _final == r.car;
      if (switched) {
        _switchPlays++;
        if (won) _switchWins++;
      } else {
        _stayPlays++;
        if (won) _stayWins++;
      }
      _step = _GameStep.done;
    });
  }

  void _again() => setState(() {
        _round = null;
        _final = null;
        _step = _GameStep.pick;
      });

  String get _prompt => switch (_step) {
        _GameStep.pick => 'Tap a door to pick it.',
        _GameStep.decide => 'The host opened door ${_round!.opened + 1}: a goat. Stay or switch?',
        _GameStep.done => _final == _round!.car ? 'You won the car! 🎉' : 'A goat. Try again?',
      };

  @override
  Widget build(BuildContext context) {
    final r = _round;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_prompt, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var d = 0; d < 3; d++) ...[
              if (d > 0) const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Door ${d + 1}',
                  child: GestureDetector(
                    key: ValueKey('monty-door-$d'),
                    onTap: () => _pick(d),
                    child: AspectRatio(
                      aspectRatio: 0.7,
                      child: CustomPaint(
                        painter: _DoorPainter(
                          number: d,
                          open: r != null && (_step == _GameStep.done || d == r.opened),
                          hasCar: r != null && d == r.car,
                          picked: r != null && d == (_final ?? r.pick),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (_step == _GameStep.decide)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
                  onPressed: () => _decide(switched: false),
                  child: const Text('Stay', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.pink),
                  onPressed: () => _decide(switched: true),
                  child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          )
        else if (_step == _GameStep.done)
          FilledButton.tonal(
            onPressed: _again,
            child: const Text('Play again', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        const SizedBox(height: 10),
        Text(
          'You: switched $_switchWins/$_switchPlays won · stayed $_stayWins/$_stayPlays won',
          style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => widget.sim.playMany(1000),
            child: const Text('Simulate 1,000 more games above'),
          ),
        ),
      ],
    );
  }
}

class _DoorPainter extends CustomPainter {
  _DoorPainter({required this.number, required this.open, required this.hasCar, required this.picked});

  final int number;
  final bool open;
  final bool hasCar;
  final bool picked;

  @override
  void paint(Canvas canvas, Size size) {
    paintDoor(canvas, (Offset.zero & size).deflate(5), number: number, open: open, hasCar: hasCar, picked: picked);
  }

  @override
  bool shouldRepaint(covariant _DoorPainter old) =>
      old.open != open || old.hasCar != hasCar || old.picked != picked || old.number != number;
}

// ===== lib/lessons/multiplication_principle.dart =====
/// Outfits: shirts × trousers × shoes, revealed one leaf at a time.
class OutfitSim extends TickSim {
  OutfitSim({super.rng});

  int shirts = 3, trousers = 2, shoes = 2;
  int revealed = 0;

  int get total => shirts * trousers * shoes;

  @override
  double get interval => total > 18 ? 0.18 : 0.4;

  @override
  void tick() {
    revealed++;
    if (revealed > total + 6) revealed = 0; // hold the full tree, then grow again
  }

  @override
  void restart() => revealed = 0;
}

const _shirtColors = [AppColors.pink, AppColors.blue, AppColors.green, AppColors.orange];
const _trouserNames = ['jeans', 'chinos', 'shorts'];
const _shoeNames = ['sneakers', 'sandals', 'boots'];

void _paintOutfits(Canvas canvas, Size size, OutfitSim sim) {
  final w = size.width;
  final h = size.height;
  final total = sim.total;
  const top = 28.0;
  final bottom = h - 10;
  final leafGap = (bottom - top) / total;
  double leafY(int i) => top + leafGap * (i + 0.5);

  final x0 = 18.0, x1 = w * 0.3, x2 = w * 0.58, x3 = w * 0.84;
  label(canvas, 'shirt', Offset(x1, 12), size: 11, color: AppColors.muted);
  label(canvas, 'trousers', Offset(x2, 12), size: 11, color: AppColors.muted);
  label(canvas, 'shoes', Offset(x3, 12), size: 11, color: AppColors.muted);

  final perShirt = sim.trousers * sim.shoes;
  final rootY = (top + bottom) / 2;
  final shown = sim.revealed.clamp(0, total);
  canvas.drawCircle(Offset(x0, rootY), 6, Paint()..color = AppColors.ink);

  for (var s = 0; s < sim.shirts; s++) {
    final firstLeaf = s * perShirt;
    if (shown <= firstLeaf) continue;
    final sy = (leafY(firstLeaf) + leafY(firstLeaf + perShirt - 1)) / 2;
    final color = _shirtColors[s];
    line(canvas, Offset(x0, rootY), Offset(x1, sy), color.withValues(alpha: 0.6), width: 2.5);
    canvas.drawCircle(Offset(x1, sy), 9, Paint()..color = color);
    for (var t = 0; t < sim.trousers; t++) {
      final tFirst = firstLeaf + t * sim.shoes;
      if (shown <= tFirst) continue;
      final ty = (leafY(tFirst) + leafY(tFirst + sim.shoes - 1)) / 2;
      line(canvas, Offset(x1, sy), Offset(x2, ty), color.withValues(alpha: 0.45), width: 2);
      canvas.drawCircle(Offset(x2, ty), 6, Paint()..color = color.withValues(alpha: 0.7));
      if (leafGap * sim.shoes > 14) {
        label(canvas, _trouserNames[t], Offset(x2 - 8, ty - 10),
            size: 9, color: AppColors.muted, align: TextAlign.right);
      }
      for (var k = 0; k < sim.shoes; k++) {
        final leaf = tFirst + k;
        if (shown <= leaf) continue;
        final ly = leafY(leaf);
        line(canvas, Offset(x2, ty), Offset(x3, ly), color.withValues(alpha: 0.3), width: 1.5);
        final isNew = leaf == shown - 1 && sim.revealed <= total;
        canvas.drawCircle(Offset(x3, ly), isNew ? 6 : 4, Paint()..color = isNew ? AppColors.ink : color);
        if (leafGap > 11) {
          label(canvas, _shoeNames[k], Offset(x3 + 9, ly), size: 9, color: AppColors.muted, align: TextAlign.left);
        }
      }
    }
  }
  label(canvas, '$shown', Offset(w - 10, h - 12), size: 16, color: AppColors.ink, align: TextAlign.right);
}

final LessonSpec multiplicationPrincipleLesson = LessonSpec(
  id: 'multiplication_principle',
  chapterLabel: 'Ch 4 · Counting',
  title: const [
    TitlePart('3 shirts, 2 trousers, 2 shoes: how many '),
    TitlePart('outfits', AppColors.pink),
    TitlePart('?'),
  ],
  subtitle: 'The multiplication principle · 2-minute animated lesson',
  createSim: () => OutfitSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<OutfitSim>(sim, _paintOutfits),
  stats: (sim) {
    final o = sim as OutfitSim;
    return [
      StatChip('outfits so far', '${o.revealed.clamp(0, o.total)}', AppColors.yellow),
      StatChip('total', '${o.total}', AppColors.pink),
    ];
  },
  bigIdea: 'Every shirt can go with every pair of trousers, so each shirt branch '
      'splits into the same number of trouser branches, and each of those splits '
      'again for shoes. When choices are made one after another and don\'t limit '
      'each other, multiply the number of options at each step.',
  formula: (sim) {
    final o = sim as OutfitSim;
    return '${o.shirts} × ${o.trousers} × ${o.shoes} = ${o.total} outfits';
  },
  tryItTitle: 'Try it: change your wardrobe',
  buildTryIt: (sim) {
    final o = sim as OutfitSim;
    Widget row(String name, int value, int max, void Function(int) set) => LabeledSlider(
          left: '$name ${value.toString().padLeft(1)}',
          right: '$max',
          value: value.toDouble(),
          min: 1,
          max: max.toDouble(),
          divisions: max - 1,
          onChanged: (v) => o.change(() => set(v.round())),
        );
    return watch(
      o,
      () => Column(
        children: [
          row('shirts', o.shirts, 4, (v) => o.shirts = v),
          row('trousers', o.trousers, 3, (v) => o.trousers = v),
          row('shoes', o.shoes, 3, (v) => o.shoes = v),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A café offers 4 drinks and 3 snacks. How many drink-and-snack combos?',
      options: ['7', '12', '43', '64'],
      answer: 1,
      explanation: 'Each of the 4 drinks pairs with each of the 3 snacks: 4 × 3 = 12.',
    ),
    QuizQuestion(
      prompt: 'A PIN has 4 digits, each 0–9. How many PINs are possible?',
      options: ['40', '1,000', '10,000', '5,040'],
      answer: 2,
      explanation: '10 choices for each of 4 digits: 10 × 10 × 10 × 10 = 10,000.',
    ),
    QuizQuestion(
      prompt: 'Number plates use 2 letters (A–Z) then 2 digits. How many plates?',
      options: ['52', '676', '67,600', '1,000,000'],
      answer: 2,
      explanation: '26 × 26 × 10 × 10 = 67,600.',
    ),
  ],
);

// ===== lib/lessons/multiplication_rule.dart =====
/// Area model: a unit square. A is a strip of width P(A); inside it, B fills
/// height P(B | A). Darts estimate the area of "A and B".
class MultRuleSim extends TickSim {
  MultRuleSim({super.rng});

  /// P(rain).
  double pA = 0.3;

  /// P(late | rain).
  double pBgivenA = 0.6;

  /// P(late | no rain), drawn to the right of the strip.
  static const double pBgivenNotA = 0.1;

  final List<Offset> darts = [];
  int total = 0, inA = 0, inAB = 0;

  double get pAB => pA * pBgivenA;

  bool isA(Offset p) => p.dx < pA;
  bool isB(Offset p) => isA(p) ? p.dy > 1 - pBgivenA : p.dy > 1 - pBgivenNotA;

  @override
  double get interval => total < 20 ? 0.12 : 0.02;

  @override
  void tick() {
    final p = Offset(rng.nextDouble(), rng.nextDouble());
    total++;
    if (isA(p)) {
      inA++;
      if (isB(p)) inAB++;
    }
    if (darts.length < 600) darts.add(p);
  }

  @override
  void restart() {
    darts.clear();
    total = inA = inAB = 0;
  }
}

void _paintMultRule(Canvas canvas, Size size, MultRuleSim sim) {
  final w = size.width;
  final h = size.height;
  const pad = 16.0;
  final side = math.min(w - pad * 2, h - 80);
  final o = Offset((w - side) / 2, 30);
  Offset toCanvas(Offset p) => o + Offset(p.dx * side, p.dy * side);

  roundRect(canvas, o & Size(side, side), Colors.white, radius: 6);
  // A strip (rain) and the B part inside it (late).
  final aRect = Rect.fromLTWH(o.dx, o.dy, side * sim.pA, side);
  canvas.drawRect(aRect, Paint()..color = AppColors.blue.withValues(alpha: 0.16));
  final abRect = Rect.fromLTWH(o.dx, o.dy + side * (1 - sim.pBgivenA), side * sim.pA, side * sim.pBgivenA);
  canvas.drawRect(abRect, Paint()..color = AppColors.violet.withValues(alpha: 0.35));
  final notAB = Rect.fromLTWH(o.dx + side * sim.pA, o.dy + side * (1 - MultRuleSim.pBgivenNotA), side * (1 - sim.pA),
      side * MultRuleSim.pBgivenNotA);
  canvas.drawRect(notAB, Paint()..color = AppColors.orange.withValues(alpha: 0.25));
  line(canvas, Offset(aRect.right, o.dy), Offset(aRect.right, o.dy + side), AppColors.blue, width: 2.5);

  for (final p in sim.darts) {
    final a = sim.isA(p), b = sim.isB(p);
    canvas.drawCircle(toCanvas(p), 2.2,
        Paint()..color = a && b ? AppColors.violet : (a ? AppColors.blue : (b ? AppColors.orange : AppColors.peg)));
  }

  label(canvas, 'rain ${(sim.pA * 100).round()}%', Offset(aRect.center.dx, o.dy - 10), size: 11, color: AppColors.blue);
  label(canvas, 'no rain', Offset((aRect.right + o.dx + side) / 2, o.dy - 10), size: 11, color: AppColors.muted);
  if (abRect.width > 40) {
    label(canvas, 'rain and late', abRect.center, size: 11, color: AppColors.ink);
  }
  label(canvas, '← P(late | rain) = ${(sim.pBgivenA * 100).round()}% of the strip →', Offset(w / 2, o.dy + side + 16),
      size: 11, color: AppColors.violet);
  label(canvas, 'Darts in purple: ${sim.total == 0 ? 0 : (sim.inAB / sim.total).toStringAsFixed(3)} of ${sim.total}',
      Offset(w / 2, h - 12),
      size: 12, color: AppColors.muted);
}

final LessonSpec multiplicationRuleLesson = LessonSpec(
  id: 'multiplication_rule',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('A '),
    TitlePart('slice', AppColors.blue),
    TitlePart(' of a '),
    TitlePart('slice', AppColors.violet),
  ],
  subtitle: 'The multiplication rule · 2-minute animated lesson',
  createSim: () => MultRuleSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<MultRuleSim>(sim, _paintMultRule),
  stats: (sim) {
    final m = sim as MultRuleSim;
    return [
      StatChip('P(rain)', m.pA.toStringAsFixed(2), AppColors.blue),
      StatChip('P(late | rain)', m.pBgivenA.toStringAsFixed(2), AppColors.violet),
      StatChip('P(both)', m.pAB.toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'The square is every possible day. The blue strip is the share of rainy '
      'days. Inside that strip, the purple part is the share of rainy days when '
      'you\'re late. Its area is width × height: a fraction of a fraction. That is '
      'the multiplication rule, and it works whether or not the events are '
      'independent, because the height is conditional on A.',
  formula: (sim) {
    final m = sim as MultRuleSim;
    return 'P(A and B) = P(A) × P(B | A) = ${m.pA.toStringAsFixed(2)} × ${m.pBgivenA.toStringAsFixed(2)} '
        '= ${m.pAB.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: resize the slices',
  buildTryIt: (sim) {
    final m = sim as MultRuleSim;
    return watch(
      m,
      () => Column(
        children: [
          LabeledSlider(
            left: 'P(rain)',
            right: '',
            value: m.pA,
            min: 0.1,
            max: 0.9,
            divisions: 8,
            label: m.pA.toStringAsFixed(1),
            onChanged: (v) => m.change(() => m.pA = v),
          ),
          LabeledSlider(
            left: 'P(late | rain)',
            right: '',
            value: m.pBgivenA,
            min: 0.1,
            max: 0.9,
            divisions: 8,
            label: m.pBgivenA.toStringAsFixed(1),
            onChanged: (v) => m.change(() => m.pBgivenA = v),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: '40% of students take the bus, and 25% of bus-takers are late. What share of '
          'all students take the bus and are late?',
      options: ['65%', '15%', '10%', '25%'],
      answer: 2,
      explanation: '0.4 × 0.25 = 0.10.',
    ),
    QuizQuestion(
      prompt: 'Draw 2 cards without replacement. P(both aces)?',
      options: ['4/52 × 4/52', '4/52 × 3/51', '4/52 + 3/51', '2/52'],
      answer: 1,
      explanation: 'P(first ace) × P(second ace | first ace) = 4/52 × 3/51.',
    ),
    QuizQuestion(
      prompt: 'When does P(A and B) = P(A) × P(B)?',
      options: ['Always', 'When A and B are independent', 'When they are mutually exclusive', 'Never'],
      answer: 1,
      explanation: 'Then P(B | A) = P(B), so the general rule simplifies.',
    ),
  ],
);

// ===== lib/lessons/mutually_exclusive.dart =====
const List<String> kSuits = ['♥', '♦', '♣', '♠'];
const List<String> kRanks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

/// Event pairs on a 52-card deck: card index = suit * 13 + rank.
enum CardPair { heartsSpades, heartsKings, redFace, acesKings }

const Map<CardPair, String> kCardPairNames = {
  CardPair.heartsSpades: '♥ or ♠',
  CardPair.heartsKings: '♥ or King',
  CardPair.redFace: 'Red or face card',
  CardPair.acesKings: 'Ace or King',
};

bool _inA(CardPair p, int card) {
  final suit = card ~/ 13, rank = card % 13;
  return switch (p) {
    CardPair.heartsSpades || CardPair.heartsKings => suit == 0,
    CardPair.redFace => suit <= 1,
    CardPair.acesKings => rank == 0,
  };
}

bool _inB(CardPair p, int card) {
  final suit = card ~/ 13, rank = card % 13;
  return switch (p) {
    CardPair.heartsSpades => suit == 3,
    CardPair.heartsKings || CardPair.acesKings => rank == 12,
    CardPair.redFace => rank >= 10,
  };
}

class MutualSim extends TickSim {
  MutualSim({super.rng});

  CardPair pair = CardPair.heartsSpades;
  int draws = 0;
  int hits = 0;
  int last = -1;

  bool inA(int c) => _inA(pair, c);
  bool inB(int c) => _inB(pair, c);
  int get countA => List.generate(52, (c) => c).where(inA).length;
  int get countB => List.generate(52, (c) => c).where(inB).length;
  int get countBoth => List.generate(52, (c) => c).where((c) => inA(c) && inB(c)).length;
  bool get exclusive => countBoth == 0;

  @override
  double get interval => draws < 10 ? 0.6 : 0.08;

  @override
  void tick() {
    last = rng.nextInt(52);
    draws++;
    if (inA(last) || inB(last)) hits++;
  }

  @override
  void restart() {
    draws = 0;
    hits = 0;
    last = -1;
  }
}

void _paintMutual(Canvas canvas, Size size, MutualSim sim) {
  final w = size.width;
  final h = size.height;
  final cellW = (w - 20) / 13;
  final cellH = cellW * 1.3;
  const top = 20.0;
  for (var c = 0; c < 52; c++) {
    final suit = c ~/ 13, rank = c % 13;
    final r = Rect.fromLTWH(10 + rank * cellW + 1.5, top + suit * (cellH + 4), cellW - 3, cellH);
    final a = sim.inA(c), b = sim.inB(c);
    final fill = a && b
        ? AppColors.violet
        : a
            ? AppColors.pink
            : b
                ? AppColors.cyan
                : Colors.white;
    roundRect(canvas, r, fill.withValues(alpha: (a || b) ? 0.85 : 1), radius: 4);
    if (c == sim.last) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(5)),
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final red = suit <= 1;
    label(canvas, kRanks[rank], r.center.translate(0, -cellH * 0.16),
        size: cellW * 0.36, color: (a || b) ? Colors.white : (red ? AppColors.pink : AppColors.ink));
    label(canvas, kSuits[suit], r.center.translate(0, cellH * 0.2),
        size: cellW * 0.36, color: (a || b) ? Colors.white : (red ? AppColors.pink : AppColors.ink));
  }

  final y = top + 4 * (cellH + 4) + 18;
  final items = [
    ('A only', AppColors.pink, sim.countA - sim.countBoth),
    ('B only', AppColors.cyan, sim.countB - sim.countBoth),
    ('both', AppColors.violet, sim.countBoth),
  ];
  for (var i = 0; i < items.length; i++) {
    final (name, color, n) = items[i];
    final x = 14 + i * (w - 28) / 3;
    roundRect(canvas, Rect.fromLTWH(x, y - 8, 16, 16), color, radius: 4);
    label(canvas, '$name: $n', Offset(x + 22, y), size: 12, align: TextAlign.left);
  }
  label(
      canvas,
      sim.exclusive ? 'No card is in both: mutually exclusive' : '${sim.countBoth} cards are in both: they overlap',
      Offset(w / 2, y + 28),
      size: 14,
      color: sim.exclusive ? AppColors.green : AppColors.violet);
  label(
      canvas,
      'Drawn ${sim.draws} cards (with replacement) · ${sim.draws == 0 ? 0 : (sim.hits / sim.draws * 100).toStringAsFixed(1)}% were A or B',
      Offset(w / 2, h - 14),
      size: 11,
      color: AppColors.muted);
}

final LessonSpec mutuallyExclusiveLesson = LessonSpec(
  id: 'mutually_exclusive',
  chapterLabel: 'Ch 3 · Probability basics',
  title: const [
    TitlePart('Can both happen '),
    TitlePart('at once', AppColors.violet),
    TitlePart('?'),
  ],
  subtitle: 'Mutually exclusive events · 2-minute animated lesson',
  createSim: () => MutualSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<MutualSim>(sim, _paintMutual),
  stats: (sim) {
    final m = sim as MutualSim;
    return [
      StatChip('P(A)', '${m.countA}/52', AppColors.pink),
      StatChip('P(B)', '${m.countB}/52', AppColors.cyan),
      StatChip('P(both)', '${m.countBoth}/52', AppColors.violet),
    ];
  },
  bigIdea: 'Two events are mutually exclusive if they can\'t happen together: one '
      'card can\'t be a heart and a spade. Then the chance of either is just the '
      'sum. But a card can be a heart and a king, so adding 13 + 4 counts the king '
      'of hearts twice. Purple cards show the overlap you must subtract.',
  formula: (sim) {
    final m = sim as MutualSim;
    final either = m.countA + m.countB - m.countBoth;
    return 'P(A or B) = ${m.countA}/52 + ${m.countB}/52 − ${m.countBoth}/52 = $either/52';
  },
  tryItTitle: 'Try it: pick two events',
  buildTryIt: (sim) {
    final m = sim as MutualSim;
    return watch(
      m,
      () => ChoiceRow<CardPair>(
        options: kCardPairNames,
        selected: m.pair,
        onSelected: (v) => m.change(() => m.pair = v),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Which pair of events is mutually exclusive for one die roll?',
      options: ['Even and 6', 'Odd and less than 3', 'Even and odd', 'Prime and odd'],
      answer: 2,
      explanation: 'No number is both even and odd. All the other pairs share at least one outcome.',
    ),
    QuizQuestion(
      prompt: 'Draw one card. What is P(heart or spade)?',
      options: ['1/4', '1/2', '13/52 × 13/52', '3/4'],
      answer: 1,
      explanation: 'They can\'t both happen, so add: 13/52 + 13/52 = 26/52 = 1/2.',
    ),
    QuizQuestion(
      prompt: 'Draw one card. What is P(heart or king)?',
      options: ['17/52', '16/52', '4/52', '13/52'],
      answer: 1,
      explanation: '13 hearts + 4 kings − 1 king of hearts counted twice = 16/52.',
    ),
  ],
);

// ===== lib/lessons/outliers.dart =====
class OutlierSim extends TickSim {
  OutlierSim({super.rng});

  static const int target = 30;

  /// (value, vertical jitter 0–1)
  final List<(double, double)> points = [];

  /// Fence multiplier: outliers are beyond k × IQR from the box.
  double k = 1.5;

  @override
  double get interval => 0.35;

  List<double> get values => [for (final p in points) p.$1];
  double get q1 => quantileOf(values, 0.25);
  double get q3 => quantileOf(values, 0.75);
  double get iqr => q3 - q1;
  double get lowFence => q1 - k * iqr;
  double get highFence => q3 + k * iqr;
  bool isOutlier(double v) => points.length >= 4 && (v < lowFence || v > highFence);
  int get outlierCount => values.where(isOutlier).length;

  void _add(double v) => points.add((v.clamp(0, 100).toDouble(), rng.nextDouble()));

  @override
  void tick() {
    if (points.length >= target) return;
    // Mostly typical values, with the odd stray one.
    _add(rng.nextDouble() < 0.07
        ? (rng.nextBool() ? 92 + rng.nextDouble() * 8 : rng.nextDouble() * 8)
        : 50 + normalDraw(rng) * 9);
  }

  void addExtreme() {
    _add(rng.nextBool() ? 95 + rng.nextDouble() * 5 : rng.nextDouble() * 5);
    notifyListeners();
  }

  void setK(double value) {
    k = value;
    notifyListeners();
  }

  @override
  void restart() => points.clear();
}

void _paintOutliers(Canvas canvas, Size size, OutlierSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 16.0;
  final right = w - 16;
  double xFor(double v) => left + v / 100 * (right - left);

  final stripTop = 30.0;
  final stripBottom = h * 0.5;
  final boxY = h * 0.66;
  final axisY = h - 40;

  // Fence zone.
  if (sim.points.length >= 4) {
    final lo = xFor(sim.lowFence.clamp(0, 100));
    final hi = xFor(sim.highFence.clamp(0, 100));
    roundRect(canvas, Rect.fromLTRB(lo, stripTop - 12, hi, axisY), AppColors.green.withValues(alpha: 0.12), radius: 10);
    dashedLine(canvas, Offset(lo, stripTop - 12), Offset(lo, axisY), AppColors.green);
    dashedLine(canvas, Offset(hi, stripTop - 12), Offset(hi, axisY), AppColors.green);
    label(canvas, 'fence', Offset(lo, axisY + 12), size: 10, color: AppColors.green);
    label(canvas, 'fence', Offset(hi, axisY + 12), size: 10, color: AppColors.green);
  }

  // Data strip.
  for (final (v, j) in sim.points) {
    final c = Offset(xFor(v), stripTop + j * (stripBottom - stripTop));
    final out = sim.isOutlier(v);
    canvas.drawCircle(c, 6, Paint()..color = out ? AppColors.pink : AppColors.blue.withValues(alpha: 0.75));
    if (out) ring(canvas, c, 10, AppColors.pink, width: 2.5);
  }

  // Box plot of the same data.
  if (sim.points.length >= 4) {
    final inliers = sim.values.where((v) => !sim.isOutlier(v)).toList();
    final lo = inliers.reduce(math.min);
    final hi = inliers.reduce(math.max);
    line(canvas, Offset(xFor(lo), boxY), Offset(xFor(sim.q1), boxY), AppColors.ink);
    line(canvas, Offset(xFor(sim.q3), boxY), Offset(xFor(hi), boxY), AppColors.ink);
    line(canvas, Offset(xFor(lo), boxY - 8), Offset(xFor(lo), boxY + 8), AppColors.ink);
    line(canvas, Offset(xFor(hi), boxY - 8), Offset(xFor(hi), boxY + 8), AppColors.ink);
    final box = Rect.fromLTRB(xFor(sim.q1), boxY - 16, xFor(sim.q3), boxY + 16);
    roundRect(canvas, box, AppColors.yellow, radius: 6);
    final med = xFor(quantileOf(sim.values, 0.5));
    line(canvas, Offset(med, boxY - 16), Offset(med, boxY + 16), AppColors.ink, width: 3);
    label(canvas, 'IQR', Offset(box.center.dx, boxY - 26), size: 11, color: AppColors.muted);
    for (final v in sim.values.where(sim.isOutlier)) {
      label(canvas, '×', Offset(xFor(v), boxY), size: 16, color: AppColors.pink);
    }
  }

  line(canvas, Offset(left, axisY), Offset(right, axisY), AppColors.peg);
  for (var v = 0; v <= 100; v += 25) {
    label(canvas, '$v', Offset(xFor(v.toDouble()), axisY + 26), size: 10, color: AppColors.muted);
  }
}

final LessonSpec outliersLesson = LessonSpec(
  id: 'outliers',
  chapterLabel: 'Ch 1 · Data & averages',
  title: const [
    TitlePart('When is a value '),
    TitlePart('too weird', AppColors.pink),
    TitlePart(' to trust?'),
  ],
  subtitle: 'Outliers · 2-minute animated lesson',
  createSim: () => OutlierSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<OutlierSim>(sim, _paintOutliers),
  stats: (sim) {
    final o = sim as OutlierSim;
    return [
      StatChip('values', '${o.points.length}', AppColors.yellow),
      StatChip('IQR', o.points.length >= 4 ? o.iqr.toStringAsFixed(1) : '…', AppColors.green),
      StatChip('outliers', '${o.outlierCount}', AppColors.pink),
    ];
  },
  bigIdea: 'The box holds the middle half of the data; its width is the IQR. A '
      'common rule flags any value more than 1.5 IQRs beyond the box as an '
      'outlier. An outlier isn\'t automatically a mistake: check it. It might be '
      'a typo, or the most interesting value in the data.',
  formula: (sim) {
    final o = sim as OutlierSim;
    if (o.points.length < 4) return 'fences = Q1 − k·IQR and Q3 + k·IQR';
    return 'fences = ${o.q1.toStringAsFixed(0)} − ${o.k.toStringAsFixed(1)}×${o.iqr.toStringAsFixed(0)} '
        'and ${o.q3.toStringAsFixed(0)} + ${o.k.toStringAsFixed(1)}×${o.iqr.toStringAsFixed(0)}';
  },
  tryItTitle: 'Try it: move the fences',
  buildTryIt: (sim) {
    final o = sim as OutlierSim;
    return watch(
      o,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'strict',
            right: 'loose',
            value: o.k,
            min: 0.5,
            max: 3,
            divisions: 5,
            label: 'k = ${o.k}',
            onChanged: o.setK,
          ),
          ControlRow(
            children: [
              ValueTag('k = ${o.k.toStringAsFixed(1)}'),
              ActionButton('Add extreme value', o.addExtreme),
            ],
          ),
          const SizedBox(height: 8),
          const TryNote('Strict fences flag normal values; loose ones miss real oddities. 1.5 is the usual choice.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Q1 = 20, Q3 = 30. With the 1.5 × IQR rule, which value is an outlier?',
      options: ['8', '42', '47', '25'],
      answer: 2,
      explanation: 'IQR = 30 − 20 = 10, so the fences are 20 − 15 = 5 and 30 + 15 = 45. '
          'Only 47 is outside them.',
    ),
    QuizQuestion(
      prompt: 'You find an outlier in your data. What should you do first?',
      options: ['Delete it', 'Check where it came from', 'Double it', 'Ignore the rest of the data'],
      answer: 1,
      explanation: 'It could be a typo or a real, important case. Investigate before '
          'removing anything.',
    ),
    QuizQuestion(
      prompt: 'Which summary is barely affected by an outlier?',
      options: ['Mean', 'Range', 'Median', 'Standard deviation'],
      answer: 2,
      explanation: 'The median only depends on the middle of the sorted data.',
    ),
  ],
);

// ===== lib/lessons/percentiles.dart =====
class PercentileSim extends TickSim {
  PercentileSim({super.rng}) {
    restart();
  }

  static const int n = 21;

  List<int> values = [];

  /// Bubble-sort position: comparing values[j] and values[j + 1] in pass [pass].
  int pass = 0;
  int j = 0;
  bool sorted = false;

  /// Percentile picked with the slider (0–100).
  double percentile = 75;

  @override
  double get interval => sorted ? 1 : 0.035;

  @override
  void tick() {
    if (sorted) return;
    if (values[j] > values[j + 1]) {
      final t = values[j];
      values[j] = values[j + 1];
      values[j + 1] = t;
    }
    j++;
    if (j >= n - 1 - pass) {
      j = 0;
      pass++;
      if (pass >= n - 1) sorted = true;
    }
  }

  /// Finishes the sort instantly.
  void sortNow() {
    values.sort();
    sorted = true;
    notifyListeners();
  }

  @override
  void restart() {
    values = List.generate(n, (_) => 10 + rng.nextInt(90));
    pass = 0;
    j = 0;
    sorted = false;
  }

  void setPercentile(double p) {
    percentile = p;
    notifyListeners();
  }

  double quantile(double q) => quantileOf(values, q);
}

void _paintPercentiles(Canvas canvas, Size size, PercentileSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 14.0;
  final right = w - 14;
  final baseline = h - 56;
  const top = 34.0;
  final slot = (right - left) / PercentileSim.n;
  final pos = sim.percentile / 100 * (PercentileSim.n - 1);

  label(canvas, sim.sorted ? 'sorted smallest → largest' : 'sorting…', Offset(w / 2, 14),
      size: 12, color: AppColors.muted);

  for (var i = 0; i < PercentileSim.n; i++) {
    final v = sim.values[i];
    final comparing = !sim.sorted && (i == sim.j || i == sim.j + 1);
    final settled = sim.sorted || i >= PercentileSim.n - sim.pass;
    Color color;
    if (comparing) {
      color = AppColors.orange;
    } else if (sim.sorted && i <= pos + 1e-9) {
      color = AppColors.violet;
    } else if (settled) {
      color = AppColors.cyan;
    } else {
      color = AppColors.peg;
    }
    bar(canvas, left + slot * (i + 0.5), slot * 0.78, baseline, (baseline - top) * v / 100, color);
    if (sim.sorted || comparing) {
      label(canvas, '$v', Offset(left + slot * (i + 0.5), baseline + 10), size: 9, color: AppColors.muted);
    }
  }

  if (!sim.sorted) return;

  // Quartile markers under the bars.
  for (final (name, q, color) in [
    ('Q1', 0.25, AppColors.green),
    ('median', 0.5, AppColors.pink),
    ('Q3', 0.75, AppColors.green),
  ]) {
    final x = left + slot * (q * (PercentileSim.n - 1) + 0.5);
    line(canvas, Offset(x, baseline + 18), Offset(x, baseline + 30), color, width: 3);
    label(canvas, '$name ${sim.quantile(q).toStringAsFixed(0)}', Offset(x, baseline + 42), size: 11, color: color);
  }

  // Percentile line across the chart.
  final pv = sim.quantile(sim.percentile / 100);
  final y = baseline - (baseline - top) * pv / 100;
  dashedLine(canvas, Offset(left, y), Offset(right, y), AppColors.violet, width: 2);
  label(canvas, 'P${sim.percentile.round()} = ${pv.toStringAsFixed(1)}', Offset(left + 4, y - 10),
      size: 12, color: AppColors.violet, align: TextAlign.left);
}

final LessonSpec percentilesLesson = LessonSpec(
  id: 'percentiles',
  chapterLabel: 'Ch 1 · Data & averages',
  title: const [
    TitlePart('Line everyone up, then '),
    TitlePart('cut', AppColors.violet),
    TitlePart(' the line'),
  ],
  subtitle: 'Percentiles & quartiles · 2-minute animated lesson',
  createSim: () => PercentileSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<PercentileSim>(sim, _paintPercentiles),
  stats: (sim) {
    final p = sim as PercentileSim;
    return [
      StatChip('Q1', p.sorted ? p.quantile(.25).toStringAsFixed(0) : '…', AppColors.green),
      StatChip('median', p.sorted ? p.quantile(.5).toStringAsFixed(0) : '…', AppColors.pink),
      StatChip('Q3', p.sorted ? p.quantile(.75).toStringAsFixed(0) : '…', AppColors.green),
    ];
  },
  bigIdea: 'Sort the data. The value 75% of the way along the line is the 75th '
      'percentile: three quarters of the data sit at or below it. The quartiles '
      'cut the line into four equal groups: Q1 at 25%, the median at 50%, Q3 at '
      '75%. Scoring in the 90th percentile means beating 90% of people, not '
      'scoring 90%.',
  formula: (sim) {
    final p = sim as PercentileSim;
    final pos = p.percentile / 100 * (PercentileSim.n - 1);
    return 'P${p.percentile.round()}: position = ${(p.percentile / 100).toStringAsFixed(2)} × (n − 1) '
        '= ${pos.toStringAsFixed(1)} in the sorted list';
  },
  tryItTitle: 'Try it: pick a percentile',
  buildTryIt: (sim) {
    final p = sim as PercentileSim;
    return watch(
      p,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '0',
            right: '100',
            value: p.percentile,
            min: 0,
            max: 100,
            divisions: 20,
            label: 'P${p.percentile.round()}',
            onChanged: p.setPercentile,
          ),
          ControlRow(
            children: [
              ValueTag(
                  'P${p.percentile.round()} = ${p.sorted ? p.quantile(p.percentile / 100).toStringAsFixed(1) : '…'}'),
              if (!p.sorted) ActionButton('Finish sorting', p.sortNow) else ActionButton('New data', p.reset),
            ],
          ),
          const SizedBox(height: 8),
          const TryNote('Purple bars are the ones at or below your percentile.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'You score in the 90th percentile on a test. What does that mean?',
      options: [
        'You got 90% of the marks',
        'You did as well as or better than about 90% of test takers',
        'You were 90th in the class',
        'You need 10% more to pass',
      ],
      answer: 1,
      explanation: 'Percentiles describe position in the sorted list, not the score '
          'itself.',
    ),
    QuizQuestion(
      prompt: 'Which percentile is the median?',
      options: ['25th', '50th', '75th', '100th'],
      answer: 1,
      explanation: 'Half the data lies at or below the median.',
    ),
    QuizQuestion(
      prompt: 'Q1 = 40 and Q3 = 70. What share of the data lies between 40 and 70?',
      options: ['25%', '50%', '70%', '75%'],
      answer: 1,
      explanation: 'From the 25th to the 75th percentile is the middle half of the '
          'data. Its width (30) is the interquartile range.',
    ),
  ],
);

// ===== lib/lessons/permutations.dart =====
const List<String> _runnerNames = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

/// Runners filling podium slots one at a time, in random order.
class PermutationSim extends TickSim {
  PermutationSim({super.rng});

  int n = 5;
  int r = 3;

  /// Runner index in each filled slot.
  List<int> podium = [];

  /// Distinct finished arrangements seen.
  final Set<String> seen = {};

  int get total => permutations(n, r);
  bool get full => podium.length == r;

  @override
  double get interval => seen.length < 3 ? 0.7 : 0.18;

  @override
  void tick() {
    if (full) {
      podium = [];
      return;
    }
    final left = [
      for (var i = 0; i < n; i++)
        if (!podium.contains(i)) i
    ];
    podium = [...podium, left[rng.nextInt(left.length)]];
    if (full) seen.add(podium.join());
  }

  @override
  void restart() {
    podium = [];
    seen.clear();
  }
}

void _paintPermutations(Canvas canvas, Size size, PermutationSim sim) {
  final w = size.width;

  // Runners waiting.
  final spacing = (w - 40) / sim.n;
  final rr = math.min(18.0, spacing * 0.36);
  label(canvas, 'Runners', Offset(20, 14), size: 11, color: AppColors.muted, align: TextAlign.left);
  for (var i = 0; i < sim.n; i++) {
    final c = Offset(20 + spacing * (i + 0.5), 44);
    final used = sim.podium.contains(i);
    canvas.drawCircle(c, rr, Paint()..color = AppColors.rainbow[i].withValues(alpha: used ? 0.2 : 1));
    label(canvas, _runnerNames[i], c, size: rr * 0.9, color: used ? AppColors.muted : Colors.white);
  }

  // Podium slots.
  final slotW = math.min(70.0, (w - 40) / sim.r - 8);
  final rowW = sim.r * (slotW + 8) - 8;
  final slotTop = 104.0;
  for (var s = 0; s < sim.r; s++) {
    final x = (w - rowW) / 2 + s * (slotW + 8);
    final rect = Rect.fromLTWH(x, slotTop, slotW, slotW * 0.9);
    roundRect(canvas, rect, AppColors.chip, radius: 10);
    label(canvas, '${s + 1}${['st', 'nd', 'rd', 'th', 'th', 'th', 'th'][s]}', Offset(rect.center.dx, rect.bottom + 12),
        size: 11, color: AppColors.muted);
    if (s < sim.podium.length) {
      final i = sim.podium[s];
      canvas.drawCircle(rect.center, slotW * 0.32, Paint()..color = AppColors.rainbow[i]);
      label(canvas, _runnerNames[i], rect.center, size: slotW * 0.3, color: Colors.white);
    }
    // How many choices this slot had.
    label(canvas, '${sim.n - s} choices', Offset(rect.center.dx, rect.top - 10),
        size: 10, color: s == sim.podium.length - 1 ? AppColors.pink : AppColors.muted);
  }

  // Progress towards seeing every arrangement.
  final y = slotTop + slotW + 52;
  final barW = w - 40;
  final frac = sim.seen.length / sim.total;
  label(canvas, 'Different podiums seen', Offset(20, y), size: 12, align: TextAlign.left);
  roundRect(canvas, Rect.fromLTWH(20, y + 14, barW, 24), Colors.white, radius: 8);
  roundRect(canvas, Rect.fromLTWH(20, y + 14, barW * frac, 24), AppColors.violet, radius: 8);
  label(canvas, '${sim.seen.length} of ${sim.total}', Offset(w / 2, y + 26),
      size: 12, color: frac > 0.5 ? Colors.white : AppColors.ink);

  // A few recent arrangements.
  final recent = sim.seen.toList().reversed.take(8).toList();
  for (var i = 0; i < recent.length; i++) {
    final text = recent[i].split('').map((d) => _runnerNames[int.parse(d)]).join();
    label(canvas, text, Offset(20 + (i % 4) * (barW / 4) + barW / 8, y + 58 + (i ~/ 4) * 20),
        size: 13, color: AppColors.muted);
  }
}

final LessonSpec permutationsLesson = LessonSpec(
  id: 'permutations',
  chapterLabel: 'Ch 4 · Counting',
  title: const [
    TitlePart('When '),
    TitlePart('order', AppColors.violet),
    TitlePart(' matters: filling a podium'),
  ],
  subtitle: 'Permutations · 2-minute animated lesson',
  createSim: () => PermutationSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<PermutationSim>(sim, _paintPermutations),
  stats: (sim) {
    final p = sim as PermutationSim;
    return [
      StatChip('runners n', '${p.n}', AppColors.yellow),
      StatChip('places r', '${p.r}', AppColors.pink),
      StatChip('podiums', '${p.total}', AppColors.violet),
    ];
  },
  bigIdea: 'Gold can go to any of the n runners. Once gold is taken, silver has one '
      'fewer choice, then bronze one fewer again. Multiply the shrinking choices. '
      'A-B-C and C-B-A are different podiums, so order matters: that is a '
      'permutation.',
  formula: (sim) {
    final p = sim as PermutationSim;
    final terms = [for (var i = 0; i < p.r; i++) '${p.n - i}'].join(' × ');
    return 'nPr = n! / (n − r)! = $terms = ${p.total}';
  },
  tryItTitle: 'Try it: more runners, more places',
  buildTryIt: (sim) {
    final p = sim as PermutationSim;
    return watch(
      p,
      () => Column(
        children: [
          LabeledSlider(
            left: 'runners ${p.n}',
            right: '7',
            value: p.n.toDouble(),
            min: 2,
            max: 7,
            divisions: 5,
            onChanged: (v) => p.change(() {
              p.n = v.round();
              p.r = math.min(p.r, p.n);
            }),
          ),
          LabeledSlider(
            left: 'places ${p.r}',
            right: '${p.n}',
            value: p.r.toDouble(),
            min: 1,
            max: p.n.toDouble(),
            divisions: math.max(1, p.n - 1),
            onChanged: (v) => p.change(() => p.r = v.round().clamp(1, p.n)),
          ),
          ControlRow(children: [ActionButton('Run 300 races', () => p.runMany(300 * (p.r + 1)))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: '8 runners race. How many ways can gold, silver and bronze be awarded?',
      options: ['24', '56', '336', '512'],
      answer: 2,
      explanation: '8 × 7 × 6 = 336.',
    ),
    QuizQuestion(
      prompt: 'How many ways can 5 books be arranged on a shelf?',
      options: ['5', '25', '120', '3,125'],
      answer: 2,
      explanation: 'All 5 positions are filled: 5! = 5 × 4 × 3 × 2 × 1 = 120.',
    ),
    QuizQuestion(
      prompt: 'Why is it n × (n − 1) × … and not n × n × …?',
      options: [
        'Because order doesn\'t matter',
        'Because a runner can\'t win two places at once',
        'Because n is small',
        'It is n × n',
      ],
      answer: 1,
      explanation: 'Each place uses up one runner, so the next place has one fewer choice.',
    ),
  ],
);

// ===== lib/lessons/pigeonhole.dart =====
/// Rounds of dropping pigeons into holes at random.
class PigeonholeSim extends TickSim {
  PigeonholeSim({super.rng});

  int holes = 5;
  int pigeons = 6;

  /// Hole of each pigeon dropped this round.
  List<int> dropped = [];

  /// Ticks spent showing a finished round.
  int hold = 0;

  int rounds = 0;
  int roundsShared = 0;

  bool get roundDone => dropped.length >= pigeons;
  bool get guaranteed => pigeons > holes;

  List<int> get counts {
    final c = List.filled(holes, 0);
    for (final hle in dropped) {
      c[hle]++;
    }
    return c;
  }

  bool get shared => counts.any((c) => c >= 2);

  /// Chance at least two share a hole when pigeons land at random.
  double get theory {
    if (guaranteed) return 1;
    var none = 1.0;
    for (var k = 0; k < pigeons; k++) {
      none *= (holes - k) / holes;
    }
    return 1 - none;
  }

  @override
  double get interval => rounds < 2 ? 0.35 : 0.12;

  @override
  void tick() {
    if (!roundDone) {
      dropped.add(rng.nextInt(holes));
      if (roundDone) {
        rounds++;
        if (shared) roundsShared++;
      }
    } else if (++hold > 5) {
      hold = 0;
      dropped = [];
    }
  }

  @override
  void restart() {
    dropped = [];
    hold = 0;
    rounds = 0;
    roundsShared = 0;
  }
}

void _paintPigeonhole(Canvas canvas, Size size, PigeonholeSim sim) {
  final w = size.width;
  final h = size.height;
  final holeW = (w - 20) / sim.holes;
  final holeTop = h * 0.3;
  final holeBottom = h - 70;
  final counts = sim.counts;

  // Pigeons still waiting.
  final waiting = sim.pigeons - sim.dropped.length;
  for (var i = 0; i < waiting; i++) {
    label(canvas, '🐦', Offset(20 + i * math.min(24.0, (w - 40) / sim.pigeons), 22), size: 18);
  }
  label(canvas, '${sim.pigeons} pigeons → ${sim.holes} holes', Offset(w / 2, holeTop - 22), size: 13);

  final stackStep = math.min(26.0, (holeBottom - holeTop - 12) / math.max(1, counts.reduce(math.max)));
  for (var hle = 0; hle < sim.holes; hle++) {
    final rect = Rect.fromLTWH(10 + hle * holeW + 3, holeTop, holeW - 6, holeBottom - holeTop);
    final crowded = counts[hle] >= 2;
    roundRect(canvas, rect, crowded ? AppColors.pink.withValues(alpha: 0.2) : AppColors.chip, radius: 10);
    if (crowded) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()
          ..color = AppColors.pink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    for (var k = 0; k < counts[hle]; k++) {
      label(canvas, '🐦', Offset(rect.center.dx, rect.bottom - 16 - k * stackStep), size: math.min(20, holeW * 0.5));
    }
  }

  final msg = !sim.roundDone
      ? (sim.guaranteed ? 'More pigeons than holes: a share is certain' : 'Will two end up together?')
      : (sim.shared ? 'Some hole holds 2 or more pigeons' : 'Every pigeon got its own hole');
  label(canvas, msg, Offset(w / 2, h - 46), size: 14, color: sim.shared ? AppColors.pink : AppColors.ink);
  label(canvas, 'Rounds with a shared hole: ${sim.roundsShared} of ${sim.rounds}', Offset(w / 2, h - 20),
      size: 12, color: AppColors.muted);
}

final LessonSpec pigeonholeLesson = LessonSpec(
  id: 'pigeonhole',
  chapterLabel: 'Ch 4 · Counting',
  title: const [
    TitlePart('More pigeons than holes means a '),
    TitlePart('guaranteed', AppColors.pink),
    TitlePart(' crowd'),
  ],
  subtitle: 'The pigeonhole principle · 2-minute animated lesson',
  createSim: () => PigeonholeSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<PigeonholeSim>(sim, _paintPigeonhole),
  stats: (sim) {
    final p = sim as PigeonholeSim;
    return [
      StatChip('rounds', '${p.rounds}', AppColors.yellow),
      StatChip('shared', p.rounds == 0 ? '…' : '${(p.roundsShared / p.rounds * 100).round()}%', AppColors.pink),
      StatChip('theory', '${(p.theory * 100).round()}%', AppColors.violet),
    ];
  },
  bigIdea: 'Put 6 pigeons into 5 holes and at least one hole must hold two. There\'s '
      'no luck involved: even the most careful spreading runs out of empty holes. '
      'This simple idea proves surprising facts, like two people in any city of '
      'a million having exactly the same number of hairs on their head.',
  formula: (sim) {
    final p = sim as PigeonholeSim;
    return p.guaranteed
        ? '${p.pigeons} > ${p.holes} → some hole has ≥ ⌈${p.pigeons}/${p.holes}⌉ = ${(p.pigeons / p.holes).ceil()}'
        : '${p.pigeons} ≤ ${p.holes}: no guarantee, but random chance of a share = ${(p.theory * 100).toStringAsFixed(0)}%';
  },
  tryItTitle: 'Try it: pigeons vs holes',
  buildTryIt: (sim) {
    final p = sim as PigeonholeSim;
    return watch(
      p,
      () => Column(
        children: [
          LabeledSlider(
            left: 'holes ${p.holes}',
            right: '10',
            value: p.holes.toDouble(),
            min: 2,
            max: 10,
            divisions: 8,
            onChanged: (v) => p.change(() => p.holes = v.round()),
          ),
          LabeledSlider(
            left: 'pigeons ${p.pigeons}',
            right: '12',
            value: p.pigeons.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            onChanged: (v) => p.change(() => p.pigeons = v.round()),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'How many people must be in a room to guarantee two share a birth month?',
      options: ['12', '13', '24', '366'],
      answer: 1,
      explanation: '12 months are the holes. With 13 people, one month must hold two.',
    ),
    QuizQuestion(
      prompt: 'A drawer has red and blue socks. How many must you pull out, in the dark, '
          'to be sure of a matching pair?',
      options: ['2', '3', '4', 'All of them'],
      answer: 1,
      explanation: 'Two colours are two holes. The third sock must match one of the first two.',
    ),
    QuizQuestion(
      prompt: '10 pigeons, 3 holes. At least one hole must hold at least…',
      options: ['2', '3', '4', '10'],
      answer: 2,
      explanation: '10 / 3 = 3.33, rounded up: 4. Three holes of 3 only hold 9.',
    ),
  ],
);

// ===== lib/lessons/pmf_cdf.dart =====
/// Ways to roll each total 2–12 with two dice (out of 36).
const List<int> kTwoDiceWays = [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1];

/// A cursor sweeps across the totals 2–12, building the CDF from the PMF.
class PmfCdfSim extends LessonSim {
  double t = 0;

  /// Chosen with the slider; null while sweeping on its own.
  int? manual;

  static const double perStep = 0.7;

  /// Sweeps 2 → 12, pauses on 12 for an extra step, then starts again.
  int get cursor => manual ?? math.min(12, 2 + (t / perStep).floor() % 12);

  double pmf(int x) => (x < 2 || x > 12) ? 0 : kTwoDiceWays[x - 2] / 36;

  double cdf(int x) {
    var s = 0.0;
    for (var k = 2; k <= x; k++) {
      s += pmf(k);
    }
    return s;
  }

  int waysUpTo(int x) => [for (var k = 2; k <= math.min(x, 12); k++) kTwoDiceWays[k - 2]].fold(0, (a, b) => a + b);

  @override
  void advance(double dt) {
    if (manual == null) t += dt;
    notifyListeners();
  }

  @override
  void step() {
    manual = null;
    t = ((t / perStep).floor() + 1) * perStep;
    notifyListeners();
  }

  @override
  void reset() {
    manual = null;
    t = 0;
    notifyListeners();
  }

  void setCursor(int x) {
    manual = x;
    notifyListeners();
  }
}

void _paintPmfCdf(Canvas canvas, Size size, PmfCdfSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 34.0;
  final right = w - 12;
  final slot = (right - left) / 11;
  double xFor(int total) => left + slot * (total - 2 + 0.5);
  final x = sim.cursor;

  // PMF.
  label(canvas, 'PMF: P(total = x)', Offset(left, 12), size: 12, color: AppColors.orange, align: TextAlign.left);
  final pBase = h * 0.44;
  const pTop = 30.0;
  for (var k = 2; k <= 12; k++) {
    final included = k <= x;
    bar(canvas, xFor(k), slot * 0.7, pBase, (pBase - pTop) * sim.pmf(k) / (6 / 36),
        included ? AppColors.orange : AppColors.peg.withValues(alpha: 0.6));
    label(canvas, '${kTwoDiceWays[k - 2]}', Offset(xFor(k), pBase - (pBase - pTop) * sim.pmf(k) / (6 / 36) - 8),
        size: 9, color: AppColors.muted);
    label(canvas, '$k', Offset(xFor(k), pBase + 10), size: 10, color: AppColors.muted);
  }

  // CDF: a staircase.
  final cTop = pBase + 40;
  final cBase = h - 26;
  label(canvas, 'CDF: P(total ≤ x)', Offset(left, cTop - 14), size: 12, color: AppColors.violet, align: TextAlign.left);
  double yFor(double p) => cBase - p * (cBase - cTop);
  line(canvas, Offset(left, cBase), Offset(right, cBase), AppColors.peg);
  for (final p in [0.5, 1.0]) {
    dashedLine(canvas, Offset(left, yFor(p)), Offset(right, yFor(p)), AppColors.peg.withValues(alpha: 0.6), width: 1);
    label(canvas, p.toStringAsFixed(1), Offset(left - 6, yFor(p)),
        size: 10, color: AppColors.muted, align: TextAlign.right);
  }
  for (var k = 2; k <= 12; k++) {
    final y = yFor(sim.cdf(k));
    final x0 = left + slot * (k - 2), x1 = left + slot * (k - 1);
    line(canvas, Offset(x0, y), Offset(x1, y), k <= x ? AppColors.violet : AppColors.peg, width: 3.5);
    canvas.drawCircle(Offset(x0, y), 3.5, Paint()..color = k <= x ? AppColors.violet : AppColors.peg);
  }
  // Cursor.
  final cx = left + slot * (x - 1);
  line(canvas, Offset(cx, pTop), Offset(cx, cBase), AppColors.pink, width: 2);
  label(canvas, 'P(total ≤ $x) = ${sim.waysUpTo(x)}/36 = ${sim.cdf(x).toStringAsFixed(2)}', Offset(w / 2, h - 10),
      size: 13, color: AppColors.pink);
}

final LessonSpec pmfCdfLesson = LessonSpec(
  id: 'pmf_cdf',
  chapterLabel: 'Ch 6 · Random variables',
  title: const [
    TitlePart('Bars', AppColors.orange),
    TitlePart(' that stack into a '),
    TitlePart('staircase', AppColors.violet),
  ],
  subtitle: 'PMF, PDF & CDF · 2-minute animated lesson',
  createSim: () => PmfCdfSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<PmfCdfSim>(sim, _paintPmfCdf),
  stats: (sim) {
    final s = sim as PmfCdfSim;
    return [
      StatChip('x', '${s.cursor}', AppColors.pink),
      StatChip('P(X = x)', '${kTwoDiceWays[s.cursor - 2]}/36', AppColors.orange),
      StatChip('P(X ≤ x)', s.cdf(s.cursor).toStringAsFixed(2), AppColors.violet),
    ];
  },
  bigIdea: 'Roll two dice and add them. The PMF (probability mass function) gives the '
      'chance of each exact total: 7 is likeliest because 6 of the 36 rolls make '
      'it. The CDF (cumulative distribution function) adds up every bar to the '
      'left: the chance of getting x or less. It climbs in steps from 0 to 1. For '
      'continuous variables, the bars melt into a smooth curve called a PDF, '
      'and the CDF becomes a smooth S-shaped ramp.',
  formula: (sim) {
    final s = sim as PmfCdfSim;
    return 'F(${s.cursor}) = Σ p(k) for k ≤ ${s.cursor} = ${s.waysUpTo(s.cursor)}/36';
  },
  tryItTitle: 'Try it: move x yourself',
  buildTryIt: (sim) {
    final s = sim as PmfCdfSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '2',
            right: '12',
            value: s.cursor.toDouble(),
            min: 2,
            max: 12,
            divisions: 10,
            label: 'x = ${s.cursor}',
            onChanged: (v) => s.setCursor(v.round()),
          ),
          TryNote('P(total > ${s.cursor}) = 1 − F(${s.cursor}) = ${(1 - s.cdf(s.cursor)).toStringAsFixed(2)}'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'With two dice, what is P(total = 7)?',
      options: ['1/36', '1/11', '6/36', '7/36'],
      answer: 2,
      explanation: '(1,6), (2,5), (3,4), (4,3), (5,2), (6,1): 6 of 36 rolls.',
    ),
    QuizQuestion(
      prompt: 'A CDF value F(5) = 0.28 means…',
      options: [
        'P(X = 5) = 0.28',
        'P(X ≤ 5) = 0.28',
        'P(X > 5) = 0.28',
        '28% of values equal 5',
      ],
      answer: 1,
      explanation: 'The CDF is cumulative: everything up to and including 5.',
    ),
    QuizQuestion(
      prompt: 'Which is always true of a CDF?',
      options: [
        'It goes up and down',
        'It never decreases and ends at 1',
        'It peaks at the mean',
        'It is always a straight line',
      ],
      answer: 1,
      explanation: 'Adding more probability can only keep it level or push it up, '
          'until everything is included.',
    ),
  ],
);

// ===== lib/lessons/registry.dart =====
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
    jointMarginalLesson,
    covarianceLesson,
    correlationLesson,
    causationLesson,
    chebyshevLesson,
    populationSampleLesson,
    samplingMethodsLesson,
    samplingBiasLesson,
    samplingDistributionsLesson,
    standardErrorLesson,
    pointEstimatesLesson,
    mleLesson,
    confidenceIntervalsLesson,
    marginOfErrorLesson,
    sampleSizeLesson,
    nullAlternativeLesson,
    pValuesLesson,
    typeErrorsLesson,
    powerLesson,
    zTestLesson,
    tTestsLesson,
    chiSquareLesson,
    anovaLesson,
    lineOfBestFitLesson,
    residualsLesson,
    rSquaredLesson,
    multipleRegressionLesson,
    logisticRegressionLesson,
    priorPosteriorLesson,
    updatingEvidenceLesson,
    bayesVsFrequentistLesson,
    abTestingLesson,
    monteCarloLesson,
    randomWalksLesson,
    markovChainsLesson,
    aiMlLesson,
    simpsonsLesson,
    gamblersFallacyLesson,
    stPetersburgLesson,
  ])
    spec.id: spec,
};

// ===== lib/lessons/scatter.dart =====
/// Pearson correlation of paired data.
double correlation(List<Offset> pts) {
  if (pts.length < 3) return 0;
  final mx = meanOf(pts.map((p) => p.dx));
  final my = meanOf(pts.map((p) => p.dy));
  var sxy = 0.0, sxx = 0.0, syy = 0.0;
  for (final p in pts) {
    sxy += (p.dx - mx) * (p.dy - my);
    sxx += (p.dx - mx) * (p.dx - mx);
    syy += (p.dy - my) * (p.dy - my);
  }
  return sxx == 0 || syy == 0 ? 0 : sxy / math.sqrt(sxx * syy);
}

/// Hours studied (x, 0–1) against marks (y, 0–1) with a chosen strength.
class ScatterSim extends TickSim {
  ScatterSim({super.rng});

  static const int target = 40;

  final List<Offset> points = [];
  double strength = 0.7;

  @override
  double get interval => points.length < 8 ? 0.35 : 0.12;

  double get r => correlation(points);

  @override
  void tick() {
    if (points.length >= target) return;
    final zx = normalDraw(rng);
    final zy = strength * zx + math.sqrt(1 - strength * strength) * normalDraw(rng);
    points.add(Offset((0.5 + zx * 0.17).clamp(0.02, 0.98), (0.5 + zy * 0.17).clamp(0.02, 0.98)));
  }

  /// Least-squares line through the points: y = a + b·x.
  (double, double) get fit {
    final mx = meanOf(points.map((p) => p.dx));
    final my = meanOf(points.map((p) => p.dy));
    var sxy = 0.0, sxx = 0.0;
    for (final p in points) {
      sxy += (p.dx - mx) * (p.dy - my);
      sxx += (p.dx - mx) * (p.dx - mx);
    }
    final b = sxx == 0 ? 0.0 : sxy / sxx;
    return (my - b * mx, b);
  }

  @override
  void restart() => points.clear();
}

void _paintScatter(Canvas canvas, Size size, ScatterSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 34.0, top = 16.0;
  final right = w - 14, bottom = h - 34;
  Offset toCanvas(Offset p) => Offset(left + p.dx * (right - left), bottom - p.dy * (bottom - top));

  line(canvas, Offset(left, top), Offset(left, bottom), AppColors.peg);
  line(canvas, Offset(left, bottom), Offset(right, bottom), AppColors.peg);
  label(canvas, 'hours studied →', Offset((left + right) / 2, bottom + 18), size: 11, color: AppColors.muted);
  canvas.save();
  canvas.translate(14, (top + bottom) / 2);
  canvas.rotate(-math.pi / 2);
  label(canvas, 'marks →', Offset.zero, size: 11, color: AppColors.muted);
  canvas.restore();

  if (sim.points.length >= 8) {
    final (a, b) = sim.fit;
    final p1 = toCanvas(Offset(0, (a).clamp(-0.2, 1.2)));
    final p2 = toCanvas(Offset(1, (a + b).clamp(-0.2, 1.2)));
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(left, top, right, bottom));
    line(canvas, p1, p2, AppColors.pink, width: 3);
    canvas.restore();
  }
  for (var i = 0; i < sim.points.length; i++) {
    final isNew = i == sim.points.length - 1;
    final c = toCanvas(sim.points[i]);
    canvas.drawCircle(
        c, isNew ? 7 : 5.5, Paint()..color = isNew ? AppColors.orange : AppColors.blue.withValues(alpha: 0.75));
  }
}

String describeR(double r) {
  final a = r.abs();
  final strength = a > 0.7 ? 'strong' : (a > 0.4 ? 'moderate' : (a > 0.15 ? 'weak' : 'no clear'));
  final dir = a <= 0.15 ? '' : (r > 0 ? ' positive' : ' negative');
  return '$strength$dir link';
}

final LessonSpec scatterLesson = LessonSpec(
  id: 'scatter',
  chapterLabel: 'Ch 2 · Seeing data',
  title: const [
    TitlePart('Do two things '),
    TitlePart('move together', AppColors.pink),
    TitlePart('?'),
  ],
  subtitle: 'Scatter plots · 2-minute animated lesson',
  createSim: () => ScatterSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<ScatterSim>(sim, _paintScatter),
  stats: (sim) {
    final s = sim as ScatterSim;
    return [
      StatChip('points', '${s.points.length}', AppColors.yellow),
      StatChip('r', s.points.length < 3 ? '…' : s.r.toStringAsFixed(2), AppColors.pink),
      StatChip('', s.points.length < 3 ? '…' : describeR(s.r), AppColors.blue),
    ];
  },
  bigIdea: 'Each dot is one student: across for hours studied, up for marks. If '
      'the cloud slopes upward, more of one tends to come with more of the other. '
      'The correlation r runs from −1 (perfect downhill line) through 0 (no '
      'pattern) to +1 (perfect uphill line). It measures how tightly the dots hug '
      'a straight line, not how steep it is.',
  formula: (sim) {
    final s = sim as ScatterSim;
    return 'r = Σ(x−x̄)(y−ȳ) / √(Σ(x−x̄)² · Σ(y−ȳ)²) = ${s.r.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: set the strength of the link',
  buildTryIt: (sim) {
    final s = sim as ScatterSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '−1',
            right: '+1',
            value: s.strength,
            min: -0.95,
            max: 0.95,
            divisions: 19,
            label: s.strength.toStringAsFixed(1),
            onChanged: (v) => s.change(() => s.strength = v),
          ),
          ControlRow(children: [
            ValueTag('target ${s.strength.toStringAsFixed(1)}'),
            ActionButton('Add 30 points', () => s.runMany(30)),
          ]),
          const SizedBox(height: 8),
          const TryNote('Try 0: the cloud is round and the line goes flat. Try −0.9: a tight downhill band.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A scatter plot slopes clearly downhill. The correlation is probably…',
      options: ['About +0.8', 'About 0', 'About −0.8', 'Exactly 1'],
      answer: 2,
      explanation: 'Downhill means one goes up as the other goes down: a negative r.',
    ),
    QuizQuestion(
      prompt: 'r = 0 means…',
      options: [
        'No straight-line relationship',
        'The variables are identical',
        'All points are on a line',
        'The data is wrong',
      ],
      answer: 0,
      explanation: 'There could still be a curved pattern, but no linear trend.',
    ),
    QuizQuestion(
      prompt: 'Which r shows the strongest relationship?',
      options: ['0.6', '−0.9', '0.1', '0.75'],
      answer: 1,
      explanation: 'Strength is the size of r, ignoring the sign. |−0.9| is the largest.',
    ),
  ],
);

// ===== lib/lessons/skew.dart =====
enum SkewShape { leftSkew, symmetric, rightSkew, bimodal }

const Map<SkewShape, String> kSkewShapeNames = {
  SkewShape.leftSkew: 'Left tail',
  SkewShape.symmetric: 'Symmetric',
  SkewShape.rightSkew: 'Right tail',
  SkewShape.bimodal: 'Two humps',
};

class SkewSim extends TickSim {
  SkewSim({super.rng});

  static const int bins = 20;

  SkewShape shape = SkewShape.rightSkew;
  List<int> counts = List.filled(bins, 0);
  final List<double> values = [];

  @override
  double get interval => values.length < 30 ? 0.08 : 0.02;

  /// A draw on 0 … 1 for the chosen shape.
  double draw() {
    switch (shape) {
      case SkewShape.symmetric:
        return (0.5 + normalDraw(rng) * 0.14).clamp(0, 0.999);
      case SkewShape.rightSkew:
        // Exponential-like: piles up on the left, tail to the right.
        return (-math.log(1 - rng.nextDouble()) * 0.16 + 0.03).clamp(0, 0.999);
      case SkewShape.leftSkew:
        return (1 - (-math.log(1 - rng.nextDouble()) * 0.16 + 0.03)).clamp(0, 0.999);
      case SkewShape.bimodal:
        final c = rng.nextBool() ? 0.28 : 0.72;
        return (c + normalDraw(rng) * 0.08).clamp(0, 0.999);
    }
  }

  double get mean => meanOf(values);
  double get median => quantileOf(values, 0.5);

  String get verdict {
    if (values.length < 30) return 'Collecting data…';
    final d = mean - median;
    if (shape == SkewShape.bimodal) return 'Two peaks: one "average" hides two groups';
    if (d > 0.015) return 'Mean > median: skewed right';
    if (d < -0.015) return 'Mean < median: skewed left';
    return 'Mean ≈ median: symmetric';
  }

  @override
  void tick() {
    if (values.length >= 1500) return;
    final v = draw();
    values.add(v);
    counts[(v * bins).floor()]++;
  }

  @override
  void restart() {
    values.clear();
    counts = List.filled(bins, 0);
  }
}

void _paintSkew(Canvas canvas, Size size, SkewSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 14.0;
  final right = w - 14;
  final baseline = h - 74;
  const top = 20.0;
  final slot = (right - left) / SkewSim.bins;
  final maxC = math.max(5, sim.counts.reduce(math.max));
  for (var i = 0; i < SkewSim.bins; i++) {
    bar(canvas, left + slot * (i + 0.5), slot * 0.86, baseline, (baseline - top) * sim.counts[i] / maxC,
        AppColors.rainbow[(i * 7 ~/ SkewSim.bins)].withValues(alpha: 0.85));
  }
  line(canvas, Offset(left, baseline), Offset(right, baseline), AppColors.peg);
  if (sim.values.length < 5) return;

  double xFor(double v) => left + v * (right - left);
  for (final (name, v, color, row) in [
    ('mean', sim.mean, AppColors.pink, 0),
    ('median', sim.median, AppColors.violet, 1),
  ]) {
    final x = xFor(v);
    line(canvas, Offset(x, top), Offset(x, baseline + 8 + row * 22), color, width: 2.5);
    final y = baseline + 20 + row * 22;
    final onRight = x < w * 0.6;
    label(canvas, name, Offset(x + (onRight ? 6 : -6), y),
        size: 12, color: color, align: onRight ? TextAlign.left : TextAlign.right);
  }
  label(canvas, sim.verdict, Offset(w / 2, h - 12), size: 13);
}

final LessonSpec skewLesson = LessonSpec(
  id: 'skew',
  chapterLabel: 'Ch 1 · Data & averages',
  title: const [
    TitlePart('Which way does the '),
    TitlePart('tail', AppColors.orange),
    TitlePart(' point?'),
  ],
  subtitle: 'Skew & shape · 2-minute animated lesson',
  createSim: () => SkewSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<SkewSim>(sim, _paintSkew),
  stats: (sim) {
    final s = sim as SkewSim;
    return [
      StatChip('values', '${s.values.length}', AppColors.yellow),
      StatChip('mean', (s.mean * 100).toStringAsFixed(0), AppColors.pink),
      StatChip('median', (s.median * 100).toStringAsFixed(0), AppColors.violet),
    ];
  },
  bigIdea: 'A skew is named after its tail, not its hump. Incomes pile up on the '
      'left with a long tail of high earners to the right: skewed right. The tail '
      'drags the mean towards it, so the mean sits on the tail side of the median. '
      'Two humps usually mean two different groups mixed together.',
  formula: (sim) {
    final s = sim as SkewSim;
    return 'mean − median = ${((s.mean - s.median) * 100).toStringAsFixed(1)}  '
        '(> 0 right skew, < 0 left skew)';
  },
  tryItTitle: 'Try it: change the shape',
  buildTryIt: (sim) {
    final s = sim as SkewSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<SkewShape>(
            options: kSkewShapeNames,
            selected: s.shape,
            onSelected: (v) => s.change(() => s.shape = v),
          ),
          const SizedBox(height: 8),
          const TryNote('Real examples: incomes (right), exam scores on an easy test (left), '
              'adult heights of men and women together (two humps).'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'House prices in a city: most are moderate, a few are huge. The data is…',
      options: ['Skewed left', 'Symmetric', 'Skewed right', 'Uniform'],
      answer: 2,
      explanation: 'The long tail of expensive houses points right.',
    ),
    QuizQuestion(
      prompt: 'In a left-skewed distribution, usually…',
      options: ['mean < median', 'mean = median', 'mean > median', 'there is no median'],
      answer: 0,
      explanation: 'The tail on the left drags the mean down below the median.',
    ),
    QuizQuestion(
      prompt: 'A histogram of heights shows two clear humps. A likely reason?',
      options: [
        'A measuring error',
        'Two groups mixed together, like adults and children',
        'The data is skewed right',
        'Too many bins',
      ],
      answer: 1,
      explanation: 'Bimodal data often hides two populations. Splitting them gives '
          'two clean single-hump shapes.',
    ),
  ],
);

// ===== lib/lessons/spread.dart =====
// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

/// A rolling sample of [size] values: every tick the oldest is replaced.
class SpreadSim extends LessonSim {
  SpreadSim({math.Random? rng}) : _rng = rng ?? math.Random() {
    _fill();
  }

  static const int size = 12;

  /// Values live on 0 … 100 around a centre of 50.
  static const double centre = 50;

  final math.Random _rng;

  /// Standard deviation the values are drawn with.
  double targetSd = 12;

  List<double> values = [];

  /// Index of the value that was replaced most recently.
  int newest = -1;

  /// 0 → 1 slide-in of the newest value.
  double t = 1;

  double _timer = 0;

  static const double every = 1.2;

  double _draw() {
    // Box–Muller normal draw, clamped to the visible range.
    final u1 = 1 - _rng.nextDouble();
    final u2 = _rng.nextDouble();
    final z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    return (centre + z * targetSd).clamp(0, 100).toDouble();
  }

  void _fill() {
    values = List.generate(size, (_) => _draw());
    newest = -1;
    t = 1;
  }

  double get mean => values.fold(0.0, (a, b) => a + b) / values.length;

  double get sumSquares {
    final m = mean;
    return values.fold(0.0, (a, v) => a + (v - m) * (v - m));
  }

  /// Sample standard deviation (divides by n − 1).
  double get sd => math.sqrt(sumSquares / (values.length - 1));

  double get range => values.reduce(math.max) - values.reduce(math.min);

  @override
  void advance(double dt) {
    if (t < 1) t = math.min(1, t + dt * 3);
    _timer += dt;
    while (_timer >= every) {
      _timer -= every;
      _replace();
    }
    notifyListeners();
  }

  void _replace() {
    newest = (newest + 1) % size;
    values[newest] = _draw();
    t = 0;
  }

  void setSpread(double sdValue) {
    targetSd = sdValue;
    _fill();
    notifyListeners();
  }

  @override
  void step() {
    _replace();
    t = 1;
    notifyListeners();
  }

  @override
  void reset() {
    _timer = 0;
    _fill();
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class SpreadPainter extends CustomPainter {
  SpreadPainter(this.sim) : super(repaint: sim);

  final SpreadSim sim;

  static const double aspectRatio = 0.95;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const left = 16.0;
    final right = w - 16;
    const top = 30.0;
    final bottom = h - 34;
    double xFor(double v) => left + v / 100 * (right - left);

    final mean = sim.mean;
    final sd = sim.sd;
    final mx = xFor(mean);

    // ±1 sd band.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(xFor((mean - sd).clamp(0, 100)), top - 8, xFor((mean + sd).clamp(0, 100)), bottom + 4),
        const Radius.circular(10),
      ),
      Paint()..color = AppColors.yellow.withValues(alpha: 0.28),
    );
    _text(canvas, '−1 sd', Offset(xFor((mean - sd).clamp(0, 100)), top - 18), 11, AppColors.muted);
    _text(canvas, '+1 sd', Offset(xFor((mean + sd).clamp(0, 100)), top - 18), 11, AppColors.muted);

    // One row per value: a dot, and a bar from the mean to it.
    final rowH = (bottom - top) / SpreadSim.size;
    final dotR = math.min(rowH * 0.32, 8.0);
    for (var i = 0; i < SpreadSim.size; i++) {
      final v = sim.values[i];
      final y = top + rowH * (i + 0.5);
      final isNew = i == sim.newest && sim.t < 1;
      final x = isNew ? right + (xFor(v) - right) * Curves.easeOutCubic.transform(sim.t) : xFor(v);
      final color = v >= mean ? AppColors.pink : AppColors.blue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(math.min(mx, x), y - rowH * 0.16, math.max(mx, x), y + rowH * 0.16),
          const Radius.circular(4),
        ),
        Paint()..color = color.withValues(alpha: 0.35),
      );
      canvas.drawCircle(Offset(x, y), dotR, Paint()..color = color);
    }

    // Mean line.
    canvas.drawLine(
      Offset(mx, top - 8),
      Offset(mx, bottom + 4),
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = 2.5,
    );
    _text(canvas, 'mean ${mean.toStringAsFixed(1)}', Offset(mx, bottom + 18), 12, AppColors.ink);
  }

  void _text(Canvas canvas, String text, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant SpreadPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec spreadLesson = LessonSpec(
  id: 'spread',
  chapterLabel: 'Ch 1 · Data & averages',
  title: const [
    TitlePart('How far is a '),
    TitlePart('typical', AppColors.pink),
    TitlePart(' value from the '),
    TitlePart('mean', AppColors.blue),
    TitlePart('?'),
  ],
  subtitle: 'Range, variance & standard deviation · 2-minute animated lesson',
  createSim: () => SpreadSim(),
  visualAspectRatio: SpreadPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: SpreadPainter(sim as SpreadSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final s = sim as SpreadSim;
    return [
      StatChip('range', s.range.toStringAsFixed(1), AppColors.orange),
      StatChip('variance', (s.sd * s.sd).toStringAsFixed(0), AppColors.violet),
      StatChip('sd', s.sd.toStringAsFixed(1), AppColors.yellow),
    ];
  },
  bigIdea: 'Each bar is one value\'s distance from the mean. Square those distances '
      '(so left and right both count), average them, and you get the variance. '
      'Take the square root to get back to normal units: that is the standard '
      'deviation, roughly how far a typical value sits from the mean. Most values '
      'land inside the yellow ±1 sd band.',
  formula: (sim) {
    final s = sim as SpreadSim;
    return 'sd = √(Σ(x − x̄)² / (n − 1)) = √(${s.sumSquares.toStringAsFixed(0)} / ${SpreadSim.size - 1}) '
        '= ${s.sd.toStringAsFixed(1)}';
  },
  tryItTitle: 'Try it: squeeze or stretch the data',
  buildTryIt: (sim) => _SpreadControls(sim: sim as SpreadSim),
  quiz: const [
    QuizQuestion(
      prompt: 'Two classes both average 60 marks. Class A has sd 5, class B has sd 20. '
          'Which is true?',
      options: [
        'Class A\'s marks are more bunched together',
        'Class B did better',
        'Class A has more students',
        'They are identical',
      ],
      answer: 0,
      explanation: 'Same centre, different spread. A small sd means most marks are '
          'close to 60.',
    ),
    QuizQuestion(
      prompt: 'Why square the distances before averaging them?',
      options: [
        'To make the numbers bigger',
        'So distances below the mean don\'t cancel those above',
        'Because the formula looks nicer',
        'To remove outliers',
      ],
      answer: 1,
      explanation: 'Raw distances from the mean always add up to exactly zero. '
          'Squaring makes every distance positive.',
    ),
    QuizQuestion(
      prompt: 'You add 10 to every value. What happens to the sd?',
      options: ['It goes up by 10', 'It doubles', 'It stays the same', 'It goes to zero'],
      answer: 2,
      explanation: 'Everything shifts together, including the mean, so every '
          'distance from the mean is unchanged.',
    ),
  ],
);

class _SpreadControls extends StatelessWidget {
  const _SpreadControls({required this.sim});
  final SpreadSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('tight', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              Expanded(
                child: Slider(
                  value: sim.targetSd,
                  min: 3,
                  max: 24,
                  divisions: 7,
                  label: sim.targetSd.toStringAsFixed(0),
                  onChanged: sim.setSpread,
                ),
              ),
              const Text('wide', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ],
          ),
          const Text(
            'New values slide in every second. Notice the sd wobbles but stays near the '
            'spread you chose, while the range jumps around much more.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ===== lib/lessons/stem_leaf.dart =====
/// Two-digit scores filed one by one into a stem-and-leaf plot.
class StemLeafSim extends TickSim {
  StemLeafSim({super.rng}) {
    restart();
  }

  static const int n = 24;
  static const int minStem = 4, maxStem = 9;

  List<int> data = [];
  int placed = 0;

  @override
  double get interval => placed < 5 ? 0.9 : 0.4;

  bool get done => placed >= n;

  /// Leaves per stem, sorted, from the values placed so far.
  Map<int, List<int>> get rows {
    final out = {for (var s = minStem; s <= maxStem; s++) s: <int>[]};
    for (var i = 0; i < placed; i++) {
      out[data[i] ~/ 10]!.add(data[i] % 10);
    }
    for (final l in out.values) {
      l.sort();
    }
    return out;
  }

  @override
  void tick() {
    if (placed < n) placed++;
  }

  @override
  void restart() {
    data = List.generate(n, (_) => (68 + normalDraw(rng) * 12).round().clamp(40, 99));
    placed = 0;
  }
}

void _paintStemLeaf(Canvas canvas, Size size, StemLeafSim sim) {
  final w = size.width;
  final h = size.height;

  // The unsorted list at the top.
  const perRow = 12;
  final cell = (w - 24) / perRow;
  for (var i = 0; i < StemLeafSim.n; i++) {
    final c = Offset(12 + cell * (i % perRow + 0.5), 20 + (i ~/ perRow) * 24.0);
    final isCurrent = i == sim.placed - 1;
    final isDone = i < sim.placed;
    if (isCurrent) roundRect(canvas, Rect.fromCenter(center: c, width: cell - 2, height: 22), AppColors.yellow);
    label(canvas, '${sim.data[i]}', c,
        size: 13, color: isDone && !isCurrent ? AppColors.peg : AppColors.ink, weight: FontWeight.w900);
  }

  // The plot.
  final top = 76.0;
  final rowH = (h - top - 30) / (StemLeafSim.maxStem - StemLeafSim.minStem + 1);
  final stemX = 44.0;
  label(canvas, 'stem', Offset(stemX - 14, top - 8), size: 10, color: AppColors.muted);
  label(canvas, 'leaves', Offset(stemX + 40, top - 8), size: 10, color: AppColors.muted);
  line(canvas, Offset(stemX + 4, top), Offset(stemX + 4, h - 30), AppColors.ink, width: 2.5);
  final current = sim.placed == 0 ? null : sim.data[sim.placed - 1];
  final rows = sim.rows;
  for (var s = StemLeafSim.minStem; s <= StemLeafSim.maxStem; s++) {
    final y = top + rowH * (s - StemLeafSim.minStem + 0.5);
    label(canvas, '$s', Offset(stemX - 14, y), size: 18, color: AppColors.violet, weight: FontWeight.w900);
    final leaves = rows[s]!;
    var highlighted = false;
    for (var k = 0; k < leaves.length; k++) {
      final x = stemX + 22 + k * math.min(22.0, (w - stemX - 40) / 12);
      final isNew = !highlighted && current != null && s == current ~/ 10 && leaves[k] == current % 10;
      if (isNew) {
        highlighted = true;
        canvas.drawCircle(Offset(x, y), 12, Paint()..color = AppColors.pink.withValues(alpha: 0.25));
      }
      label(canvas, '${leaves[k]}', Offset(x, y),
          size: 17, color: isNew ? AppColors.pink : AppColors.ink, weight: FontWeight.w900);
    }
  }
  if (current != null) {
    label(canvas, '$current → stem ${current ~/ 10} | leaf ${current % 10}', Offset(w / 2, h - 12),
        size: 13, color: AppColors.pink);
  }
}

final LessonSpec stemLeafLesson = LessonSpec(
  id: 'stem_leaf',
  chapterLabel: 'Ch 2 · Seeing data',
  title: const [
    TitlePart('A chart made of the '),
    TitlePart('numbers themselves', AppColors.violet),
  ],
  subtitle: 'Stem-and-leaf plots · 2-minute animated lesson',
  createSim: () => StemLeafSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<StemLeafSim>(sim, _paintStemLeaf),
  stats: (sim) {
    final s = sim as StemLeafSim;
    final busiest = s.rows.entries.reduce((a, b) => b.value.length > a.value.length ? b : a);
    return [
      StatChip('placed', '${s.placed}/${StemLeafSim.n}', AppColors.yellow),
      StatChip('busiest', s.placed == 0 ? '…' : '${busiest.key}0s', AppColors.violet),
      StatChip('median', s.done ? quantileOf(s.data, .5).toStringAsFixed(1) : '…', AppColors.pink),
    ];
  },
  bigIdea: 'Split each number into a stem (the tens) and a leaf (the units). Each '
      'row is a bin of ten, and its leaves make a little bar, so turning the page '
      'sideways gives a histogram. Unlike a histogram, every original value can '
      'still be read back, and with sorted leaves you can count to the median.',
  formula: (sim) {
    final s = sim as StemLeafSim;
    if (s.placed == 0) return '73 → 7 | 3';
    final v = s.data[s.placed - 1];
    return '$v → ${v ~/ 10} | ${v % 10}   (key: 7 | 3 means 73)';
  },
  tryItTitle: 'Try it: new data',
  buildTryIt: (sim) {
    final s = sim as StemLeafSim;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ControlRow(children: [
          ActionButton('New scores', s.reset),
          ActionButton('Place all', () => s.runMany(StemLeafSim.n)),
        ]),
        const SizedBox(height: 8),
        const TryNote('Tilt your head left: the rows of leaves are the bars of a histogram.'),
      ],
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'In a stem-and-leaf plot with key "6 | 4 = 64", what does the row "8 | 0 2 7" show?',
      options: ['8, 0, 2, 7', '80, 82, 87', '8.027', '802 and 7'],
      answer: 1,
      explanation: 'The stem 8 is the tens digit; each leaf adds a units digit.',
    ),
    QuizQuestion(
      prompt: 'An advantage over a histogram is that a stem-and-leaf plot…',
      options: [
        'Works for millions of values',
        'Keeps every original value',
        'Shows categories',
        'Needs no sorting',
      ],
      answer: 1,
      explanation: 'You can rebuild the exact data from it. Histograms only keep counts.',
    ),
    QuizQuestion(
      prompt: 'The row with the most leaves tells you…',
      options: ['The mean', 'Where the data is most concentrated', 'The range', 'Nothing'],
      answer: 1,
      explanation: 'The longest row is the tallest "bar": the most common ten-band.',
    ),
  ],
);

// ===== lib/lessons/total_probability.dart =====
/// Bulbs from three factories; what share of all bulbs is faulty?
class TotalProbSim extends TickSim {
  TotalProbSim({super.rng});

  static const List<String> names = ['A', 'B', 'C'];
  static const List<double> shares = [0.5, 0.3, 0.2];
  static const List<Color> colors = [AppColors.blue, AppColors.green, AppColors.orange];

  /// Faulty rate of each factory (C adjustable).
  List<double> faultRates = [0.04, 0.06, 0.15];

  List<int> made = [0, 0, 0];
  List<int> faulty = [0, 0, 0];

  /// Last bulb: (factory, faulty).
  (int, bool)? last;

  int get total => made.fold(0, (a, b) => a + b);
  int get totalFaulty => faulty.fold(0, (a, b) => a + b);

  double get theory {
    var t = 0.0;
    for (var i = 0; i < 3; i++) {
      t += shares[i] * faultRates[i];
    }
    return t;
  }

  @override
  double get interval => total < 10 ? 0.5 : 0.03;

  @override
  void tick() {
    var r = rng.nextDouble();
    var f = 0;
    while (f < 2 && r > shares[f]) {
      r -= shares[f];
      f++;
    }
    final bad = rng.nextDouble() < faultRates[f];
    made[f]++;
    if (bad) faulty[f]++;
    last = (f, bad);
  }

  @override
  void restart() {
    made = [0, 0, 0];
    faulty = [0, 0, 0];
    last = null;
  }
}

void _paintTotal(Canvas canvas, Size size, TotalProbSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 16.0;
  final right = w - 16;
  const top = 34.0;
  final colBottom = h * 0.62;
  final total = right - left;

  // Each factory's column: width = share of production, faulty part on top.
  var x = left;
  label(canvas, 'Width = share of all bulbs · pink = faulty part', Offset(w / 2, 14), size: 11, color: AppColors.muted);
  for (var i = 0; i < 3; i++) {
    final cw = total * TotalProbSim.shares[i];
    final rect = Rect.fromLTWH(x + 2, top, cw - 4, colBottom - top);
    roundRect(canvas, rect, TotalProbSim.colors[i].withValues(alpha: 0.25), radius: 8);
    // Faulty band drawn 3× taller so small rates stay visible.
    final fh = (colBottom - top) * (sim.faultRates[i] * 3).clamp(0.0, 1.0);
    roundRect(canvas, Rect.fromLTWH(x + 2, top, cw - 4, fh), AppColors.pink.withValues(alpha: 0.75), radius: 8);
    label(canvas, 'Factory ${TotalProbSim.names[i]}', Offset(x + cw / 2, colBottom - 40),
        size: 12, color: TotalProbSim.colors[i]);
    label(canvas, '${(TotalProbSim.shares[i] * 100).round()}% of bulbs', Offset(x + cw / 2, colBottom - 22),
        size: 10, color: AppColors.ink);
    label(canvas, '${(sim.faultRates[i] * 100).round()}% faulty', Offset(x + cw / 2, colBottom - 9),
        size: 10, color: AppColors.pink);
    if (sim.last?.$1 == i) {
      label(canvas, sim.last!.$2 ? '💡✗' : '💡', Offset(x + cw / 2, top + (colBottom - top) / 2), size: 20);
    }
    x += cw;
  }
  label(canvas, '(faulty bands drawn 3× taller to be visible)', Offset(w / 2, colBottom + 12),
      size: 9, color: AppColors.muted);

  // The overall faulty share, built from the three pieces.
  final y = colBottom + 36;
  label(canvas, 'All faulty bulbs, by factory', Offset(left, y), size: 12, align: TextAlign.left);
  final barY = y + 14;
  final barW = right - left;
  roundRect(canvas, Rect.fromLTWH(left, barY, barW, 26), Colors.white, radius: 8);
  var bx = left;
  for (var i = 0; i < 3; i++) {
    final piece = TotalProbSim.shares[i] * sim.faultRates[i];
    final pw = barW * piece / 0.2; // scale: full bar = 20%
    roundRect(canvas, Rect.fromLTWH(bx, barY, pw, 26), TotalProbSim.colors[i], radius: 6);
    bx += pw;
  }
  label(canvas, '= ${(sim.theory * 100).toStringAsFixed(1)}% of all bulbs are faulty', Offset(left, barY + 40),
      size: 12, color: AppColors.pink, align: TextAlign.left);
  label(canvas, 'full bar = 20%', Offset(right, barY + 40), size: 10, color: AppColors.muted, align: TextAlign.right);
  final seen = sim.total == 0 ? 0 : sim.totalFaulty / sim.total;
  label(canvas, 'seen: ${sim.totalFaulty} faulty of ${sim.total} = ${(seen * 100).toStringAsFixed(1)}%',
      Offset(w / 2, h - 12),
      size: 12, color: AppColors.muted);
}

final LessonSpec totalProbabilityLesson = LessonSpec(
  id: 'total_probability',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('Add up the '),
    TitlePart('pieces', AppColors.orange),
    TitlePart(' from every source'),
  ],
  subtitle: 'The law of total probability · 2-minute animated lesson',
  createSim: () => TotalProbSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<TotalProbSim>(sim, _paintTotal),
  stats: (sim) {
    final s = sim as TotalProbSim;
    return [
      StatChip('bulbs', '${s.total}', AppColors.yellow),
      StatChip('faulty', '${s.totalFaulty}', AppColors.pink),
      StatChip('theory', '${(s.theory * 100).toStringAsFixed(1)}%', AppColors.violet),
    ];
  },
  bigIdea: 'Every bulb comes from exactly one factory. So the faulty bulbs split into '
      'three non-overlapping groups: faulty from A, from B, from C. Each group is '
      'the factory\'s share times its faulty rate. Add the pieces to get the '
      'overall rate. A small factory with a high fault rate can still matter a lot.',
  formula: (sim) {
    final s = sim as TotalProbSim;
    final r = s.faultRates;
    return 'P(faulty) = Σ P(factory) × P(faulty | factory)\n'
        '= 0.5×${r[0]} + 0.3×${r[1]} + 0.2×${r[2].toStringAsFixed(2)} = ${s.theory.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: factory C\'s fault rate',
  buildTryIt: (sim) {
    final s = sim as TotalProbSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '1%',
            right: '30%',
            value: s.faultRates[2],
            min: 0.01,
            max: 0.3,
            divisions: 29,
            label: '${(s.faultRates[2] * 100).round()}%',
            onChanged: (v) => s.change(() => s.faultRates = [0.04, 0.06, v]),
          ),
          ControlRow(children: [ActionButton('Make 2,000 bulbs', () => s.runMany(2000))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: '60% of days are sunny (you walk late 10% of them) and 40% rainy (late 50%). '
          'Overall P(late)?',
      options: ['0.30', '0.26', '0.60', '0.06'],
      answer: 1,
      explanation: '0.6 × 0.1 + 0.4 × 0.5 = 0.06 + 0.20 = 0.26.',
    ),
    QuizQuestion(
      prompt: 'The law of total probability needs the groups (factories) to…',
      options: [
        'Be equal in size',
        'Not overlap and together cover everything',
        'Have the same fault rate',
        'Be independent',
      ],
      answer: 1,
      explanation: 'Each outcome must fall into exactly one group so nothing is missed '
          'or counted twice.',
    ),
    QuizQuestion(
      prompt: 'Factory A makes 90% of bulbs with 1% faulty; B makes 10% with 20% faulty. '
          'Which contributes more faulty bulbs?',
      options: ['A', 'B', 'Equal', 'Can\'t tell'],
      answer: 1,
      explanation: 'A: 0.9 × 0.01 = 0.009. B: 0.1 × 0.2 = 0.02. The small factory '
          'adds more than twice as many.',
    ),
  ],
);

// ===== lib/lessons/tree_diagrams.dart =====
/// Two draws from a bag of 3 red and 2 blue balls.
class TreeSim extends TickSim {
  TreeSim({super.rng});

  static const int red = 3, blue = 2;

  bool replace = false;

  /// Last path: (first is red, second is red).
  (bool, bool)? last;

  /// counts for RR, RB, BR, BB.
  List<int> counts = List.filled(4, 0);

  int get trials => counts.fold(0, (a, b) => a + b);

  /// P(second red | first red / blue).
  double secondRed(bool firstRed) {
    if (replace) return red / (red + blue);
    return firstRed ? (red - 1) / (red + blue - 1) : red / (red + blue - 1);
  }

  double get firstRed => red / (red + blue);

  List<double> get theory => [
        firstRed * secondRed(true),
        firstRed * (1 - secondRed(true)),
        (1 - firstRed) * secondRed(false),
        (1 - firstRed) * (1 - secondRed(false)),
      ];

  @override
  double get interval => trials < 6 ? 1.0 : 0.12;

  @override
  void tick() {
    final a = rng.nextDouble() < firstRed;
    final b = rng.nextDouble() < secondRed(a);
    last = (a, b);
    counts[(a ? 0 : 2) + (b ? 0 : 1)]++;
  }

  @override
  void restart() {
    counts = List.filled(4, 0);
    last = null;
  }
}

String _frac(double p, int denom) => '${(p * denom).round()}/$denom';

void _paintTree(Canvas canvas, Size size, TreeSim sim) {
  final w = size.width;
  final h = size.height;
  const top = 26.0;
  final bottom = h - 30;
  final rootX = 20.0, midX = w * 0.36, leafX = w * 0.66;
  final rootY = (top + bottom) / 2;
  double leafY(int i) => top + (bottom - top) * (i + 0.5) / 4;
  final mids = [(leafY(0) + leafY(1)) / 2, (leafY(2) + leafY(3)) / 2];
  final denom2 = sim.replace ? 5 : 4;

  label(canvas, '1st draw', Offset(midX, 10), size: 11, color: AppColors.muted);
  label(canvas, '2nd draw', Offset(leafX, 10), size: 11, color: AppColors.muted);

  final last = sim.last;
  final t = sim.phase;
  for (var a = 0; a < 2; a++) {
    final firstRed = a == 0;
    final onPath1 = last != null && last.$1 == firstRed;
    final p1 = firstRed ? sim.firstRed : 1 - sim.firstRed;
    final c1 = firstRed ? AppColors.pink : AppColors.blue;
    line(canvas, Offset(rootX, rootY), Offset(midX, mids[a]), onPath1 ? c1 : c1.withValues(alpha: 0.35),
        width: onPath1 ? 4 : 2);
    label(canvas, _frac(p1, 5), Offset((rootX + midX) / 2 - 6, (rootY + mids[a]) / 2 + (a == 0 ? -12 : 12)),
        size: 12, color: c1);
    canvas.drawCircle(Offset(midX, mids[a]), 11, Paint()..color = c1);
    for (var b = 0; b < 2; b++) {
      final secondRed = b == 0;
      final i = a * 2 + b;
      final onPath = onPath1 && last.$2 == secondRed;
      final p2 = secondRed ? sim.secondRed(firstRed) : 1 - sim.secondRed(firstRed);
      final c2 = secondRed ? AppColors.pink : AppColors.blue;
      line(canvas, Offset(midX, mids[a]), Offset(leafX, leafY(i)), onPath ? c2 : c2.withValues(alpha: 0.35),
          width: onPath ? 4 : 2);
      label(canvas, _frac(p2, denom2), Offset((midX + leafX) / 2, (mids[a] + leafY(i)) / 2 - 10), size: 11, color: c2);
      canvas.drawCircle(Offset(leafX, leafY(i)), 9, Paint()..color = c2);
      // Leaf: outcome, theory and what we've seen.
      final name = '${firstRed ? 'R' : 'B'}${secondRed ? 'R' : 'B'}';
      final seen = sim.trials == 0 ? 0 : sim.counts[i] / sim.trials;
      label(canvas, '$name ${sim.theory[i].toStringAsFixed(2)}', Offset(leafX + 16, leafY(i) - 7),
          size: 12, align: TextAlign.left);
      label(canvas, 'seen ${seen.toStringAsFixed(2)}', Offset(leafX + 16, leafY(i) + 9),
          size: 10, color: AppColors.muted, align: TextAlign.left);
    }
  }
  canvas.drawCircle(Offset(rootX, rootY), 7, Paint()..color = AppColors.ink);

  // A ball travelling along the latest path.
  if (last != null && sim.trials <= 6) {
    final a = last.$1 ? 0 : 1;
    final i = a * 2 + (last.$2 ? 0 : 1);
    final p = t < 0.5
        ? Offset.lerp(Offset(rootX, rootY), Offset(midX, mids[a]), t * 2)!
        : Offset.lerp(Offset(midX, mids[a]), Offset(leafX, leafY(i)), (t - 0.5) * 2)!;
    canvas.drawCircle(p, 7, Paint()..color = AppColors.yellow);
  }
  label(canvas, sim.replace ? 'Ball goes back in the bag' : 'Ball stays out of the bag', Offset(w / 2, h - 10),
      size: 12, color: AppColors.violet);
}

final LessonSpec treeDiagramsLesson = LessonSpec(
  id: 'tree_diagrams',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('Follow the '),
    TitlePart('branches', AppColors.green),
    TitlePart(', multiply along the way'),
  ],
  subtitle: 'Tree diagrams · 2-minute animated lesson',
  createSim: () => TreeSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<TreeSim>(sim, _paintTree),
  stats: (sim) {
    final s = sim as TreeSim;
    return [
      StatChip('draws', '${s.trials}', AppColors.yellow),
      StatChip('P(RR)', s.theory[0].toStringAsFixed(2), AppColors.pink),
      StatChip('P(BB)', s.theory[3].toStringAsFixed(2), AppColors.blue),
    ];
  },
  bigIdea: 'A bag holds 3 red and 2 blue balls; you take two. Each branch carries the '
      'chance of that step, given everything before it. If the first ball stays '
      'out, the bag changes, so the second-draw chances depend on the first. '
      'Multiply along a path for one outcome; add paths for "either" outcomes.',
  formula: (sim) {
    final s = sim as TreeSim;
    final d = s.replace ? 5 : 4;
    return 'P(RR) = 3/5 × ${_frac(s.secondRed(true), d)} = ${s.theory[0].toStringAsFixed(2)}   '
        'P(one of each) = ${(s.theory[1] + s.theory[2]).toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: put the ball back or not',
  buildTryIt: (sim) {
    final s = sim as TreeSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<bool>(
            options: const {false: 'Keep it out', true: 'Put it back'},
            selected: s.replace,
            onSelected: (v) => s.change(() => s.replace = v),
          ),
          const SizedBox(height: 8),
          ControlRow(children: [ActionButton('Draw 500 pairs', () => s.runMany(500))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A bag has 3 red and 2 blue. You draw two without replacement. P(both red)?',
      options: ['9/25', '3/10', '6/25', '1/2'],
      answer: 1,
      explanation: '3/5 × 2/4 = 6/20 = 3/10.',
    ),
    QuizQuestion(
      prompt: 'Along one path of a tree diagram, you…',
      options: ['Add the probabilities', 'Multiply the probabilities', 'Subtract them', 'Average them'],
      answer: 1,
      explanation: 'Each step happens and then the next: multiply.',
    ),
    QuizQuestion(
      prompt: 'P(RB) = 0.3 and P(BR) = 0.3. What is P(one of each colour)?',
      options: ['0.09', '0.3', '0.6', '0.9'],
      answer: 2,
      explanation: 'Two separate paths lead to "one of each": add them, 0.3 + 0.3.',
    ),
  ],
);

// ===== lib/lessons/types_of_data.dart =====
enum DataKind { nominal, ordinal, discrete, continuous }

const Map<DataKind, String> kDataKindNames = {
  DataKind.nominal: 'Categories',
  DataKind.ordinal: 'Ordered categories',
  DataKind.discrete: 'Counts',
  DataKind.continuous: 'Measurements',
};

const Map<DataKind, Color> kDataKindColors = {
  DataKind.nominal: AppColors.pink,
  DataKind.ordinal: AppColors.orange,
  DataKind.discrete: AppColors.green,
  DataKind.continuous: AppColors.blue,
};

/// Example values with their kind.
const List<(String, DataKind)> kDataExamples = [
  ('Eye colour: brown', DataKind.nominal),
  ('T-shirt size: M', DataKind.ordinal),
  ('Siblings: 2', DataKind.discrete),
  ('Height: 172.4 cm', DataKind.continuous),
  ('Blood group: O+', DataKind.nominal),
  ('Rating: ★★★★', DataKind.ordinal),
  ('Goals scored: 3', DataKind.discrete),
  ('Time: 9.58 s', DataKind.continuous),
  ('City: Pune', DataKind.nominal),
  ('Grade: B+', DataKind.ordinal),
  ('Cars owned: 1', DataKind.discrete),
  ('Weight: 61.2 kg', DataKind.continuous),
  ('Favourite fruit: mango', DataKind.nominal),
  ('Spice level: hot', DataKind.ordinal),
  ('Emails today: 14', DataKind.discrete),
  ('Temperature: 31.6 °C', DataKind.continuous),
];

class TypesOfDataSim extends TickSim {
  TypesOfDataSim({super.rng});

  /// How many examples have been sorted.
  int sorted = 0;

  @override
  double get interval => 1.3;

  (String, DataKind) get current => kDataExamples[sorted % kDataExamples.length];

  Map<DataKind, int> get counts {
    final c = {for (final k in DataKind.values) k: 0};
    for (var i = 0; i < sorted; i++) {
      final k = kDataExamples[i % kDataExamples.length].$2;
      c[k] = c[k]! + 1;
    }
    return c;
  }

  @override
  void tick() => sorted++;

  @override
  void restart() => sorted = 0;
}

void _paintTypes(Canvas canvas, Size size, TypesOfDataSim sim) {
  final w = size.width;
  final h = size.height;
  final binTop = h * 0.5;
  final binW = (w - 30) / 2;
  final binH = (h - binTop - 28) / 2;

  // Four bins in a 2×2 grid: categorical on top, numerical below.
  final bins = <DataKind, Rect>{};
  for (var i = 0; i < 4; i++) {
    final kind = DataKind.values[i];
    final r = Rect.fromLTWH(10 + (i % 2) * (binW + 10), binTop + (i ~/ 2) * (binH + 20), binW, binH);
    bins[kind] = r;
    roundRect(canvas, r, kDataKindColors[kind]!.withValues(alpha: 0.18), radius: 14);
    label(canvas, kDataKindNames[kind]!, Offset(r.center.dx, r.top + 14), size: 12, color: kDataKindColors[kind]!);
    label(canvas, '${sim.counts[kind]}', r.center.translate(0, 8), size: 26, color: kDataKindColors[kind]!);
  }
  label(canvas, 'CATEGORICAL: words / labels', Offset(w / 2, binTop - 10), size: 11, color: AppColors.muted);
  label(canvas, 'NUMERICAL: numbers you can add', Offset(w / 2, binTop + binH + 10), size: 10, color: AppColors.muted);

  // The card in flight: from the top centre into its bin.
  final (text, kind) = sim.current;
  final t = Curves.easeInOutCubic.transform(math.min(1, sim.phase * 1.4));
  final from = Offset(w / 2, h * 0.16);
  final to = bins[kind]!.center;
  final pos = Offset.lerp(from, to, t)!;
  final scale = 1 - 0.5 * t;
  final cardW = w * 0.7 * scale;
  final cardH = 46.0 * scale;
  final card = Rect.fromCenter(center: pos, width: cardW, height: cardH);
  canvas.drawRRect(
    RRect.fromRectAndRadius(card.shift(const Offset(0, 3)), const Radius.circular(12)),
    Paint()..color = AppColors.ink.withValues(alpha: 0.08),
  );
  roundRect(canvas, card, Colors.white, radius: 12);
  canvas.drawRRect(
    RRect.fromRectAndRadius(card, const Radius.circular(12)),
    Paint()
      ..color = kDataKindColors[kind]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );
  label(canvas, text, pos, size: 15 * scale);
  if (t < 0.15) {
    label(canvas, '→ ${kDataKindNames[kind]}', Offset(w / 2, h * 0.32), size: 13, color: kDataKindColors[kind]!);
  }
}

final LessonSpec typesOfDataLesson = LessonSpec(
  id: 'types_of_data',
  chapterLabel: 'Ch 1 · Data & averages',
  title: const [
    TitlePart('Labels', AppColors.pink),
    TitlePart(' or '),
    TitlePart('numbers', AppColors.blue),
    TitlePart('? It changes everything'),
  ],
  subtitle: 'Types of data · 2-minute animated lesson',
  createSim: () => TypesOfDataSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<TypesOfDataSim>(sim, _paintTypes),
  stats: (sim) {
    final c = (sim as TypesOfDataSim).counts;
    return [
      StatChip('sorted', '${sim.sorted}', AppColors.yellow),
      StatChip('categorical', '${c[DataKind.nominal]! + c[DataKind.ordinal]!}', AppColors.pink),
      StatChip('numerical', '${c[DataKind.discrete]! + c[DataKind.continuous]!}', AppColors.blue),
    ];
  },
  bigIdea: 'Categorical data are labels: you can count them but not average them. '
      'Some labels have a natural order (small, medium, large). Numerical data '
      'are real numbers: counts jump in whole steps, measurements can take any '
      'value in between. The type decides which charts and averages make sense.',
  formula: (_) => 'Can you add it? → numerical.  Can you order it? → ordinal.',
  tryItTitle: 'Try it: sort these yourself',
  buildTryIt: (_) => const _SortGame(),
  quiz: const [
    QuizQuestion(
      prompt: 'Which of these is continuous data?',
      options: ['Number of pets', 'Shoe brand', 'Time to run 100 m', 'Exam grade A–F'],
      answer: 2,
      explanation: 'Time can be measured ever more finely (11.2 s, 11.23 s…). Pets '
          'are counted in whole numbers.',
    ),
    QuizQuestion(
      prompt: 'Survey answers "poor, fair, good, excellent" are…',
      options: ['Nominal', 'Ordinal', 'Discrete', 'Continuous'],
      answer: 1,
      explanation: 'They are labels with a natural order, but the gaps between them '
          'are not measurable numbers.',
    ),
    QuizQuestion(
      prompt: 'Why can\'t you take the mean of PIN codes?',
      options: [
        'They are too long',
        'They are labels that just look like numbers',
        'They are always even',
        'You can',
      ],
      answer: 1,
      explanation: 'A PIN code names a place. Adding two PIN codes means nothing, '
          'so they are categorical.',
    ),
  ],
);

class _SortGame extends StatefulWidget {
  const _SortGame();

  @override
  State<_SortGame> createState() => _SortGameState();
}

class _SortGameState extends State<_SortGame> {
  final _rng = math.Random();
  late int _item = _rng.nextInt(kDataExamples.length);
  DataKind? _picked;
  int _right = 0;
  int _total = 0;

  void _pick(DataKind k) {
    if (_picked != null) return;
    setState(() {
      _picked = k;
      _total++;
      if (k == kDataExamples[_item].$2) _right++;
    });
  }

  void _next() => setState(() {
        _picked = null;
        _item = (_item + 1 + _rng.nextInt(kDataExamples.length - 1)) % kDataExamples.length;
      });

  @override
  Widget build(BuildContext context) {
    final (text, kind) = kDataExamples[_item];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in DataKind.values)
              ChoiceChip(
                label: Text(kDataKindNames[k]!, style: const TextStyle(fontWeight: FontWeight.w800)),
                selected: _picked == k,
                selectedColor: k == kind ? AppColors.green : AppColors.orange,
                onSelected: (_) => _pick(k),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                _picked == null
                    ? 'Score: $_right / $_total'
                    : _picked == kind
                        ? 'Right! Score: $_right / $_total'
                        : 'It\'s ${kDataKindNames[kind]}. Score: $_right / $_total',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (_picked != null) ActionButton('Next', _next),
          ],
        ),
      ],
    );
  }
}

// ===== lib/lessons/variance_rv.dart =====
/// Two zero-average games played by many players, round after round.
/// Steady: win or lose ₹1 on a coin. Risky: win ₹k with chance 1/(k+1),
/// otherwise lose ₹1. Same mean (0), very different spread.
class VarianceSim extends TickSim {
  VarianceSim({super.rng}) {
    restart();
  }

  static const int players = 24;
  static const int maxRounds = 60;

  int k = 9;
  int round = 0;
  late List<List<double>> steady;
  late List<List<double>> risky;

  double get varSteady => 1;
  double get varRisky => k.toDouble(); // k²/(k+1) + 1·k/(k+1) = k

  double _sdOfFinal(List<List<double>> paths) => sdOf([for (final p in paths) p.last]);
  double get spreadSteady => _sdOfFinal(steady);
  double get spreadRisky => _sdOfFinal(risky);

  @override
  double get interval => 0.12;

  @override
  void tick() {
    if (round >= maxRounds + 15) {
      restart();
      return;
    }
    if (round < maxRounds) {
      for (final p in steady) {
        p.add(p.last + (rng.nextBool() ? 1 : -1));
      }
      for (final p in risky) {
        p.add(p.last + (rng.nextDouble() < 1 / (k + 1) ? k : -1));
      }
    }
    round++;
  }

  @override
  void restart() {
    round = 0;
    steady = List.generate(players, (_) => [0.0]);
    risky = List.generate(players, (_) => [0.0]);
  }
}

void _paintVariance(Canvas canvas, Size size, VarianceSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 40.0;
  final right = w - 12;

  void panel(List<List<double>> paths, double top, double bottom, Color color, String name, double variance) {
    final range = math.max(12.0, 2.6 * math.sqrt(variance * VarianceSim.maxRounds));
    double yFor(double v) => (top + bottom) / 2 - v.clamp(-range, range) / range * (bottom - top) / 2;
    double xFor(int i) => left + i / VarianceSim.maxRounds * (right - left);
    label(canvas, name, Offset(left, top - 8), size: 12, color: color, align: TextAlign.left);
    line(canvas, Offset(left, yFor(0)), Offset(right, yFor(0)), AppColors.ink.withValues(alpha: 0.5));
    label(canvas, '₹0', Offset(left - 6, yFor(0)), size: 10, color: AppColors.muted, align: TextAlign.right);
    label(canvas, '+${range.round()}', Offset(left - 6, top + 4),
        size: 9, color: AppColors.muted, align: TextAlign.right);
    label(canvas, '−${range.round()}', Offset(left - 6, bottom - 4),
        size: 9, color: AppColors.muted, align: TextAlign.right);
    // ±1 sd envelope of the total after i rounds: sd·√i.
    final env = Path();
    for (var i = 0; i <= VarianceSim.maxRounds; i++) {
      final y = yFor(math.sqrt(variance * i));
      i == 0 ? env.moveTo(xFor(i), y) : env.lineTo(xFor(i), y);
    }
    for (var i = VarianceSim.maxRounds; i >= 0; i--) {
      env.lineTo(xFor(i), yFor(-math.sqrt(variance * i)));
    }
    canvas.drawPath(env, Paint()..color = color.withValues(alpha: 0.12));
    for (final p in paths) {
      final path = Path()..moveTo(xFor(0), yFor(p.first));
      for (var i = 1; i < p.length; i++) {
        path.lineTo(xFor(i), yFor(p[i]));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  final mid = h / 2;
  panel(sim.steady, 20, mid - 16, AppColors.blue, 'Steady: ±₹1 on a coin', sim.varSteady);
  panel(sim.risky, mid + 20, h - 26, AppColors.pink, 'Risky: +₹${sim.k} or −₹1', sim.varRisky);
  label(
      canvas,
      'round ${math.min(sim.round, VarianceSim.maxRounds)} of ${VarianceSim.maxRounds} · '
      '${VarianceSim.players} players each',
      Offset(w / 2, h - 10),
      size: 11,
      color: AppColors.muted);
}

final LessonSpec varianceRvLesson = LessonSpec(
  id: 'variance_rv',
  chapterLabel: 'Ch 6 · Random variables',
  title: const [
    TitlePart('Same average, very different '),
    TitlePart('ride', AppColors.pink),
  ],
  subtitle: 'Variance of a random variable · 2-minute animated lesson',
  createSim: () => VarianceSim(),
  visualAspectRatio: 0.85,
  buildVisual: (sim) => simCanvas<VarianceSim>(sim, _paintVariance),
  stats: (sim) {
    final v = sim as VarianceSim;
    return [
      StatChip('mean', '₹0 both', AppColors.yellow),
      StatChip('Var steady', v.varSteady.toStringAsFixed(0), AppColors.blue),
      StatChip('Var risky', v.varRisky.toStringAsFixed(0), AppColors.pink),
    ];
  },
  bigIdea: 'Both games average ₹0 a round, so their expected values match. But the '
      'risky game\'s results sit far from that average, so players\' totals fan '
      'out wildly: a few get rich, most slowly lose. Variance measures this: the '
      'expected squared distance from the mean. Its square root, the standard '
      'deviation, is in rupees. Spread after n rounds grows like sd × √n.',
  formula: (sim) {
    final v = sim as VarianceSim;
    return 'Var(X) = E[(X − μ)²] · risky: ${v.k}²×1/${v.k + 1} + 1²×${v.k}/${v.k + 1} = ${v.k} · '
        'sd = ${math.sqrt(v.k).toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: make the risky game riskier',
  buildTryIt: (sim) {
    final v = sim as VarianceSim;
    return watch(
      v,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'win ₹1',
            right: '₹20',
            value: v.k.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: 'win ₹${v.k}, 1 in ${v.k + 1}',
            onChanged: (x) => v.change(() => v.k = x.round()),
          ),
          TryNote('Win ₹${v.k} with chance 1/${v.k + 1}, otherwise lose ₹1: still ₹0 on average. '
              'At ₹1 the two games are identical.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Two investments both average 8% a year. A has variance 1, B has variance 25. '
          'Which is riskier?',
      options: ['A', 'B', 'Same risk', 'Can\'t tell'],
      answer: 1,
      explanation: 'Same mean, but B\'s results swing much further from it.',
    ),
    QuizQuestion(
      prompt: 'X is +1 or −1 with equal chance. What is Var(X)?',
      options: ['0', '0.5', '1', '2'],
      answer: 2,
      explanation: 'The mean is 0, and both values are 1 away from it: (1² + 1²)/2 = 1.',
    ),
    QuizQuestion(
      prompt: 'If a variance is 16, the standard deviation is…',
      options: ['4', '8', '16', '256'],
      answer: 0,
      explanation: 'The sd is the square root of the variance: √16 = 4.',
    ),
  ],
);

// ===== lib/lessons/venn.dart =====
// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

/// Darts land uniformly in a unit square holding two circles, A and B.
class VennSim extends LessonSim {
  VennSim({math.Random? rng}) : _rng = rng ?? math.Random();

  /// Small enough that both circles stay inside the square at [maxSeparation].
  static const double radius = 0.22;
  static const double maxSeparation = 0.56;

  /// Most darts kept for drawing; counting continues beyond this.
  static const int maxDrawn = 700;

  final math.Random _rng;

  /// Distance between the circle centres (0 = same circle).
  double separation = 0.26;

  final List<Offset> darts = [];
  int total = 0;
  int inA = 0;
  int inB = 0;
  int inBoth = 0;

  double _timer = 0;

  Offset get centreA => Offset(0.5 - separation / 2, 0.5);
  Offset get centreB => Offset(0.5 + separation / 2, 0.5);

  bool isInA(Offset p) => (p - centreA).distance <= radius;
  bool isInB(Offset p) => (p - centreB).distance <= radius;

  /// Exact areas (the true probabilities).
  double get pA => math.pi * radius * radius;
  double get pBoth {
    final d = separation;
    if (mutuallyExclusive) return 0;
    if (d == 0) return pA;
    final r = radius;
    return 2 * r * r * math.acos(d / (2 * r)) - d / 2 * math.sqrt(4 * r * r - d * d);
  }

  double get pEither => 2 * pA - pBoth;

  bool get mutuallyExclusive => separation >= 2 * radius - 1e-9;

  double get estA => total == 0 ? 0 : inA / total;
  double get estB => total == 0 ? 0 : inB / total;
  double get estBoth => total == 0 ? 0 : inBoth / total;
  double get estEither => total == 0 ? 0 : (inA + inB - inBoth) / total;

  double get _rate => total < 30 ? 6 : (total < 200 ? 30 : 90);

  @override
  void advance(double dt) {
    _timer += dt * _rate;
    while (_timer >= 1) {
      _timer -= 1;
      _throw();
    }
    notifyListeners();
  }

  void _throw() {
    final p = Offset(_rng.nextDouble(), _rng.nextDouble());
    total++;
    final a = isInA(p);
    final b = isInB(p);
    if (a) inA++;
    if (b) inB++;
    if (a && b) inBoth++;
    if (darts.length < maxDrawn) darts.add(p);
  }

  void throwMany(int count) {
    for (var i = 0; i < count; i++) {
      _throw();
    }
    notifyListeners();
  }

  void setSeparation(double value) {
    separation = value;
    reset();
  }

  @override
  void step() {
    _throw();
    notifyListeners();
  }

  @override
  void reset() {
    darts.clear();
    total = inA = inB = inBoth = 0;
    _timer = 0;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class VennPainter extends CustomPainter {
  VennPainter(this.sim) : super(repaint: sim);

  final VennSim sim;

  static const double aspectRatio = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 14.0;
    final side = math.min(size.width, size.height) - pad * 2;
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    Offset toCanvas(Offset p) => origin + Offset(p.dx * side, p.dy * side);

    // Sample space.
    canvas.drawRRect(
      RRect.fromRectAndRadius(origin & Size(side, side), const Radius.circular(14)),
      Paint()..color = Colors.white,
    );
    _text(canvas, 'everything that can happen', origin + Offset(side / 2, 14), 11, AppColors.muted);

    // Circles.
    final r = VennSim.radius * side;
    for (final (c, color) in [(sim.centreA, AppColors.pink), (sim.centreB, AppColors.cyan)]) {
      canvas.drawCircle(toCanvas(c), r, Paint()..color = color.withValues(alpha: 0.18));
      canvas.drawCircle(
        toCanvas(c),
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Darts.
    final dotR = math.max(1.8, side * 0.007);
    for (final p in sim.darts) {
      final a = sim.isInA(p);
      final b = sim.isInB(p);
      final color = a && b
          ? AppColors.violet
          : a
              ? AppColors.pink
              : b
                  ? AppColors.cyan
                  : AppColors.peg.withValues(alpha: 0.7);
      canvas.drawCircle(toCanvas(p), dotR, Paint()..color = color);
    }

    // Labels.
    _text(canvas, 'A', toCanvas(sim.centreA) - Offset(r * 0.55, r * 0.75), 22, AppColors.pink);
    _text(canvas, 'B', toCanvas(sim.centreB) + Offset(r * 0.55, -r * 0.75), 22, AppColors.cyan);
    if (!sim.mutuallyExclusive) {
      _text(canvas, 'A and B', toCanvas(const Offset(0.5, 0.5)) + Offset(0, r * 1.25), 13, AppColors.violet);
    } else {
      _text(canvas, 'no overlap: mutually exclusive', origin + Offset(side / 2, side - 18), 12, AppColors.violet);
    }
  }

  void _text(Canvas canvas, String text, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant VennPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec vennLesson = LessonSpec(
  id: 'venn',
  chapterLabel: 'Ch 3 · Probability basics',
  title: const [
    TitlePart('Why '),
    TitlePart('A or B', AppColors.pink),
    TitlePart(' isn\'t just '),
    TitlePart('A + B', AppColors.cyan),
  ],
  subtitle: 'Addition rule & Venn diagrams · 2-minute animated lesson',
  createSim: () => VennSim(),
  visualAspectRatio: VennPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: VennPainter(sim as VennSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final v = sim as VennSim;
    return [
      StatChip('darts', '${v.total}', AppColors.yellow),
      StatChip('in A or B', '${(v.estEither * 100).toStringAsFixed(1)}%', AppColors.pink),
      StatChip('in both', '${(v.estBoth * 100).toStringAsFixed(1)}%', AppColors.violet),
    ];
  },
  bigIdea: 'Each dart is one random outcome, so the share of darts in a region is '
      'its probability. Add the darts in A to the darts in B and every purple '
      'dart in the overlap gets counted twice. Subtract the overlap once and the '
      'count is right. If the circles don\'t touch, there is nothing to subtract.',
  formula: (sim) {
    final v = sim as VennSim;
    return 'P(A or B) = P(A) + P(B) − P(A and B)\n'
        '= ${v.estA.toStringAsFixed(3)} + ${v.estB.toStringAsFixed(3)} − ${v.estBoth.toStringAsFixed(3)} '
        '= ${v.estEither.toStringAsFixed(3)}  (true ${v.pEither.toStringAsFixed(3)})';
  },
  tryItTitle: 'Try it: pull the circles apart',
  buildTryIt: (sim) => _VennControls(sim: sim as VennSim),
  quiz: const [
    QuizQuestion(
      prompt: 'In a class, 60% play cricket, 40% play football and 25% play both. '
          'What share plays at least one?',
      options: ['100%', '75%', '65%', '25%'],
      answer: 1,
      explanation: '60% + 40% − 25% = 75%. The 25% who play both were counted twice.',
    ),
    QuizQuestion(
      prompt: 'When can you simply add P(A) + P(B)?',
      options: [
        'Always',
        'When A and B can\'t happen together',
        'When P(A) = P(B)',
        'When both are below 50%',
      ],
      answer: 1,
      explanation: 'Mutually exclusive events have no overlap, so P(A and B) = 0 and '
          'there is nothing to subtract.',
    ),
    QuizQuestion(
      prompt: 'Roll one die. A = "even", B = "greater than 3". What is P(A or B)?',
      options: ['1/2', '2/3', '5/6', '1'],
      answer: 1,
      explanation: 'A = {2,4,6}, B = {4,5,6}, both = {4,6}. 3/6 + 3/6 − 2/6 = 4/6 = 2/3: '
          'the outcomes 2, 4, 5, 6.',
    ),
  ],
);

class _VennControls extends StatelessWidget {
  const _VennControls({required this.sim});
  final VennSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('overlap', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              Expanded(
                child: Slider(
                  value: sim.separation,
                  min: 0.08,
                  max: VennSim.maxSeparation,
                  divisions: 8,
                  onChanged: sim.setSeparation,
                ),
              ),
              const Text('apart', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ],
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  sim.mutuallyExclusive ? 'Mutually exclusive!' : 'Overlap: ${(sim.pBoth * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => sim.throwMany(500),
                child: const Text('Throw 500', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===== lib/lessons/zscores.dart =====
/// Two tests on different scales, morphing onto one standard scale and back.
class ZScoreSim extends LessonSim {
  static const double cycle = 8;

  // Maths: mean 60, sd 12. English: mean 72, sd 5.
  static const double mathsMean = 60, mathsSd = 12;
  static const double englishMean = 72, englishSd = 5;

  double maths = 78;
  double english = 80;

  /// Seconds into the loop.
  double t = 0;

  double get zMaths => (maths - mathsMean) / mathsSd;
  double get zEnglish => (english - englishMean) / englishSd;

  /// 0 = raw marks, 1 = standardised.
  double get morph {
    final s = t % cycle;
    if (s < 2) return 0;
    if (s < 4) return Curves.easeInOut.transform((s - 2) / 2);
    if (s < 6) return 1;
    return 1 - Curves.easeInOut.transform((s - 6) / 2);
  }

  @override
  void advance(double dt) {
    t = (t + dt) % cycle;
    notifyListeners();
  }

  @override
  void step() {
    t = ((t ~/ 2) * 2 + 2.0) % cycle;
    notifyListeners();
  }

  @override
  void reset() {
    t = 0;
    notifyListeners();
  }

  void setScores({double? maths, double? english}) {
    this.maths = maths ?? this.maths;
    this.english = english ?? this.english;
    notifyListeners();
  }
}

void _paintZ(Canvas canvas, Size size, ZScoreSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 14.0;
  final right = w - 14;
  final m = sim.morph;

  // Raw axis covers marks 20–100; z axis covers −3.5 … 3.5.
  double rawX(double mark) => left + (mark - 20) / 80 * (right - left);
  double zX(double z) => left + (z + 3.5) / 7 * (right - left);

  void curve(double mean, double sd, double top, double height, Color color, double score, String name) {
    final baseline = top + height;
    final path = Path();
    for (var i = 0; i <= 120; i++) {
      final z = -3.5 + 7 * i / 120;
      final x = rawX(mean + z * sd) * (1 - m) + zX(z) * m;
      // Peak height shrinks with sd on the raw scale (area stays 1); equal when standardised.
      final peakRaw = height * 5 / sd * 0.95;
      final peak = math.min(height * 0.95, peakRaw) * (1 - m) + height * 0.95 * m;
      final y = baseline - peak * math.exp(-z * z / 2);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    line(canvas, Offset(left, baseline), Offset(right, baseline), AppColors.peg);
    final z = (score - mean) / sd;
    final sx = rawX(score) * (1 - m) + zX(z) * m;
    line(canvas, Offset(sx, top + 4), Offset(sx, baseline), AppColors.ink, width: 2.5);
    canvas.drawCircle(Offset(sx, top + 4), 6, Paint()..color = AppColors.ink);
    final mx = rawX(mean) * (1 - m) + zX(0) * m;
    dashedLine(canvas, Offset(mx, top + 10), Offset(mx, baseline), color.withValues(alpha: 0.7));
    final text = m < 0.5 ? '$name ${score.round()} (avg ${mean.round()})' : '$name z = ${z.toStringAsFixed(2)}';
    label(canvas, text, Offset(left, top - 6), size: 13, color: color, align: TextAlign.left);
  }

  final panel = (h - 60) / 2;
  curve(ZScoreSim.mathsMean, ZScoreSim.mathsSd, 26, panel - 26, AppColors.blue, sim.maths, 'Maths');
  curve(ZScoreSim.englishMean, ZScoreSim.englishSd, 26 + panel, panel - 26, AppColors.pink, sim.english, 'English');

  // Axis labels morph between marks and z.
  final axisY = h - 18;
  if (m < 0.5) {
    for (var mark = 20; mark <= 100; mark += 20) {
      label(canvas, '$mark', Offset(rawX(mark.toDouble()), axisY), size: 11, color: AppColors.muted);
    }
  } else {
    for (var z = -3; z <= 3; z++) {
      label(canvas, z == 0 ? '0' : '${z > 0 ? '+' : ''}$z', Offset(zX(z.toDouble()), axisY),
          size: 11, color: AppColors.muted);
    }
  }
  label(canvas, m < 0.5 ? 'marks' : 'standard deviations from average', Offset(w - 16, axisY - 16),
      size: 10, color: AppColors.muted, align: TextAlign.right);
}

final LessonSpec zScoresLesson = LessonSpec(
  id: 'zscores',
  chapterLabel: 'Ch 1 · Data & averages',
  title: const [
    TitlePart('78 in Maths or 80 in English: which is '),
    TitlePart('better', AppColors.violet),
    TitlePart('?'),
  ],
  subtitle: 'Z-scores · 2-minute animated lesson',
  createSim: () => ZScoreSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<ZScoreSim>(sim, _paintZ),
  stats: (sim) {
    final z = sim as ZScoreSim;
    return [
      StatChip('Maths z', z.zMaths.toStringAsFixed(2), AppColors.blue),
      StatChip('English z', z.zEnglish.toStringAsFixed(2), AppColors.pink),
      StatChip('better', z.zMaths >= z.zEnglish ? 'Maths' : 'English', AppColors.yellow),
    ];
  },
  bigIdea: 'Raw marks from different tests can\'t be compared directly: the averages '
      'and spreads differ. A z-score asks "how many standard deviations above '
      'average is this?" Subtract the mean, divide by the sd, and both tests land '
      'on the same standard scale, where the higher z-score is the more impressive '
      'result.',
  formula: (sim) {
    final z = sim as ZScoreSim;
    return 'z = (x − μ) / σ\nMaths (${z.maths.round()} − 60) / 12 = ${z.zMaths.toStringAsFixed(2)} · '
        'English (${z.english.round()} − 72) / 5 = ${z.zEnglish.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: change the two scores',
  buildTryIt: (sim) {
    final z = sim as ZScoreSim;
    return watch(
      z,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Maths: ${z.maths.round()}  (avg 60, sd 12)', style: const TextStyle(fontWeight: FontWeight.w800)),
          Slider(value: z.maths, min: 30, max: 99, divisions: 69, onChanged: (v) => z.setScores(maths: v)),
          Text('English: ${z.english.round()}  (avg 72, sd 5)', style: const TextStyle(fontWeight: FontWeight.w800)),
          Slider(value: z.english, min: 55, max: 90, divisions: 35, onChanged: (v) => z.setScores(english: v)),
          const TryNote('English marks are bunched together, so each extra mark counts for more.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A test has mean 50 and sd 10. What is the z-score of 65?',
      options: ['0.65', '1.5', '15', '6.5'],
      answer: 1,
      explanation: '(65 − 50) / 10 = 1.5 standard deviations above average.',
    ),
    QuizQuestion(
      prompt: 'A z-score of 0 means…',
      options: ['The value is zero', 'The value equals the mean', 'The data has no spread', 'It is an outlier'],
      answer: 1,
      explanation: 'Zero standard deviations from the mean: exactly average.',
    ),
    QuizQuestion(
      prompt: 'Riya: 80 on a test with mean 70, sd 5. Sam: 85 on a test with mean 75, sd 10. '
          'Who did relatively better?',
      options: ['Sam', 'Riya', 'Equal', 'Can\'t tell'],
      answer: 1,
      explanation: 'Riya z = 10/5 = 2. Sam z = 10/10 = 1. Riya was further above her '
          'class average.',
    ),
  ],
);

// ===== lib/screens/learn_screen.dart =====
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      child: PhoneWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Row(
              children: [
                AppLogo(),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                StreakChip(),
                SizedBox(width: 8),
                XpChip(),
              ],
            ),
            const SizedBox(height: 22),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(text: 'Master '),
                  TextSpan(text: 'probability', style: TextStyle(color: AppColors.pink)),
                  TextSpan(text: ' & '),
                  TextSpan(text: 'statistics', style: TextStyle(color: AppColors.violet)),
                  TextSpan(text: ' by watching it happen.'),
                ],
              ),
              style: kDisplay.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 20),
            const _DailyGoalCard(),
            const SizedBox(height: 12),
            const _ContinueCard(),
            if (!state.premium) ...[
              const SizedBox(height: 12),
              const _UnlockBanner(),
            ],
            const SizedBox(height: 26),
            SectionLabel('${kChapters.length} chapters · $kLessonCount lessons'),
            const SizedBox(height: 12),
            for (final chapter in kChapters) ...[
              _ChapterCard(key: ValueKey(chapter.number), chapter: chapter),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opens a lesson, or explains why it can't be opened yet.
void openLesson(BuildContext context, Lesson lesson) {
  final spec = lesson.id == null ? null : lessonRegistry[lesson.id];
  if (spec == null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${lesson.title}" is being animated. Coming soon!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    return;
  }
  if (!AppScope.read(context).canOpen(spec.id)) {
    Navigator.of(context).push(PaywallScreen.route(reason: lesson.title));
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => LessonScreen(spec: spec)),
  );
}

/// The lesson to suggest next: the first built, openable lesson not yet
/// finished, in catalogue order. Falls back to the first built lesson.
LessonSpec nextLessonFor(AppState state) {
  for (final c in kChapters) {
    for (final l in c.lessons) {
      final spec = lessonRegistry[l.id];
      if (spec != null && state.canOpen(spec.id) && !state.completed.contains(spec.id)) return spec;
    }
  }
  return lessonRegistry[kLessonsById.keys.firstWhere(lessonRegistry.containsKey)]!;
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    // Three dots of a die face, in brand colours.
    final dot = size * 0.175;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.175),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Stack(
        children: [
          Align(alignment: Alignment.topLeft, child: _Dot(AppColors.pink, dot)),
          Align(alignment: Alignment.center, child: _Dot(AppColors.yellow, dot)),
          Align(alignment: Alignment.bottomRight, child: _Dot(AppColors.cyan, dot)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color, this.size);
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final left = s.dailyGoal - s.todayXp;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ProgressRing(
            value: s.todayXp / s.dailyGoal,
            color: AppColors.green,
            size: 52,
            stroke: 7,
            child: Icon(
              s.goalMetToday ? Icons.check_rounded : Icons.flag_rounded,
              color: s.goalMetToday ? AppColors.green : AppColors.muted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.goalMetToday ? 'Daily goal done. Nice!' : 'Today: $left XP to your goal',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.todayXp} / ${s.dailyGoal} XP · level ${s.level}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final spec = nextLessonFor(state);
    final started = state.completed.isNotEmpty;
    final ref = kLessonsById[spec.id]!;
    return Material(
      color: AppColors.pink,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => openLesson(context, ref.lesson),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      started ? 'UP NEXT' : 'TRY THE FIRST LESSON',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spec.title.map((t) => t.text).join(),
                      style: const TextStyle(
                        fontSize: 21,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spec.subtitle.split('·').first.trim(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, size: 34, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockBanner extends StatelessWidget {
  const _UnlockBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.violet.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(PaywallScreen.route()),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.lock_open_rounded, color: AppColors.violet),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unlock all 17 chapters with one purchase',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.violet),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterCard extends StatefulWidget {
  const _ChapterCard({super.key, required this.chapter});
  final Chapter chapter;

  @override
  State<_ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<_ChapterCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.chapter;
    final state = AppScope.of(context);
    final hasPreview = c.lessons.any((l) => l.preview && lessonRegistry.containsKey(l.id));
    final builtIds = {
      for (final l in c.lessons)
        if (lessonRegistry.containsKey(l.id)) l.id!
    };
    final doneCount = builtIds.where(state.completed.contains).length;

    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${c.number}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          builtIds.isEmpty
                              ? '${c.lessons.length} lessons · ${c.tagline}'
                              : '$doneCount/${builtIds.length} played · ${c.tagline}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (c.free)
                    const _Tag(text: 'FREE', color: AppColors.green)
                  else if (state.premium)
                    const SizedBox.shrink()
                  else if (hasPreview)
                    const _Tag(text: 'PREVIEW', color: AppColors.yellow)
                  else
                    const Icon(Icons.lock_rounded, color: AppColors.muted, size: 20),
                  Icon(
                    _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Column(
                      children: [
                        for (final lesson in c.lessons)
                          _LessonRow(
                            lesson: lesson,
                            color: c.color,
                            built: lessonRegistry.containsKey(lesson.id),
                            locked: !(state.premium || lesson.isFreeIn(c)),
                            done: lesson.id != null && state.completed.contains(lesson.id),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.ink),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.color,
    required this.built,
    required this.locked,
    required this.done,
  });

  final Lesson lesson;
  final Color color;
  final bool built;
  final bool locked;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => openLesson(context, lesson),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.circle,
              size: done ? 20 : 10,
              color: done ? AppColors.green : color,
            ),
            SizedBox(width: done ? 10 : 15),
            Expanded(
              child: Text(
                lesson.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: built ? FontWeight.w800 : FontWeight.w500,
                  color: built ? AppColors.ink : AppColors.muted,
                ),
              ),
            ),
            if (built && locked)
              const Icon(Icons.lock_rounded, size: 18, color: AppColors.muted)
            else if (built)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
                child: Text(
                  done ? 'Replay' : 'Play',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
              )
            else
              const Text('soon', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

// ===== lib/screens/lesson_screen.dart =====
/// Generic lesson page. Any [LessonSpec] plugs into this layout:
/// header → title → animated stage + controls → big idea → try it → quiz.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.spec});
  final LessonSpec spec;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> with SingleTickerProviderStateMixin {
  late final LessonSim _sim;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _sim = widget.spec.createSim();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_sim.playing) {
      // Clamp so a dropped frame doesn't teleport everything.
      _sim.advance(math.min(dt, 0.05) * _sim.speed);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _Header(label: spec.chapterLabel),
              const SizedBox(height: 18),
              Text.rich(
                TextSpan(
                  children: [
                    for (final part in spec.title)
                      TextSpan(
                        text: part.text,
                        style: TextStyle(color: part.color ?? AppColors.ink),
                      ),
                  ],
                ),
                style: kDisplay,
              ),
              const SizedBox(height: 6),
              Text(
                spec.subtitle,
                style: const TextStyle(fontSize: 15, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              _StageCard(spec: spec, sim: _sim),
              const SizedBox(height: 16),
              _BigIdeaCard(spec: spec, sim: _sim),
              const SizedBox(height: 16),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.tryItTitle,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    spec.buildTryIt(_sim),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              BigButton(
                label: 'Quick check · ${spec.quiz.length} questions',
                color: AppColors.pink,
                onPressed: () {
                  if (_sim.playing) _sim.togglePlay();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QuizScreen.forLesson(spec, AppScope.read(context)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          child: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label.toUpperCase(),
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: AppColors.muted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const XpChip(),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.spec, required this.sim});
  final LessonSpec spec;
  final LessonSim sim;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          ListenableBuilder(
            listenable: sim,
            builder: (context, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in spec.stats(sim)) _StatPill(stat: s),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ColoredBox(
              color: AppColors.board,
              child: AspectRatio(
                aspectRatio: spec.visualAspectRatio,
                child: spec.buildVisual(sim),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Controls(sim: sim),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.stat});
  final StatChip stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${stat.label} ',
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
            TextSpan(
              text: stat.value,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.sim});
  final LessonSim sim;

  static const _speeds = <double>[0.5, 1, 3];
  static const _speedLabels = <String>['½×', '1×', '3×'];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Row(
        children: [
          _SquareButton(
            icon: Icons.replay_rounded,
            tooltip: 'Reset',
            onTap: sim.reset,
          ),
          const SizedBox(width: 10),
          _SquareButton(
            icon: sim.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            tooltip: sim.playing ? 'Pause' : 'Play',
            onTap: sim.togglePlay,
            size: 62,
            color: AppColors.pink,
            iconColor: Colors.white,
          ),
          const SizedBox(width: 10),
          _SquareButton(
            icon: Icons.skip_next_rounded,
            tooltip: 'Step',
            onTap: () {
              if (sim.playing) sim.togglePlay();
              sim.step();
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.chip,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _speeds.length; i++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => sim.setSpeed(_speeds[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sim.speed == _speeds[i] ? AppColors.cyan : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _speedLabels[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: sim.speed == _speeds[i] ? AppColors.ink : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 48,
    this.color = AppColors.chip,
    this.iconColor = AppColors.ink,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.33),
        child: InkWell(
          borderRadius: BorderRadius.circular(size * 0.33),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: iconColor, size: size * 0.48),
          ),
        ),
      ),
    );
  }
}

class _BigIdeaCard extends StatelessWidget {
  const _BigIdeaCard({required this.spec, required this.sim});
  final LessonSpec spec;
  final LessonSim sim;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: AppColors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THE BIG IDEA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            spec.bigIdea,
            style: const TextStyle(
              fontSize: 17,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: sim,
            builder: (context, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                spec.formula(sim),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          if (kWhy[spec.id] case final why?) _WhyPanel(text: why),
        ],
      ),
    );
  }
}

/// "Why does this work?": tap to show the reasoning behind the formula.
class _WhyPanel extends StatefulWidget {
  const _WhyPanel({required this.text});
  final String text;

  @override
  State<_WhyPanel> createState() => _WhyPanelState();
}

class _WhyPanelState extends State<_WhyPanel> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            key: const ValueKey('why-toggle'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, size: 20, color: AppColors.ink),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Why does this work?',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded, color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _open
              ? Text(
                  widget.text,
                  style: const TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w600, color: AppColors.ink),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

// ===== lib/screens/onboarding_screen.dart =====
/// First-launch intro: what the app is, how lessons work, pick a goal.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  int _goal = 50;

  static const _pageCount = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _pages.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      AppScope.read(context).finishOnboarding(goal: _goal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < _pageCount; i++)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i <= _page ? AppColors.pink : AppColors.chip,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (p) => setState(() => _page = p),
                    children: [
                      const _WelcomePage(),
                      const _HowPage(),
                      _GoalPage(goal: _goal, onChanged: (g) => setState(() => _goal = g)),
                    ],
                  ),
                ),
                BigButton(
                  label: _page < _pageCount - 1 ? 'Continue' : 'Start learning',
                  color: _page < _pageCount - 1 ? AppColors.pink : AppColors.green,
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AppLogo(size: 96),
        const SizedBox(height: 28),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'See '),
              TextSpan(text: 'probability', style: TextStyle(color: AppColors.pink)),
              TextSpan(text: ' & '),
              TextSpan(text: 'statistics', style: TextStyle(color: AppColors.violet)),
              TextSpan(text: ' happen.'),
            ],
          ),
          textAlign: TextAlign.center,
          style: kDisplay.copyWith(fontSize: 34),
        ),
        const SizedBox(height: 14),
        const Text(
          'Short animated lessons that show why the formulas work, not just what they are.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, height: 1.4, color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _Chip('Galton board', AppColors.yellow),
            _Chip('Monty Hall', AppColors.pink),
            _Chip('Coin flips', AppColors.cyan),
            _Chip('Central Limit Theorem', AppColors.green),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      );
}

class _HowPage extends StatelessWidget {
  const _HowPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Every lesson, 4 steps', textAlign: TextAlign.center, style: kDisplay.copyWith(fontSize: 30)),
        const SizedBox(height: 24),
        const _Step(Icons.play_circle_fill_rounded, AppColors.pink, 'Watch', 'An animation plays the idea out.'),
        const _Step(Icons.lightbulb_rounded, AppColors.cyan, 'Understand', 'One big idea and the formula, live.'),
        const _Step(Icons.tune_rounded, AppColors.orange, 'Play', 'Change the settings, see what moves.'),
        const _Step(Icons.check_circle_rounded, AppColors.green, 'Check', 'A quick quiz earns you XP.'),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.icon, this.color, this.title, this.text);
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  Text(text, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({required this.goal, required this.onChanged});
  final int goal;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pick a daily goal', textAlign: TextAlign.center, style: kDisplay.copyWith(fontSize: 30)),
        const SizedBox(height: 8),
        const Text(
          'Hit it each day to build a streak. You can change it any time.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        DailyGoalPicker(goal: goal, onChanged: onChanged),
      ],
    );
  }
}

/// Three selectable goal cards. Also used in settings.
class DailyGoalPicker extends StatelessWidget {
  const DailyGoalPicker({super.key, required this.goal, required this.onChanged});
  final int goal;
  final ValueChanged<int> onChanged;

  static const _minutes = {20: '~3 min a day', 50: '~8 min a day', 100: '~15 min a day'};
  static const _colors = {20: AppColors.cyan, 50: AppColors.orange, 100: AppColors.pink};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in kDailyGoals.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: entry.key == goal ? _colors[entry.key]!.withValues(alpha: 0.18) : AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: entry.key == goal ? _colors[entry.key]! : AppColors.chip,
                  width: 2.5,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onChanged(entry.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                            Text(_minutes[entry.key]!, style: const TextStyle(color: AppColors.muted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${entry.key} XP', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ===== lib/screens/paywall_screen.dart =====
/// One-time "unlock everything" purchase.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.reason});

  /// The locked lesson that brought the learner here, if any.
  final String? reason;

  static Route<void> route({String? reason}) => MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PaywallScreen(reason: reason),
      );

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String? _price;
  bool _available = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final purchases = AppScope.read(context).purchases;
    purchases.isAvailable().then((ok) async {
      final price = ok ? await purchases.price() : null;
      if (!mounted) return;
      setState(() {
        _available = ok && price != null;
        _price = price;
      });
    });
  }

  Future<void> _run(Future<PurchaseOutcome> Function() action) async {
    setState(() => _busy = true);
    final outcome = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    final message = switch (outcome) {
      PurchaseOutcome.purchased => 'Unlocked! Thank you for supporting Chance.',
      PurchaseOutcome.restored => 'Purchase restored. Everything is unlocked.',
      PurchaseOutcome.pending => 'Payment pending. Lessons unlock as soon as it clears.',
      PurchaseOutcome.cancelled => 'No purchase found to restore.',
      PurchaseOutcome.failed => 'Something went wrong. Please try again.',
      PurchaseOutcome.unavailable => 'The store isn\'t available on this device.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
    if (outcome == PurchaseOutcome.purchased || outcome == PurchaseOutcome.restored) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final lockedChapters = kChapters.where((c) => !c.free).length;
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
                  child: const Icon(Icons.lock_open_rounded, size: 48, color: Colors.white),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                state.premium ? 'Everything is unlocked' : 'Unlock all of Chance',
                textAlign: TextAlign.center,
                style: kDisplay,
              ),
              if (widget.reason != null && !state.premium) ...[
                const SizedBox(height: 8),
                Text(
                  '"${widget.reason}" is part of the full course.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 22),
              SoftCard(
                child: Column(
                  children: [
                    _Perk(Icons.auto_stories_rounded, AppColors.pink,
                        '$lockedChapters more chapters, from counting to Bayes'),
                    _Perk(Icons.animation_rounded, AppColors.orange, 'Every new animated lesson as it ships'),
                    const _Perk(Icons.all_inclusive_rounded, AppColors.green, 'One payment. No subscription, no ads'),
                    const _Perk(Icons.favorite_rounded, AppColors.violet, 'Support an indie learning app'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (state.premium)
                BigButton(
                  label: 'Back to learning',
                  color: AppColors.green,
                  onPressed: () => Navigator.of(context).pop(),
                )
              else ...[
                BigButton(
                  label: _busy
                      ? 'Working…'
                      : _available
                          ? 'Unlock everything${_price == null ? '' : ' · $_price'}'
                          : 'Store unavailable',
                  color: AppColors.violet,
                  icon: Icons.lock_open_rounded,
                  onPressed: _busy || !_available ? null : () => _run(state.buyPremium),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : () => _run(state.restorePurchases),
                  child: const Text('Restore purchase'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk(this.icon, this.color, this.text);
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

// ===== lib/screens/practice_screen.dart =====
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  void _startChallenge(BuildContext context) {
    final state = AppScope.read(context);
    final questions = dailyChallengeFor(state.clock());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          title: 'Daily challenge',
          questions: questions,
          onFinish: state.completeChallenge,
          noXpNote: 'You already claimed today\'s bonus. Come back tomorrow!',
          shareText: (correct) => 'Chance daily challenge ${state.today}: '
              '$correct/${questions.length} ${'🟩' * correct}${'⬜' * (questions.length - correct)}',
        ),
      ),
    );
  }

  void _startPractice(BuildContext context) {
    final state = AppScope.read(context);
    final questions = practiceSet(state.completed);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          title: 'Practice',
          questions: questions,
          onFinish: state.completePractice,
          noXpNote: 'Keep going, every right answer earns XP.',
          shareText: (correct) => 'I scored $correct/${questions.length} in a probability '
              'practice round on Chance!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final done = state.challengeDoneToday;
    return SafeArea(
      child: PhoneWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Practice',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                StreakChip(),
                SizedBox(width: 8),
                XpChip(),
              ],
            ),
            const SizedBox(height: 20),
            Material(
              color: done ? AppColors.green : AppColors.orange,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                key: const ValueKey('daily-challenge'),
                borderRadius: BorderRadius.circular(28),
                onTap: () => _startChallenge(context),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DAILY CHALLENGE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              done ? 'Done for today!' : '5 questions · up to ${challengeReward(5)} XP',
                              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              done
                                  ? 'Replay it for fun, or come back tomorrow for a new set.'
                                  : 'A fresh mix every day, same questions for everyone.',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          done ? Icons.check_rounded : Icons.bolt_rounded,
                          size: 32,
                          color: done ? AppColors.green : AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Free practice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    state.completed.isEmpty
                        ? 'Mixed questions on the basics. Finish lessons to add their questions here.'
                        : 'Mixed questions from your ${state.completed.length} finished '
                            '${state.completed.length == 1 ? 'lesson' : 'lessons'} and the basics.',
                    style: const TextStyle(color: AppColors.muted, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  BigButton(
                    label: 'Start a round · $kPracticeXpPerCorrect XP each',
                    color: AppColors.blue,
                    onPressed: () => _startPractice(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SoftCard(
              color: AppColors.cyan.withValues(alpha: 0.16),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: AppColors.cyan, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Challenges finished: ${state.challengesDone}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== lib/screens/progress_screen.dart =====
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final earned = kAchievements.where((a) => a.earned(s)).length;
    return SafeArea(
      child: PhoneWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Progress',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                XpChip(),
              ],
            ),
            const SizedBox(height: 20),
            // Level card.
            SoftCard(
              color: AppColors.violet,
              child: Row(
                children: [
                  ProgressRing(
                    value: s.levelProgress,
                    color: AppColors.yellow,
                    size: 76,
                    stroke: 9,
                    child: Text(
                      '${s.level}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${s.level}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Text(
                          '${s.xpToNextLevel} XP to level ${s.level + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: [
                _Stat('Total XP', '${s.xp}', Icons.bolt_rounded, AppColors.yellow),
                _Stat('Streak', '${s.currentStreak} days', Icons.local_fire_department_rounded, AppColors.orange),
                _Stat(
                    'Lessons', '${s.completed.length}/${lessonRegistry.length}', Icons.school_rounded, AppColors.green),
                _Stat('Best streak', '${s.bestStreak} days', Icons.whatshot_rounded, AppColors.pink),
              ],
            ),
            const SizedBox(height: 22),
            const SectionLabel('Last 7 days'),
            const SizedBox(height: 10),
            _WeekChart(days: s.recentDays(7), goal: s.dailyGoal),
            const SizedBox(height: 22),
            SectionLabel('Badges · $earned of ${kAchievements.length}'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: [for (final a in kAchievements) _BadgeTile(a, earned: a.earned(s))],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
                Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days, required this.goal});
  final List<MapEntry<DateTime, int>> days;
  final int goal;

  static const _names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxXp = days.fold<int>(goal, (m, d) => d.value > m ? d.value : m);
    return SoftCard(
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        days[i].value > 0 ? '${days[i].value}' : '',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        height: 4 + 96 * days[i].value / maxXp,
                        decoration: BoxDecoration(
                          color: days[i].value >= goal
                              ? AppColors.green
                              : days[i].value > 0
                                  ? AppColors.cyan
                                  : AppColors.chip,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _names[days[i].key.weekday - 1],
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: i == days.length - 1 ? AppColors.ink : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile(this.achievement, {required this.earned});
  final Achievement achievement;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: achievement.description,
      triggerMode: TooltipTriggerMode.tap,
      child: SoftCard(
        padding: const EdgeInsets.all(10),
        radius: 20,
        color: earned ? AppColors.card : AppColors.chip,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: earned ? achievement.color : AppColors.peg.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                earned ? achievement.icon : Icons.lock_rounded,
                color: earned ? Colors.white : AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: earned ? AppColors.ink : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== lib/screens/quiz_screen.dart =====
/// Runs a list of questions, then shows a result card.
///
/// [onFinish] records the result and returns the XP awarded (0 is fine,
/// e.g. on a lesson replay). [shareText] builds the brag message.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.onFinish,
    required this.shareText,
    this.noXpNote = 'Replays don\'t earn XP, but practice still counts.',
  });

  /// Quiz at the end of a lesson: first completion earns XP.
  factory QuizScreen.forLesson(LessonSpec spec, AppState state) {
    final name = spec.title.map((t) => t.text).join();
    return QuizScreen(
      title: 'Quick check',
      questions: spec.quiz,
      onFinish: (correct) => state.completeLesson(spec.id, correct: correct, total: spec.quiz.length),
      shareText: (correct) => 'I just learned "$name" on Chance and scored '
          '$correct/${spec.quiz.length} on the quiz. Probability, animated!',
    );
  }

  final String title;
  final List<QuizQuestion> questions;
  final int Function(int correct) onFinish;
  final String Function(int correct) shareText;
  final String noXpNote;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int? _picked;
  int _score = 0;
  bool _finished = false;
  int _reward = 0;

  static const _optionColors = [AppColors.pink, AppColors.orange, AppColors.blue, AppColors.violet];

  List<QuizQuestion> get _quiz => widget.questions;

  void _pick(int option) {
    if (_picked != null) return;
    final correct = option == _quiz[_index].answer;
    if (AppScope.read(context).haptics) {
      correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    }
    setState(() {
      _picked = option;
      if (correct) _score++;
    });
  }

  void _next() {
    if (_index + 1 < _quiz.length) {
      setState(() {
        _index++;
        _picked = null;
      });
    } else {
      final reward = widget.onFinish(_score);
      setState(() {
        _reward = reward;
        _finished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: _finished ? _buildResult(context) : _buildQuestion(context),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final q = _quiz[_index];
    final answered = _picked != null;
    final correct = _picked == q.answer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_index + (answered ? 1 : 0)) / _quiz.length,
                  minHeight: 10,
                  backgroundColor: AppColors.chip,
                  color: AppColors.green,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const XpChip(),
          ],
        ),
        const SizedBox(height: 24),
        SectionLabel('${widget.title} · question ${_index + 1} of ${_quiz.length}'),
        const SizedBox(height: 8),
        Text(q.prompt, style: kDisplay.copyWith(fontSize: 24)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: [
              for (var i = 0; i < q.options.length; i++) ...[
                _OptionTile(
                  text: q.options[i],
                  color: _optionColors[i % _optionColors.length],
                  state: !answered
                      ? _OptionState.idle
                      : i == q.answer
                          ? _OptionState.correct
                          : i == _picked
                              ? _OptionState.wrong
                              : _OptionState.dimmed,
                  onTap: () => _pick(i),
                ),
                const SizedBox(height: 10),
              ],
              if (answered) ...[
                const SizedBox(height: 6),
                SoftCard(
                  color: correct ? AppColors.green.withValues(alpha: 0.16) : AppColors.orange.withValues(alpha: 0.16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        correct ? 'Spot on!' : 'Not quite.',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(q.explanation, style: const TextStyle(fontSize: 15, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        BigButton(
          label: _index + 1 < _quiz.length ? 'Next' : 'Finish',
          color: AppColors.green,
          onPressed: answered ? _next : null,
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final state = AppScope.of(context);
    final perfect = _score == _quiz.length;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_rounded, size: 64, color: AppColors.ink),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          perfect ? 'Perfect score!' : 'Nice work!',
          textAlign: TextAlign.center,
          style: kDisplay,
        ),
        const SizedBox(height: 8),
        Text(
          'You got $_score of ${_quiz.length} right'
          '${_reward > 0 ? ' · +$_reward XP' : ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.muted),
        ),
        if (_reward == 0) ...[
          const SizedBox(height: 4),
          Text(
            widget.noXpNote,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 20),
        SoftCard(
          child: Row(
            children: [
              ProgressRing(
                value: state.todayXp / state.dailyGoal,
                color: AppColors.green,
                size: 56,
                child: Icon(
                  state.goalMetToday ? Icons.check_rounded : Icons.flag_rounded,
                  color: state.goalMetToday ? AppColors.green : AppColors.muted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.goalMetToday ? 'Daily goal reached!' : 'Daily goal',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${state.todayXp} / ${state.dailyGoal} XP today · '
                      '${state.currentStreak}-day streak',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        BigButton(
          label: 'Share my score',
          color: AppColors.violet,
          icon: Icons.ios_share_rounded,
          onPressed: () => state.share.shareText(widget.shareText(_score)),
        ),
        const SizedBox(height: 12),
        BigButton(
          label: 'Done',
          color: AppColors.pink,
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.color,
    required this.state,
    required this.onTap,
  });

  final String text;
  final Color color;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    IconData? icon;
    switch (state) {
      case _OptionState.idle:
        bg = AppColors.card;
        border = color;
      case _OptionState.correct:
        bg = AppColors.green.withValues(alpha: 0.18);
        border = AppColors.green;
        icon = Icons.check_circle_rounded;
      case _OptionState.wrong:
        bg = AppColors.orange.withValues(alpha: 0.18);
        border = AppColors.orange;
        icon = Icons.cancel_rounded;
      case _OptionState.dimmed:
        bg = AppColors.card;
        border = AppColors.chip;
    }

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border, width: 2.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: state == _OptionState.idle ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: state == _OptionState.dimmed ? AppColors.muted : AppColors.ink,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, color: border),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== lib/screens/settings_screen.dart =====
const String kAppVersion = '1.3.0';

const String kShareAppText = 'I\'m learning probability & statistics with Chance: '
    'short animated lessons that show why the formulas work. Try it!';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text('This clears your XP, streak, finished lessons and badges. '
            'Your purchase and settings are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.pink),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) AppScope.read(context).resetProgress();
  }

  Future<void> _restore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await AppScope.read(context).restorePurchases();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(switch (outcome) {
          PurchaseOutcome.purchased || PurchaseOutcome.restored => 'Purchase restored.',
          PurchaseOutcome.unavailable => 'The store isn\'t available on this device.',
          _ => 'No purchase found to restore.',
        }),
      ),
    );
  }

  Future<void> _toggleReminder(BuildContext context, bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    final nowOn = await AppScope.read(context).setReminder(on);
    if (on && !nowOn) {
      messenger.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Notifications are off for Chance. Allow them in your phone\'s settings.'),
        ),
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final s = AppScope.read(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute),
      helpText: 'Remind me at',
    );
    if (picked != null) s.setReminderTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return SafeArea(
      child: PhoneWidth(
        child: ListView(
          key: const ValueKey('settings-list'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            const SectionLabel('Daily goal'),
            const SizedBox(height: 10),
            DailyGoalPicker(goal: s.dailyGoal, onChanged: s.setDailyGoal),
            const SizedBox(height: 14),
            const SectionLabel('Preferences'),
            const SizedBox(height: 10),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    key: const ValueKey('reminder-switch'),
                    value: s.reminderOn,
                    onChanged: s.reminders.supported ? (on) => _toggleReminder(context, on) : null,
                    activeThumbColor: AppColors.green,
                    title: const Text('Daily reminder', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(s.reminders.supported
                        ? 'Skipped on days you have already met your goal'
                        : 'Available in the Android and iPhone app'),
                    secondary: const Icon(Icons.notifications_active_rounded, color: AppColors.violet),
                  ),
                  if (s.reminderOn)
                    ListTile(
                      key: const ValueKey('reminder-time'),
                      leading: const Icon(Icons.schedule_rounded, color: AppColors.blue),
                      title: const Text('Reminder time', style: TextStyle(fontWeight: FontWeight.w800)),
                      trailing: Text(
                        TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute).format(context),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.blue),
                      ),
                      onTap: () => _pickTime(context),
                    ),
                  SwitchListTile(
                    value: s.sound,
                    onChanged: s.setSound,
                    activeThumbColor: AppColors.green,
                    title: const Text('Sound effects', style: TextStyle(fontWeight: FontWeight.w800)),
                    secondary: const Icon(Icons.volume_up_rounded, color: AppColors.cyan),
                  ),
                  SwitchListTile(
                    value: s.haptics,
                    onChanged: s.setHaptics,
                    activeThumbColor: AppColors.green,
                    title: const Text('Vibration on answers', style: TextStyle(fontWeight: FontWeight.w800)),
                    secondary: const Icon(Icons.vibration_rounded, color: AppColors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionLabel('Full course'),
            const SizedBox(height: 10),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      s.premium ? Icons.verified_rounded : Icons.lock_open_rounded,
                      color: AppColors.violet,
                    ),
                    title: Text(
                      s.premium ? 'All lessons unlocked' : 'Unlock all lessons',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(s.premium ? 'Thank you for your support!' : 'One-time purchase'),
                    trailing: s.premium ? null : const Icon(Icons.chevron_right_rounded),
                    onTap: s.premium ? null : () => Navigator.of(context).push(PaywallScreen.route()),
                  ),
                  if (!s.premium)
                    ListTile(
                      leading: const Icon(Icons.restore_rounded, color: AppColors.blue),
                      title: const Text('Restore purchase', style: TextStyle(fontWeight: FontWeight.w800)),
                      onTap: () => _restore(context),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionLabel('About'),
            const SizedBox(height: 10),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.ios_share_rounded, color: AppColors.cyan),
                    title: const Text('Share Chance with a friend', style: TextStyle(fontWeight: FontWeight.w800)),
                    onTap: () => s.share.shareText(kShareAppText),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.pink),
                    title: const Text('Reset progress', style: TextStyle(fontWeight: FontWeight.w800)),
                    onTap: () => _confirmReset(context),
                  ),
                  const ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: AppColors.muted),
                    title: Text('Version $kAppVersion', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('No ads. No account. Your progress stays on this device.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== lib/screens/shell_screen.dart =====
/// Main app frame with bottom navigation between the four tabs.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _tab = 0;

  static const _tabs = [LearnScreen(), PracticeScreen(), ProgressScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.yellow,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school_rounded), label: 'Learn'),
          NavigationDestination(
              icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt_rounded), label: 'Practice'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Progress'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

// ===== tool/dartpad_stubs/backends.dart =====
/// DartPad stand-in for lib/services/backends.dart: no plugins there, so
/// progress lives in memory and purchases always succeed.
class Backends {
  const Backends({required this.store, required this.purchases, required this.share, required this.reminders});

  final KeyValueStore store;
  final PurchaseService purchases;
  final ShareService share;
  final ReminderService reminders;

  static Future<Backends> create() async => Backends(
        store: MemoryStore(),
        purchases: FakePurchaseService(),
        share: FakeShareService(),
        reminders: FakeReminderService(supported: false),
      );
}

// ===== lib/services/key_value_store.dart =====
/// Tiny persistence contract so state can be tested without a device.
abstract class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

/// Keeps everything in memory. Used by tests and the DartPad preview.
class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? initial]) : data = {...?initial};

  final Map<String, String> data;

  @override
  String? getString(String key) => data[key];

  @override
  Future<void> setString(String key, String value) async => data[key] = value;

  @override
  Future<void> remove(String key) async => data.remove(key);
}

// ===== lib/services/purchase_service.dart =====
/// Product id of the one-time "unlock everything" purchase. Create a
/// non-consumable / managed product with this id in Play Console and
/// App Store Connect.
const String kPremiumProductId = 'chance_premium_unlock';

enum PurchaseOutcome { purchased, restored, cancelled, pending, failed, unavailable }

/// One-time premium unlock.
abstract class PurchaseService {
  /// Whether the store can be used on this device.
  Future<bool> isAvailable();

  /// Localised price, e.g. "₹299.00", or null if it can't be loaded.
  Future<String?> price();

  Future<PurchaseOutcome> buy();

  Future<PurchaseOutcome> restore();

  /// Called with true whenever the store reports an owned premium unlock,
  /// including purchases that finish while the app was closed.
  void listen(void Function(bool premium) onPremium);

  void dispose();
}

/// Store stand-in for tests, web and the DartPad preview. Every purchase
/// succeeds instantly so the unlocked flow can be tried.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({this.available = true});

  final bool available;
  void Function(bool premium)? _onPremium;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String?> price() async => available ? '\$4.99' : null;

  @override
  Future<PurchaseOutcome> buy() async {
    if (!available) return PurchaseOutcome.unavailable;
    _onPremium?.call(true);
    return PurchaseOutcome.purchased;
  }

  @override
  Future<PurchaseOutcome> restore() async => available ? PurchaseOutcome.cancelled : PurchaseOutcome.unavailable;

  @override
  void listen(void Function(bool premium) onPremium) => _onPremium = onPremium;

  @override
  void dispose() => _onPremium = null;
}

// ===== lib/services/reminder_service.dart =====
/// A daily "time to learn" notification at a fixed time of day.
abstract class ReminderService {
  /// Whether this device can show reminders at all (false on web).
  bool get supported;

  /// Asks the user for permission to notify. Returns whether it was granted.
  Future<bool> requestPermission();

  /// Replaces any reminder with one every day at [hour]:[minute] local time.
  /// With [skipToday] the first one comes tomorrow.
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required bool skipToday,
    required String title,
    required String body,
  });

  Future<void> cancel();
}

/// Records what would have been scheduled. Used by tests and DartPad.
class FakeReminderService implements ReminderService {
  FakeReminderService({this.supported = true, this.grant = true});

  @override
  final bool supported;

  /// What [requestPermission] answers.
  bool grant;

  /// The current reminder as (hour, minute, skipToday), or null if none.
  (int, int, bool)? scheduled;
  String? body;

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required bool skipToday,
    required String title,
    required String body,
  }) async {
    scheduled = (hour, minute, skipToday);
    this.body = body;
  }

  @override
  Future<void> cancel() async => scheduled = null;
}

// ===== lib/services/share_service.dart =====
/// Opens the system share sheet.
abstract class ShareService {
  Future<void> shareText(String text);
}

/// Records what would have been shared. Used by tests and DartPad.
class FakeShareService implements ShareService {
  final List<String> shared = [];

  @override
  Future<void> shareText(String text) async => shared.add(text);
}

// ===== lib/state/app_state.dart =====
/// Daily XP goals offered in onboarding and settings.
const Map<int, String> kDailyGoals = {20: 'Casual', 50: 'Regular', 100: 'Serious'};

/// XP for finishing a lesson quiz the first time.
int lessonReward(int correct) => 10 + correct * 10;

/// XP for the daily challenge (once a day).
int challengeReward(int correct) => 20 + correct * 10;

/// XP per correct answer in free practice.
const int kPracticeXpPerCorrect = 5;

/// Total XP at which [level] starts: 0, 100, 300, 600, 1000, …
int xpForLevel(int level) => 50 * level * (level - 1);

String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

/// Whole calendar days from [from] to [to] (both yyyy-mm-dd), DST-safe.
int _daysBetween(String from, String to) =>
    DateTime.utc(int.parse(to.substring(0, 4)), int.parse(to.substring(5, 7)), int.parse(to.substring(8, 10)))
        .difference(DateTime.utc(
            int.parse(from.substring(0, 4)), int.parse(from.substring(5, 7)), int.parse(from.substring(8, 10))))
        .inDays;

/// Everything the learner has earned, saved on the device after every change.
class AppState extends ChangeNotifier {
  AppState({
    required this.store,
    required this.purchases,
    required this.share,
    ReminderService? reminders,
    DateTime Function()? clock,
  })  : reminders = reminders ?? FakeReminderService(supported: false),
        clock = clock ?? DateTime.now {
    _load();
    purchases.listen((premium) {
      if (premium) setPremium(true);
    });
    // Today's reminder is skipped once the goal is met, so refresh it on launch.
    _syncReminder();
  }

  final KeyValueStore store;
  final PurchaseService purchases;
  final ShareService share;
  final ReminderService reminders;
  final DateTime Function() clock;

  static const _p = 'chance.';

  int xp = 0;
  Set<String> completed = {};
  Set<String> perfect = {};
  int streak = 0;
  int bestStreak = 0;
  String? lastActive;
  int dailyGoal = 50;
  Map<String, int> history = {};
  String? challengeDay;
  int challengesDone = 0;
  bool premium = false;
  bool onboarded = false;
  bool haptics = true;
  bool sound = true;
  bool reminderOn = false;
  int reminderHour = 19;
  int reminderMinute = 0;

  String get today => dayKey(clock());

  // ---------------------------------------------------------------- derived

  int get level {
    var l = 1;
    while (xp >= xpForLevel(l + 1)) {
      l++;
    }
    return l;
  }

  /// 0 → 1 progress through the current level.
  double get levelProgress {
    final start = xpForLevel(level);
    final end = xpForLevel(level + 1);
    return (xp - start) / (end - start);
  }

  int get xpToNextLevel => xpForLevel(level + 1) - xp;

  int get todayXp => history[today] ?? 0;

  bool get goalMetToday => todayXp >= dailyGoal;

  /// The streak as it should be shown now: it breaks once a whole day
  /// passes with no activity.
  int get currentStreak {
    if (lastActive == null) return 0;
    return _daysBetween(lastActive!, today) <= 1 ? streak : 0;
  }

  bool get challengeDoneToday => challengeDay == today;

  /// XP per day for the last [days] days, oldest first.
  List<MapEntry<DateTime, int>> recentDays([int days = 7]) {
    final now = clock();
    return [
      for (var i = days - 1; i >= 0; i--)
        MapEntry(
          DateTime(now.year, now.month, now.day - i),
          history[dayKey(DateTime(now.year, now.month, now.day - i))] ?? 0,
        ),
    ];
  }

  bool canOpen(String lessonId) => premium || isLessonFree(lessonId);

  // ---------------------------------------------------------------- actions

  /// Records quiz results. Returns the XP awarded (0 on a replay).
  int completeLesson(String lessonId, {required int correct, required int total}) {
    if (correct == total) perfect = {...perfect, lessonId};
    if (completed.contains(lessonId)) {
      _save();
      notifyListeners();
      return 0;
    }
    completed = {...completed, lessonId};
    final reward = lessonReward(correct);
    _addXp(reward);
    return reward;
  }

  /// Records the daily challenge. Returns XP awarded (0 if already done today).
  int completeChallenge(int correct) {
    if (challengeDoneToday) return 0;
    challengeDay = today;
    challengesDone++;
    final reward = challengeReward(correct);
    _addXp(reward);
    return reward;
  }

  /// Free practice. Returns XP awarded.
  int completePractice(int correct) {
    final reward = correct * kPracticeXpPerCorrect;
    if (reward > 0) _addXp(reward);
    return reward;
  }

  void _addXp(int amount) {
    final day = today;
    if (lastActive != day) {
      streak = (lastActive != null && _daysBetween(lastActive!, day) == 1) ? streak + 1 : 1;
      bestStreak = math.max(bestStreak, streak);
      lastActive = day;
    }
    final goalWasMet = goalMetToday;
    xp += amount;
    history = {...history, day: (history[day] ?? 0) + amount};
    _save();
    notifyListeners();
    if (!goalWasMet && goalMetToday) _syncReminder();
  }

  void setDailyGoal(int goal) {
    dailyGoal = goal;
    _save();
    notifyListeners();
    _syncReminder();
  }

  void setSound(bool value) {
    sound = value;
    _save();
    notifyListeners();
  }

  /// Turns the daily reminder on (asking for permission first) or off.
  /// Returns whether it is on afterwards.
  Future<bool> setReminder(bool on) async {
    if (on && !(reminders.supported && await reminders.requestPermission())) return false;
    reminderOn = on;
    _save();
    notifyListeners();
    await _syncReminder();
    return reminderOn;
  }

  void setReminderTime(int hour, int minute) {
    reminderHour = hour;
    reminderMinute = minute;
    _save();
    notifyListeners();
    _syncReminder();
  }

  /// The text of the next reminder.
  String get reminderBody => currentStreak > 0
      ? 'Keep your streak going: one 2-minute lesson is enough.'
      : 'One short animated lesson a day builds real intuition.';

  /// Schedules or cancels the reminder to match the settings. The reminder
  /// skips today once the daily goal is met.
  Future<void> _syncReminder() async {
    if (!reminders.supported) return;
    try {
      if (!reminderOn) return await reminders.cancel();
      await reminders.scheduleDaily(
        hour: reminderHour,
        minute: reminderMinute,
        skipToday: goalMetToday,
        title: 'Time for a quick lesson',
        body: reminderBody,
      );
    } on Object catch (e) {
      // A reminder that fails to schedule must never break the app.
      debugPrint('Reminder not scheduled: $e');
    }
  }

  void setHaptics(bool value) {
    haptics = value;
    _save();
    notifyListeners();
  }

  void finishOnboarding({required int goal}) {
    dailyGoal = goal;
    onboarded = true;
    _save();
    notifyListeners();
  }

  void setPremium(bool value) {
    if (premium == value) return;
    premium = value;
    _save();
    notifyListeners();
  }

  Future<PurchaseOutcome> buyPremium() => _unlockVia(purchases.buy);

  Future<PurchaseOutcome> restorePurchases() => _unlockVia(purchases.restore);

  Future<PurchaseOutcome> _unlockVia(Future<PurchaseOutcome> Function() action) async {
    final outcome = await action();
    if (outcome == PurchaseOutcome.purchased || outcome == PurchaseOutcome.restored) setPremium(true);
    return outcome;
  }

  /// Wipes learning progress. Keeps premium, onboarding and settings.
  void resetProgress() {
    xp = 0;
    completed = {};
    perfect = {};
    streak = 0;
    bestStreak = 0;
    lastActive = null;
    history = {};
    challengeDay = null;
    challengesDone = 0;
    _save();
    notifyListeners();
    _syncReminder();
  }

  // ------------------------------------------------------------ persistence

  void _load() {
    String? s(String k) => store.getString('$_p$k');
    int i(String k, int fallback) => int.tryParse(s(k) ?? '') ?? fallback;
    Set<String> set(String k) {
      final v = s(k);
      return v == null || v.isEmpty ? <String>{} : v.split(',').toSet();
    }

    xp = i('xp', 0);
    completed = set('completed');
    perfect = set('perfect');
    streak = i('streak', 0);
    bestStreak = i('bestStreak', 0);
    lastActive = s('lastActive');
    dailyGoal = i('dailyGoal', 50);
    challengeDay = s('challengeDay');
    challengesDone = i('challengesDone', 0);
    premium = s('premium') == 'true';
    onboarded = s('onboarded') == 'true';
    haptics = s('haptics') != 'false';
    sound = s('sound') != 'false';
    reminderOn = s('reminderOn') == 'true';
    reminderHour = i('reminderHour', 19).clamp(0, 23);
    reminderMinute = i('reminderMinute', 0).clamp(0, 59);
    try {
      final raw = jsonDecode(s('history') ?? '{}') as Map<String, dynamic>;
      history = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
    } on Object {
      history = {};
    }
  }

  void _save() {
    // Keep two months of daily history.
    final cutoff = dayKey(clock().subtract(const Duration(days: 60)));
    history.removeWhere((k, _) => k.compareTo(cutoff) < 0);

    final values = <String, String?>{
      'xp': '$xp',
      'completed': completed.join(','),
      'perfect': perfect.join(','),
      'streak': '$streak',
      'bestStreak': '$bestStreak',
      'lastActive': lastActive,
      'dailyGoal': '$dailyGoal',
      'history': jsonEncode(history),
      'challengeDay': challengeDay,
      'challengesDone': '$challengesDone',
      'premium': '$premium',
      'onboarded': '$onboarded',
      'haptics': '$haptics',
      'sound': '$sound',
      'reminderOn': '$reminderOn',
      'reminderHour': '$reminderHour',
      'reminderMinute': '$reminderMinute',
    };
    values.forEach((k, v) => v == null ? store.remove('$_p$k') : store.setString('$_p$k', v));
  }

  @override
  void dispose() {
    purchases.dispose();
    super.dispose();
  }
}

/// Makes [AppState] available to the widget tree and rebuilds dependants
/// when it changes.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Access without subscribing to changes (for callbacks).
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

// ===== lib/theme/app_theme.dart =====
/// Light, bright, colourful palette.
class AppColors {
  AppColors._();

  // Grounds
  static const bg = Color(0xFFFFF9F2); // warm white page
  static const card = Color(0xFFFFFFFF);
  static const board = Color(0xFFF2EEFF); // soft lavender animation stage
  static const chip = Color(0xFFF3F0FA);
  static const peg = Color(0xFFA79FD9);

  // Text
  static const ink = Color(0xFF1E1B3A);
  static const muted = Color(0xFF625E86);

  // Accents
  static const pink = Color(0xFFFF3D8B);
  static const orange = Color(0xFFFF7A1A);
  static const yellow = Color(0xFFFFC93C);
  static const green = Color(0xFF2BC46F);
  static const cyan = Color(0xFF14C3D0);
  static const blue = Color(0xFF4C7DFF);
  static const violet = Color(0xFF9B5CFF);

  static const rainbow = <Color>[pink, orange, yellow, green, cyan, blue, violet];
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: AppColors.pink,
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: AppColors.orange,
      inactiveTrackColor: AppColors.chip,
      thumbColor: AppColors.orange,
      overlayColor: AppColors.orange.withValues(alpha: 0.15),
      trackHeight: 8,
    ),
  );
}

/// Shared heavy display style for titles.
const TextStyle kDisplay = TextStyle(
  fontSize: 30,
  height: 1.08,
  fontWeight: FontWeight.w900,
  letterSpacing: -0.6,
  color: AppColors.ink,
);

// ===== lib/widgets/common.dart =====
/// Yellow XP pill that updates live.
class XpChip extends StatelessWidget {
  const XpChip({super.key});

  @override
  Widget build(BuildContext context) {
    final xp = AppScope.of(context).xp;
    return _Pill(color: AppColors.yellow, icon: Icons.bolt_rounded, text: '$xp XP');
  }
}

/// Orange flame pill with the current daily streak.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context) {
    final streak = AppScope.of(context).currentStreak;
    return Tooltip(
      message: '$streak-day streak',
      child: _Pill(
        color: streak > 0 ? AppColors.orange.withValues(alpha: 0.22) : AppColors.chip,
        icon: Icons.local_fire_department_rounded,
        iconColor: streak > 0 ? AppColors.orange : AppColors.muted,
        text: '$streak',
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.icon, required this.text, this.iconColor = AppColors.ink});

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
        ],
      ),
    );
  }
}

/// Small uppercase heading above a group of cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: AppColors.muted),
    );
  }
}

/// Circular progress ring with a label in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    required this.child,
    this.size = 64,
    this.stroke = 8,
  });

  final double value;
  final Color color;
  final Widget child;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value.clamp(0.0, 1.0),
            strokeWidth: stroke,
            strokeCap: StrokeCap.round,
            backgroundColor: AppColors.chip,
            color: color,
          ),
          Center(child: child),
        ],
      ),
    );
  }
}

/// White rounded card with a soft coloured shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.color = AppColors.card,
    this.padding = const EdgeInsets.all(18),
    this.radius = 26,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// Keeps content phone-width on tablets and the web.
class PhoneWidth extends StatelessWidget {
  const PhoneWidth({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: child,
      ),
    );
  }
}

/// Big chunky call-to-action button.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.pink,
    this.textColor = Colors.white,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: AppColors.chip,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 10),
            Icon(icon, size: 22),
          ],
        ),
      ),
    );
  }
}
