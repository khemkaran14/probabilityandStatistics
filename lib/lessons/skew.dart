import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

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
