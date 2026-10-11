import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Pearson correlation of paired data.
double correlation(List<Offset> pts) {
  if (pts.length < 3) return 0;
  final mx = meanOf(pts.map((p) => p.dx));
  final my = meanOf(pts.map((p) => p.dy));
  var sxy = 0.0, sxx = 0.0, syy = 0.0;
  for (final p in pts) {
    sxy += (p.dx - mx) * (p.dy - my);
    sxx += (p.dx - mx) * (p.dx - mx);
    syy += (p.dy - my) * (p.dy - my);
  }
  return sxx == 0 || syy == 0 ? 0 : sxy / math.sqrt(sxx * syy);
}

/// Hours studied (x, 0–1) against marks (y, 0–1) with a chosen strength.
class ScatterSim extends TickSim {
  ScatterSim({super.rng});

  static const int target = 40;

  final List<Offset> points = [];
  double strength = 0.7;

  @override
  double get interval => points.length < 8 ? 0.35 : 0.12;

  double get r => correlation(points);

  @override
  void tick() {
    if (points.length >= target) return;
    final zx = normalDraw(rng);
    final zy = strength * zx + math.sqrt(1 - strength * strength) * normalDraw(rng);
    points.add(Offset((0.5 + zx * 0.17).clamp(0.02, 0.98), (0.5 + zy * 0.17).clamp(0.02, 0.98)));
  }

  /// Least-squares line through the points: y = a + b·x.
  (double, double) get fit {
    final mx = meanOf(points.map((p) => p.dx));
    final my = meanOf(points.map((p) => p.dy));
    var sxy = 0.0, sxx = 0.0;
    for (final p in points) {
      sxy += (p.dx - mx) * (p.dy - my);
      sxx += (p.dx - mx) * (p.dx - mx);
    }
    final b = sxx == 0 ? 0.0 : sxy / sxx;
    return (my - b * mx, b);
  }

  @override
  void restart() => points.clear();
}

void _paintScatter(Canvas canvas, Size size, ScatterSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 34.0, top = 16.0;
  final right = w - 14, bottom = h - 34;
  Offset toCanvas(Offset p) => Offset(left + p.dx * (right - left), bottom - p.dy * (bottom - top));

  line(canvas, Offset(left, top), Offset(left, bottom), AppColors.peg);
  line(canvas, Offset(left, bottom), Offset(right, bottom), AppColors.peg);
  label(canvas, 'hours studied →', Offset((left + right) / 2, bottom + 18), size: 11, color: AppColors.muted);
  canvas.save();
  canvas.translate(14, (top + bottom) / 2);
  canvas.rotate(-math.pi / 2);
  label(canvas, 'marks →', Offset.zero, size: 11, color: AppColors.muted);
  canvas.restore();

  if (sim.points.length >= 8) {
    final (a, b) = sim.fit;
    final p1 = toCanvas(Offset(0, (a).clamp(-0.2, 1.2)));
    final p2 = toCanvas(Offset(1, (a + b).clamp(-0.2, 1.2)));
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(left, top, right, bottom));
    line(canvas, p1, p2, AppColors.pink, width: 3);
    canvas.restore();
  }
  for (var i = 0; i < sim.points.length; i++) {
    final isNew = i == sim.points.length - 1;
    final c = toCanvas(sim.points[i]);
    canvas.drawCircle(
        c, isNew ? 7 : 5.5, Paint()..color = isNew ? AppColors.orange : AppColors.blue.withValues(alpha: 0.75));
  }
}

String describeR(double r) {
  final a = r.abs();
  final strength = a > 0.7 ? 'strong' : (a > 0.4 ? 'moderate' : (a > 0.15 ? 'weak' : 'no clear'));
  final dir = a <= 0.15 ? '' : (r > 0 ? ' positive' : ' negative');
  return '$strength$dir link';
}

final LessonSpec scatterLesson = LessonSpec(
  id: 'scatter',
  chapterLabel: 'Ch 2 · Seeing data',
  title: const [
    TitlePart('Do two things '),
    TitlePart('move together', AppColors.pink),
    TitlePart('?'),
  ],
  subtitle: 'Scatter plots · 2-minute animated lesson',
  createSim: () => ScatterSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<ScatterSim>(sim, _paintScatter),
  stats: (sim) {
    final s = sim as ScatterSim;
    return [
      StatChip('points', '${s.points.length}', AppColors.yellow),
      StatChip('r', s.points.length < 3 ? '…' : s.r.toStringAsFixed(2), AppColors.pink),
      StatChip('', s.points.length < 3 ? '…' : describeR(s.r), AppColors.blue),
    ];
  },
  bigIdea: 'Each dot is one student: across for hours studied, up for marks. If '
      'the cloud slopes upward, more of one tends to come with more of the other. '
      'The correlation r runs from −1 (perfect downhill line) through 0 (no '
      'pattern) to +1 (perfect uphill line). It measures how tightly the dots hug '
      'a straight line, not how steep it is.',
  formula: (sim) {
    final s = sim as ScatterSim;
    return 'r = Σ(x−x̄)(y−ȳ) / √(Σ(x−x̄)² · Σ(y−ȳ)²) = ${s.r.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: set the strength of the link',
  buildTryIt: (sim) {
    final s = sim as ScatterSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '−1',
            right: '+1',
            value: s.strength,
            min: -0.95,
            max: 0.95,
            divisions: 19,
            label: s.strength.toStringAsFixed(1),
            onChanged: (v) => s.change(() => s.strength = v),
          ),
          ControlRow(children: [
            ValueTag('target ${s.strength.toStringAsFixed(1)}'),
            ActionButton('Add 30 points', () => s.runMany(30)),
          ]),
          const SizedBox(height: 8),
          const TryNote('Try 0: the cloud is round and the line goes flat. Try −0.9: a tight downhill band.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A scatter plot slopes clearly downhill. The correlation is probably…',
      options: ['About +0.8', 'About 0', 'About −0.8', 'Exactly 1'],
      answer: 2,
      explanation: 'Downhill means one goes up as the other goes down: a negative r.',
    ),
    QuizQuestion(
      prompt: 'r = 0 means…',
      options: [
        'No straight-line relationship',
        'The variables are identical',
        'All points are on a line',
        'The data is wrong',
      ],
      answer: 0,
      explanation: 'There could still be a curved pattern, but no linear trend.',
    ),
    QuizQuestion(
      prompt: 'Which r shows the strongest relationship?',
      options: ['0.6', '−0.9', '0.1', '0.75'],
      answer: 1,
      explanation: 'Strength is the size of r, ignoring the sign. |−0.9| is the largest.',
    ),
  ],
);
