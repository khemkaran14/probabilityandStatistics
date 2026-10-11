import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Rounds of dropping pigeons into holes at random.
class PigeonholeSim extends TickSim {
  PigeonholeSim({super.rng});

  int holes = 5;
  int pigeons = 6;

  /// Hole of each pigeon dropped this round.
  List<int> dropped = [];

  /// Ticks spent showing a finished round.
  int hold = 0;

  int rounds = 0;
  int roundsShared = 0;

  bool get roundDone => dropped.length >= pigeons;
  bool get guaranteed => pigeons > holes;

  List<int> get counts {
    final c = List.filled(holes, 0);
    for (final hle in dropped) {
      c[hle]++;
    }
    return c;
  }

  bool get shared => counts.any((c) => c >= 2);

  /// Chance at least two share a hole when pigeons land at random.
  double get theory {
    if (guaranteed) return 1;
    var none = 1.0;
    for (var k = 0; k < pigeons; k++) {
      none *= (holes - k) / holes;
    }
    return 1 - none;
  }

  @override
  double get interval => rounds < 2 ? 0.35 : 0.12;

  @override
  void tick() {
    if (!roundDone) {
      dropped.add(rng.nextInt(holes));
      if (roundDone) {
        rounds++;
        if (shared) roundsShared++;
      }
    } else if (++hold > 5) {
      hold = 0;
      dropped = [];
    }
  }

  @override
  void restart() {
    dropped = [];
    hold = 0;
    rounds = 0;
    roundsShared = 0;
  }
}

void _paintPigeonhole(Canvas canvas, Size size, PigeonholeSim sim) {
  final w = size.width;
  final h = size.height;
  final holeW = (w - 20) / sim.holes;
  final holeTop = h * 0.3;
  final holeBottom = h - 70;
  final counts = sim.counts;

  // Pigeons still waiting.
  final waiting = sim.pigeons - sim.dropped.length;
  for (var i = 0; i < waiting; i++) {
    label(canvas, '🐦', Offset(20 + i * math.min(24.0, (w - 40) / sim.pigeons), 22), size: 18);
  }
  label(canvas, '${sim.pigeons} pigeons → ${sim.holes} holes', Offset(w / 2, holeTop - 22), size: 13);

  final stackStep = math.min(26.0, (holeBottom - holeTop - 12) / math.max(1, counts.reduce(math.max)));
  for (var hle = 0; hle < sim.holes; hle++) {
    final rect = Rect.fromLTWH(10 + hle * holeW + 3, holeTop, holeW - 6, holeBottom - holeTop);
    final crowded = counts[hle] >= 2;
    roundRect(canvas, rect, crowded ? AppColors.pink.withValues(alpha: 0.2) : AppColors.chip, radius: 10);
    if (crowded) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()
          ..color = AppColors.pink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    for (var k = 0; k < counts[hle]; k++) {
      label(canvas, '🐦', Offset(rect.center.dx, rect.bottom - 16 - k * stackStep), size: math.min(20, holeW * 0.5));
    }
  }

  final msg = !sim.roundDone
      ? (sim.guaranteed ? 'More pigeons than holes: a share is certain' : 'Will two end up together?')
      : (sim.shared ? 'Some hole holds 2 or more pigeons' : 'Every pigeon got its own hole');
  label(canvas, msg, Offset(w / 2, h - 46), size: 14, color: sim.shared ? AppColors.pink : AppColors.ink);
  label(canvas, 'Rounds with a shared hole: ${sim.roundsShared} of ${sim.rounds}', Offset(w / 2, h - 20),
      size: 12, color: AppColors.muted);
}

final LessonSpec pigeonholeLesson = LessonSpec(
  id: 'pigeonhole',
  chapterLabel: 'Ch 4 · Counting',
  title: const [
    TitlePart('More pigeons than holes means a '),
    TitlePart('guaranteed', AppColors.pink),
    TitlePart(' crowd'),
  ],
  subtitle: 'The pigeonhole principle · 2-minute animated lesson',
  createSim: () => PigeonholeSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<PigeonholeSim>(sim, _paintPigeonhole),
  stats: (sim) {
    final p = sim as PigeonholeSim;
    return [
      StatChip('rounds', '${p.rounds}', AppColors.yellow),
      StatChip('shared', p.rounds == 0 ? '…' : '${(p.roundsShared / p.rounds * 100).round()}%', AppColors.pink),
      StatChip('theory', '${(p.theory * 100).round()}%', AppColors.violet),
    ];
  },
  bigIdea: 'Put 6 pigeons into 5 holes and at least one hole must hold two. There\'s '
      'no luck involved: even the most careful spreading runs out of empty holes. '
      'This simple idea proves surprising facts, like two people in any city of '
      'a million having exactly the same number of hairs on their head.',
  formula: (sim) {
    final p = sim as PigeonholeSim;
    return p.guaranteed
        ? '${p.pigeons} > ${p.holes} → some hole has ≥ ⌈${p.pigeons}/${p.holes}⌉ = ${(p.pigeons / p.holes).ceil()}'
        : '${p.pigeons} ≤ ${p.holes}: no guarantee, but random chance of a share = ${(p.theory * 100).toStringAsFixed(0)}%';
  },
  tryItTitle: 'Try it: pigeons vs holes',
  buildTryIt: (sim) {
    final p = sim as PigeonholeSim;
    return watch(
      p,
      () => Column(
        children: [
          LabeledSlider(
            left: 'holes ${p.holes}',
            right: '10',
            value: p.holes.toDouble(),
            min: 2,
            max: 10,
            divisions: 8,
            onChanged: (v) => p.change(() => p.holes = v.round()),
          ),
          LabeledSlider(
            left: 'pigeons ${p.pigeons}',
            right: '12',
            value: p.pigeons.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            onChanged: (v) => p.change(() => p.pigeons = v.round()),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'How many people must be in a room to guarantee two share a birth month?',
      options: ['12', '13', '24', '366'],
      answer: 1,
      explanation: '12 months are the holes. With 13 people, one month must hold two.',
    ),
    QuizQuestion(
      prompt: 'A drawer has red and blue socks. How many must you pull out, in the dark, '
          'to be sure of a matching pair?',
      options: ['2', '3', '4', 'All of them'],
      answer: 1,
      explanation: 'Two colours are two holes. The third sock must match one of the first two.',
    ),
    QuizQuestion(
      prompt: '10 pigeons, 3 holes. At least one hole must hold at least…',
      options: ['2', '3', '4', '10'],
      answer: 2,
      explanation: '10 / 3 = 3.33, rounded up: 4. Three holes of 3 only hold 9.',
    ),
  ],
);
