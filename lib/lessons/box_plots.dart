import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Marks of two classes: dots first, then each box plot is built in stages.
class BoxPlotSim extends TickSim {
  BoxPlotSim({super.rng});

  static const int perGroup = 20;

  final List<double> a = [];
  final List<double> b = [];

  /// Spread of class B (class A is fixed).
  double spreadB = 18;

  /// 0 = dots only, 1 median, 2 box, 3 whiskers.
  int stage = 0;

  bool get full => a.length >= perGroup && b.length >= perGroup;

  @override
  double get interval => full ? 0.8 : 0.1;

  double _draw(double mean, double sd) => (mean + normalDraw(rng) * sd).clamp(0, 100).toDouble();

  @override
  void tick() {
    if (!full) {
      if (a.length <= b.length) {
        a.add(_draw(62, 8));
      } else {
        b.add(_draw(58, spreadB));
      }
    } else if (stage < 3) {
      stage++;
    }
  }

  @override
  void restart() {
    a.clear();
    b.clear();
    stage = 0;
  }
}

void _paintBoxes(Canvas canvas, Size size, BoxPlotSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 16.0;
  final right = w - 16;
  double xFor(double v) => left + v / 100 * (right - left);

  void group(List<double> data, double y, Color color, String name) {
    label(canvas, name, Offset(left, y - 50), size: 13, color: color, align: TextAlign.left);
    for (var i = 0; i < data.length; i++) {
      canvas.drawCircle(
          Offset(xFor(data[i]), y - 26 + (i % 4) * 5.0), 4.5, Paint()..color = color.withValues(alpha: 0.6));
    }
    if (data.length < 4 || sim.stage == 0) return;
    final q1 = quantileOf(data, .25), med = quantileOf(data, .5), q3 = quantileOf(data, .75);
    final lo = data.reduce(math.min), hi = data.reduce(math.max);
    final boxTop = y + 6, boxBottom = y + 40, mid = (boxTop + boxBottom) / 2;
    if (sim.stage >= 3) {
      line(canvas, Offset(xFor(lo), mid), Offset(xFor(q1), mid), AppColors.ink);
      line(canvas, Offset(xFor(q3), mid), Offset(xFor(hi), mid), AppColors.ink);
      line(canvas, Offset(xFor(lo), mid - 8), Offset(xFor(lo), mid + 8), AppColors.ink);
      line(canvas, Offset(xFor(hi), mid - 8), Offset(xFor(hi), mid + 8), AppColors.ink);
      label(canvas, 'min', Offset(xFor(lo), boxBottom + 10), size: 10, color: AppColors.muted);
      label(canvas, 'max', Offset(xFor(hi), boxBottom + 10), size: 10, color: AppColors.muted);
    }
    if (sim.stage >= 2) {
      roundRect(canvas, Rect.fromLTRB(xFor(q1), boxTop, xFor(q3), boxBottom), color.withValues(alpha: 0.35), radius: 6);
      label(canvas, 'Q1', Offset(xFor(q1), boxTop - 8), size: 10, color: AppColors.muted);
      label(canvas, 'Q3', Offset(xFor(q3), boxTop - 8), size: 10, color: AppColors.muted);
    }
    line(canvas, Offset(xFor(med), boxTop - 2), Offset(xFor(med), boxBottom + 2), AppColors.ink, width: 3.5);
  }

  group(sim.a, h * 0.28, AppColors.blue, 'Class A');
  group(sim.b, h * 0.68, AppColors.pink, 'Class B');

  final axisY = h - 14;
  for (var v = 0; v <= 100; v += 20) {
    label(canvas, '$v', Offset(xFor(v.toDouble()), axisY), size: 10, color: AppColors.muted);
  }
}

final LessonSpec boxPlotsLesson = LessonSpec(
  id: 'box_plots',
  chapterLabel: 'Ch 2 · Seeing data',
  title: const [
    TitlePart('Five numbers that '),
    TitlePart('summarise', AppColors.blue),
    TitlePart(' a whole class'),
  ],
  subtitle: 'Box plots · 2-minute animated lesson',
  createSim: () => BoxPlotSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<BoxPlotSim>(sim, _paintBoxes),
  stats: (sim) {
    final s = sim as BoxPlotSim;
    String med(List<double> d) => d.isEmpty ? '…' : quantileOf(d, .5).toStringAsFixed(0);
    String iqr(List<double> d) => d.length < 4 ? '…' : (quantileOf(d, .75) - quantileOf(d, .25)).toStringAsFixed(0);
    return [
      StatChip('median A', med(s.a), AppColors.blue),
      StatChip('median B', med(s.b), AppColors.pink),
      StatChip('IQR A / B', '${iqr(s.a)} / ${iqr(s.b)}', AppColors.yellow),
    ];
  },
  bigIdea: 'A box plot squeezes data into five numbers: min, Q1, median, Q3, max. The '
      'box holds the middle half of the values and the thick line is the median. '
      'Stacking two box plots shows at a glance which group is higher and which '
      'is more spread out, even when their averages are close.',
  formula: (_) => 'min · Q1 · median · Q3 · max     IQR = Q3 − Q1',
  tryItTitle: 'Try it: change how spread out class B is',
  buildTryIt: (sim) {
    final s = sim as BoxPlotSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'tight',
            right: 'wide',
            value: s.spreadB,
            min: 4,
            max: 24,
            divisions: 5,
            onChanged: (v) => s.change(() => s.spreadB = v),
          ),
          const TryNote('A long box and long whiskers mean the class has very mixed marks.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'What does the box in a box plot contain?',
      options: ['All the data', 'The middle 50% of the data', 'Only outliers', 'The top 25%'],
      answer: 1,
      explanation: 'From Q1 to Q3: the middle half of the values.',
    ),
    QuizQuestion(
      prompt: 'Two box plots have the same median, but one box is much longer. That group…',
      options: ['Scored higher', 'Is more spread out', 'Is smaller', 'Has no outliers'],
      answer: 1,
      explanation: 'A longer box means a bigger IQR: the middle half of the values '
          'are spread over a wider range.',
    ),
    QuizQuestion(
      prompt: 'Which value does a box plot NOT show directly?',
      options: ['Median', 'Mean', 'Q1', 'Maximum'],
      answer: 1,
      explanation: 'The five-number summary uses the median, quartiles and extremes. '
          'The mean isn\'t one of them.',
    ),
  ],
);
