import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

/// Shape of the data being dropped onto the number line.
enum DataShape { symmetric, skewed }

class AveragesSim extends LessonSim {
  AveragesSim({math.Random? rng}) : _rng = rng ?? math.Random();

  /// Values run 0 … [maxValue] (think "salary in lakh").
  static const int maxValue = 20;

  /// Dots stop arriving at this many.
  static const int target = 40;

  final math.Random _rng;
  DataShape shape = DataShape.skewed;

  /// Values in arrival order.
  final List<int> values = [];

  /// The newest dot falls from the top: 0 → 1.
  double drop = 1;

  /// Outliers added by the learner (drawn past the end of the axis).
  int outliers = 0;

  /// Value an outlier counts as.
  static const int outlierValue = 200;

  double _timer = 0;

  int _sample() {
    switch (shape) {
      case DataShape.symmetric:
        // Sum of 4 dice-ish draws centred on 10.
        var s = 0;
        for (var i = 0; i < 4; i++) {
          s += _rng.nextInt(6);
        }
        return (s * maxValue / 20).round().clamp(0, maxValue);
      case DataShape.skewed:
        // Most values small, a long tail to the right.
        final x = -math.log(1 - _rng.nextDouble()) * 4 + 2;
        return x.round().clamp(0, maxValue);
    }
  }

  List<int> get _all => [...values, for (var i = 0; i < outliers; i++) outlierValue];

  double get mean {
    final all = _all;
    if (all.isEmpty) return 0;
    return all.fold(0, (a, b) => a + b) / all.length;
  }

  double get median {
    final all = _all..sort();
    if (all.isEmpty) return 0;
    final mid = all.length ~/ 2;
    return all.length.isOdd ? all[mid].toDouble() : (all[mid - 1] + all[mid]) / 2;
  }

  /// Most common value among the regular dots (smallest on a tie).
  int? get mode {
    if (values.isEmpty) return null;
    final counts = List<int>.filled(maxValue + 1, 0);
    for (final v in values) {
      counts[v]++;
    }
    var best = 0;
    for (var v = 1; v <= maxValue; v++) {
      if (counts[v] > counts[best]) best = v;
    }
    return best;
  }

  int get count => values.length + outliers;

  @override
  void advance(double dt) {
    if (drop < 1) drop = math.min(1, drop + dt * 4);
    if (values.length < target) {
      _timer += dt;
      final every = values.length < 8 ? 0.45 : 0.15;
      while (_timer >= every && values.length < target) {
        _timer -= every;
        _add();
      }
    }
    notifyListeners();
  }

  void _add() {
    values.add(_sample());
    drop = 0;
  }

  void addOutlier() {
    outliers++;
    notifyListeners();
  }

  void setShape(DataShape s) {
    shape = s;
    reset();
  }

  @override
  void step() {
    if (values.length < target) _add();
    drop = 1;
    notifyListeners();
  }

  @override
  void reset() {
    values.clear();
    outliers = 0;
    drop = 1;
    _timer = 0;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class AveragesPainter extends CustomPainter {
  AveragesPainter(this.sim) : super(repaint: sim);

  final AveragesSim sim;

  static const double aspectRatio = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const left = 18.0;
    final right = w - (sim.outliers > 0 ? 58 : 18);
    final axisY = h * 0.72;
    final unit = (right - left) / AveragesSim.maxValue;
    final dotR = math.min(unit * 0.42, 9.0);
    double xFor(double v) => left + v * unit;

    // Axis and ticks.
    final axis = Paint()
      ..color = AppColors.peg
      ..strokeWidth = 2;
    canvas.drawLine(Offset(left, axisY), Offset(right, axisY), axis);
    for (var v = 0; v <= AveragesSim.maxValue; v += 5) {
      canvas.drawLine(Offset(xFor(v.toDouble()), axisY), Offset(xFor(v.toDouble()), axisY + 6), axis);
      _text(canvas, '$v', Offset(xFor(v.toDouble()), axisY + 16), 11, AppColors.muted);
    }

    // Stacked dots (dot plot).
    final stacks = List<int>.filled(AveragesSim.maxValue + 1, 0);
    for (var i = 0; i < sim.values.length; i++) {
      final v = sim.values[i];
      final level = stacks[v]++;
      final restY = axisY - dotR - 2 - level * dotR * 2.1;
      final isNewest = i == sim.values.length - 1;
      final y = isNewest ? 14 + (restY - 14) * Curves.easeIn.transform(sim.drop) : restY;
      canvas.drawCircle(
        Offset(xFor(v.toDouble()), y),
        dotR,
        Paint()..color = AppColors.rainbow[i % AppColors.rainbow.length],
      );
    }

    // Outliers: drawn just past the axis end with a "200" tag.
    if (sim.outliers > 0) {
      final ox = w - 32;
      for (var i = 0; i < sim.outliers; i++) {
        canvas.drawCircle(Offset(ox, axisY - dotR - 2 - i * dotR * 2.1), dotR, Paint()..color = AppColors.ink);
      }
      _text(canvas, '${AveragesSim.outlierValue}', Offset(ox, axisY + 16), 11, AppColors.ink);
      _text(canvas, '⋯', Offset((right + ox) / 2, axisY), 14, AppColors.muted);
    }

    if (sim.count == 0) return;

    // Markers under the axis.
    final markers = <(String, double, Color)>[
      ('mean', sim.mean, AppColors.pink),
      ('median', sim.median, AppColors.violet),
      if (sim.mode != null) ('mode', sim.mode!.toDouble(), AppColors.cyan),
    ];
    for (var i = 0; i < markers.length; i++) {
      final (name, value, color) = markers[i];
      final shown = value.clamp(0, AveragesSim.maxValue + (sim.outliers > 0 ? 1.8 : 0)).toDouble();
      final x = xFor(shown);
      final y = axisY + 34 + i * 22;
      canvas.drawLine(
        Offset(x, axisY + 2),
        Offset(x, y - 6),
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..strokeWidth = 2,
      );
      final path = Path()
        ..moveTo(x, y - 8)
        ..lineTo(x - 7, y + 4)
        ..lineTo(x + 7, y + 4)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      final label = '$name ${value.toStringAsFixed(name == 'mode' ? 0 : 1)}';
      final onRight = x < w * 0.6;
      _text(canvas, label, Offset(x + (onRight ? 12 : -12), y - 1), 12, color,
          align: onRight ? TextAlign.left : TextAlign.right);
    }
  }

  void _text(Canvas canvas, String text, Offset anchor, double size, Color color,
      {TextAlign align = TextAlign.center}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.left => 0.0,
      TextAlign.right => tp.width,
      _ => tp.width / 2,
    };
    tp.paint(canvas, anchor - Offset(dx, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant AveragesPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec averagesLesson = LessonSpec(
  id: 'averages',
  chapterLabel: 'Ch 1 · Data & averages',
  title: const [
    TitlePart('Three '),
    TitlePart('averages', AppColors.pink),
    TitlePart(', three '),
    TitlePart('different', AppColors.violet),
    TitlePart(' answers'),
  ],
  subtitle: 'Mean, median & mode · 2-minute animated lesson',
  createSim: () => AveragesSim(),
  visualAspectRatio: AveragesPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: AveragesPainter(sim as AveragesSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final a = sim as AveragesSim;
    return [
      StatChip('values', '${a.count}', AppColors.yellow),
      StatChip('mean', a.mean.toStringAsFixed(1), AppColors.pink),
      StatChip('median', a.median.toStringAsFixed(1), AppColors.violet),
    ];
  },
  bigIdea: 'The mean adds everything up and shares it equally, so one huge value '
      'drags it along. The median is just the middle value once sorted, so it '
      'barely notices. The mode is the most common value. When data has a long '
      'tail, like salaries, the median tells you what is typical.',
  formula: (sim) {
    final a = sim as AveragesSim;
    return 'mean = sum / n = ${(a.mean * a.count).round()} / ${a.count} = ${a.mean.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: add a billionaire',
  buildTryIt: (sim) => _AveragesControls(sim: sim as AveragesSim),
  quiz: const [
    QuizQuestion(
      prompt: 'Five friends earn 3, 4, 4, 5 and 4 lakh. One more joins earning 100 lakh. '
          'Which average changes the most?',
      options: ['The mean', 'The median', 'The mode', 'None of them'],
      answer: 0,
      explanation: 'The mean jumps from 4 to 20 lakh. The median and mode stay at 4, '
          'which still describes a typical friend.',
    ),
    QuizQuestion(
      prompt: 'Data with a long tail to the right usually has…',
      options: ['mean < median', 'mean = median', 'mean > median', 'no median'],
      answer: 2,
      explanation: 'The few big values in the tail pull the mean to the right of the '
          'median.',
    ),
    QuizQuestion(
      prompt: 'Which average can you use for data like "favourite colour"?',
      options: ['Mean', 'Median', 'Mode', 'Any of them'],
      answer: 2,
      explanation: 'Colours cannot be added or sorted, but you can still count which '
          'one is the most common.',
    ),
  ],
);

class _AveragesControls extends StatelessWidget {
  const _AveragesControls({required this.sim});
  final AveragesSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<DataShape>(
            segments: const [
              ButtonSegment(value: DataShape.symmetric, label: Text('Symmetric')),
              ButtonSegment(value: DataShape.skewed, label: Text('Long tail')),
            ],
            selected: {sim.shape},
            onSelectionChanged: (s) => sim.setShape(s.first),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: sim.addOutlier,
            icon: const Icon(Icons.diamond_rounded),
            label: Text(
              sim.outliers == 0 ? 'Add a value of ${AveragesSim.outlierValue}' : 'Add another (${sim.outliers} so far)',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Watch the pink mean race to the right while the purple median hardly moves.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
