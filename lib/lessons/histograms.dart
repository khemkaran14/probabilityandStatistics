import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Reaction times in milliseconds, binned with an adjustable bin count.
class HistogramSim extends TickSim {
  HistogramSim({super.rng});

  static const double lo = 150, hi = 450;
  static const int target = 150;

  final List<double> values = [];
  int bins = 10;

  @override
  double get interval => values.length < 12 ? 0.3 : 0.05;

  double get width => (hi - lo) / bins;

  List<int> get counts {
    final c = List.filled(bins, 0);
    for (final v in values) {
      c[((v - lo) / width).floor().clamp(0, bins - 1)]++;
    }
    return c;
  }

  @override
  void tick() {
    if (values.length >= target) return;
    // Right-skewed: most people react fast, a few are slow.
    final v = 200 + -math.log(1 - rng.nextDouble()) * 45 + normalDraw(rng) * 12;
    values.add(v.clamp(lo, hi - 0.01).toDouble());
  }

  void setBins(int n) {
    bins = n;
    notifyListeners();
  }

  @override
  void restart() => values.clear();
}

void _paintHistogram(Canvas canvas, Size size, HistogramSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 16.0;
  final right = w - 16;
  double xFor(double v) => left + (v - HistogramSim.lo) / (HistogramSim.hi - HistogramSim.lo) * (right - left);

  // Raw data strip.
  label(canvas, 'raw data: ${sim.values.length} reaction times', Offset(left, 12),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  final stripY = 36.0;
  for (var i = 0; i < sim.values.length; i++) {
    final v = sim.values[i];
    final isNew = i == sim.values.length - 1;
    canvas.drawCircle(Offset(xFor(v), stripY + ((i * 37) % 11) * 1.6), isNew ? 5 : 3,
        Paint()..color = (isNew ? AppColors.pink : AppColors.blue).withValues(alpha: isNew ? 1 : 0.45));
  }

  // Histogram.
  final baseline = h - 34;
  final top = stripY + 34;
  final counts = sim.counts;
  final maxC = math.max(4, counts.reduce(math.max));
  final binPx = (right - left) / sim.bins;
  for (var b = 0; b < sim.bins; b++) {
    final bh = (baseline - top) * counts[b] / maxC;
    // Bars touch: a histogram's bins are a continuous number line.
    final rect = Rect.fromLTWH(left + b * binPx, baseline - bh, binPx, bh);
    canvas.drawRect(rect, Paint()..color = AppColors.rainbow[(b * 7 ~/ sim.bins)].withValues(alpha: 0.85));
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
  line(canvas, Offset(left, baseline), Offset(right, baseline), AppColors.peg);
  for (var v = 150; v <= 450; v += 50) {
    label(canvas, '$v', Offset(xFor(v.toDouble()), baseline + 12), size: 10, color: AppColors.muted);
  }
  label(canvas, 'ms', Offset(right, baseline + 26), size: 10, color: AppColors.muted, align: TextAlign.right);
}

final LessonSpec histogramsLesson = LessonSpec(
  id: 'histograms',
  chapterLabel: 'Ch 2 · Seeing data',
  title: const [
    TitlePart('How many '),
    TitlePart('bins', AppColors.cyan),
    TitlePart(' should a histogram have?'),
  ],
  subtitle: 'Histograms · 2-minute animated lesson',
  createSim: () => HistogramSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<HistogramSim>(sim, _paintHistogram),
  stats: (sim) {
    final s = sim as HistogramSim;
    return [
      StatChip('values', '${s.values.length}', AppColors.yellow),
      StatChip('bins', '${s.bins}', AppColors.cyan),
      StatChip('bin width', '${s.width.round()} ms', AppColors.pink),
    ];
  },
  bigIdea: 'A histogram chops a number line into equal bins and counts how many '
      'values fall into each. Bars touch because the numbers are continuous. Too '
      'few bins hide the shape in a few blocks; too many turn it into noise. Pick '
      'enough bins to see the shape clearly, often around √n.',
  formula: (sim) {
    final s = sim as HistogramSim;
    return 'bin width = range / bins = 300 / ${s.bins} = ${s.width.toStringAsFixed(0)} ms · '
        '√n ≈ ${math.sqrt(math.max(1, s.values.length)).round()}';
  },
  tryItTitle: 'Try it: change the number of bins',
  buildTryIt: (sim) {
    final s = sim as HistogramSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '3',
            right: '40',
            value: s.bins.toDouble(),
            min: 3,
            max: 40,
            divisions: 37,
            label: '${s.bins} bins',
            onChanged: (v) => s.setBins(v.round()),
          ),
          const TryNote('Try 3 bins (one blob), then 40 (a comb of spikes), then about 12.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'How is a histogram different from a bar chart?',
      options: [
        'Histograms use colours',
        'Histogram bars show counts in ranges of a number, so they touch',
        'Histograms are always vertical',
        'There is no difference',
      ],
      answer: 1,
      explanation: 'Bar charts compare separate categories. Histograms slice one '
          'continuous number line into bins.',
    ),
    QuizQuestion(
      prompt: 'With far too many bins, a histogram usually looks…',
      options: ['Smooth', 'Spiky and noisy', 'Like a pie chart', 'Empty'],
      answer: 1,
      explanation: 'Each bin holds only a few values, so random variation dominates '
          'the picture.',
    ),
    QuizQuestion(
      prompt: 'Data from 0 to 100 split into 20 bins. How wide is each bin?',
      options: ['2', '5', '20', '100'],
      answer: 1,
      explanation: 'Width = range / bins = 100 / 20 = 5.',
    ),
  ],
);
