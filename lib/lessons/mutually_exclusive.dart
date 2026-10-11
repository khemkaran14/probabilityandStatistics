import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

const List<String> kSuits = ['♥', '♦', '♣', '♠'];
const List<String> kRanks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

/// Event pairs on a 52-card deck: card index = suit * 13 + rank.
enum CardPair { heartsSpades, heartsKings, redFace, acesKings }

const Map<CardPair, String> kCardPairNames = {
  CardPair.heartsSpades: '♥ or ♠',
  CardPair.heartsKings: '♥ or King',
  CardPair.redFace: 'Red or face card',
  CardPair.acesKings: 'Ace or King',
};

bool _inA(CardPair p, int card) {
  final suit = card ~/ 13, rank = card % 13;
  return switch (p) {
    CardPair.heartsSpades || CardPair.heartsKings => suit == 0,
    CardPair.redFace => suit <= 1,
    CardPair.acesKings => rank == 0,
  };
}

bool _inB(CardPair p, int card) {
  final suit = card ~/ 13, rank = card % 13;
  return switch (p) {
    CardPair.heartsSpades => suit == 3,
    CardPair.heartsKings || CardPair.acesKings => rank == 12,
    CardPair.redFace => rank >= 10,
  };
}

class MutualSim extends TickSim {
  MutualSim({super.rng});

  CardPair pair = CardPair.heartsSpades;
  int draws = 0;
  int hits = 0;
  int last = -1;

  bool inA(int c) => _inA(pair, c);
  bool inB(int c) => _inB(pair, c);
  int get countA => List.generate(52, (c) => c).where(inA).length;
  int get countB => List.generate(52, (c) => c).where(inB).length;
  int get countBoth => List.generate(52, (c) => c).where((c) => inA(c) && inB(c)).length;
  bool get exclusive => countBoth == 0;

  @override
  double get interval => draws < 10 ? 0.6 : 0.08;

  @override
  void tick() {
    last = rng.nextInt(52);
    draws++;
    if (inA(last) || inB(last)) hits++;
  }

  @override
  void restart() {
    draws = 0;
    hits = 0;
    last = -1;
  }
}

void _paintMutual(Canvas canvas, Size size, MutualSim sim) {
  final w = size.width;
  final h = size.height;
  final cellW = (w - 20) / 13;
  final cellH = cellW * 1.3;
  const top = 20.0;
  for (var c = 0; c < 52; c++) {
    final suit = c ~/ 13, rank = c % 13;
    final r = Rect.fromLTWH(10 + rank * cellW + 1.5, top + suit * (cellH + 4), cellW - 3, cellH);
    final a = sim.inA(c), b = sim.inB(c);
    final fill = a && b
        ? AppColors.violet
        : a
            ? AppColors.pink
            : b
                ? AppColors.cyan
                : Colors.white;
    roundRect(canvas, r, fill.withValues(alpha: (a || b) ? 0.85 : 1), radius: 4);
    if (c == sim.last) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(5)),
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final red = suit <= 1;
    label(canvas, kRanks[rank], r.center.translate(0, -cellH * 0.16),
        size: cellW * 0.36, color: (a || b) ? Colors.white : (red ? AppColors.pink : AppColors.ink));
    label(canvas, kSuits[suit], r.center.translate(0, cellH * 0.2),
        size: cellW * 0.36, color: (a || b) ? Colors.white : (red ? AppColors.pink : AppColors.ink));
  }

  final y = top + 4 * (cellH + 4) + 18;
  final items = [
    ('A only', AppColors.pink, sim.countA - sim.countBoth),
    ('B only', AppColors.cyan, sim.countB - sim.countBoth),
    ('both', AppColors.violet, sim.countBoth),
  ];
  for (var i = 0; i < items.length; i++) {
    final (name, color, n) = items[i];
    final x = 14 + i * (w - 28) / 3;
    roundRect(canvas, Rect.fromLTWH(x, y - 8, 16, 16), color, radius: 4);
    label(canvas, '$name: $n', Offset(x + 22, y), size: 12, align: TextAlign.left);
  }
  label(
      canvas,
      sim.exclusive ? 'No card is in both: mutually exclusive' : '${sim.countBoth} cards are in both: they overlap',
      Offset(w / 2, y + 28),
      size: 14,
      color: sim.exclusive ? AppColors.green : AppColors.violet);
  label(
      canvas,
      'Drawn ${sim.draws} cards (with replacement) · ${sim.draws == 0 ? 0 : (sim.hits / sim.draws * 100).toStringAsFixed(1)}% were A or B',
      Offset(w / 2, h - 14),
      size: 11,
      color: AppColors.muted);
}

final LessonSpec mutuallyExclusiveLesson = LessonSpec(
  id: 'mutually_exclusive',
  chapterLabel: 'Ch 3 · Probability basics',
  title: const [
    TitlePart('Can both happen '),
    TitlePart('at once', AppColors.violet),
    TitlePart('?'),
  ],
  subtitle: 'Mutually exclusive events · 2-minute animated lesson',
  createSim: () => MutualSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<MutualSim>(sim, _paintMutual),
  stats: (sim) {
    final m = sim as MutualSim;
    return [
      StatChip('P(A)', '${m.countA}/52', AppColors.pink),
      StatChip('P(B)', '${m.countB}/52', AppColors.cyan),
      StatChip('P(both)', '${m.countBoth}/52', AppColors.violet),
    ];
  },
  bigIdea: 'Two events are mutually exclusive if they can\'t happen together: one '
      'card can\'t be a heart and a spade. Then the chance of either is just the '
      'sum. But a card can be a heart and a king, so adding 13 + 4 counts the king '
      'of hearts twice. Purple cards show the overlap you must subtract.',
  formula: (sim) {
    final m = sim as MutualSim;
    final either = m.countA + m.countB - m.countBoth;
    return 'P(A or B) = ${m.countA}/52 + ${m.countB}/52 − ${m.countBoth}/52 = $either/52';
  },
  tryItTitle: 'Try it: pick two events',
  buildTryIt: (sim) {
    final m = sim as MutualSim;
    return watch(
      m,
      () => ChoiceRow<CardPair>(
        options: kCardPairNames,
        selected: m.pair,
        onSelected: (v) => m.change(() => m.pair = v),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Which pair of events is mutually exclusive for one die roll?',
      options: ['Even and 6', 'Odd and less than 3', 'Even and odd', 'Prime and odd'],
      answer: 2,
      explanation: 'No number is both even and odd. All the other pairs share at least one outcome.',
    ),
    QuizQuestion(
      prompt: 'Draw one card. What is P(heart or spade)?',
      options: ['1/4', '1/2', '13/52 × 13/52', '3/4'],
      answer: 1,
      explanation: 'They can\'t both happen, so add: 13/52 + 13/52 = 26/52 = 1/2.',
    ),
    QuizQuestion(
      prompt: 'Draw one card. What is P(heart or king)?',
      options: ['17/52', '16/52', '4/52', '13/52'],
      answer: 1,
      explanation: '13 hearts + 4 kings − 1 king of hearts counted twice = 16/52.',
    ),
  ],
);
