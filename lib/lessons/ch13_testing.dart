import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

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
      prompt: 'The coin is fair and we use this test. How often will we wrongly reject H₀?',
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
      prompt: 'The diets truly have no effect. How often will this test call it significant?',
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
      final face = loaded && rng.nextDouble() < 0.12 ? 5 : rng.nextInt(6);
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
