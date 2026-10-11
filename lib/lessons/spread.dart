import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

/// A rolling sample of [size] values: every tick the oldest is replaced.
class SpreadSim extends LessonSim {
  SpreadSim({math.Random? rng}) : _rng = rng ?? math.Random() {
    _fill();
  }

  static const int size = 12;

  /// Values live on 0 … 100 around a centre of 50.
  static const double centre = 50;

  final math.Random _rng;

  /// Standard deviation the values are drawn with.
  double targetSd = 12;

  List<double> values = [];

  /// Index of the value that was replaced most recently.
  int newest = -1;

  /// 0 → 1 slide-in of the newest value.
  double t = 1;

  double _timer = 0;

  static const double every = 1.2;

  double _draw() {
    // Box–Muller normal draw, clamped to the visible range.
    final u1 = 1 - _rng.nextDouble();
    final u2 = _rng.nextDouble();
    final z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    return (centre + z * targetSd).clamp(0, 100).toDouble();
  }

  void _fill() {
    values = List.generate(size, (_) => _draw());
    newest = -1;
    t = 1;
  }

  double get mean => values.fold(0.0, (a, b) => a + b) / values.length;

  double get sumSquares {
    final m = mean;
    return values.fold(0.0, (a, v) => a + (v - m) * (v - m));
  }

  /// Sample standard deviation (divides by n − 1).
  double get sd => math.sqrt(sumSquares / (values.length - 1));

  double get range => values.reduce(math.max) - values.reduce(math.min);

  @override
  void advance(double dt) {
    if (t < 1) t = math.min(1, t + dt * 3);
    _timer += dt;
    while (_timer >= every) {
      _timer -= every;
      _replace();
    }
    notifyListeners();
  }

  void _replace() {
    newest = (newest + 1) % size;
    values[newest] = _draw();
    t = 0;
  }

  void setSpread(double sdValue) {
    targetSd = sdValue;
    _fill();
    notifyListeners();
  }

  @override
  void step() {
    _replace();
    t = 1;
    notifyListeners();
  }

  @override
  void reset() {
    _timer = 0;
    _fill();
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class SpreadPainter extends CustomPainter {
  SpreadPainter(this.sim) : super(repaint: sim);

  final SpreadSim sim;

  static const double aspectRatio = 0.95;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const left = 16.0;
    final right = w - 16;
    const top = 30.0;
    final bottom = h - 34;
    double xFor(double v) => left + v / 100 * (right - left);

    final mean = sim.mean;
    final sd = sim.sd;
    final mx = xFor(mean);

    // ±1 sd band.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(xFor((mean - sd).clamp(0, 100)), top - 8, xFor((mean + sd).clamp(0, 100)), bottom + 4),
        const Radius.circular(10),
      ),
      Paint()..color = AppColors.yellow.withValues(alpha: 0.28),
    );
    _text(canvas, '−1 sd', Offset(xFor((mean - sd).clamp(0, 100)), top - 18), 11, AppColors.muted);
    _text(canvas, '+1 sd', Offset(xFor((mean + sd).clamp(0, 100)), top - 18), 11, AppColors.muted);

    // One row per value: a dot, and a bar from the mean to it.
    final rowH = (bottom - top) / SpreadSim.size;
    final dotR = math.min(rowH * 0.32, 8.0);
    for (var i = 0; i < SpreadSim.size; i++) {
      final v = sim.values[i];
      final y = top + rowH * (i + 0.5);
      final isNew = i == sim.newest && sim.t < 1;
      final x = isNew ? right + (xFor(v) - right) * Curves.easeOutCubic.transform(sim.t) : xFor(v);
      final color = v >= mean ? AppColors.pink : AppColors.blue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(math.min(mx, x), y - rowH * 0.16, math.max(mx, x), y + rowH * 0.16),
          const Radius.circular(4),
        ),
        Paint()..color = color.withValues(alpha: 0.35),
      );
      canvas.drawCircle(Offset(x, y), dotR, Paint()..color = color);
    }

    // Mean line.
    canvas.drawLine(
      Offset(mx, top - 8),
      Offset(mx, bottom + 4),
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = 2.5,
    );
    _text(canvas, 'mean ${mean.toStringAsFixed(1)}', Offset(mx, bottom + 18), 12, AppColors.ink);
  }

  void _text(Canvas canvas, String text, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant SpreadPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec spreadLesson = LessonSpec(
  id: 'spread',
  chapterLabel: 'Ch 1 · Data & averages',
  title: const [
    TitlePart('How far is a '),
    TitlePart('typical', AppColors.pink),
    TitlePart(' value from the '),
    TitlePart('mean', AppColors.blue),
    TitlePart('?'),
  ],
  subtitle: 'Range, variance & standard deviation · 2-minute animated lesson',
  createSim: () => SpreadSim(),
  visualAspectRatio: SpreadPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: SpreadPainter(sim as SpreadSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final s = sim as SpreadSim;
    return [
      StatChip('range', s.range.toStringAsFixed(1), AppColors.orange),
      StatChip('variance', (s.sd * s.sd).toStringAsFixed(0), AppColors.violet),
      StatChip('sd', s.sd.toStringAsFixed(1), AppColors.yellow),
    ];
  },
  bigIdea: 'Each bar is one value\'s distance from the mean. Square those distances '
      '(so left and right both count), average them, and you get the variance. '
      'Take the square root to get back to normal units: that is the standard '
      'deviation, roughly how far a typical value sits from the mean. Most values '
      'land inside the yellow ±1 sd band.',
  formula: (sim) {
    final s = sim as SpreadSim;
    return 'sd = √(Σ(x − x̄)² / (n − 1)) = √(${s.sumSquares.toStringAsFixed(0)} / ${SpreadSim.size - 1}) '
        '= ${s.sd.toStringAsFixed(1)}';
  },
  tryItTitle: 'Try it: squeeze or stretch the data',
  buildTryIt: (sim) => _SpreadControls(sim: sim as SpreadSim),
  quiz: const [
    QuizQuestion(
      prompt: 'Two classes both average 60 marks. Class A has sd 5, class B has sd 20. '
          'Which is true?',
      options: [
        'Class A\'s marks are more bunched together',
        'Class B did better',
        'Class A has more students',
        'They are identical',
      ],
      answer: 0,
      explanation: 'Same centre, different spread. A small sd means most marks are '
          'close to 60.',
    ),
    QuizQuestion(
      prompt: 'Why square the distances before averaging them?',
      options: [
        'To make the numbers bigger',
        'So distances below the mean don\'t cancel those above',
        'Because the formula looks nicer',
        'To remove outliers',
      ],
      answer: 1,
      explanation: 'Raw distances from the mean always add up to exactly zero. '
          'Squaring makes every distance positive.',
    ),
    QuizQuestion(
      prompt: 'You add 10 to every value. What happens to the sd?',
      options: ['It goes up by 10', 'It doubles', 'It stays the same', 'It goes to zero'],
      answer: 2,
      explanation: 'Everything shifts together, including the mean, so every '
          'distance from the mean is unchanged.',
    ),
  ],
);

class _SpreadControls extends StatelessWidget {
  const _SpreadControls({required this.sim});
  final SpreadSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('tight', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              Expanded(
                child: Slider(
                  value: sim.targetSd,
                  min: 3,
                  max: 24,
                  divisions: 7,
                  label: sim.targetSd.toStringAsFixed(0),
                  onChanged: sim.setSpread,
                ),
              ),
              const Text('wide', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ],
          ),
          const Text(
            'New values slide in every second. Notice the sd wobbles but stays near the '
            'spread you chose, while the range jumps around much more.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
