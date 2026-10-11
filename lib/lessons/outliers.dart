import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

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
