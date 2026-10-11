import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

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
