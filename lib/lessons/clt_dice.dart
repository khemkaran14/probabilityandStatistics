import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/theme/app_theme.dart';

/// Standard deviation of one fair die: √(35/12).
final double kDieSigma = math.sqrt(35 / 12);

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

class CltSim extends LessonSim {
  CltSim({this.dice = 1, math.Random? rng}) : _rng = rng ?? math.Random() {
    _resetCounts();
    _roll();
  }

  /// Dice averaged per sample (n).
  int dice;

  final math.Random _rng;

  /// counts[k] = samples whose dice total was dice + k (k = 0 … 5·dice).
  late List<int> counts;
  int samples = 0;
  double _sumOfMeans = 0;

  /// Faces of the sample currently on show.
  List<int> faces = [];

  /// 0 → 1 tumble of the dice on show.
  double t = 0;

  double get _rate => samples < 10 ? 2.5 : (samples < 60 ? 10 : 45);

  double get observedMean => samples == 0 ? 0 : _sumOfMeans / samples;

  double get expectedSd => kDieSigma / math.sqrt(dice);

  double get observedSd {
    if (samples < 2) return 0;
    final mu = observedMean;
    var ss = 0.0;
    for (var k = 0; k < counts.length; k++) {
      final mean = (dice + k) / dice;
      ss += counts[k] * (mean - mu) * (mean - mu);
    }
    return math.sqrt(ss / (samples - 1));
  }

  void _resetCounts() => counts = List<int>.filled(5 * dice + 1, 0);

  void _roll() => faces = List<int>.generate(dice, (_) => 1 + _rng.nextInt(6));

  void _land() {
    final total = faces.fold(0, (a, b) => a + b);
    counts[total - dice]++;
    samples++;
    _sumOfMeans += total / dice;
    _roll();
  }

  @override
  void advance(double dt) {
    t += dt * _rate;
    while (t >= 1) {
      t -= 1;
      _land();
    }
    notifyListeners();
  }

  void rollMany(int count) {
    for (var i = 0; i < count; i++) {
      _land();
    }
    notifyListeners();
  }

  @override
  void step() {
    t = 0;
    _land();
    notifyListeners();
  }

  @override
  void reset() {
    samples = 0;
    _sumOfMeans = 0;
    t = 0;
    _resetCounts();
    _roll();
    notifyListeners();
  }

  void setDice(int n) {
    dice = n;
    reset();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class CltPainter extends CustomPainter {
  CltPainter(this.sim) : super(repaint: sim);

  final CltSim sim;

  static const double aspectRatio = 0.85;

  static const _pips = <int, List<Offset>>{
    1: [Offset(0, 0)],
    2: [Offset(-1, -1), Offset(1, 1)],
    3: [Offset(-1, -1), Offset(0, 0), Offset(1, 1)],
    4: [Offset(-1, -1), Offset(1, -1), Offset(-1, 1), Offset(1, 1)],
    5: [Offset(-1, -1), Offset(1, -1), Offset(0, 0), Offset(-1, 1), Offset(1, 1)],
    6: [Offset(-1, -1), Offset(1, -1), Offset(-1, 0), Offset(1, 0), Offset(-1, 1), Offset(1, 1)],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final n = sim.dice;

    // --- Dice on show ------------------------------------------------------
    final dieS = math.min(w * 0.13, (w - 24) / (n * 1.25));
    final rowW = n * dieS * 1.25 - dieS * 0.25;
    final topY = h * 0.05;
    final tumble = math.sin(sim.t * math.pi);
    for (var i = 0; i < n; i++) {
      final cx = (w - rowW) / 2 + i * dieS * 1.25 + dieS / 2;
      final cy = topY + dieS / 2 + tumble * dieS * 0.12;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate((sim.t - 0.5) * 0.5 * (i.isEven ? 1 : -1));
      final rect = Rect.fromCenter(center: Offset.zero, width: dieS, height: dieS);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(dieS * 0.2)),
        Paint()..color = AppColors.rainbow[i % AppColors.rainbow.length],
      );
      final face = sim.faces[i];
      for (final p in _pips[face]!) {
        canvas.drawCircle(p * (dieS * 0.25), dieS * 0.085, Paint()..color = AppColors.ink);
      }
      canvas.restore();
    }
    final mean = sim.faces.fold(0, (a, b) => a + b) / n;
    _text(canvas, n == 1 ? 'roll = ${mean.toStringAsFixed(0)}' : 'average = ${mean.toStringAsFixed(2)}',
        Offset(w / 2, topY + dieS + 18), 14, AppColors.ink);

    // --- Histogram of sample means -----------------------------------------
    const left = 14.0;
    final right = w - 14;
    final top = topY + dieS + 44;
    final bottom = h - 26;
    final chartH = bottom - top;
    final slots = sim.counts.length; // 5n + 1 possible averages
    final slotW = (right - left) / slots;
    double xForMean(double m) => left + ((m - 1) / 5) * (right - left - slotW) + slotW / 2;

    final sd = sim.expectedSd;
    // Expected count in one slot ≈ samples × density × slot width (1/n).
    double expected(double m) =>
        sim.samples * math.exp(-math.pow(m - 3.5, 2) / (2 * sd * sd)) / (sd * math.sqrt(2 * math.pi)) / n;
    final peak = n == 1 ? sim.samples / 6 : expected(3.5);
    final maxCount = sim.counts.fold(0, math.max).toDouble();
    final scaleMax = math.max(8.0, math.max(maxCount, peak) * 1.1);

    final barW = math.max(1.5, slotW * 0.8);
    for (var k = 0; k < slots; k++) {
      final c = sim.counts[k];
      if (c == 0) continue;
      final m = (n + k) / n;
      final bh = c / scaleMax * chartH;
      final x = xForMean(m);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x - barW / 2, bottom - bh, barW, bh),
          topLeft: Radius.circular(barW * 0.3),
          topRight: Radius.circular(barW * 0.3),
        ),
        Paint()..color = AppColors.rainbow[((m - 1) / 5 * 6.99).floor()],
      );
    }

    // Normal curve predicted by the CLT (skip n = 1, where the truth is flat).
    if (n > 1 && sim.samples >= 30) {
      final path = Path();
      for (var i = 0; i <= 200; i++) {
        final m = 1 + 5 * i / 200;
        final y = bottom - expected(m) / scaleMax * chartH;
        i == 0 ? path.moveTo(xForMean(m), y) : path.lineTo(xForMean(m), y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    canvas.drawLine(
      Offset(left, bottom),
      Offset(right, bottom),
      Paint()
        ..color = AppColors.peg
        ..strokeWidth = 1.5,
    );
    for (var v = 1; v <= 6; v++) {
      _text(canvas, '$v', Offset(xForMean(v.toDouble()), h - 13), 11, AppColors.muted);
    }
  }

  void _text(Canvas canvas, String text, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CltPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec cltLesson = LessonSpec(
  id: 'clt_dice',
  chapterLabel: 'Ch 10 · The big theorems',
  title: const [
    TitlePart('Average '),
    TitlePart('flat', AppColors.green),
    TitlePart(' dice, get a '),
    TitlePart('bell', AppColors.violet),
  ],
  subtitle: 'The Central Limit Theorem · 3-minute animated lesson',
  createSim: () => CltSim(dice: 1),
  visualAspectRatio: CltPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: CltPainter(sim as CltSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final c = sim as CltSim;
    return [
      StatChip('samples', '${c.samples}', AppColors.yellow),
      StatChip('mean', c.observedMean.toStringAsFixed(2), AppColors.cyan),
      StatChip('spread (sd)', c.observedSd.toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'One die is flat: every face is equally likely. But average a few '
      'dice and extreme results need every die to be extreme at once, which '
      'is rare. The averages pile up around 3.5 in a bell, and the bell gets '
      'narrower as you average more dice. This works for almost any starting '
      'shape.',
  formula: (sim) {
    final c = sim as CltSim;
    return 'sd of average = σ/√n = 1.71/√${c.dice} = ${c.expectedSd.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: average more dice',
  buildTryIt: (sim) => _DiceControls(sim: sim as CltSim),
  quiz: const [
    QuizQuestion(
      prompt: 'You roll ONE die thousands of times. What shape is the histogram?',
      options: ['A bell', 'Flat: all six bars equal', 'Tall at 1 and 6', 'A U shape'],
      answer: 1,
      explanation: 'Each face has the same 1/6 chance. The bell only appears '
          'when you average several dice.',
    ),
    QuizQuestion(
      prompt: 'You switch from averaging 4 dice to averaging 16. The bell becomes…',
      options: ['Twice as wide', 'Half as wide', 'Four times narrower', 'Unchanged'],
      answer: 1,
      explanation: 'Spread is σ/√n. √16 / √4 = 2, so the bell is half as wide.',
    ),
    QuizQuestion(
      prompt: 'Where is the centre of the bell of averages?',
      options: ['1', '3', '3.5', '6'],
      answer: 2,
      explanation: 'The average of one die is (1+2+3+4+5+6)/6 = 3.5, and '
          'averaging more dice keeps the same centre.',
    ),
  ],
);

class _DiceControls extends StatelessWidget {
  const _DiceControls({required this.sim});
  final CltSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('1 die', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              Expanded(
                child: Slider(
                  value: sim.dice.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${sim.dice}',
                  onChanged: (v) => sim.setDice(v.round()),
                ),
              ),
              const Text('10', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ],
          ),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'n = ${sim.dice} ${sim.dice == 1 ? 'die' : 'dice'}',
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => sim.rollMany(500),
                child: const Text('Roll 500', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Start at 1 die (flat), then slide to 2, 5, 10 and watch the bell form and narrow.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
