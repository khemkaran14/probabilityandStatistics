import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Game logic (shared by the simulation and the play-it-yourself game)
// ---------------------------------------------------------------------------

/// One round of Monty Hall with three doors.
class MontyRound {
  MontyRound(math.Random rng, {int? pick})
      : car = rng.nextInt(3),
        pick = pick ?? rng.nextInt(3) {
    // The host opens a goat door that the player didn't pick.
    final choices = [
      for (var d = 0; d < 3; d++)
        if (d != this.pick && d != car) d
    ];
    opened = choices[rng.nextInt(choices.length)];
  }

  final int car;
  final int pick;
  late final int opened;

  /// The one door left to switch to.
  int get switchTo => 3 - pick - opened;

  bool get stayWins => pick == car;
  bool get switchWins => switchTo == car;
}

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

enum MontyPhase { pick, open, offer, reveal }

class MontyHallSim extends LessonSim {
  MontyHallSim({math.Random? rng}) : _rng = rng ?? math.Random() {
    round = MontyRound(_rng);
  }

  final math.Random _rng;
  late MontyRound round;

  int games = 0;
  int stayWins = 0;
  int switchWins = 0;

  /// Seconds into the current round.
  double t = 0;

  /// Phase start times within a round, at 1×.
  static const double openAt = 0.7;
  static const double offerAt = 1.4;
  static const double revealAt = 2.0;
  static const double roundTime = 2.9;

  /// The first rounds play slowly so each step can be followed, then the
  /// tally speeds up.
  double get _pace => games < 5 ? 1 : (games < 20 ? 3 : 12);

  MontyPhase get phase {
    if (t < openAt) return MontyPhase.pick;
    if (t < offerAt) return MontyPhase.open;
    if (t < revealAt) return MontyPhase.offer;
    return MontyPhase.reveal;
  }

  double get stayRate => games == 0 ? 0 : stayWins / games;
  double get switchRate => games == 0 ? 0 : switchWins / games;

  @override
  void advance(double dt) {
    t += dt * _pace;
    while (t >= roundTime) {
      t -= roundTime;
      _finishRound();
    }
    notifyListeners();
  }

  void _finishRound() {
    games++;
    if (round.stayWins) stayWins++;
    if (round.switchWins) switchWins++;
    round = MontyRound(_rng);
  }

  /// Plays [count] rounds instantly.
  void playMany(int count) {
    for (var i = 0; i < count; i++) {
      _finishRound();
    }
    t = 0;
    notifyListeners();
  }

  @override
  void step() {
    // Jump to the next phase boundary.
    const marks = [openAt, offerAt, revealAt, roundTime];
    final next = marks.firstWhere((m) => m > t + 1e-9);
    if (next >= roundTime) {
      t = 0;
      _finishRound();
    } else {
      t = next;
    }
    notifyListeners();
  }

  @override
  void reset() {
    games = 0;
    stayWins = 0;
    switchWins = 0;
    t = 0;
    round = MontyRound(_rng);
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Painting helpers (also used by the mini-game)
// ---------------------------------------------------------------------------

void paintDoor(
  Canvas canvas,
  Rect rect, {
  required int number,
  required bool open,
  required bool hasCar,
  bool picked = false,
  bool dimmed = false,
}) {
  final radius = Radius.circular(rect.width * 0.12);
  final frame = RRect.fromRectAndCorners(rect, topLeft: radius, topRight: radius);
  final doorColor = AppColors.rainbow[(number * 2) % AppColors.rainbow.length];

  if (open) {
    canvas.drawRRect(frame, Paint()..color = Colors.white);
    _emoji(canvas, hasCar ? '🚗' : '🐐', rect.center, rect.width * 0.5);
  } else {
    canvas.drawRRect(frame, Paint()..color = doorColor.withValues(alpha: dimmed ? 0.35 : 1));
    final inset = rect.deflate(rect.width * 0.14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, Radius.circular(rect.width * 0.06)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      Offset(rect.right - rect.width * 0.24, rect.center.dy),
      rect.width * 0.05,
      Paint()..color = AppColors.ink,
    );
    _label(canvas, '${number + 1}', rect.center.translate(0, -rect.height * 0.18), rect.width * 0.28, AppColors.ink);
  }

  if (picked) {
    canvas.drawRRect(
      frame.inflate(4),
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }
}

void _emoji(Canvas canvas, String e, Offset centre, double size) {
  final tp = TextPainter(
    text: TextSpan(text: e, style: TextStyle(fontSize: size)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
}

void _label(Canvas canvas, String text, Offset centre, double size, Color color,
    {FontWeight weight = FontWeight.w900}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
}

class MontyHallPainter extends CustomPainter {
  MontyHallPainter(this.sim) : super(repaint: sim);

  final MontyHallSim sim;

  static const double aspectRatio = 0.95;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = sim.round;
    final phase = sim.phase;

    // --- Doors ---------------------------------------------------------------
    final doorW = w * 0.24;
    final doorH = h * 0.36;
    final gap = (w - doorW * 3) / 4;
    final doorTop = h * 0.08;
    for (var d = 0; d < 3; d++) {
      final rect = Rect.fromLTWH(gap + d * (doorW + gap), doorTop, doorW, doorH);
      final open = phase == MontyPhase.reveal || (phase != MontyPhase.pick && d == r.opened);
      paintDoor(canvas, rect, number: d, open: open, hasCar: d == r.car, picked: d == r.pick, dimmed: d == r.opened);

      final under = Offset(rect.center.dx, rect.bottom + 16);
      if (d == r.pick) {
        _label(canvas, phase == MontyPhase.pick ? 'YOU' : 'STAY', under, 12, AppColors.blue);
      } else if (phase.index >= MontyPhase.offer.index && d == r.switchTo) {
        _label(canvas, 'SWITCH', under, 12, AppColors.pink);
      } else if (phase != MontyPhase.pick && d == r.opened) {
        _label(canvas, 'host opens', under, 11, AppColors.muted, weight: FontWeight.w700);
      }
    }

    // Caption for what is happening.
    final caption = switch (phase) {
      MontyPhase.pick => 'You pick door ${r.pick + 1}',
      MontyPhase.open => 'Host opens door ${r.opened + 1}: a goat',
      MontyPhase.offer => 'Stay on ${r.pick + 1} or switch to ${r.switchTo + 1}?',
      MontyPhase.reveal => r.switchWins ? 'Switching wins this one' : 'Staying wins this one',
    };
    _label(canvas, caption, Offset(w / 2, doorTop + doorH + 42), 15, AppColors.ink, weight: FontWeight.w800);

    // --- Win-rate bars -------------------------------------------------------
    final barLeft = w * 0.24;
    final barRight = w - 18;
    final barW = barRight - barLeft;
    final rows = [
      ('Stay', sim.stayRate, sim.stayWins, AppColors.blue),
      ('Switch', sim.switchRate, sim.switchWins, AppColors.pink),
    ];
    final firstBarY = h * 0.70;
    const barH = 26.0;
    for (var i = 0; i < rows.length; i++) {
      final (name, rate, wins, color) = rows[i];
      final y = firstBarY + i * (barH + 18);
      _label(canvas, name, Offset(barLeft / 2 + 4, y + barH / 2), 14, AppColors.ink);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barLeft, y, barW, barH), const Radius.circular(10)),
        Paint()..color = Colors.white,
      );
      if (rate > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(barLeft, y, barW * rate, barH), const Radius.circular(10)),
          Paint()..color = color,
        );
      }
      _label(canvas, '${(rate * 100).toStringAsFixed(0)}% · $wins wins', Offset(barLeft + barW * 0.5, y + barH / 2), 12,
          AppColors.ink);
    }
    // 1/3 and 2/3 reference ticks.
    final tick = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    for (final f in [1 / 3, 2 / 3]) {
      final x = barLeft + barW * f;
      canvas.drawLine(Offset(x, firstBarY - 6), Offset(x, firstBarY + 2 * barH + 24), tick);
      _label(canvas, f < 0.5 ? '⅓' : '⅔', Offset(x, firstBarY - 14), 12, AppColors.muted);
    }
  }

  @override
  bool shouldRepaint(covariant MontyHallPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec montyHallLesson = LessonSpec(
  id: 'monty_hall',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('Should you '),
    TitlePart('switch', AppColors.pink),
    TitlePart(' doors? '),
    TitlePart('Always.', AppColors.blue),
  ],
  subtitle: 'The Monty Hall puzzle · 3-minute animated lesson',
  createSim: () => MontyHallSim(),
  visualAspectRatio: MontyHallPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: MontyHallPainter(sim as MontyHallSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final m = sim as MontyHallSim;
    return [
      StatChip('games', '${m.games}', AppColors.yellow),
      StatChip('stay wins', '${(m.stayRate * 100).toStringAsFixed(0)}%', AppColors.blue),
      StatChip('switch wins', '${(m.switchRate * 100).toStringAsFixed(0)}%', AppColors.pink),
    ];
  },
  bigIdea: 'Your first pick is right only 1 time in 3, and the host opening a '
      'goat door cannot change that. So the other closed door holds the car '
      'the remaining 2 times in 3. The host knows where the car is, and that '
      'knowledge leaks into the door he leaves shut.',
  formula: (sim) {
    final m = sim as MontyHallSim;
    return 'P(win | switch) = 2/3 ≈ 0.667 · seen ${m.switchRate.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: play the game yourself',
  buildTryIt: (sim) => MontyGame(sim: sim as MontyHallSim),
  quiz: const [
    QuizQuestion(
      prompt: 'You pick door 1. The host opens door 3 and shows a goat. '
          'What is the chance the car is behind door 2?',
      options: ['1/3', '1/2', '2/3', '1'],
      answer: 2,
      explanation: 'Door 1 keeps its original 1/3. All of the remaining 2/3 '
          'now sits on door 2, the only other closed door.',
    ),
    QuizQuestion(
      prompt: 'Why is it not 50/50 once two doors are left?',
      options: [
        'Because the host knows where the car is and never reveals it',
        'Because door numbers matter',
        'Because cars are heavier than goats',
        'It actually is 50/50',
      ],
      answer: 0,
      explanation: 'The host\'s choice is forced by where the car is. A random '
          'host who might reveal the car would make it 50/50.',
    ),
    QuizQuestion(
      prompt: 'With 100 doors, you pick one, and the host opens 98 goat doors. '
          'Chance of winning if you switch?',
      options: ['1/100', '1/2', '98/100', '99/100'],
      answer: 3,
      explanation: 'Your pick is right 1 time in 100. Every other time, the car '
          'is behind the one door the host left closed.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Play-it-yourself mini-game
// ---------------------------------------------------------------------------

class MontyGame extends StatefulWidget {
  const MontyGame({super.key, required this.sim, this.rng});
  final MontyHallSim sim;
  final math.Random? rng;

  @override
  State<MontyGame> createState() => _MontyGameState();
}

enum _GameStep { pick, decide, done }

class _MontyGameState extends State<MontyGame> {
  late final math.Random _rng = widget.rng ?? math.Random();
  MontyRound? _round;
  _GameStep _step = _GameStep.pick;
  int? _final;

  int _switchPlays = 0, _switchWins = 0, _stayPlays = 0, _stayWins = 0;

  void _pick(int door) {
    if (_step != _GameStep.pick) return;
    setState(() {
      _round = MontyRound(_rng, pick: door);
      _step = _GameStep.decide;
    });
  }

  void _decide({required bool switched}) {
    final r = _round!;
    setState(() {
      _final = switched ? r.switchTo : r.pick;
      final won = _final == r.car;
      if (switched) {
        _switchPlays++;
        if (won) _switchWins++;
      } else {
        _stayPlays++;
        if (won) _stayWins++;
      }
      _step = _GameStep.done;
    });
  }

  void _again() => setState(() {
        _round = null;
        _final = null;
        _step = _GameStep.pick;
      });

  String get _prompt => switch (_step) {
        _GameStep.pick => 'Tap a door to pick it.',
        _GameStep.decide => 'The host opened door ${_round!.opened + 1}: a goat. Stay or switch?',
        _GameStep.done => _final == _round!.car ? 'You won the car! 🎉' : 'A goat. Try again?',
      };

  @override
  Widget build(BuildContext context) {
    final r = _round;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_prompt, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var d = 0; d < 3; d++) ...[
              if (d > 0) const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Door ${d + 1}',
                  child: GestureDetector(
                    key: ValueKey('monty-door-$d'),
                    onTap: () => _pick(d),
                    child: AspectRatio(
                      aspectRatio: 0.7,
                      child: CustomPaint(
                        painter: _DoorPainter(
                          number: d,
                          open: r != null && (_step == _GameStep.done || d == r.opened),
                          hasCar: r != null && d == r.car,
                          picked: r != null && d == (_final ?? r.pick),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (_step == _GameStep.decide)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
                  onPressed: () => _decide(switched: false),
                  child: const Text('Stay', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.pink),
                  onPressed: () => _decide(switched: true),
                  child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          )
        else if (_step == _GameStep.done)
          FilledButton.tonal(
            onPressed: _again,
            child: const Text('Play again', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        const SizedBox(height: 10),
        Text(
          'You: switched $_switchWins/$_switchPlays won · stayed $_stayWins/$_stayPlays won',
          style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => widget.sim.playMany(1000),
            child: const Text('Simulate 1,000 more games above'),
          ),
        ),
      ],
    );
  }
}

class _DoorPainter extends CustomPainter {
  _DoorPainter({required this.number, required this.open, required this.hasCar, required this.picked});

  final int number;
  final bool open;
  final bool hasCar;
  final bool picked;

  @override
  void paint(Canvas canvas, Size size) {
    paintDoor(canvas, (Offset.zero & size).deflate(5), number: number, open: open, hasCar: hasCar, picked: picked);
  }

  @override
  bool shouldRepaint(covariant _DoorPainter old) =>
      old.open != open || old.hasCar != hasCar || old.picked != picked || old.number != number;
}
