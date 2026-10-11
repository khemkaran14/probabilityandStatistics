import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Every ordered pick of r people from n, sliding into columns by team.
class CombinationSim extends LessonSim {
  CombinationSim() {
    _build();
  }

  static const double cycle = 8;

  int n = 4;
  int r = 2;
  double t = 0;

  /// Ordered picks in dictionary order.
  late List<List<int>> ordered;

  /// Distinct teams (sorted picks) in dictionary order.
  late List<List<int>> teams;

  int get perms => ordered.length;
  int get combos => teams.length;

  void _build() {
    ordered = [];
    void go(List<int> prefix) {
      if (prefix.length == r) {
        ordered.add(prefix);
        return;
      }
      for (var i = 0; i < n; i++) {
        if (!prefix.contains(i)) go([...prefix, i]);
      }
    }

    go([]);
    final keys = <String>{};
    teams = [];
    for (final p in ordered) {
      final s = [...p]..sort();
      if (keys.add(s.join())) teams.add(s);
    }
    teams.sort((a, b) => a.join().compareTo(b.join()));
  }

  int teamOf(List<int> p) {
    final key = ([...p]..sort()).join();
    return teams.indexWhere((t) => t.join() == key);
  }

  /// 0 = arrangements in order, 1 = grouped into teams.
  double get grouping {
    final s = t % cycle;
    if (s < 2) return 0;
    if (s < 4) return Curves.easeInOutCubic.transform((s - 2) / 2);
    if (s < 6) return 1;
    return 1 - Curves.easeInOutCubic.transform((s - 6) / 2);
  }

  @override
  void advance(double dt) {
    t = (t + dt) % cycle;
    notifyListeners();
  }

  @override
  void step() {
    t = ((t ~/ 2) * 2 + 2.0) % cycle;
    notifyListeners();
  }

  @override
  void reset() {
    t = 0;
    notifyListeners();
  }

  void setSizes({int? n, int? r}) {
    this.n = n ?? this.n;
    this.r = math.min(r ?? this.r, this.n);
    _build();
    t = 0;
    notifyListeners();
  }
}

const _people = ['A', 'B', 'C', 'D', 'E'];

void _paintCombinations(Canvas canvas, Size size, CombinationSim sim) {
  final w = size.width;
  final h = size.height;
  final cols = sim.combos;
  final rows = sim.perms ~/ cols; // = r!
  const top = 30.0;
  final cellW = (w - 20) / cols;
  final cellH = math.min((h - top - 50) / rows, cellW * 1.6);
  final g = sim.grouping;

  final within = List.filled(cols, 0);
  for (var i = 0; i < sim.perms; i++) {
    final p = sim.ordered[i];
    final team = sim.teamOf(p);
    final from = Offset(10 + (i % cols + 0.5) * cellW, top + (i ~/ cols + 0.5) * cellH);
    final to = Offset(10 + (team + 0.5) * cellW, top + (within[team]++ + 0.5) * cellH);
    final c = Offset.lerp(from, to, g)!;
    final color = HSVColor.fromAHSV(1, 360 * team / cols, 0.55, 0.95).toColor();
    final rect = Rect.fromCenter(center: c, width: cellW - 4, height: cellH - 4);
    roundRect(canvas, rect, color.withValues(alpha: 0.35), radius: 6);
    // The people in pick order.
    final dot = math.min(rect.width / (sim.r * 1.25), rect.height * 0.7);
    final vertical = rect.height > rect.width * 1.3;
    for (var k = 0; k < sim.r; k++) {
      final off = (k - (sim.r - 1) / 2) * dot * 1.1;
      final pc = vertical ? c.translate(0, off) : c.translate(off, 0);
      canvas.drawCircle(pc, dot * 0.48, Paint()..color = AppColors.rainbow[p[k]]);
      label(canvas, _people[p[k]], pc, size: dot * 0.55, color: Colors.white);
    }
  }

  label(canvas, g < 0.5 ? 'All ${sim.perms} ordered picks' : '${sim.combos} teams, each listed $rows× (r! orders)',
      Offset(w / 2, 14),
      size: 13, color: g < 0.5 ? AppColors.ink : AppColors.violet);
  label(canvas, '${sim.perms} ÷ $rows = ${sim.combos} different teams', Offset(w / 2, h - 16),
      size: 14, color: AppColors.violet);
}

final LessonSpec combinationsLesson = LessonSpec(
  id: 'combinations',
  chapterLabel: 'Ch 4 · Counting',
  title: const [
    TitlePart('When order '),
    TitlePart('doesn\'t', AppColors.violet),
    TitlePart(' matter: picking a team'),
  ],
  subtitle: 'Combinations · 2-minute animated lesson',
  createSim: () => CombinationSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<CombinationSim>(sim, _paintCombinations),
  stats: (sim) {
    final c = sim as CombinationSim;
    return [
      StatChip('ordered nPr', '${c.perms}', AppColors.yellow),
      StatChip('orders each r!', '${factorial(c.r)}', AppColors.pink),
      StatChip('teams nCr', '${c.combos}', AppColors.violet),
    ];
  },
  bigIdea: 'Picking A then B, or B then A, gives the same team. Count the ordered '
      'picks first (a permutation), then notice every team appears once for each '
      'way of ordering its r members, which is r! times. Divide those repeats out '
      'and you get the number of combinations.',
  formula: (sim) {
    final c = sim as CombinationSim;
    return 'nCr = nPr / r! = ${c.perms} / ${factorial(c.r)} = ${c.combos}';
  },
  tryItTitle: 'Try it: change the group and team size',
  buildTryIt: (sim) {
    final c = sim as CombinationSim;
    return watch(
      c,
      () => Column(
        children: [
          LabeledSlider(
            left: 'people ${c.n}',
            right: '5',
            value: c.n.toDouble(),
            min: 3,
            max: 5,
            divisions: 2,
            onChanged: (v) => c.setSizes(n: v.round()),
          ),
          LabeledSlider(
            left: 'team ${c.r}',
            right: '3',
            value: c.r.toDouble(),
            min: 1,
            max: 3,
            divisions: 2,
            onChanged: (v) => c.setSizes(r: v.round()),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'How many ways can you choose 2 toppings from 6?',
      options: ['12', '15', '30', '36'],
      answer: 1,
      explanation: '6 × 5 = 30 ordered picks, but each pair is counted twice: 30 / 2 = 15.',
    ),
    QuizQuestion(
      prompt: 'Which situation is a combination, not a permutation?',
      options: [
        'Gold, silver and bronze medals',
        'A 4-digit PIN',
        'Choosing 3 friends to invite',
        'Seating people in a row',
      ],
      answer: 2,
      explanation: 'Inviting Asha, Ben and Chen is the same invitation in any order.',
    ),
    QuizQuestion(
      prompt: 'What is C(10, 3)?',
      options: ['30', '120', '720', '1,000'],
      answer: 1,
      explanation: '10 × 9 × 8 = 720 ordered picks, divided by 3! = 6 orders: 120.',
    ),
  ],
);
