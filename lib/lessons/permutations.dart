import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

const List<String> _runnerNames = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

/// Runners filling podium slots one at a time, in random order.
class PermutationSim extends TickSim {
  PermutationSim({super.rng});

  int n = 5;
  int r = 3;

  /// Runner index in each filled slot.
  List<int> podium = [];

  /// Distinct finished arrangements seen.
  final Set<String> seen = {};

  int get total => permutations(n, r);
  bool get full => podium.length == r;

  @override
  double get interval => seen.length < 3 ? 0.7 : 0.18;

  @override
  void tick() {
    if (full) {
      podium = [];
      return;
    }
    final left = [
      for (var i = 0; i < n; i++)
        if (!podium.contains(i)) i
    ];
    podium = [...podium, left[rng.nextInt(left.length)]];
    if (full) seen.add(podium.join());
  }

  @override
  void restart() {
    podium = [];
    seen.clear();
  }
}

void _paintPermutations(Canvas canvas, Size size, PermutationSim sim) {
  final w = size.width;

  // Runners waiting.
  final spacing = (w - 40) / sim.n;
  final rr = math.min(18.0, spacing * 0.36);
  label(canvas, 'Runners', Offset(20, 14), size: 11, color: AppColors.muted, align: TextAlign.left);
  for (var i = 0; i < sim.n; i++) {
    final c = Offset(20 + spacing * (i + 0.5), 44);
    final used = sim.podium.contains(i);
    canvas.drawCircle(c, rr, Paint()..color = AppColors.rainbow[i].withValues(alpha: used ? 0.2 : 1));
    label(canvas, _runnerNames[i], c, size: rr * 0.9, color: used ? AppColors.muted : Colors.white);
  }

  // Podium slots.
  final slotW = math.min(70.0, (w - 40) / sim.r - 8);
  final rowW = sim.r * (slotW + 8) - 8;
  final slotTop = 104.0;
  for (var s = 0; s < sim.r; s++) {
    final x = (w - rowW) / 2 + s * (slotW + 8);
    final rect = Rect.fromLTWH(x, slotTop, slotW, slotW * 0.9);
    roundRect(canvas, rect, AppColors.chip, radius: 10);
    label(canvas, '${s + 1}${['st', 'nd', 'rd', 'th', 'th', 'th', 'th'][s]}', Offset(rect.center.dx, rect.bottom + 12),
        size: 11, color: AppColors.muted);
    if (s < sim.podium.length) {
      final i = sim.podium[s];
      canvas.drawCircle(rect.center, slotW * 0.32, Paint()..color = AppColors.rainbow[i]);
      label(canvas, _runnerNames[i], rect.center, size: slotW * 0.3, color: Colors.white);
    }
    // How many choices this slot had.
    label(canvas, '${sim.n - s} choices', Offset(rect.center.dx, rect.top - 10),
        size: 10, color: s == sim.podium.length - 1 ? AppColors.pink : AppColors.muted);
  }

  // Progress towards seeing every arrangement.
  final y = slotTop + slotW + 52;
  final barW = w - 40;
  final frac = sim.seen.length / sim.total;
  label(canvas, 'Different podiums seen', Offset(20, y), size: 12, align: TextAlign.left);
  roundRect(canvas, Rect.fromLTWH(20, y + 14, barW, 24), Colors.white, radius: 8);
  roundRect(canvas, Rect.fromLTWH(20, y + 14, barW * frac, 24), AppColors.violet, radius: 8);
  label(canvas, '${sim.seen.length} of ${sim.total}', Offset(w / 2, y + 26),
      size: 12, color: frac > 0.5 ? Colors.white : AppColors.ink);

  // A few recent arrangements.
  final recent = sim.seen.toList().reversed.take(8).toList();
  for (var i = 0; i < recent.length; i++) {
    final text = recent[i].split('').map((d) => _runnerNames[int.parse(d)]).join();
    label(canvas, text, Offset(20 + (i % 4) * (barW / 4) + barW / 8, y + 58 + (i ~/ 4) * 20),
        size: 13, color: AppColors.muted);
  }
}

final LessonSpec permutationsLesson = LessonSpec(
  id: 'permutations',
  chapterLabel: 'Ch 4 · Counting',
  title: const [
    TitlePart('When '),
    TitlePart('order', AppColors.violet),
    TitlePart(' matters: filling a podium'),
  ],
  subtitle: 'Permutations · 2-minute animated lesson',
  createSim: () => PermutationSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<PermutationSim>(sim, _paintPermutations),
  stats: (sim) {
    final p = sim as PermutationSim;
    return [
      StatChip('runners n', '${p.n}', AppColors.yellow),
      StatChip('places r', '${p.r}', AppColors.pink),
      StatChip('podiums', '${p.total}', AppColors.violet),
    ];
  },
  bigIdea: 'Gold can go to any of the n runners. Once gold is taken, silver has one '
      'fewer choice, then bronze one fewer again. Multiply the shrinking choices. '
      'A-B-C and C-B-A are different podiums, so order matters: that is a '
      'permutation.',
  formula: (sim) {
    final p = sim as PermutationSim;
    final terms = [for (var i = 0; i < p.r; i++) '${p.n - i}'].join(' × ');
    return 'nPr = n! / (n − r)! = $terms = ${p.total}';
  },
  tryItTitle: 'Try it: more runners, more places',
  buildTryIt: (sim) {
    final p = sim as PermutationSim;
    return watch(
      p,
      () => Column(
        children: [
          LabeledSlider(
            left: 'runners ${p.n}',
            right: '7',
            value: p.n.toDouble(),
            min: 2,
            max: 7,
            divisions: 5,
            onChanged: (v) => p.change(() {
              p.n = v.round();
              p.r = math.min(p.r, p.n);
            }),
          ),
          LabeledSlider(
            left: 'places ${p.r}',
            right: '${p.n}',
            value: p.r.toDouble(),
            min: 1,
            max: p.n.toDouble(),
            divisions: math.max(1, p.n - 1),
            onChanged: (v) => p.change(() => p.r = v.round().clamp(1, p.n)),
          ),
          ControlRow(children: [ActionButton('Run 300 races', () => p.runMany(300 * (p.r + 1)))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: '8 runners race. How many ways can gold, silver and bronze be awarded?',
      options: ['24', '56', '336', '512'],
      answer: 2,
      explanation: '8 × 7 × 6 = 336.',
    ),
    QuizQuestion(
      prompt: 'How many ways can 5 books be arranged on a shelf?',
      options: ['5', '25', '120', '3,125'],
      answer: 2,
      explanation: 'All 5 positions are filled: 5! = 5 × 4 × 3 × 2 × 1 = 120.',
    ),
    QuizQuestion(
      prompt: 'Why is it n × (n − 1) × … and not n × n × …?',
      options: [
        'Because order doesn\'t matter',
        'Because a runner can\'t win two places at once',
        'Because n is small',
        'It is n × n',
      ],
      answer: 1,
      explanation: 'Each place uses up one runner, so the next place has one fewer choice.',
    ),
  ],
);
