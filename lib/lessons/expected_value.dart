import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// A ₹10 ticket spins a prize wheel. Does the game pay on average?
class ExpectedValueSim extends TickSim {
  ExpectedValueSim({super.rng});

  static const double ticket = 10;
  static const List<double> prizes = [0, 10, 20, 100];
  static const List<Color> colors = [AppColors.peg, AppColors.cyan, AppColors.green, AppColors.yellow];

  /// Chance of the ₹100 jackpot (taken from the ₹0 slice).
  double jackpot = 0.05;

  List<double> get chances => [0.6 - (jackpot - 0.05), 0.25, 0.10, jackpot];

  /// Net win (prize − ticket) per outcome.
  List<double> get nets => [for (final p in prizes) p - ticket];

  double get expected {
    var e = 0.0;
    for (var i = 0; i < 4; i++) {
      e += chances[i] * nets[i];
    }
    return e;
  }

  int plays = 0;
  double totalNet = 0;
  int last = 0;
  final List<double> averages = [];

  double get average => plays == 0 ? 0 : totalNet / plays;

  @override
  double get interval => plays < 8 ? 0.9 : (plays < 60 ? 0.15 : 0.03);

  @override
  void tick() {
    var r = rng.nextDouble();
    var i = 0;
    while (i < 3 && r > chances[i]) {
      r -= chances[i];
      i++;
    }
    last = i;
    plays++;
    totalNet += nets[i];
    if (averages.length < 1500) averages.add(average);
  }

  @override
  void restart() {
    plays = 0;
    totalNet = 0;
    averages.clear();
  }
}

void _paintEV(Canvas canvas, Size size, ExpectedValueSim sim) {
  final w = size.width;
  final h = size.height;

  // Wheel.
  final r = math.min(w * 0.2, 70.0);
  final c = Offset(20 + r, 20 + r);
  var start = -math.pi / 2;
  final spin = sim.plays == 0 ? 0.0 : (1 - sim.phase) * 0.6;
  for (var i = 0; i < 4; i++) {
    final sweep = sim.chances[i] * 2 * math.pi;
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), start + spin, sweep, true, Paint()..color = ExpectedValueSim.colors[i]);
    start += sweep;
  }
  ring(canvas, c, r, Colors.white, width: 3);
  final tri = Path()
    ..moveTo(c.dx - 8, c.dy - r - 12)
    ..lineTo(c.dx + 8, c.dy - r - 12)
    ..lineTo(c.dx, c.dy - r + 2)
    ..close();
  canvas.drawPath(tri, Paint()..color = AppColors.ink);

  // Legend with nets.
  final lx = c.dx + r + 22;
  for (var i = 0; i < 4; i++) {
    final y = 30 + i * 26.0;
    canvas.drawCircle(Offset(lx, y), 7, Paint()..color = ExpectedValueSim.colors[i]);
    final net = sim.nets[i];
    label(
        canvas,
        '₹${ExpectedValueSim.prizes[i].round()} (${net >= 0 ? '+' : ''}${net.round()}) · ${(sim.chances[i] * 100).round()}%',
        Offset(lx + 14, y),
        size: 12,
        align: TextAlign.left,
        color: i == sim.last && sim.plays > 0 ? AppColors.pink : AppColors.ink);
  }

  // Running average vs expected value.
  const left = 40.0;
  final right = w - 14;
  final top = 2 * r + 50;
  final bottom = h - 24;
  const lo = -12.0, hi = 12.0;
  double yFor(double v) => bottom - (v.clamp(lo, hi) - lo) / (hi - lo) * (bottom - top);
  line(canvas, Offset(left, yFor(0)), Offset(right, yFor(0)), AppColors.peg);
  label(canvas, '₹0', Offset(left - 6, yFor(0)), size: 10, color: AppColors.muted, align: TextAlign.right);
  dashedLine(canvas, Offset(left, yFor(sim.expected)), Offset(right, yFor(sim.expected)), AppColors.pink, width: 2.5);
  label(canvas, 'E[X] = ₹${sim.expected.toStringAsFixed(2)}', Offset(right, yFor(sim.expected) - 10),
      size: 11, color: AppColors.pink, align: TextAlign.right);
  final n = sim.averages.length;
  if (n > 1) {
    final span = math.max(60, n).toDouble();
    final path = Path()..moveTo(left, yFor(sim.averages.first));
    for (var i = 1; i < n; i++) {
      path.lineTo(left + i / span * (right - left), yFor(sim.averages[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.violet
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }
  label(canvas, 'your average win per play →', Offset(left, bottom + 14),
      size: 10, color: AppColors.muted, align: TextAlign.left);
}

final LessonSpec expectedValueLesson = LessonSpec(
  id: 'expected_value',
  chapterLabel: 'Ch 6 · Random variables',
  title: const [
    TitlePart('Is this game '),
    TitlePart('worth playing', AppColors.green),
    TitlePart('?'),
  ],
  subtitle: 'Expected value · 2-minute animated lesson',
  createSim: () => ExpectedValueSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<ExpectedValueSim>(sim, _paintEV),
  stats: (sim) {
    final e = sim as ExpectedValueSim;
    return [
      StatChip('plays', '${e.plays}', AppColors.yellow),
      StatChip('avg win', '₹${e.average.toStringAsFixed(2)}', AppColors.violet),
      StatChip('E[X]', '₹${e.expected.toStringAsFixed(2)}', AppColors.pink),
    ];
  },
  bigIdea: 'The expected value is the long-run average result per play. Weight each '
      'possible outcome by its chance and add them up. One spin can win ₹90, but '
      'over hundreds of spins your average settles near the expected value. '
      'Casinos and lotteries set it below zero for players, which is why the '
      'house always wins in the end.',
  formula: (sim) {
    final e = sim as ExpectedValueSim;
    final terms = [for (var i = 0; i < 4; i++) '${e.chances[i].toStringAsFixed(2)}×${e.nets[i].round()}'].join(' + ');
    return 'E[X] = Σ x·p(x) = $terms = ${e.expected.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: change the jackpot chance',
  buildTryIt: (sim) {
    final e = sim as ExpectedValueSim;
    return watch(
      e,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '1%',
            right: '10%',
            value: e.jackpot,
            min: 0.01,
            max: 0.10,
            divisions: 9,
            label: '${(e.jackpot * 100).round()}% jackpot',
            onChanged: (v) => e.change(() => e.jackpot = v),
          ),
          ControlRow(children: [
            ValueTag(e.expected >= 0 ? 'Fair or better for you' : 'You lose on average'),
            ActionButton('Play 500 times', () => e.runMany(500)),
          ]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A game: win ₹10 with chance 0.3, lose ₹5 otherwise. Expected value?',
      options: ['+₹5', '−₹0.50', '+₹3', '−₹5'],
      answer: 1,
      explanation: '0.3 × 10 + 0.7 × (−5) = 3 − 3.5 = −0.5.',
    ),
    QuizQuestion(
      prompt: 'What is the expected value of one fair die roll?',
      options: ['3', '3.5', '4', '6'],
      answer: 1,
      explanation: '(1 + 2 + 3 + 4 + 5 + 6) / 6 = 3.5. It needn\'t be a possible roll.',
    ),
    QuizQuestion(
      prompt: 'A game has E[X] = −₹2. What happens if you play 1,000 times?',
      options: [
        'You lose exactly ₹2',
        'You lose about ₹2,000 in total',
        'You break even',
        'You must win eventually',
      ],
      answer: 1,
      explanation: 'The average per play settles near −₹2, so the total heads towards '
          '1,000 × −₹2.',
    ),
  ],
);
