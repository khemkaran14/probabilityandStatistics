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
  final state = AppState(store: backends.store, purchases: backends.purchases, share: backends.share);
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
    Lesson('Theory vs experiment: coin flips', id: 'coin_flips'),
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
  Chapter(
      number: 5,
      title: 'Conditional probability',
      tagline: 'When new info changes the odds',
      free: false,
      lessons: [
        Lesson('Conditional probability'),
        Lesson('Independence'),
        Lesson('Tree diagrams'),
        Lesson('Multiplication rule'),
        Lesson('Law of total probability'),
        Lesson("Bayes' theorem: the medical test"),
        Lesson('Monty Hall', id: 'monty_hall', preview: true),
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
    Lesson('Binomial: the Galton board', id: 'galton', preview: true),
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
    Lesson('Law of Large Numbers', id: 'coin_flips'),
    Lesson('Central Limit Theorem', id: 'clt_dice'),
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
    Lesson('Monty Hall', id: 'monty_hall', preview: true),
    Lesson('Birthday paradox'),
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

// ===== lib/lessons/registry.dart =====
/// Every lesson with a built animation, keyed by its catalogue id.
/// Add new lessons here as they're built.
final Map<String, LessonSpec> lessonRegistry = {
  for (final spec in [coinFlipsLesson, montyHallLesson, galtonLesson, cltLesson]) spec.id: spec,
};

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
        ],
      ),
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
const String kAppVersion = '1.0.0';

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
              child: SwitchListTile(
                value: s.haptics,
                onChanged: s.setHaptics,
                activeThumbColor: AppColors.green,
                title: const Text('Vibration on answers', style: TextStyle(fontWeight: FontWeight.w800)),
                secondary: const Icon(Icons.vibration_rounded, color: AppColors.orange),
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
  const Backends({required this.store, required this.purchases, required this.share});

  final KeyValueStore store;
  final PurchaseService purchases;
  final ShareService share;

  static Future<Backends> create() async => Backends(
        store: MemoryStore(),
        purchases: FakePurchaseService(),
        share: FakeShareService(),
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
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now {
    _load();
    purchases.listen((premium) {
      if (premium) setPremium(true);
    });
  }

  final KeyValueStore store;
  final PurchaseService purchases;
  final ShareService share;
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
    xp += amount;
    history = {...history, day: (history[day] ?? 0) + amount};
    _save();
    notifyListeners();
  }

  void setDailyGoal(int goal) {
    dailyGoal = goal;
    _save();
    notifyListeners();
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
