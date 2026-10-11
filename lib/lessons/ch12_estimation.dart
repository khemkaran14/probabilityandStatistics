import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

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
