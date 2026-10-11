import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// The hat-check puzzle: n hats handed back at random. How many people get
/// their own hat, on average?
class LinearitySim extends TickSim {
  LinearitySim({super.rng}) {
    _deal();
  }

  int n = 8;
  late List<int> hats; // hats[person] = whose hat they got
  int rounds = 0;
  int totalMatches = 0;
  List<int> matchCounts = List.filled(21, 0);

  int get matches => [
        for (var i = 0; i < n; i++)
          if (hats[i] == i) i
      ].length;
  double get average => rounds == 0 ? 0 : totalMatches / rounds;

  @override
  double get interval => rounds < 5 ? 1.2 : 0.08;

  void _deal() => hats = List.generate(n, (i) => i)..shuffle(rng);

  @override
  void tick() {
    _deal();
    rounds++;
    totalMatches += matches;
    matchCounts[matches]++;
  }

  @override
  void restart() {
    rounds = 0;
    totalMatches = 0;
    matchCounts = List.filled(21, 0);
    _deal();
  }
}

void _paintLinearity(Canvas canvas, Size size, LinearitySim sim) {
  final w = size.width;
  final h = size.height;

  // People in a row with the hat they got.
  final slot = (w - 20) / sim.n;
  final r = math.min(16.0, slot * 0.36);
  for (var i = 0; i < sim.n; i++) {
    final x = 10 + slot * (i + 0.5);
    final match = sim.hats[i] == i;
    canvas.drawCircle(Offset(x, 64), r, Paint()..color = AppColors.rainbow[i % 7].withValues(alpha: 0.85));
    label(canvas, '${i + 1}', Offset(x, 64), size: r * 0.8, color: Colors.white);
    // Hat on top, coloured by its owner.
    final hat = Rect.fromCenter(center: Offset(x, 64 - r - 8), width: r * 1.8, height: r * 0.8);
    roundRect(canvas, hat, AppColors.rainbow[sim.hats[i] % 7], radius: 4);
    label(canvas, '${sim.hats[i] + 1}', hat.center, size: r * 0.55, color: Colors.white);
    if (match) ring(canvas, Offset(x, 58), r + 14, AppColors.green, width: 3);
  }
  label(canvas, sim.rounds == 0 ? 'Hats handed back at random' : '${sim.matches} got their own hat', Offset(w / 2, 100),
      size: 14, color: sim.matches > 0 ? AppColors.green : AppColors.muted);

  // Histogram of matches per round.
  const left = 20.0;
  final right = w - 20;
  final baseline = h - 50;
  const top = 132.0;
  const maxShown = 6;
  final slotH = (right - left) / (maxShown + 1);
  final maxC = math.max(1, sim.matchCounts.take(maxShown + 1).reduce(math.max));
  for (var m = 0; m <= maxShown; m++) {
    bar(canvas, left + slotH * (m + 0.5), slotH * 0.7, baseline, (baseline - top) * sim.matchCounts[m] / maxC,
        m == 1 ? AppColors.green : AppColors.violet.withValues(alpha: 0.7));
    label(canvas, '$m', Offset(left + slotH * (m + 0.5), baseline + 10), size: 11, color: AppColors.muted);
  }
  label(canvas, 'own hats per round', Offset(w / 2, baseline + 24), size: 10, color: AppColors.muted);
  label(canvas, 'average so far: ${sim.average.toStringAsFixed(3)} (rounds: ${sim.rounds})', Offset(w / 2, h - 10),
      size: 13, color: AppColors.violet);
}

final LessonSpec linearityLesson = LessonSpec(
  id: 'linearity',
  chapterLabel: 'Ch 6 · Random variables',
  title: const [
    TitlePart('Any crowd, the answer is always '),
    TitlePart('1', AppColors.green),
  ],
  subtitle: 'Linearity of expectation · 2-minute animated lesson',
  createSim: () => LinearitySim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<LinearitySim>(sim, _paintLinearity),
  stats: (sim) {
    final l = sim as LinearitySim;
    return [
      StatChip('people', '${l.n}', AppColors.yellow),
      StatChip('rounds', '${l.rounds}', AppColors.violet),
      StatChip('avg own hats', l.average.toStringAsFixed(2), AppColors.green),
    ];
  },
  bigIdea: 'n people check their hats and get them back at random. Counting all the '
      'ways to match is hard, so don\'t. Give each person their own 0-or-1 score: '
      '1 if they got their hat. Each person gets their hat with chance 1/n, so '
      'each score averages 1/n. The expected total is the sum of the expected '
      'scores: n × 1/n = 1. This works even though the scores depend on each other.',
  formula: (sim) {
    final l = sim as LinearitySim;
    return 'E[X₁ + … + Xₙ] = E[X₁] + … + E[Xₙ] = ${l.n} × 1/${l.n} = 1';
  },
  tryItTitle: 'Try it: change the crowd size',
  buildTryIt: (sim) {
    final l = sim as LinearitySim;
    return watch(
      l,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '2',
            right: '20',
            value: l.n.toDouble(),
            min: 2,
            max: 20,
            divisions: 18,
            label: '${l.n} people',
            onChanged: (v) => l.change(() => l.n = v.round()),
          ),
          ControlRow(children: [ActionButton('Hand back 1,000 times', () => l.runMany(1000))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'E[X] = 3 and E[Y] = 5. What is E[X + Y]?',
      options: ['8', '15', 'Only 8 if independent', 'Can\'t tell'],
      answer: 0,
      explanation: 'Expectations always add, independent or not.',
    ),
    QuizQuestion(
      prompt: 'You roll 10 dice. What is the expected total?',
      options: ['10', '35', '60', '3.5'],
      answer: 1,
      explanation: 'Each die averages 3.5, so 10 × 3.5 = 35.',
    ),
    QuizQuestion(
      prompt: '100 letters are put into 100 addressed envelopes at random. Expected '
          'number in the right envelope?',
      options: ['0', '1', '10', '50'],
      answer: 1,
      explanation: 'Each letter is right with chance 1/100: 100 × 1/100 = 1.',
    ),
  ],
);
