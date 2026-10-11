// Chance – single-file preview for DartPad. Generated; edit lib/ instead.

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ===== main.dart =====
void main() => runApp(const ChanceApp());

class ChanceApp extends StatelessWidget {
  const ChanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chance',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}

// ===== data/catalogue.dart =====
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

// ===== engine/lesson_sim.dart =====
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

// ===== engine/lesson_spec.dart =====
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

// ===== lessons/galton_board.dart =====
// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

class _Ball {
  _Ball(this.path, this.color);

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

  final List<_Ball> balls = [];
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
    balls.add(_Ball(path, color));
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
        final density = math.exp(-math.pow(x - mu, 2) / (2 * sigma * sigma)) /
            (sigma * math.sqrt(2 * math.pi));
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

// ===== lessons/registry.dart =====
/// Every lesson with a built animation, keyed by its catalogue id.
/// Add new lessons here as they're built.
final Map<String, LessonSpec> lessonRegistry = {
  galtonLesson.id: galtonLesson,
};

// ===== screens/home_screen.dart =====
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Row(
                children: [
                  _Logo(),
                  SizedBox(width: 10),
                  Text('Chance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  Spacer(),
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
              const _ContinueCard(),
              const SizedBox(height: 26),
              Text(
                '${kChapters.length} CHAPTERS · $kLessonCount LESSONS',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              for (final chapter in kChapters) ...[
                _ChapterCard(chapter: chapter),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => LessonScreen(spec: spec)),
  );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    // Three dots of a die face, in brand colours.
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Stack(
        children: [
          Align(alignment: Alignment.topLeft, child: _Dot(AppColors.pink)),
          Align(alignment: Alignment.center, child: _Dot(AppColors.yellow)),
          Align(alignment: Alignment.bottomRight, child: _Dot(AppColors.cyan)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard();

  static const _galton = Lesson('Binomial: the Galton board', id: 'galton');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pink,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => openLesson(context, _galton),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRY THE FIRST LESSON',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Why does everything end up as a bell?',
                      style: TextStyle(
                        fontSize: 21,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Galton board · 2 min',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

class _ChapterCard extends StatefulWidget {
  const _ChapterCard({required this.chapter});
  final Chapter chapter;

  @override
  State<_ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<_ChapterCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.chapter;
    final hasBuilt = c.lessons.any((l) => l.id != null && lessonRegistry.containsKey(l.id));

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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
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
                          '${c.lessons.length} lessons · ${c.tagline}',
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
                  else if (hasBuilt)
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
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: Progress.completed,
                      builder: (context, done, _) => Column(
                        children: [
                          for (final lesson in c.lessons)
                            _LessonRow(
                              lesson: lesson,
                              color: c.color,
                              built: lesson.id != null && lessonRegistry.containsKey(lesson.id),
                              done: lesson.id != null && done.contains(lesson.id),
                            ),
                        ],
                      ),
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
    required this.done,
  });

  final Lesson lesson;
  final Color color;
  final bool built;
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
            if (built)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
                child: const Text(
                  'Play',
                  style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink),
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

// ===== screens/lesson_screen.dart =====
/// Generic lesson page. Any [LessonSpec] plugs into this layout:
/// header → title → animated stage + controls → big idea → try it → quiz.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.spec});
  final LessonSpec spec;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
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
                    MaterialPageRoute<void>(builder: (_) => QuizScreen(spec: spec)),
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
                            color: sim.speed == _speeds[i]
                                ? AppColors.cyan
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _speedLabels[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: sim.speed == _speeds[i]
                                  ? AppColors.ink
                                  : AppColors.muted,
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

// ===== screens/quiz_screen.dart =====
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.spec});
  final LessonSpec spec;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int? _picked;
  int _score = 0;
  bool _finished = false;

  static const _optionColors = [AppColors.pink, AppColors.orange, AppColors.blue, AppColors.violet];

  List<QuizQuestion> get _quiz => widget.spec.quiz;

  void _pick(int option) {
    if (_picked != null) return;
    setState(() {
      _picked = option;
      if (option == _quiz[_index].answer) _score++;
    });
  }

  void _next() {
    if (_index + 1 < _quiz.length) {
      setState(() {
        _index++;
        _picked = null;
      });
    } else {
      Progress.complete(widget.spec.id, 10 + _score * 10);
      setState(() => _finished = true);
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
        Text(
          'QUESTION ${_index + 1} OF ${_quiz.length}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: AppColors.muted,
          ),
        ),
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
                  color: correct
                      ? AppColors.green.withValues(alpha: 0.16)
                      : AppColors.orange.withValues(alpha: 0.16),
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
          perfect ? 'Perfect score!' : 'Lesson complete!',
          textAlign: TextAlign.center,
          style: kDisplay,
        ),
        const SizedBox(height: 8),
        Text(
          'You got $_score of ${_quiz.length} right · +${10 + _score * 10} XP',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.muted),
        ),
        const SizedBox(height: 32),
        BigButton(
          label: 'Back to lessons',
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

// ===== state/progress.dart =====
/// Very small in-memory progress store (XP + finished lessons).
/// Will be swapped for on-device storage later.
class Progress {
  Progress._();

  static final ValueNotifier<int> xp = ValueNotifier<int>(0);
  static final ValueNotifier<Set<String>> completed =
      ValueNotifier<Set<String>>(<String>{});

  static void complete(String lessonId, int reward) {
    if (completed.value.contains(lessonId)) return;
    completed.value = {...completed.value, lessonId};
    xp.value += reward;
  }
}

// ===== theme/app_theme.dart =====
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

// ===== widgets/common.dart =====
/// Yellow XP pill that updates live.
class XpChip extends StatelessWidget {
  const XpChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Progress.xp,
      builder: (context, xp, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.yellow,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 18, color: AppColors.ink),
            const SizedBox(width: 4),
            Text(
              '$xp XP',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ],
        ),
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
      child: child,
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
            Text(label),
            const SizedBox(width: 10),
            Icon(icon, size: 22),
          ],
        ),
      ),
    );
  }
}
