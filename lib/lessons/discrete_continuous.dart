import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

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
