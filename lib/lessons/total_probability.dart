import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Bulbs from three factories; what share of all bulbs is faulty?
class TotalProbSim extends TickSim {
  TotalProbSim({super.rng});

  static const List<String> names = ['A', 'B', 'C'];
  static const List<double> shares = [0.5, 0.3, 0.2];
  static const List<Color> colors = [AppColors.blue, AppColors.green, AppColors.orange];

  /// Faulty rate of each factory (C adjustable).
  List<double> faultRates = [0.04, 0.06, 0.15];

  List<int> made = [0, 0, 0];
  List<int> faulty = [0, 0, 0];

  /// Last bulb: (factory, faulty).
  (int, bool)? last;

  int get total => made.fold(0, (a, b) => a + b);
  int get totalFaulty => faulty.fold(0, (a, b) => a + b);

  double get theory {
    var t = 0.0;
    for (var i = 0; i < 3; i++) {
      t += shares[i] * faultRates[i];
    }
    return t;
  }

  @override
  double get interval => total < 10 ? 0.5 : 0.03;

  @override
  void tick() {
    var r = rng.nextDouble();
    var f = 0;
    while (f < 2 && r > shares[f]) {
      r -= shares[f];
      f++;
    }
    final bad = rng.nextDouble() < faultRates[f];
    made[f]++;
    if (bad) faulty[f]++;
    last = (f, bad);
  }

  @override
  void restart() {
    made = [0, 0, 0];
    faulty = [0, 0, 0];
    last = null;
  }
}

void _paintTotal(Canvas canvas, Size size, TotalProbSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 16.0;
  final right = w - 16;
  const top = 34.0;
  final colBottom = h * 0.62;
  final total = right - left;

  // Each factory's column: width = share of production, faulty part on top.
  var x = left;
  label(canvas, 'Width = share of all bulbs · pink = faulty part', Offset(w / 2, 14), size: 11, color: AppColors.muted);
  for (var i = 0; i < 3; i++) {
    final cw = total * TotalProbSim.shares[i];
    final rect = Rect.fromLTWH(x + 2, top, cw - 4, colBottom - top);
    roundRect(canvas, rect, TotalProbSim.colors[i].withValues(alpha: 0.25), radius: 8);
    // Faulty band drawn 3× taller so small rates stay visible.
    final fh = (colBottom - top) * (sim.faultRates[i] * 3).clamp(0.0, 1.0);
    roundRect(canvas, Rect.fromLTWH(x + 2, top, cw - 4, fh), AppColors.pink.withValues(alpha: 0.75), radius: 8);
    label(canvas, 'Factory ${TotalProbSim.names[i]}', Offset(x + cw / 2, colBottom - 40),
        size: 12, color: TotalProbSim.colors[i]);
    label(canvas, '${(TotalProbSim.shares[i] * 100).round()}% of bulbs', Offset(x + cw / 2, colBottom - 22),
        size: 10, color: AppColors.ink);
    label(canvas, '${(sim.faultRates[i] * 100).round()}% faulty', Offset(x + cw / 2, colBottom - 9),
        size: 10, color: AppColors.pink);
    if (sim.last?.$1 == i) {
      label(canvas, sim.last!.$2 ? '💡✗' : '💡', Offset(x + cw / 2, top + (colBottom - top) / 2), size: 20);
    }
    x += cw;
  }
  label(canvas, '(faulty bands drawn 3× taller to be visible)', Offset(w / 2, colBottom + 12),
      size: 9, color: AppColors.muted);

  // The overall faulty share, built from the three pieces.
  final y = colBottom + 36;
  label(canvas, 'All faulty bulbs, by factory', Offset(left, y), size: 12, align: TextAlign.left);
  final barY = y + 14;
  final barW = right - left;
  roundRect(canvas, Rect.fromLTWH(left, barY, barW, 26), Colors.white, radius: 8);
  var bx = left;
  for (var i = 0; i < 3; i++) {
    final piece = TotalProbSim.shares[i] * sim.faultRates[i];
    final pw = barW * piece / 0.2; // scale: full bar = 20%
    roundRect(canvas, Rect.fromLTWH(bx, barY, pw, 26), TotalProbSim.colors[i], radius: 6);
    bx += pw;
  }
  label(canvas, '= ${(sim.theory * 100).toStringAsFixed(1)}% of all bulbs are faulty', Offset(left, barY + 40),
      size: 12, color: AppColors.pink, align: TextAlign.left);
  label(canvas, 'full bar = 20%', Offset(right, barY + 40), size: 10, color: AppColors.muted, align: TextAlign.right);
  final seen = sim.total == 0 ? 0 : sim.totalFaulty / sim.total;
  label(canvas, 'seen: ${sim.totalFaulty} faulty of ${sim.total} = ${(seen * 100).toStringAsFixed(1)}%',
      Offset(w / 2, h - 12),
      size: 12, color: AppColors.muted);
}

final LessonSpec totalProbabilityLesson = LessonSpec(
  id: 'total_probability',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('Add up the '),
    TitlePart('pieces', AppColors.orange),
    TitlePart(' from every source'),
  ],
  subtitle: 'The law of total probability · 2-minute animated lesson',
  createSim: () => TotalProbSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<TotalProbSim>(sim, _paintTotal),
  stats: (sim) {
    final s = sim as TotalProbSim;
    return [
      StatChip('bulbs', '${s.total}', AppColors.yellow),
      StatChip('faulty', '${s.totalFaulty}', AppColors.pink),
      StatChip('theory', '${(s.theory * 100).toStringAsFixed(1)}%', AppColors.violet),
    ];
  },
  bigIdea: 'Every bulb comes from exactly one factory. So the faulty bulbs split into '
      'three non-overlapping groups: faulty from A, from B, from C. Each group is '
      'the factory\'s share times its faulty rate. Add the pieces to get the '
      'overall rate. A small factory with a high fault rate can still matter a lot.',
  formula: (sim) {
    final s = sim as TotalProbSim;
    final r = s.faultRates;
    return 'P(faulty) = Σ P(factory) × P(faulty | factory)\n'
        '= 0.5×${r[0]} + 0.3×${r[1]} + 0.2×${r[2].toStringAsFixed(2)} = ${s.theory.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: factory C\'s fault rate',
  buildTryIt: (sim) {
    final s = sim as TotalProbSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '1%',
            right: '30%',
            value: s.faultRates[2],
            min: 0.01,
            max: 0.3,
            divisions: 29,
            label: '${(s.faultRates[2] * 100).round()}%',
            onChanged: (v) => s.change(() => s.faultRates = [0.04, 0.06, v]),
          ),
          ControlRow(children: [ActionButton('Make 2,000 bulbs', () => s.runMany(2000))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: '60% of days are sunny (you walk late 10% of them) and 40% rainy (late 50%). '
          'Overall P(late)?',
      options: ['0.30', '0.26', '0.60', '0.06'],
      answer: 1,
      explanation: '0.6 × 0.1 + 0.4 × 0.5 = 0.06 + 0.20 = 0.26.',
    ),
    QuizQuestion(
      prompt: 'The law of total probability needs the groups (factories) to…',
      options: [
        'Be equal in size',
        'Not overlap and together cover everything',
        'Have the same fault rate',
        'Be independent',
      ],
      answer: 1,
      explanation: 'Each outcome must fall into exactly one group so nothing is missed '
          'or counted twice.',
    ),
    QuizQuestion(
      prompt: 'Factory A makes 90% of bulbs with 1% faulty; B makes 10% with 20% faulty. '
          'Which contributes more faulty bulbs?',
      options: ['A', 'B', 'Equal', 'Can\'t tell'],
      answer: 1,
      explanation: 'A: 0.9 × 0.01 = 0.009. B: 0.1 × 0.2 = 0.02. The small factory '
          'adds more than twice as many.',
    ),
  ],
);
