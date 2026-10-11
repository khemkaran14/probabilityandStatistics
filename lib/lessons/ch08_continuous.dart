import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

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
