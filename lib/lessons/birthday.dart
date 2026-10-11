import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// People walk into a room one by one; does anyone share a birthday?
class BirthdaySim extends TickSim {
  BirthdaySim({super.rng});

  int people = 23;

  /// Birthdays (day 0–364) of people in the current room.
  List<int> room = [];

  /// Day of the first shared birthday in this room, if any.
  int? match;

  int rooms = 0;
  int roomsWithMatch = 0;
  int _hold = 0;

  bool get full => room.length >= people;

  double get theory => birthdayChance(people);

  @override
  double get interval => rooms < 2 ? 0.12 : 0.03;

  @override
  void tick() {
    if (!full) {
      final day = rng.nextInt(365);
      if (match == null && room.contains(day)) match = day;
      room.add(day);
      if (full) {
        rooms++;
        if (match != null) roomsWithMatch++;
      }
    } else if (++_hold > (rooms < 3 ? 25 : 8)) {
      _hold = 0;
      room = [];
      match = null;
    }
  }

  @override
  void restart() {
    room = [];
    match = null;
    rooms = 0;
    roomsWithMatch = 0;
    _hold = 0;
  }
}

/// P(at least two of n people share a birthday), ignoring leap years.
double birthdayChance(int n) {
  var none = 1.0;
  for (var k = 0; k < n; k++) {
    none *= (365 - k) / 365;
  }
  return 1 - none;
}

void _paintBirthday(Canvas canvas, Size size, BirthdaySim sim) {
  final w = size.width;
  final h = size.height;

  // A year as a 21 × 18 grid of days (365 cells, last row partly empty).
  const cols = 21;
  final cell = (w - 20) / cols;
  const top = 20.0;
  label(canvas, 'every day of the year', Offset(w / 2, 8), size: 10, color: AppColors.muted);
  final taken = <int, int>{};
  for (final d in sim.room) {
    taken[d] = (taken[d] ?? 0) + 1;
  }
  for (var d = 0; d < 365; d++) {
    final c = Offset(10 + (d % cols + 0.5) * cell, top + (d ~/ cols + 0.5) * cell);
    final n = taken[d] ?? 0;
    if (n >= 2) {
      canvas.drawCircle(c, cell * 0.62, Paint()..color = AppColors.pink);
      ring(canvas, c, cell * 0.9, AppColors.pink, width: 2);
    } else if (n == 1) {
      canvas.drawCircle(c, cell * 0.38, Paint()..color = AppColors.blue);
    } else {
      canvas.drawCircle(c, cell * 0.14, Paint()..color = AppColors.peg.withValues(alpha: 0.5));
    }
  }

  final y = top + 18 * cell + 18;
  label(canvas, '${sim.room.length} of ${sim.people} people in the room', Offset(w / 2, y), size: 13);
  label(canvas, sim.match != null ? 'Shared birthday found!' : (sim.full ? 'No shared birthday this time' : ''),
      Offset(w / 2, y + 22),
      size: 15, color: sim.match != null ? AppColors.pink : AppColors.muted);
  label(canvas, 'Rooms with a match: ${sim.roomsWithMatch} of ${sim.rooms}', Offset(w / 2, h - 12),
      size: 12, color: AppColors.muted);
}

final LessonSpec birthdayLesson = LessonSpec(
  id: 'birthday',
  chapterLabel: 'Ch 4 · Counting',
  title: const [
    TitlePart('Just '),
    TitlePart('23 people', AppColors.blue),
    TitlePart(' for a 50% chance of a '),
    TitlePart('shared birthday', AppColors.pink),
  ],
  subtitle: 'The birthday paradox · 2-minute animated lesson',
  createSim: () => BirthdaySim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<BirthdaySim>(sim, _paintBirthday),
  stats: (sim) {
    final b = sim as BirthdaySim;
    return [
      StatChip('rooms', '${b.rooms}', AppColors.yellow),
      StatChip('with a match', b.rooms == 0 ? '…' : '${(b.roomsWithMatch / b.rooms * 100).round()}%', AppColors.pink),
      StatChip('theory', '${(b.theory * 100).round()}%', AppColors.violet),
    ];
  },
  bigIdea: 'It feels like you\'d need about 180 people, but you aren\'t looking for '
      'someone who shares your birthday: any pair will do. 23 people make 253 '
      'different pairs, and each pair is another chance for a match. Count the '
      'opposite instead: everyone different means each new person must miss all '
      'the days already taken.',
  formula: (sim) {
    final b = sim as BirthdaySim;
    return 'P(match) = 1 − (365/365 × 364/365 × … × ${365 - b.people + 1}/365) = ${b.theory.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: change the room size',
  buildTryIt: (sim) {
    final b = sim as BirthdaySim;
    return watch(
      b,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '5',
            right: '70',
            value: b.people.toDouble(),
            min: 5,
            max: 70,
            divisions: 65,
            label: '${b.people} people',
            onChanged: (v) => b.change(() => b.people = v.round()),
          ),
          ControlRow(children: [
            ValueTag('${b.people} people → ${(b.theory * 100).toStringAsFixed(1)}%'),
            ActionButton('Fill 100 rooms', () => b.runMany(100 * (b.people + 10))),
          ]),
          const SizedBox(height: 8),
          const TryNote('At 50 people a shared birthday is 97% likely; at 70 it is 99.9%.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Roughly how many people do you need for a 50% chance that two share a birthday?',
      options: ['23', '50', '183', '366'],
      answer: 0,
      explanation: 'With 23 people there are 253 pairs, and the chance passes 50%.',
    ),
    QuizQuestion(
      prompt: 'Why is the answer so much smaller than people expect?',
      options: [
        'Birthdays cluster in summer',
        'Any pair counts, and pairs grow fast as people are added',
        'Leap years',
        'It is a trick question',
      ],
      answer: 1,
      explanation: 'n people make n(n − 1)/2 pairs. 23 people already make 253.',
    ),
    QuizQuestion(
      prompt: 'How many people guarantee a shared birthday (ignoring 29 Feb)?',
      options: ['183', '365', '366', '730'],
      answer: 2,
      explanation: 'The pigeonhole principle: 366 people, 365 days.',
    ),
  ],
);
