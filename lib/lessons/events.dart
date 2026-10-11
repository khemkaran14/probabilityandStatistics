import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

enum DieEvent { even, overFour, prime, six }

const Map<DieEvent, String> kDieEventNames = {
  DieEvent.even: 'Even',
  DieEvent.overFour: 'More than 4',
  DieEvent.prime: 'Prime',
  DieEvent.six: 'A six',
};

const Map<DieEvent, Set<int>> kDieEventFaces = {
  DieEvent.even: {2, 4, 6},
  DieEvent.overFour: {5, 6},
  DieEvent.prime: {2, 3, 5},
  DieEvent.six: {6},
};

class EventsSim extends TickSim {
  EventsSim({super.rng});

  DieEvent event = DieEvent.even;
  int rolls = 0;
  int hits = 0;
  int last = 1;
  List<int> faceCounts = List.filled(7, 0);

  Set<int> get faces => kDieEventFaces[event]!;
  double get theory => faces.length / 6;
  double get freq => rolls == 0 ? 0 : hits / rolls;

  @override
  double get interval => rolls < 12 ? 0.6 : (rolls < 60 ? 0.15 : 0.04);

  @override
  void tick() {
    last = 1 + rng.nextInt(6);
    rolls++;
    faceCounts[last]++;
    if (faces.contains(last)) hits++;
  }

  @override
  void restart() {
    rolls = 0;
    hits = 0;
    faceCounts = List.filled(7, 0);
  }
}

void _paintEvents(Canvas canvas, Size size, EventsSim sim) {
  final w = size.width;
  final h = size.height;

  // Sample space: the six faces, event faces ringed.
  label(canvas, 'Sample space S: every possible outcome', Offset(w / 2, 14), size: 12, color: AppColors.muted);
  final die = (w - 40) / 6 * 0.72;
  for (var f = 1; f <= 6; f++) {
    final c = Offset(20 + (w - 40) / 6 * (f - 0.5), 34 + die / 2);
    final inEvent = sim.faces.contains(f);
    final isLast = sim.rolls > 0 && f == sim.last;
    if (inEvent) {
      roundRect(
          canvas, Rect.fromCenter(center: c, width: die + 10, height: die + 10), AppColors.pink.withValues(alpha: 0.18),
          radius: 12);
    }
    paintDie(canvas, c, die * (isLast ? 1.0 + (1 - sim.phase) * 0.15 : 1.0), f,
        isLast ? AppColors.yellow : (inEvent ? AppColors.pink : AppColors.chip));
    // Count of each face below.
    label(canvas, '${sim.faceCounts[f]}', c.translate(0, die / 2 + 14), size: 11, color: AppColors.muted);
  }
  label(canvas, 'Event E = ${kDieEventNames[sim.event]}: {${(sim.faces.toList()..sort()).join(', ')}}',
      Offset(w / 2, 34 + die + 44),
      size: 14, color: AppColors.pink);

  // Running frequency vs theory.
  final barTop = 34 + die + 76;
  final barW = w - 40;
  label(canvas, 'Share of rolls that landed in E', Offset(20, barTop), size: 12, align: TextAlign.left);
  final y = barTop + 18;
  roundRect(canvas, Rect.fromLTWH(20, y, barW, 28), Colors.white, radius: 10);
  roundRect(canvas, Rect.fromLTWH(20, y, barW * sim.freq, 28), AppColors.pink, radius: 10);
  final tx = 20 + barW * sim.theory;
  line(canvas, Offset(tx, y - 6), Offset(tx, y + 34), AppColors.ink, width: 3);
  label(canvas, 'theory ${sim.faces.length}/6', Offset(tx, y + 46), size: 11);
  label(canvas, '${(sim.freq * 100).toStringAsFixed(1)}%', Offset(26, y + 14),
      size: 12, color: Colors.white, align: TextAlign.left);
  label(canvas, '${sim.hits} of ${sim.rolls} rolls', Offset(w - 20, h - 12),
      size: 11, color: AppColors.muted, align: TextAlign.right);
}

final LessonSpec eventsLesson = LessonSpec(
  id: 'events',
  chapterLabel: 'Ch 3 · Probability basics',
  title: const [
    TitlePart('Outcomes', AppColors.yellow),
    TitlePart(', '),
    TitlePart('events', AppColors.pink),
    TitlePart(' and the chance of them'),
  ],
  subtitle: 'Experiments, outcomes & events · 2-minute animated lesson',
  createSim: () => EventsSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<EventsSim>(sim, _paintEvents),
  stats: (sim) {
    final e = sim as EventsSim;
    return [
      StatChip('rolls', '${e.rolls}', AppColors.yellow),
      StatChip('in E', '${e.hits}', AppColors.pink),
      StatChip('share', e.freq.toStringAsFixed(3), AppColors.violet),
    ];
  },
  bigIdea: 'An experiment (rolling a die) has outcomes (1 to 6); all of them '
      'together are the sample space. An event is any group of outcomes you care '
      'about, like "even". When every outcome is equally likely, the chance of '
      'an event is simply how many outcomes it contains divided by how many there '
      'are in total.',
  formula: (sim) {
    final e = sim as EventsSim;
    return 'P(E) = |E| / |S| = ${e.faces.length} / 6 = ${e.theory.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: choose a different event',
  buildTryIt: (sim) {
    final e = sim as EventsSim;
    return watch(
      e,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<DieEvent>(
            options: kDieEventNames,
            selected: e.event,
            onSelected: (v) => e.change(() => e.event = v),
          ),
          const SizedBox(height: 8),
          ControlRow(children: [ActionButton('Roll 600', () => e.runMany(600))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'You flip two coins. How many outcomes are in the sample space?',
      options: ['2', '3', '4', '6'],
      answer: 2,
      explanation: 'HH, HT, TH, TT. HT and TH are different outcomes.',
    ),
    QuizQuestion(
      prompt: 'Roll a die. What is P(a number less than 3)?',
      options: ['1/6', '1/3', '1/2', '2/3'],
      answer: 1,
      explanation: 'The event is {1, 2}: 2 outcomes out of 6, so 2/6 = 1/3.',
    ),
    QuizQuestion(
      prompt: 'Which is an event, not a single outcome, when rolling a die?',
      options: ['Rolling a 4', 'Rolling an odd number', 'Rolling a 6', 'Rolling a 1'],
      answer: 1,
      explanation: '"Odd" groups three outcomes: {1, 3, 5}.',
    ),
  ],
);
