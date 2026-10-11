import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/lessons/scatter.dart' show correlation;
import 'package:chance/theme/app_theme.dart';

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
