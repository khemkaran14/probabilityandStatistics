import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Two-digit scores filed one by one into a stem-and-leaf plot.
class StemLeafSim extends TickSim {
  StemLeafSim({super.rng}) {
    restart();
  }

  static const int n = 24;
  static const int minStem = 4, maxStem = 9;

  List<int> data = [];
  int placed = 0;

  @override
  double get interval => placed < 5 ? 0.9 : 0.4;

  bool get done => placed >= n;

  /// Leaves per stem, sorted, from the values placed so far.
  Map<int, List<int>> get rows {
    final out = {for (var s = minStem; s <= maxStem; s++) s: <int>[]};
    for (var i = 0; i < placed; i++) {
      out[data[i] ~/ 10]!.add(data[i] % 10);
    }
    for (final l in out.values) {
      l.sort();
    }
    return out;
  }

  @override
  void tick() {
    if (placed < n) placed++;
  }

  @override
  void restart() {
    data = List.generate(n, (_) => (68 + normalDraw(rng) * 12).round().clamp(40, 99));
    placed = 0;
  }
}

void _paintStemLeaf(Canvas canvas, Size size, StemLeafSim sim) {
  final w = size.width;
  final h = size.height;

  // The unsorted list at the top.
  const perRow = 12;
  final cell = (w - 24) / perRow;
  for (var i = 0; i < StemLeafSim.n; i++) {
    final c = Offset(12 + cell * (i % perRow + 0.5), 20 + (i ~/ perRow) * 24.0);
    final isCurrent = i == sim.placed - 1;
    final isDone = i < sim.placed;
    if (isCurrent) roundRect(canvas, Rect.fromCenter(center: c, width: cell - 2, height: 22), AppColors.yellow);
    label(canvas, '${sim.data[i]}', c,
        size: 13, color: isDone && !isCurrent ? AppColors.peg : AppColors.ink, weight: FontWeight.w900);
  }

  // The plot.
  final top = 76.0;
  final rowH = (h - top - 30) / (StemLeafSim.maxStem - StemLeafSim.minStem + 1);
  final stemX = 44.0;
  label(canvas, 'stem', Offset(stemX - 14, top - 8), size: 10, color: AppColors.muted);
  label(canvas, 'leaves', Offset(stemX + 40, top - 8), size: 10, color: AppColors.muted);
  line(canvas, Offset(stemX + 4, top), Offset(stemX + 4, h - 30), AppColors.ink, width: 2.5);
  final current = sim.placed == 0 ? null : sim.data[sim.placed - 1];
  final rows = sim.rows;
  for (var s = StemLeafSim.minStem; s <= StemLeafSim.maxStem; s++) {
    final y = top + rowH * (s - StemLeafSim.minStem + 0.5);
    label(canvas, '$s', Offset(stemX - 14, y), size: 18, color: AppColors.violet, weight: FontWeight.w900);
    final leaves = rows[s]!;
    var highlighted = false;
    for (var k = 0; k < leaves.length; k++) {
      final x = stemX + 22 + k * math.min(22.0, (w - stemX - 40) / 12);
      final isNew = !highlighted && current != null && s == current ~/ 10 && leaves[k] == current % 10;
      if (isNew) {
        highlighted = true;
        canvas.drawCircle(Offset(x, y), 12, Paint()..color = AppColors.pink.withValues(alpha: 0.25));
      }
      label(canvas, '${leaves[k]}', Offset(x, y),
          size: 17, color: isNew ? AppColors.pink : AppColors.ink, weight: FontWeight.w900);
    }
  }
  if (current != null) {
    label(canvas, '$current → stem ${current ~/ 10} | leaf ${current % 10}', Offset(w / 2, h - 12),
        size: 13, color: AppColors.pink);
  }
}

final LessonSpec stemLeafLesson = LessonSpec(
  id: 'stem_leaf',
  chapterLabel: 'Ch 2 · Seeing data',
  title: const [
    TitlePart('A chart made of the '),
    TitlePart('numbers themselves', AppColors.violet),
  ],
  subtitle: 'Stem-and-leaf plots · 2-minute animated lesson',
  createSim: () => StemLeafSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<StemLeafSim>(sim, _paintStemLeaf),
  stats: (sim) {
    final s = sim as StemLeafSim;
    final busiest = s.rows.entries.reduce((a, b) => b.value.length > a.value.length ? b : a);
    return [
      StatChip('placed', '${s.placed}/${StemLeafSim.n}', AppColors.yellow),
      StatChip('busiest', s.placed == 0 ? '…' : '${busiest.key}0s', AppColors.violet),
      StatChip('median', s.done ? quantileOf(s.data, .5).toStringAsFixed(1) : '…', AppColors.pink),
    ];
  },
  bigIdea: 'Split each number into a stem (the tens) and a leaf (the units). Each '
      'row is a bin of ten, and its leaves make a little bar, so turning the page '
      'sideways gives a histogram. Unlike a histogram, every original value can '
      'still be read back, and with sorted leaves you can count to the median.',
  formula: (sim) {
    final s = sim as StemLeafSim;
    if (s.placed == 0) return '73 → 7 | 3';
    final v = s.data[s.placed - 1];
    return '$v → ${v ~/ 10} | ${v % 10}   (key: 7 | 3 means 73)';
  },
  tryItTitle: 'Try it: new data',
  buildTryIt: (sim) {
    final s = sim as StemLeafSim;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ControlRow(children: [
          ActionButton('New scores', s.reset),
          ActionButton('Place all', () => s.runMany(StemLeafSim.n)),
        ]),
        const SizedBox(height: 8),
        const TryNote('Tilt your head left: the rows of leaves are the bars of a histogram.'),
      ],
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'In a stem-and-leaf plot with key "6 | 4 = 64", what does the row "8 | 0 2 7" show?',
      options: ['8, 0, 2, 7', '80, 82, 87', '8.027', '802 and 7'],
      answer: 1,
      explanation: 'The stem 8 is the tens digit; each leaf adds a units digit.',
    ),
    QuizQuestion(
      prompt: 'An advantage over a histogram is that a stem-and-leaf plot…',
      options: [
        'Works for millions of values',
        'Keeps every original value',
        'Shows categories',
        'Needs no sorting',
      ],
      answer: 1,
      explanation: 'You can rebuild the exact data from it. Histograms only keep counts.',
    ),
    QuizQuestion(
      prompt: 'The row with the most leaves tells you…',
      options: ['The mean', 'Where the data is most concentrated', 'The range', 'Nothing'],
      answer: 1,
      explanation: 'The longest row is the tallest "bar": the most common ten-band.',
    ),
  ],
);
