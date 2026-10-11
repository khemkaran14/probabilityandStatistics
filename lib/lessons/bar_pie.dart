import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

const List<String> kFruits = ['Mango', 'Apple', 'Banana', 'Grapes', 'Guava'];
const List<double> _fruitWeights = [0.34, 0.22, 0.18, 0.15, 0.11];
const List<Color> _fruitColors = [
  AppColors.orange,
  AppColors.pink,
  AppColors.yellow,
  AppColors.violet,
  AppColors.green
];

class BarPieSim extends TickSim {
  BarPieSim({super.rng});

  List<int> votes = List.filled(kFruits.length, 0);

  /// Index of the latest vote, for a highlight pulse.
  int last = -1;

  int get total => votes.fold(0, (a, b) => a + b);
  int get leader => total == 0 ? 0 : votes.indexOf(votes.reduce(math.max));

  @override
  double get interval => total < 15 ? 0.4 : 0.15;

  @override
  void tick() {
    if (total >= 300) return;
    var r = rng.nextDouble();
    var i = 0;
    while (i < kFruits.length - 1 && r > _fruitWeights[i]) {
      r -= _fruitWeights[i];
      i++;
    }
    vote(i, notify: false);
  }

  void vote(int i, {bool notify = true}) {
    votes[i]++;
    last = i;
    if (notify) notifyListeners();
  }

  @override
  void restart() {
    votes = List.filled(kFruits.length, 0);
    last = -1;
  }
}

void _paintBarPie(Canvas canvas, Size size, BarPieSim sim) {
  final w = size.width;
  final h = size.height;
  final total = math.max(1, sim.total);

  // --- Bar chart (top) ---
  const left = 16.0;
  final right = w - 16;
  final baseline = h * 0.46;
  const top = 26.0;
  final slot = (right - left) / kFruits.length;
  final maxV = math.max(5, sim.votes.reduce(math.max));
  label(canvas, 'Bar chart: compare sizes', Offset(left, 12), size: 11, color: AppColors.muted, align: TextAlign.left);
  for (var i = 0; i < kFruits.length; i++) {
    final x = left + slot * (i + 0.5);
    bar(canvas, x, slot * 0.62, baseline, (baseline - top - 14) * sim.votes[i] / maxV, _fruitColors[i]);
    label(canvas, '${sim.votes[i]}', Offset(x, baseline - (baseline - top - 14) * sim.votes[i] / maxV - 9), size: 11);
    label(canvas, kFruits[i], Offset(x, baseline + 10), size: 10, color: AppColors.muted);
  }
  line(canvas, Offset(left, baseline), Offset(right, baseline), AppColors.peg);

  // --- Pie chart (bottom) ---
  final pieTop = baseline + 30;
  label(canvas, 'Pie chart: parts of a whole', Offset(left, pieTop),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  final r = math.min((h - pieTop - 22) / 2, w * 0.22);
  final c = Offset(left + r + 8, pieTop + 14 + r);
  var start = -math.pi / 2;
  for (var i = 0; i < kFruits.length; i++) {
    final sweep = sim.votes[i] / total * 2 * math.pi;
    if (sweep <= 0) continue;
    final rr = i == sim.last ? r + 4 : r;
    canvas.drawArc(Rect.fromCircle(center: c, radius: rr), start, sweep, true, Paint()..color = _fruitColors[i]);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: rr),
      start,
      sweep,
      true,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    start += sweep;
  }
  if (sim.total == 0) ring(canvas, c, r, AppColors.peg);

  // Legend with percentages.
  final lx = c.dx + r + 22;
  for (var i = 0; i < kFruits.length; i++) {
    final y = pieTop + 22 + i * ((2 * r) / kFruits.length);
    canvas.drawCircle(Offset(lx, y), 6, Paint()..color = _fruitColors[i]);
    label(canvas, '${kFruits[i]} ${(sim.votes[i] / total * 100).round()}%', Offset(lx + 12, y),
        size: 12, align: TextAlign.left);
  }
}

final LessonSpec barPieLesson = LessonSpec(
  id: 'bar_pie',
  chapterLabel: 'Ch 2 · Seeing data',
  title: const [
    TitlePart('Same votes, two '),
    TitlePart('pictures', AppColors.orange),
  ],
  subtitle: 'Bar & pie charts · 2-minute animated lesson',
  createSim: () => BarPieSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<BarPieSim>(sim, _paintBarPie),
  stats: (sim) {
    final b = sim as BarPieSim;
    return [
      StatChip('votes', '${b.total}', AppColors.yellow),
      StatChip('leader', b.total == 0 ? '…' : kFruits[b.leader], AppColors.orange),
      StatChip('its share', b.total == 0 ? '…' : '${(b.votes[b.leader] / b.total * 100).round()}%', AppColors.pink),
    ];
  },
  bigIdea: 'Bars are best for comparing categories: our eyes judge lengths on a '
      'shared baseline very accurately. Pies show parts of one whole, but angles '
      'are hard to compare, so close slices look the same. Use a pie only for a '
      'few categories that add up to 100%.',
  formula: (sim) {
    final b = sim as BarPieSim;
    final t = math.max(1, b.total);
    return 'slice angle = share × 360° → ${kFruits[b.leader]}: '
        '${b.votes[b.leader]}/$t × 360° = ${(b.votes[b.leader] / t * 360).round()}°';
  },
  tryItTitle: 'Try it: cast your own votes',
  buildTryIt: (sim) {
    final b = sim as BarPieSim;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < kFruits.length; i++)
              ActionChip(
                avatar: CircleAvatar(backgroundColor: _fruitColors[i], radius: 8),
                label: Text(kFruits[i], style: const TextStyle(fontWeight: FontWeight.w800)),
                onPressed: () => b.vote(i),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const TryNote('Pause the animation, then vote for Guava ten times. Which chart shows the change more clearly?'),
      ],
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'You want to compare sales of 12 different phone models. Best chart?',
      options: ['Pie chart', 'Bar chart', 'A single number', 'Either is equally good'],
      answer: 1,
      explanation: 'Twelve thin pie slices are impossible to compare. Bars on a common '
          'baseline make small differences visible.',
    ),
    QuizQuestion(
      prompt: 'A slice is 25% of a pie. What angle is it?',
      options: ['25°', '45°', '90°', '180°'],
      answer: 2,
      explanation: '0.25 × 360° = 90°, a right angle.',
    ),
    QuizQuestion(
      prompt: 'When is a pie chart a reasonable choice?',
      options: [
        'Showing change over 10 years',
        'A few parts that add up to one whole',
        'Comparing two unrelated totals',
        'Showing averages',
      ],
      answer: 1,
      explanation: 'Pies show how one whole splits up. They need the parts to sum to '
          '100% and work best with 2–5 slices.',
    ),
  ],
);
