import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

// Chapter 17 · Paradoxes & puzzles (Monty Hall, birthday and base-rate live elsewhere).

// ===========================================================================
// Simpson's paradox
// ===========================================================================

/// The classic kidney-stone study: (successes, patients).
const Map<String, Map<String, (int, int)>> kSimpson = {
  'A': {'small': (81, 87), 'large': (192, 263)},
  'B': {'small': (234, 270), 'large': (55, 80)},
};

class SimpsonSim extends LessonSim {
  double t = 0;
  bool? manualSplit;

  /// 0 = combined view, 1 = split by stone size.
  double get split {
    if (manualSplit != null) return manualSplit! ? 1 : 0;
    final s = t % 8;
    if (s < 3) return 0;
    if (s < 4) return Curves.easeInOut.transform(s - 3);
    if (s < 7) return 1;
    return 1 - Curves.easeInOut.transform(s - 7);
  }

  static double rate(String treatment, [String? group]) {
    final g = kSimpson[treatment]!;
    if (group != null) return g[group]!.$1 / g[group]!.$2;
    final s = g.values.fold(0, (a, b) => a + b.$1), n = g.values.fold(0, (a, b) => a + b.$2);
    return s / n;
  }

  @override
  void advance(double dt) {
    if (manualSplit == null) t += dt;
    notifyListeners();
  }

  @override
  void step() {
    manualSplit = !(split > 0.5);
    notifyListeners();
  }

  @override
  void reset() {
    manualSplit = null;
    t = 0;
    notifyListeners();
  }

  void choose(bool v) {
    manualSplit = v;
    notifyListeners();
  }
}

void _paintSimpson(Canvas canvas, Size size, SimpsonSim sim) {
  final w = size.width;
  final h = size.height;
  final s = sim.split;
  final plot = Plot(Rect.fromLTRB(16, 40, w - 16, h - 60), x0: 0, x1: 1, y0: 0.5, y1: 1);
  void barAt(double x, double width, double rate, Color color, String text) {
    final r = Rect.fromLTRB(plot.x(x - width / 2), plot.y(rate), plot.x(x + width / 2), plot.y(0.5));
    roundRect(canvas, r, color, radius: 6);
    label(canvas, '${(rate * 100).toStringAsFixed(0)}%', Offset(r.center.dx, r.top - 10), size: 12);
    label(canvas, text, Offset(r.center.dx, plot.rect.bottom + 12), size: 10, color: AppColors.muted);
  }

  // Combined bars fade out while grouped bars fade in.
  if (s < 0.99) {
    final a = 1 - s;
    barAt(0.3, 0.2, SimpsonSim.rate('A'), AppColors.blue.withValues(alpha: a), s < 0.5 ? 'A overall' : '');
    barAt(0.7, 0.2, SimpsonSim.rate('B'), AppColors.orange.withValues(alpha: a), s < 0.5 ? 'B overall' : '');
  }
  if (s > 0.01) {
    for (final (gx, group) in [(0.27, 'small'), (0.73, 'large')]) {
      barAt(gx - 0.1, 0.16, SimpsonSim.rate('A', group), AppColors.blue.withValues(alpha: s), s > 0.5 ? 'A' : '');
      barAt(gx + 0.1, 0.16, SimpsonSim.rate('B', group), AppColors.orange.withValues(alpha: s), s > 0.5 ? 'B' : '');
      if (s > 0.5) label(canvas, '$group stones', Offset(plot.x(gx), plot.rect.bottom + 28), size: 12);
    }
  }
  label(canvas, s < 0.5 ? 'All patients: B looks better' : 'Split by stone size: A wins both!', Offset(w / 2, 16),
      size: 15, color: s < 0.5 ? AppColors.orange : AppColors.blue);
}

final LessonSpec simpsonsLesson = LessonSpec(
  id: 'simpsons',
  chapterLabel: 'Ch 17 · Paradoxes & puzzles',
  title: const [
    TitlePart('Better in '),
    TitlePart('every', AppColors.blue),
    TitlePart(' group, worse '),
    TitlePart('overall', AppColors.orange),
  ],
  subtitle: "Simpson's paradox · 2-minute animated lesson",
  createSim: () => SimpsonSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<SimpsonSim>(sim, _paintSimpson),
  stats: (_) => [
    StatChip('A overall', '${(SimpsonSim.rate('A') * 100).toStringAsFixed(0)}%', AppColors.blue),
    StatChip('B overall', '${(SimpsonSim.rate('B') * 100).toStringAsFixed(0)}%', AppColors.orange),
  ],
  bigIdea: 'In a real kidney-stone study, treatment A beat B for small stones (93% vs 87%) '
      'and for large stones (73% vs 69%), yet B looked better overall (83% vs 78%). '
      'How? Doctors gave A mostly to the hard, large-stone cases and B mostly to easy '
      'small ones. Mixing groups of different difficulty in different proportions '
      'can flip a comparison. Always ask what was lumped together.',
  formula: (_) => 'A: 81/87 small, 192/263 large → 273/350 = 78%\nB: 234/270 small, 55/80 large → 289/350 = 83%',
  tryItTitle: 'Try it: combine or split',
  buildTryIt: (sim) {
    final s = sim as SimpsonSim;
    return watch(
      s,
      () => ChoiceRow<bool>(
        options: const {false: 'All patients', true: 'By stone size'},
        selected: s.split > 0.5,
        onSelected: s.choose,
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'What causes Simpson\'s paradox?',
      options: [
        'Rounding errors',
        'A lurking variable that is unevenly spread between groups',
        'Too little data',
        'Using percentages',
      ],
      answer: 1,
      explanation: 'Here stone size affects both the treatment choice and the outcome.',
    ),
    QuizQuestion(
      prompt: 'In the stone study, which treatment should a new patient with a small stone get?',
      options: ['A', 'B', 'Either', 'Neither'],
      answer: 0,
      explanation: 'Compare like with like: for small stones, A succeeds more often.',
    ),
    QuizQuestion(
      prompt: 'A school\'s overall pass rate fell, yet every class\'s pass rate rose. Is that possible?',
      options: ['No', 'Yes, if more students moved into harder classes', 'Only with a mistake', 'Only with one class'],
      answer: 1,
      explanation: 'A shift in the mix of groups can drag the overall rate down.',
    ),
  ],
);

// ===========================================================================
// Gambler's fallacy
// ===========================================================================

class GamblerSim extends TickSim {
  GamblerSim({super.rng});

  int streakLength = 4;
  final List<bool> spins = []; // true = red
  int streak = 0;
  bool? streakColour;
  int afterStreak = 0, continued = 0;

  @override
  double get interval => spins.length < 20 ? 0.4 : 0.01;

  @override
  void tick() {
    final red = rng.nextBool();
    if (streak >= streakLength) {
      afterStreak++;
      if (red == streakColour) continued++;
    }
    if (red == streakColour) {
      streak++;
    } else {
      streak = 1;
      streakColour = red;
    }
    spins.add(red);
    if (spins.length > 5000) spins.removeAt(0);
  }

  @override
  void restart() {
    spins.clear();
    streak = 0;
    streakColour = null;
    afterStreak = continued = 0;
  }
}

void _paintGambler(Canvas canvas, Size size, GamblerSim sim) {
  final w = size.width;
  final h = size.height;
  label(canvas, 'Latest spins', Offset(16, 12), size: 11, color: AppColors.muted, align: TextAlign.left);
  final recent = sim.spins.length > 40 ? sim.spins.sublist(sim.spins.length - 40) : sim.spins;
  final d = (w - 32) / 20;
  for (var i = 0; i < recent.length; i++) {
    final c = Offset(16 + d * (i % 20 + 0.5), 32 + (i ~/ 20) * d);
    final inStreak = i >= recent.length - sim.streak;
    canvas.drawCircle(c, d * 0.4, Paint()..color = recent[i] ? AppColors.pink : AppColors.ink);
    if (inStreak && sim.streak >= sim.streakLength) ring(canvas, c, d * 0.48, AppColors.yellow, width: 2.5);
  }
  final y = 32 + 2 * d + 20;
  label(canvas, 'After ${sim.streakLength}+ in a row of the same colour, the next spin…', Offset(16, y),
      size: 12, align: TextAlign.left);
  final share = sim.afterStreak == 0 ? 0.5 : sim.continued / sim.afterStreak;
  final barW = w - 32;
  roundRect(canvas, Rect.fromLTWH(16, y + 18, barW, 30), AppColors.chip, radius: 8);
  roundRect(canvas, Rect.fromLTWH(16, y + 18, barW * share, 30), AppColors.violet, radius: 8);
  line(canvas, Offset(16 + barW / 2, y + 12), Offset(16 + barW / 2, y + 54), AppColors.ink, width: 2);
  label(canvas, 'kept the streak going: ${(share * 100).toStringAsFixed(1)}%', Offset(24, y + 33),
      size: 12, color: Colors.white, align: TextAlign.left);
  label(canvas, '50%', Offset(16 + barW / 2, y + 64), size: 11);
  label(canvas, '${sim.afterStreak} streaks seen in ${sim.spins.length} spins', Offset(w / 2, h - 12),
      size: 11, color: AppColors.muted);
}

final LessonSpec gamblersFallacyLesson = LessonSpec(
  id: 'gamblers_fallacy',
  chapterLabel: 'Ch 17 · Paradoxes & puzzles',
  title: const [
    TitlePart('Black is '),
    TitlePart('not', AppColors.pink),
    TitlePart(' "due"'),
  ],
  subtitle: "The gambler's fallacy · 2-minute animated lesson",
  createSim: () => GamblerSim(),
  visualAspectRatio: 1.15,
  buildVisual: (sim) => simCanvas<GamblerSim>(sim, _paintGambler),
  stats: (sim) {
    final s = sim as GamblerSim;
    return [
      StatChip('spins', '${s.spins.length}', AppColors.yellow),
      StatChip('streak now', '${s.streak}', AppColors.pink),
    ];
  },
  bigIdea: 'In 1913 at Monte Carlo, black came up 26 times in a row and gamblers lost '
      'fortunes betting red was "due". A wheel has no memory: after any streak the '
      'next spin is still 50-50, and the bar sits on 50% however long the streak. '
      'Long-run averages even out because new spins dilute old ones, not because '
      'the wheel corrects itself.',
  formula: (sim) {
    final s = sim as GamblerSim;
    return 'P(red | ${s.streakLength} reds in a row) = P(red) = 1/2   (ignoring the green zero)';
  },
  tryItTitle: 'Try it: demand a longer streak',
  buildTryIt: (sim) {
    final s = sim as GamblerSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'streak ${s.streakLength}',
            right: '8',
            value: s.streakLength.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            onChanged: (v) => s.change(() => s.streakLength = v.round()),
          ),
          ControlRow(children: [ActionButton('Spin 20,000 times', () => s.runMany(20000))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A fair coin lands heads 6 times in a row. P(heads next)?',
      options: ['Less than 1/2', '1/2', 'More than 1/2', '1/64'],
      answer: 1,
      explanation: 'Each flip is independent of the ones before.',
    ),
    QuizQuestion(
      prompt: 'Why is a run of 6 heads in a row less surprising than it feels?',
      options: [
        'Coins are biased',
        'In many flips, some long runs are almost certain to appear somewhere',
        'It isn\'t possible',
        'Heads is more common',
      ],
      answer: 1,
      explanation: 'Over hundreds of flips, a run of 6 is expected to happen.',
    ),
    QuizQuestion(
      prompt: 'Which belief is the gambler\'s fallacy?',
      options: [
        '"Over many spins, about half will be red"',
        '"After five blacks, red is more likely next"',
        '"Each spin is independent"',
        '"The casino has an edge"',
      ],
      answer: 1,
      explanation: 'It assumes the wheel balances things out in the short run.',
    ),
  ],
);

// ===========================================================================
// St. Petersburg paradox
// ===========================================================================

class StPetersburgSim extends TickSim {
  StPetersburgSim({super.rng});

  int games = 0;
  double total = 0;
  int lastFlips = 1;
  List<int> byFlips = List.filled(41, 0);
  final List<double> averages = [];

  double get average => games == 0 ? 0 : total / games;

  @override
  double get interval => games < 8 ? 0.7 : 0.01;

  @override
  void tick() {
    // Flip until tails; the pot starts at ₹2 and doubles with each head.
    var flips = 1;
    while (rng.nextBool() && flips < 40) {
      flips++;
    }
    lastFlips = flips;
    total += math.pow(2, flips).toDouble();
    games++;
    byFlips[flips]++;
    if (averages.length < 4000) averages.add(average);
  }

  @override
  void restart() {
    games = 0;
    total = 0;
    byFlips = List.filled(41, 0);
    averages.clear();
  }
}

void _paintStPete(Canvas canvas, Size size, StPetersburgSim sim) {
  final w = size.width;
  final h = size.height;
  if (sim.games > 0) {
    label(
        canvas,
        'Last game: ${sim.lastFlips} flip${sim.lastFlips == 1 ? '' : 's'} → won ₹${math.pow(2, sim.lastFlips).round()}',
        Offset(w / 2, 14),
        size: 13);
  }
  // Payout table: chance × prize = ₹1 each row.
  final rows = Plot(Rect.fromLTRB(16, 36, w - 16, h * 0.45), x0: 0.4, x1: 10.6, y1: 0.55);
  rows.intBars(canvas, [for (var k = 1; k <= 10; k++) sim.games == 0 ? 0.0 : sim.byFlips[k] / sim.games], 1,
      (k) => AppColors.yellow.withValues(alpha: 0.8));
  rows.intDots(canvas, [for (var k = 1; k <= 10; k++) math.pow(0.5, k).toDouble()], 1, AppColors.ink);
  rows.axis(canvas, [for (var k = 1; k <= 10; k++) k.toDouble()],
      format: (v) => '₹${math.pow(2, v).round()}', title: 'prize');
  // Running average payout.
  final n = math.max(100, sim.averages.length).toDouble();
  final hi = math.max(20.0, (sim.averages.isEmpty ? 0 : sim.averages.reduce(math.max)) * 1.1);
  final plot = Plot(Rect.fromLTRB(40, h * 0.45 + 48, w - 16, h - 28), x0: 0, x1: n, y1: hi);
  label(canvas, 'average winnings per game ↑', Offset(40, h * 0.45 + 34),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  if (sim.averages.length > 1) {
    final path = Path()..moveTo(plot.x(0), plot.y(sim.averages.first.clamp(0, hi)));
    for (var i = 1; i < sim.averages.length; i++) {
      path.lineTo(plot.x(i.toDouble()), plot.y(sim.averages[i].clamp(0, hi)));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
  label(canvas, '₹${hi.round()}', Offset(34, plot.y(hi)), size: 9, color: AppColors.muted, align: TextAlign.right);
  plot.axis(canvas, [0, n / 2, n], format: (v) => '${v.round()}', title: 'games');
}

final LessonSpec stPetersburgLesson = LessonSpec(
  id: 'st_petersburg',
  chapterLabel: 'Ch 17 · Paradoxes & puzzles',
  title: const [
    TitlePart('A game worth '),
    TitlePart('infinity', AppColors.orange),
    TitlePart('… that nobody would pay ₹100 for'),
  ],
  subtitle: 'The St. Petersburg paradox · 3-minute animated lesson',
  createSim: () => StPetersburgSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<StPetersburgSim>(sim, _paintStPete),
  stats: (sim) {
    final s = sim as StPetersburgSim;
    return [
      StatChip('games', '${s.games}', AppColors.yellow),
      StatChip('average win', '₹${s.average.toStringAsFixed(1)}', AppColors.orange),
    ];
  },
  bigIdea: 'Flip a coin until it lands tails. The prize starts at ₹2 and doubles with every '
      'head. Each row of the table is worth chance × prize = ½ × 2 = ¼ × 4 = … = ₹1, '
      'and there are endless rows, so the expected value is infinite. Yet you\'d '
      'rarely pay even ₹20 to play: the huge prizes are so rare that the average '
      'creeps up only slowly (roughly with log₂ of the number of games). Expected '
      'value alone isn\'t everything; risk and a real banker\'s limited money matter.',
  formula: (_) => 'E[prize] = ½·2 + ¼·4 + ⅛·8 + … = 1 + 1 + 1 + … = ∞',
  tryItTitle: 'Try it: play a lot of games',
  buildTryIt: (sim) {
    final s = sim as StPetersburgSim;
    return ControlRow(children: [
      ActionButton('Play 4,000 games', () => s.runMany(4000)),
      ActionButton('Start over', s.reset),
    ]);
  },
  quiz: const [
    QuizQuestion(
      prompt: 'What is the chance the game ends on the 3rd flip (H, H, T)?',
      options: ['1/3', '1/8', '1/4', '1/2'],
      answer: 1,
      explanation: '½ × ½ × ½ = 1/8, and the prize is ₹8.',
    ),
    QuizQuestion(
      prompt: 'Why is the expected value infinite?',
      options: [
        'The prizes are large',
        'Every outcome contributes ₹1 to the sum, and there are infinitely many outcomes',
        'The coin is biased',
        'It isn\'t',
      ],
      answer: 1,
      explanation: '(½)ᵏ × 2ᵏ = 1 for every k.',
    ),
    QuizQuestion(
      prompt: 'Why won\'t people pay a huge amount to play?',
      options: [
        'They can\'t count',
        'Huge prizes are extremely rare and no bank can pay out infinitely',
        'The game is illegal',
        'The expected value is negative',
      ],
      answer: 1,
      explanation: 'Real-world limits and risk aversion matter more than an infinite average.',
    ),
  ],
);
