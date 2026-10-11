import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Two nearly equal numbers, drawn with an axis that starts higher and higher.
class GraphsLieSim extends LessonSim {
  static const double a = 52, b = 55;
  static const double cycle = 8;

  double t = 0;

  /// Axis start chosen with the slider; null while animating on its own.
  double? manualStart;

  double get axisStart {
    if (manualStart != null) return manualStart!;
    // 0 → 50 → 0, holding at both ends.
    final s = (t % cycle) / cycle;
    final wave = (1 - math.cos(2 * math.pi * s)) / 2;
    return (wave * 1.2).clamp(0.0, 1.0) * 50;
  }

  /// How many times taller bar B looks than bar A.
  double get looksLike => (b - axisStart) / (a - axisStart);

  @override
  void advance(double dt) {
    if (manualStart == null) t += dt;
    notifyListeners();
  }

  @override
  void step() {
    manualStart = null;
    t = ((t / (cycle / 4)).floor() + 1) * (cycle / 4);
    notifyListeners();
  }

  @override
  void reset() {
    manualStart = null;
    t = 0;
    notifyListeners();
  }

  void setStart(double v) {
    manualStart = v;
    notifyListeners();
  }
}

void _paintLie(Canvas canvas, Size size, GraphsLieSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 46.0, top = 30.0;
  final right = w - 20, bottom = h - 60;
  final start = sim.axisStart;
  const end = 56.0;
  double yFor(double v) => bottom - (v - start) / (end - start) * (bottom - top);

  label(canvas, 'Sales this year (lakh)', Offset(w / 2, 12), size: 13);
  // Axis with ticks.
  line(canvas, Offset(left, top), Offset(left, bottom), AppColors.ink);
  line(canvas, Offset(left, bottom), Offset(right, bottom), AppColors.ink);
  final step = (end - start) > 20 ? 10.0 : ((end - start) > 8 ? 2.0 : 1.0);
  for (var v = (start / step).ceil() * step; v <= end; v += step) {
    line(canvas, Offset(left - 5, yFor(v)), Offset(left, yFor(v)), AppColors.ink);
    label(canvas, v.toStringAsFixed(0), Offset(left - 8, yFor(v)),
        size: 10, color: AppColors.muted, align: TextAlign.right);
  }
  if (start > 0.5) {
    // Axis-break mark: a warning sign of a cut axis.
    label(canvas, '≈', Offset(left, bottom - 6), size: 18, color: AppColors.pink);
  }

  final slot = (right - left) / 2;
  for (final (i, name, v, color) in [
    (0, 'Us', GraphsLieSim.a, AppColors.blue),
    (1, 'Rival', GraphsLieSim.b, AppColors.pink)
  ]) {
    final x = left + slot * (i + 0.5);
    bar(canvas, x, slot * 0.5, bottom, bottom - yFor(v), color);
    label(canvas, '${v.round()}', Offset(x, yFor(v) - 12), size: 14);
    label(canvas, name, Offset(x, bottom + 14), size: 12, color: AppColors.muted);
  }

  final looks = sim.looksLike;
  label(canvas, 'Rival\'s bar looks ${looks.toStringAsFixed(1)}× as tall', Offset(w / 2, h - 30),
      size: 14, color: looks > 1.5 ? AppColors.pink : AppColors.ink);
  label(
      canvas,
      'Really: ${(GraphsLieSim.b / GraphsLieSim.a).toStringAsFixed(2)}× · axis starts at ${start.toStringAsFixed(0)}',
      Offset(w / 2, h - 12),
      size: 11,
      color: AppColors.muted);
}

final LessonSpec graphsLieLesson = LessonSpec(
  id: 'graphs_lie',
  chapterLabel: 'Ch 2 · Seeing data',
  title: const [
    TitlePart('Same numbers, '),
    TitlePart('very different', AppColors.pink),
    TitlePart(' story'),
  ],
  subtitle: 'How graphs lie · 2-minute animated lesson',
  createSim: () => GraphsLieSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<GraphsLieSim>(sim, _paintLie),
  stats: (sim) {
    final g = sim as GraphsLieSim;
    return [
      StatChip('axis starts', g.axisStart.toStringAsFixed(0), AppColors.yellow),
      StatChip('looks', '${g.looksLike.toStringAsFixed(1)}×', AppColors.pink),
      StatChip('really', '${(GraphsLieSim.b / GraphsLieSim.a).toStringAsFixed(2)}×', AppColors.green),
    ];
  },
  bigIdea: 'Bar charts work because bar length is proportional to the value. Start '
      'the axis at 50 instead of 0 and a 6% difference looks like a landslide. '
      'Always read the axis: check where it starts, whether it\'s evenly spaced, '
      'and whether two charts you\'re comparing use the same scale.',
  formula: (sim) {
    final g = sim as GraphsLieSim;
    final s = g.axisStart.toStringAsFixed(0);
    return 'looks = (55 − $s) / (52 − $s) = ${g.looksLike.toStringAsFixed(2)}   really = 55 / 52 = 1.06';
  },
  tryItTitle: 'Try it: be the misleading designer',
  buildTryIt: (sim) {
    final g = sim as GraphsLieSim;
    return watch(
      g,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'from 0',
            right: 'from 51',
            value: g.axisStart,
            min: 0,
            max: 51,
            divisions: 51,
            label: 'axis starts at ${g.axisStart.round()}',
            onChanged: g.setStart,
          ),
          const TryNote('Moving the slider stops the animation; press reset to let it run again.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A bar chart\'s y-axis starts at 95 instead of 0. What is the risk?',
      options: [
        'Small differences look huge',
        'Big differences look small',
        'Bars become invisible',
        'There is no risk',
      ],
      answer: 0,
      explanation: 'Cutting off the bottom of every bar exaggerates the gaps between '
          'their tops.',
    ),
    QuizQuestion(
      prompt: 'Two news charts compare crime in two cities but use different y-axis scales. '
          'You should…',
      options: [
        'Compare bar heights directly',
        'Compare the actual numbers on the axes',
        'Trust the taller bar',
        'Ignore both',
      ],
      answer: 1,
      explanation: 'Heights only compare fairly when the scales match. Read the values.',
    ),
    QuizQuestion(
      prompt: 'When is starting a line chart\'s axis above zero acceptable?',
      options: [
        'Never',
        'When showing small changes over time, clearly labelled',
        'Only for bar charts',
        'When you want to win an argument',
      ],
      answer: 1,
      explanation: 'Line charts show change, not size, so a zoomed axis is fine if it '
          'is clearly marked. Bar charts should start at zero.',
    ),
  ],
);
