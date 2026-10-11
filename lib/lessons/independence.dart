import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Two coins. A "sticky" second coin copies the first with some chance.
class IndependenceSim extends TickSim {
  IndependenceSim({super.rng});

  /// Chance the second coin just copies the first (0 = independent).
  double sticky = 0;

  bool first = true, second = true;

  /// counts[first ? 0 : 1][second ? 0 : 1]
  List<List<int>> counts = [
    [0, 0],
    [0, 0],
  ];

  int get flips => counts[0][0] + counts[0][1] + counts[1][0] + counts[1][1];

  double _rate(int row) {
    final n = counts[row][0] + counts[row][1];
    return n == 0 ? 0 : counts[row][0] / n;
  }

  /// P(second heads | first heads) and P(second heads | first tails).
  double get headsAfterHeads => _rate(0);
  double get headsAfterTails => _rate(1);

  @override
  double get interval => flips < 10 ? 0.6 : 0.06;

  @override
  void tick() {
    first = rng.nextBool();
    second = rng.nextDouble() < sticky ? first : rng.nextBool();
    counts[first ? 0 : 1][second ? 0 : 1]++;
  }

  @override
  void restart() {
    counts = [
      [0, 0],
      [0, 0],
    ];
  }
}

void _paintIndependence(Canvas canvas, Size size, IndependenceSim sim) {
  final w = size.width;
  final h = size.height;

  void coin(Offset c, bool heads, String name) {
    canvas.drawCircle(c, 26, Paint()..color = heads ? AppColors.yellow : AppColors.cyan);
    label(canvas, heads ? 'H' : 'T', c, size: 22);
    label(canvas, name, c.translate(0, 38), size: 11, color: AppColors.muted);
  }

  if (sim.flips > 0) {
    coin(Offset(w * 0.35, 40), sim.first, 'coin 1');
    coin(Offset(w * 0.65, 40), sim.second, 'coin 2');
  }

  // 2×2 table.
  const tableTop = 104.0;
  final cellW = (w - 110) / 2;
  const cellH = 44.0;
  label(canvas, 'coin 2: H', Offset(90 + cellW * 0.5, tableTop - 10), size: 11, color: AppColors.muted);
  label(canvas, 'coin 2: T', Offset(90 + cellW * 1.5, tableTop - 10), size: 11, color: AppColors.muted);
  for (var r = 0; r < 2; r++) {
    label(canvas, r == 0 ? 'coin 1: H' : 'coin 1: T', Offset(84, tableTop + cellH * (r + 0.5)),
        size: 11, color: AppColors.muted, align: TextAlign.right);
    for (var c = 0; c < 2; c++) {
      final rect = Rect.fromLTWH(90 + cellW * c + 2, tableTop + cellH * r + 2, cellW - 4, cellH - 4);
      final share = sim.flips == 0 ? 0.0 : sim.counts[r][c] / sim.flips;
      roundRect(canvas, rect, AppColors.violet.withValues(alpha: 0.1 + share * 1.6), radius: 8);
      label(canvas, '${sim.counts[r][c]}', rect.center, size: 15);
    }
  }

  // The test: does coin 1 change coin 2's chances?
  final y = tableTop + cellH * 2 + 30;
  final barW = w - 150;
  for (final (i, name, p, color) in [
    (0, 'H after H', sim.headsAfterHeads, AppColors.yellow),
    (1, 'H after T', sim.headsAfterTails, AppColors.cyan),
  ]) {
    final by = y + i * 36;
    label(canvas, name, Offset(116, by + 12), size: 12, align: TextAlign.right);
    roundRect(canvas, Rect.fromLTWH(126, by, barW, 24), Colors.white, radius: 8);
    roundRect(canvas, Rect.fromLTWH(126, by, barW * p, 24), color, radius: 8);
    label(canvas, p.toStringAsFixed(2), Offset(126 + barW + 4, by + 12), size: 12, align: TextAlign.left);
  }
  dashedLine(canvas, Offset(126 + barW / 2, y - 6), Offset(126 + barW / 2, y + 66), AppColors.ink);
  final gap = (sim.headsAfterHeads - sim.headsAfterTails).abs();
  label(
    canvas,
    sim.flips < 40
        ? 'Flipping…'
        : (gap < 0.06 ? 'Same chance either way: independent' : 'Coin 1 changes coin 2: dependent'),
    Offset(w / 2, h - 14),
    size: 13,
    color: gap < 0.06 ? AppColors.green : AppColors.pink,
  );
}

final LessonSpec independenceLesson = LessonSpec(
  id: 'independence',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('Does one result '),
    TitlePart('change', AppColors.pink),
    TitlePart(' the other?'),
  ],
  subtitle: 'Independence · 2-minute animated lesson',
  createSim: () => IndependenceSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<IndependenceSim>(sim, _paintIndependence),
  stats: (sim) {
    final s = sim as IndependenceSim;
    return [
      StatChip('pairs', '${s.flips}', AppColors.yellow),
      StatChip('H after H', s.headsAfterHeads.toStringAsFixed(2), AppColors.orange),
      StatChip('H after T', s.headsAfterTails.toStringAsFixed(2), AppColors.cyan),
    ];
  },
  bigIdea: 'Two events are independent when knowing one tells you nothing about the '
      'other. With fair coins, coin 2 lands heads half the time whether coin 1 was '
      'heads or tails: the bars match. Make coin 2 "sticky" and it copies coin 1, '
      'so the bars split apart. Only for independent events can you simply '
      'multiply: P(A and B) = P(A) × P(B).',
  formula: (sim) {
    final s = sim as IndependenceSim;
    final hh = s.flips == 0 ? 0 : s.counts[0][0] / s.flips;
    return 'independent ⇔ P(B | A) = P(B)\n'
        'P(H, H) seen ${hh.toStringAsFixed(3)} vs ½ × ½ = 0.250';
  },
  tryItTitle: 'Try it: make coin 2 sticky',
  buildTryIt: (sim) {
    final s = sim as IndependenceSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'fair',
            right: 'copycat',
            value: s.sticky,
            min: 0,
            max: 0.9,
            divisions: 9,
            label: '${(s.sticky * 100).round()}% copy',
            onChanged: (v) => s.change(() => s.sticky = v),
          ),
          ControlRow(children: [ActionButton('Flip 500 pairs', () => s.runMany(500))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Which pair of events is independent?',
      options: [
        'Raining today and carrying an umbrella',
        'Rolling a 6 and flipping heads',
        'Studying and passing',
        'Drawing two cards without putting the first back',
      ],
      answer: 1,
      explanation: 'The die and the coin have no way to affect each other.',
    ),
    QuizQuestion(
      prompt: 'P(A) = 0.5, P(B) = 0.4, and they are independent. What is P(A and B)?',
      options: ['0.9', '0.2', '0.1', '0.45'],
      answer: 1,
      explanation: '0.5 × 0.4 = 0.2.',
    ),
    QuizQuestion(
      prompt: 'P(B | A) = 0.7 but P(B) = 0.3. Are A and B independent?',
      options: ['Yes', 'No', 'Only if P(A) = 0.5', 'Can\'t tell'],
      answer: 1,
      explanation: 'Knowing A happened raises B\'s chance from 0.3 to 0.7, so they are dependent.',
    ),
  ],
);
