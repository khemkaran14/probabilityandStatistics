import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Area model: a unit square. A is a strip of width P(A); inside it, B fills
/// height P(B | A). Darts estimate the area of "A and B".
class MultRuleSim extends TickSim {
  MultRuleSim({super.rng});

  /// P(rain).
  double pA = 0.3;

  /// P(late | rain).
  double pBgivenA = 0.6;

  /// P(late | no rain), drawn to the right of the strip.
  static const double pBgivenNotA = 0.1;

  final List<Offset> darts = [];
  int total = 0, inA = 0, inAB = 0;

  double get pAB => pA * pBgivenA;

  bool isA(Offset p) => p.dx < pA;
  bool isB(Offset p) => isA(p) ? p.dy > 1 - pBgivenA : p.dy > 1 - pBgivenNotA;

  @override
  double get interval => total < 20 ? 0.12 : 0.02;

  @override
  void tick() {
    final p = Offset(rng.nextDouble(), rng.nextDouble());
    total++;
    if (isA(p)) {
      inA++;
      if (isB(p)) inAB++;
    }
    if (darts.length < 600) darts.add(p);
  }

  @override
  void restart() {
    darts.clear();
    total = inA = inAB = 0;
  }
}

void _paintMultRule(Canvas canvas, Size size, MultRuleSim sim) {
  final w = size.width;
  final h = size.height;
  const pad = 16.0;
  final side = math.min(w - pad * 2, h - 80);
  final o = Offset((w - side) / 2, 30);
  Offset toCanvas(Offset p) => o + Offset(p.dx * side, p.dy * side);

  roundRect(canvas, o & Size(side, side), Colors.white, radius: 6);
  // A strip (rain) and the B part inside it (late).
  final aRect = Rect.fromLTWH(o.dx, o.dy, side * sim.pA, side);
  canvas.drawRect(aRect, Paint()..color = AppColors.blue.withValues(alpha: 0.16));
  final abRect = Rect.fromLTWH(o.dx, o.dy + side * (1 - sim.pBgivenA), side * sim.pA, side * sim.pBgivenA);
  canvas.drawRect(abRect, Paint()..color = AppColors.violet.withValues(alpha: 0.35));
  final notAB = Rect.fromLTWH(o.dx + side * sim.pA, o.dy + side * (1 - MultRuleSim.pBgivenNotA), side * (1 - sim.pA),
      side * MultRuleSim.pBgivenNotA);
  canvas.drawRect(notAB, Paint()..color = AppColors.orange.withValues(alpha: 0.25));
  line(canvas, Offset(aRect.right, o.dy), Offset(aRect.right, o.dy + side), AppColors.blue, width: 2.5);

  for (final p in sim.darts) {
    final a = sim.isA(p), b = sim.isB(p);
    canvas.drawCircle(toCanvas(p), 2.2,
        Paint()..color = a && b ? AppColors.violet : (a ? AppColors.blue : (b ? AppColors.orange : AppColors.peg)));
  }

  label(canvas, 'rain ${(sim.pA * 100).round()}%', Offset(aRect.center.dx, o.dy - 10), size: 11, color: AppColors.blue);
  label(canvas, 'no rain', Offset((aRect.right + o.dx + side) / 2, o.dy - 10), size: 11, color: AppColors.muted);
  if (abRect.width > 40) {
    label(canvas, 'rain and late', abRect.center, size: 11, color: AppColors.ink);
  }
  label(canvas, '← P(late | rain) = ${(sim.pBgivenA * 100).round()}% of the strip →', Offset(w / 2, o.dy + side + 16),
      size: 11, color: AppColors.violet);
  label(canvas, 'Darts in purple: ${sim.total == 0 ? 0 : (sim.inAB / sim.total).toStringAsFixed(3)} of ${sim.total}',
      Offset(w / 2, h - 12),
      size: 12, color: AppColors.muted);
}

final LessonSpec multiplicationRuleLesson = LessonSpec(
  id: 'multiplication_rule',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('A '),
    TitlePart('slice', AppColors.blue),
    TitlePart(' of a '),
    TitlePart('slice', AppColors.violet),
  ],
  subtitle: 'The multiplication rule · 2-minute animated lesson',
  createSim: () => MultRuleSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<MultRuleSim>(sim, _paintMultRule),
  stats: (sim) {
    final m = sim as MultRuleSim;
    return [
      StatChip('P(rain)', m.pA.toStringAsFixed(2), AppColors.blue),
      StatChip('P(late | rain)', m.pBgivenA.toStringAsFixed(2), AppColors.violet),
      StatChip('P(both)', m.pAB.toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'The square is every possible day. The blue strip is the share of rainy '
      'days. Inside that strip, the purple part is the share of rainy days when '
      'you\'re late. Its area is width × height: a fraction of a fraction. That is '
      'the multiplication rule, and it works whether or not the events are '
      'independent, because the height is conditional on A.',
  formula: (sim) {
    final m = sim as MultRuleSim;
    return 'P(A and B) = P(A) × P(B | A) = ${m.pA.toStringAsFixed(2)} × ${m.pBgivenA.toStringAsFixed(2)} '
        '= ${m.pAB.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: resize the slices',
  buildTryIt: (sim) {
    final m = sim as MultRuleSim;
    return watch(
      m,
      () => Column(
        children: [
          LabeledSlider(
            left: 'P(rain)',
            right: '',
            value: m.pA,
            min: 0.1,
            max: 0.9,
            divisions: 8,
            label: m.pA.toStringAsFixed(1),
            onChanged: (v) => m.change(() => m.pA = v),
          ),
          LabeledSlider(
            left: 'P(late | rain)',
            right: '',
            value: m.pBgivenA,
            min: 0.1,
            max: 0.9,
            divisions: 8,
            label: m.pBgivenA.toStringAsFixed(1),
            onChanged: (v) => m.change(() => m.pBgivenA = v),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: '40% of students take the bus, and 25% of bus-takers are late. What share of '
          'all students take the bus and are late?',
      options: ['65%', '15%', '10%', '25%'],
      answer: 2,
      explanation: '0.4 × 0.25 = 0.10.',
    ),
    QuizQuestion(
      prompt: 'Draw 2 cards without replacement. P(both aces)?',
      options: ['4/52 × 4/52', '4/52 × 3/51', '4/52 + 3/51', '2/52'],
      answer: 1,
      explanation: 'P(first ace) × P(second ace | first ace) = 4/52 × 3/51.',
    ),
    QuizQuestion(
      prompt: 'When does P(A and B) = P(A) × P(B)?',
      options: ['Always', 'When A and B are independent', 'When they are mutually exclusive', 'Never'],
      answer: 1,
      explanation: 'Then P(B | A) = P(B), so the general rule simplifies.',
    ),
  ],
);
