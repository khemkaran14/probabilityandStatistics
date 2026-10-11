import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Each trial rolls n dice: did at least one six turn up?
class ComplementSim extends TickSim {
  ComplementSim({super.rng}) {
    _roll();
  }

  int dice = 4;
  int trials = 0;
  int atLeastOne = 0;
  List<int> faces = [];

  /// Recent trial results, newest last (true = at least one six).
  final List<bool> recent = [];

  double get noSixTheory => math.pow(5 / 6, dice).toDouble();
  double get theory => 1 - noSixTheory;
  double get observed => trials == 0 ? 0 : atLeastOne / trials;

  @override
  double get interval => trials < 8 ? 0.8 : (trials < 40 ? 0.25 : 0.06);

  void _roll() => faces = List.generate(dice, (_) => 1 + rng.nextInt(6));

  @override
  void tick() {
    _roll();
    trials++;
    final hit = faces.contains(6);
    if (hit) atLeastOne++;
    recent.add(hit);
    if (recent.length > 60) recent.removeAt(0);
  }

  @override
  void restart() {
    trials = 0;
    atLeastOne = 0;
    recent.clear();
    _roll();
  }
}

void _paintComplement(Canvas canvas, Size size, ComplementSim sim) {
  final w = size.width;
  final h = size.height;

  // Current dice.
  final die = math.min(44.0, (w - 40) / sim.dice * 0.8);
  final rowW = sim.dice * die * 1.2;
  for (var i = 0; i < sim.dice; i++) {
    final f = sim.faces[i];
    paintDie(canvas, Offset((w - rowW) / 2 + die * 1.2 * (i + 0.5), 14 + die / 2), die, f,
        f == 6 ? AppColors.pink : AppColors.chip);
  }
  final hit = sim.faces.contains(6);
  label(canvas, sim.trials == 0 ? 'Roll ${sim.dice} dice…' : (hit ? 'At least one six ✓' : 'No six at all'),
      Offset(w / 2, 30 + die),
      size: 14, color: hit ? AppColors.pink : AppColors.muted);

  // Recent trials as a strip of squares.
  final stripY = 52 + die;
  final sq = (w - 40) / 30;
  for (var i = 0; i < sim.recent.length; i++) {
    final r = Rect.fromLTWH(20 + (i % 30) * sq + 1, stripY + (i ~/ 30) * sq + 1, sq - 2, sq - 2);
    roundRect(canvas, r, sim.recent[i] ? AppColors.pink : AppColors.peg.withValues(alpha: 0.6), radius: 3);
  }

  // Theory bar: split into "no six" (5/6)^n and the complement.
  final barY = stripY + sq * 2 + 40;
  final barW = w - 40;
  label(canvas, 'Every possible result of ${sim.dice} dice', Offset(20, barY - 14), size: 12, align: TextAlign.left);
  final noW = barW * sim.noSixTheory;
  roundRect(canvas, Rect.fromLTWH(20, barY, noW, 34), AppColors.peg, radius: 8);
  roundRect(canvas, Rect.fromLTWH(20 + noW, barY, barW - noW, 34), AppColors.pink, radius: 8);
  label(canvas, 'no six', Offset(20 + noW / 2, barY + 17), size: 12, color: Colors.white);
  if (barW - noW > 60) {
    label(canvas, 'at least one', Offset(20 + noW + (barW - noW) / 2, barY + 17), size: 12, color: Colors.white);
  }
  label(canvas, '(5/6)^${sim.dice} = ${sim.noSixTheory.toStringAsFixed(3)}', Offset(20 + noW / 2, barY + 48),
      size: 11, color: AppColors.muted);
  label(canvas, '1 − that = ${sim.theory.toStringAsFixed(3)}', Offset(w - 20, barY + 66),
      size: 12, color: AppColors.pink, align: TextAlign.right);
  label(canvas, 'seen: ${sim.observed.toStringAsFixed(3)} of ${sim.trials} trials', Offset(20, h - 12),
      size: 11, color: AppColors.muted, align: TextAlign.left);
}

final LessonSpec complementLesson = LessonSpec(
  id: 'complement',
  chapterLabel: 'Ch 3 · Probability basics',
  title: const [
    TitlePart('Hard to count? Count what '),
    TitlePart('didn\'t', AppColors.pink),
    TitlePart(' happen'),
  ],
  subtitle: 'The complement rule · 2-minute animated lesson',
  createSim: () => ComplementSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<ComplementSim>(sim, _paintComplement),
  stats: (sim) {
    final c = sim as ComplementSim;
    return [
      StatChip('trials', '${c.trials}', AppColors.yellow),
      StatChip('≥ one six', c.observed.toStringAsFixed(3), AppColors.pink),
      StatChip('theory', c.theory.toStringAsFixed(3), AppColors.violet),
    ];
  },
  bigIdea: '"At least one six" can happen in many ways: one six, two sixes, six '
      'on the first die or the third… Counting them all is painful. Its opposite, '
      '"no six at all", happens in just one way: every die misses, with chance '
      '5/6 each. Something either happens or it doesn\'t, so the two chances add '
      'up to 1.',
  formula: (sim) {
    final c = sim as ComplementSim;
    return 'P(at least one six) = 1 − P(no six) = 1 − (5/6)^${c.dice} = ${c.theory.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: roll more dice at once',
  buildTryIt: (sim) {
    final c = sim as ComplementSim;
    return watch(
      c,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '1 die',
            right: '10',
            value: c.dice.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '${c.dice}',
            onChanged: (v) => c.change(() => c.dice = v.round()),
          ),
          const TryNote('With 4 dice you already have better than even odds of a six (0.518).'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'P(rain tomorrow) = 0.3. What is P(no rain)?',
      options: ['0.3', '0.7', '1.3', 'Can\'t tell'],
      answer: 1,
      explanation: 'It either rains or it doesn\'t: 1 − 0.3 = 0.7.',
    ),
    QuizQuestion(
      prompt: 'Flip 3 coins. What is P(at least one head)?',
      options: ['1/8', '3/8', '1/2', '7/8'],
      answer: 3,
      explanation: 'P(no heads) = (1/2)³ = 1/8, so P(at least one) = 1 − 1/8 = 7/8.',
    ),
    QuizQuestion(
      prompt: 'Why use the complement for "at least one" questions?',
      options: [
        'It is always smaller',
        '"None" is one simple case; "at least one" is many cases',
        'It avoids decimals',
        'It only works for dice',
      ],
      answer: 1,
      explanation: 'Calculating the single "none" case and subtracting from 1 is far '
          'quicker than adding up every way to get one or more.',
    ),
  ],
);
