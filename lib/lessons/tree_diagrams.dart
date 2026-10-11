import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Two draws from a bag of 3 red and 2 blue balls.
class TreeSim extends TickSim {
  TreeSim({super.rng});

  static const int red = 3, blue = 2;

  bool replace = false;

  /// Last path: (first is red, second is red).
  (bool, bool)? last;

  /// counts for RR, RB, BR, BB.
  List<int> counts = List.filled(4, 0);

  int get trials => counts.fold(0, (a, b) => a + b);

  /// P(second red | first red / blue).
  double secondRed(bool firstRed) {
    if (replace) return red / (red + blue);
    return firstRed ? (red - 1) / (red + blue - 1) : red / (red + blue - 1);
  }

  double get firstRed => red / (red + blue);

  List<double> get theory => [
        firstRed * secondRed(true),
        firstRed * (1 - secondRed(true)),
        (1 - firstRed) * secondRed(false),
        (1 - firstRed) * (1 - secondRed(false)),
      ];

  @override
  double get interval => trials < 6 ? 1.0 : 0.12;

  @override
  void tick() {
    final a = rng.nextDouble() < firstRed;
    final b = rng.nextDouble() < secondRed(a);
    last = (a, b);
    counts[(a ? 0 : 2) + (b ? 0 : 1)]++;
  }

  @override
  void restart() {
    counts = List.filled(4, 0);
    last = null;
  }
}

String _frac(double p, int denom) => '${(p * denom).round()}/$denom';

void _paintTree(Canvas canvas, Size size, TreeSim sim) {
  final w = size.width;
  final h = size.height;
  const top = 26.0;
  final bottom = h - 30;
  final rootX = 20.0, midX = w * 0.36, leafX = w * 0.66;
  final rootY = (top + bottom) / 2;
  double leafY(int i) => top + (bottom - top) * (i + 0.5) / 4;
  final mids = [(leafY(0) + leafY(1)) / 2, (leafY(2) + leafY(3)) / 2];
  final denom2 = sim.replace ? 5 : 4;

  label(canvas, '1st draw', Offset(midX, 10), size: 11, color: AppColors.muted);
  label(canvas, '2nd draw', Offset(leafX, 10), size: 11, color: AppColors.muted);

  final last = sim.last;
  final t = sim.phase;
  for (var a = 0; a < 2; a++) {
    final firstRed = a == 0;
    final onPath1 = last != null && last.$1 == firstRed;
    final p1 = firstRed ? sim.firstRed : 1 - sim.firstRed;
    final c1 = firstRed ? AppColors.pink : AppColors.blue;
    line(canvas, Offset(rootX, rootY), Offset(midX, mids[a]), onPath1 ? c1 : c1.withValues(alpha: 0.35),
        width: onPath1 ? 4 : 2);
    label(canvas, _frac(p1, 5), Offset((rootX + midX) / 2 - 6, (rootY + mids[a]) / 2 + (a == 0 ? -12 : 12)),
        size: 12, color: c1);
    canvas.drawCircle(Offset(midX, mids[a]), 11, Paint()..color = c1);
    for (var b = 0; b < 2; b++) {
      final secondRed = b == 0;
      final i = a * 2 + b;
      final onPath = onPath1 && last.$2 == secondRed;
      final p2 = secondRed ? sim.secondRed(firstRed) : 1 - sim.secondRed(firstRed);
      final c2 = secondRed ? AppColors.pink : AppColors.blue;
      line(canvas, Offset(midX, mids[a]), Offset(leafX, leafY(i)), onPath ? c2 : c2.withValues(alpha: 0.35),
          width: onPath ? 4 : 2);
      label(canvas, _frac(p2, denom2), Offset((midX + leafX) / 2, (mids[a] + leafY(i)) / 2 - 10), size: 11, color: c2);
      canvas.drawCircle(Offset(leafX, leafY(i)), 9, Paint()..color = c2);
      // Leaf: outcome, theory and what we've seen.
      final name = '${firstRed ? 'R' : 'B'}${secondRed ? 'R' : 'B'}';
      final seen = sim.trials == 0 ? 0 : sim.counts[i] / sim.trials;
      label(canvas, '$name ${sim.theory[i].toStringAsFixed(2)}', Offset(leafX + 16, leafY(i) - 7),
          size: 12, align: TextAlign.left);
      label(canvas, 'seen ${seen.toStringAsFixed(2)}', Offset(leafX + 16, leafY(i) + 9),
          size: 10, color: AppColors.muted, align: TextAlign.left);
    }
  }
  canvas.drawCircle(Offset(rootX, rootY), 7, Paint()..color = AppColors.ink);

  // A ball travelling along the latest path.
  if (last != null && sim.trials <= 6) {
    final a = last.$1 ? 0 : 1;
    final i = a * 2 + (last.$2 ? 0 : 1);
    final p = t < 0.5
        ? Offset.lerp(Offset(rootX, rootY), Offset(midX, mids[a]), t * 2)!
        : Offset.lerp(Offset(midX, mids[a]), Offset(leafX, leafY(i)), (t - 0.5) * 2)!;
    canvas.drawCircle(p, 7, Paint()..color = AppColors.yellow);
  }
  label(canvas, sim.replace ? 'Ball goes back in the bag' : 'Ball stays out of the bag', Offset(w / 2, h - 10),
      size: 12, color: AppColors.violet);
}

final LessonSpec treeDiagramsLesson = LessonSpec(
  id: 'tree_diagrams',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('Follow the '),
    TitlePart('branches', AppColors.green),
    TitlePart(', multiply along the way'),
  ],
  subtitle: 'Tree diagrams · 2-minute animated lesson',
  createSim: () => TreeSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<TreeSim>(sim, _paintTree),
  stats: (sim) {
    final s = sim as TreeSim;
    return [
      StatChip('draws', '${s.trials}', AppColors.yellow),
      StatChip('P(RR)', s.theory[0].toStringAsFixed(2), AppColors.pink),
      StatChip('P(BB)', s.theory[3].toStringAsFixed(2), AppColors.blue),
    ];
  },
  bigIdea: 'A bag holds 3 red and 2 blue balls; you take two. Each branch carries the '
      'chance of that step, given everything before it. If the first ball stays '
      'out, the bag changes, so the second-draw chances depend on the first. '
      'Multiply along a path for one outcome; add paths for "either" outcomes.',
  formula: (sim) {
    final s = sim as TreeSim;
    final d = s.replace ? 5 : 4;
    return 'P(RR) = 3/5 × ${_frac(s.secondRed(true), d)} = ${s.theory[0].toStringAsFixed(2)}   '
        'P(one of each) = ${(s.theory[1] + s.theory[2]).toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: put the ball back or not',
  buildTryIt: (sim) {
    final s = sim as TreeSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<bool>(
            options: const {false: 'Keep it out', true: 'Put it back'},
            selected: s.replace,
            onSelected: (v) => s.change(() => s.replace = v),
          ),
          const SizedBox(height: 8),
          ControlRow(children: [ActionButton('Draw 500 pairs', () => s.runMany(500))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A bag has 3 red and 2 blue. You draw two without replacement. P(both red)?',
      options: ['9/25', '3/10', '6/25', '1/2'],
      answer: 1,
      explanation: '3/5 × 2/4 = 6/20 = 3/10.',
    ),
    QuizQuestion(
      prompt: 'Along one path of a tree diagram, you…',
      options: ['Add the probabilities', 'Multiply the probabilities', 'Subtract them', 'Average them'],
      answer: 1,
      explanation: 'Each step happens and then the next: multiply.',
    ),
    QuizQuestion(
      prompt: 'P(RB) = 0.3 and P(BR) = 0.3. What is P(one of each colour)?',
      options: ['0.09', '0.3', '0.6', '0.9'],
      answer: 2,
      explanation: 'Two separate paths lead to "one of each": add them, 0.3 + 0.3.',
    ),
  ],
);
