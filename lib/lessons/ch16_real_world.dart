import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

// Chapter 16 · Stats in the real world.

// ===========================================================================
// A/B testing
// ===========================================================================

class AbTestSim extends TickSim {
  AbTestSim({super.rng});

  static const double baseRate = 0.10;
  static const int maxVisitors = 4000;
  double lift = 0.02;
  int nA = 0, nB = 0, cA = 0, cB = 0;
  final List<double> pHistory = [];

  double get rateA => nA == 0 ? 0 : cA / nA;
  double get rateB => nB == 0 ? 0 : cB / nB;

  double get pValue {
    if (nA < 20 || nB < 20) return 1;
    final pool = (cA + cB) / (nA + nB);
    final se = math.sqrt(pool * (1 - pool) * (1 / nA + 1 / nB));
    if (se == 0) return 1;
    final z = (rateB - rateA) / se;
    return 2 * (1 - normalCdf(z.abs()));
  }

  @override
  double get interval => 0.08;

  @override
  void tick() {
    if (nA + nB >= maxVisitors) return;
    for (var i = 0; i < 10; i++) {
      nA++;
      if (rng.nextDouble() < baseRate) cA++;
      nB++;
      if (rng.nextDouble() < baseRate + lift) cB++;
    }
    pHistory.add(pValue);
  }

  @override
  void restart() {
    nA = nB = cA = cB = 0;
    pHistory.clear();
  }
}

void _paintAb(Canvas canvas, Size size, AbTestSim sim) {
  final w = size.width;
  final h = size.height;
  // Conversion rates with 95% intervals.
  final rates = Plot(Rect.fromLTRB(70, 16, w - 16, 92), x0: 0.04, x1: 0.18, y1: 2);
  for (final (row, name, n, r, color) in [
    (1.5, 'Button A', sim.nA, sim.rateA, AppColors.blue),
    (0.5, 'Button B', sim.nB, sim.rateB, AppColors.green),
  ]) {
    label(canvas, name, Offset(64, rates.y(row)), size: 12, color: color, align: TextAlign.right);
    if (n > 0) {
      final m = 1.96 * math.sqrt(r * (1 - r) / n);
      line(canvas, rates.at((r - m).clamp(0.04, 0.18), row), rates.at((r + m).clamp(0.04, 0.18), row),
          color.withValues(alpha: 0.5),
          width: 8);
      canvas.drawCircle(rates.at(r.clamp(0.04, 0.18), row), 6, Paint()..color = color);
    }
  }
  rates.axis(canvas, [0.06, 0.1, 0.14, 0.18], format: (v) => '${(v * 100).round()}%');
  // p-value over time.
  final pp = Plot(Rect.fromLTRB(40, 140, w - 16, h - 34), x0: 0, x1: AbTestSim.maxVisitors / 20, y1: 1);
  label(canvas, 'p-value as visitors arrive ↓', Offset(40, 126),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  canvas.drawRect(Rect.fromLTRB(pp.rect.left, pp.y(0.05), pp.rect.right, pp.y(0)),
      Paint()..color = AppColors.pink.withValues(alpha: 0.18));
  label(canvas, 'p < 0.05', Offset(pp.rect.right - 4, pp.y(0.025)),
      size: 10, color: AppColors.pink, align: TextAlign.right);
  if (sim.pHistory.length > 1) {
    final path = Path()..moveTo(pp.x(0), pp.y(sim.pHistory.first));
    for (var i = 1; i < sim.pHistory.length; i++) {
      path.lineTo(pp.x(i.toDouble()), pp.y(sim.pHistory[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.violet
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
  for (final t in [0.5, 1.0]) {
    label(canvas, t.toStringAsFixed(1), Offset(34, pp.y(t)), size: 9, color: AppColors.muted, align: TextAlign.right);
  }
  pp.axis(canvas, [0, 50, 100, 150, 200], format: (v) => '${(v * 20).round()}', title: 'visitors');
}

final LessonSpec abTestingLesson = LessonSpec(
  id: 'ab_testing',
  chapterLabel: 'Ch 16 · Stats in the real world',
  title: const [
    TitlePart('Which '),
    TitlePart('button', AppColors.green),
    TitlePart(' gets more clicks?'),
  ],
  subtitle: 'A/B testing · 3-minute animated lesson',
  createSim: () => AbTestSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<AbTestSim>(sim, _paintAb),
  stats: (sim) {
    final s = sim as AbTestSim;
    return [
      StatChip('visitors', '${s.nA + s.nB}', AppColors.yellow),
      StatChip(
          'A / B', '${(s.rateA * 100).toStringAsFixed(1)}% / ${(s.rateB * 100).toStringAsFixed(1)}%', AppColors.green),
      StatChip('p', s.pValue.toStringAsFixed(3), AppColors.violet),
    ];
  },
  bigIdea: 'Show half your visitors button A and half button B, at random, and compare '
      'how many click. Randomising makes it a real experiment, so a difference '
      'means cause. The hard part is noise: early on the p-value swings wildly and '
      'can dip below 0.05 by luck. Decide the sample size in advance and look once '
      'at the end; "peeking" and stopping at the first good-looking p-value gives '
      'far more false winners.',
  formula: (sim) {
    final s = sim as AbTestSim;
    return 'two-proportion z-test: z = (p̂_B − p̂_A) / √(p̄(1−p̄)(1/n_A + 1/n_B))  →  p = ${s.pValue.toStringAsFixed(4)}';
  },
  tryItTitle: 'Try it: how much better is B really?',
  buildTryIt: (sim) {
    final s = sim as AbTestSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'same',
            right: '+5 pts',
            value: s.lift,
            min: 0,
            max: 0.05,
            divisions: 10,
            label: '+${(s.lift * 100).toStringAsFixed(1)} points',
            onChanged: (v) => s.change(() => s.lift = v),
          ),
          const TryNote('Set B equal to A and rerun a few times: the purple line still sometimes dips into pink.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Why must visitors be assigned to A or B at random?',
      options: [
        'To save money',
        'So the groups differ only by the button, not by who saw it',
        'Because servers are random',
        'It doesn\'t matter',
      ],
      answer: 1,
      explanation: 'Randomisation balances everything else, so differences can be blamed on the button.',
    ),
    QuizQuestion(
      prompt: 'You check the p-value after every 100 visitors and stop as soon as p < 0.05. The risk?',
      options: [
        'Too few false positives',
        'Many more false positives than 5%',
        'No risk',
        'The test becomes biased toward A'
      ],
      answer: 1,
      explanation: 'Many looks give many chances for noise to cross the line.',
    ),
    QuizQuestion(
      prompt: 'B converts at 10.4% vs A\'s 10.0% with p = 0.6. A sensible conclusion?',
      options: ['B is better', 'No clear evidence of a difference yet', 'A is better', 'The test is broken'],
      answer: 1,
      explanation: 'The gap is well within what chance produces.',
    ),
  ],
);

// ===========================================================================
// Monte Carlo
// ===========================================================================

class MonteCarloSim extends TickSim {
  MonteCarloSim({super.rng});

  final List<Offset> darts = [];
  int total = 0, inside = 0;
  final List<double> estimates = [];

  double get estimate => total == 0 ? 0 : 4 * inside / total;

  @override
  double get interval => total < 50 ? 0.04 : 0.01;

  @override
  void tick() {
    final batch = total < 200 ? 1 : 20;
    for (var i = 0; i < batch; i++) {
      final p = Offset(rng.nextDouble(), rng.nextDouble());
      total++;
      if (p.distanceSquared <= 1) inside++;
      if (darts.length < 1500) darts.add(p);
    }
    if (estimates.length < 2000) estimates.add(estimate);
  }

  @override
  void restart() {
    darts.clear();
    total = inside = 0;
    estimates.clear();
  }
}

void _paintMonteCarlo(Canvas canvas, Size size, MonteCarloSim sim) {
  final w = size.width;
  final h = size.height;
  final side = math.min(w * 0.55, h - 60);
  final o = Offset(16, 20);
  roundRect(canvas, o & Size(side, side), Colors.white, radius: 4);
  canvas.drawArc(Rect.fromCircle(center: o.translate(0, side), radius: side), -math.pi / 2, math.pi / 2, true,
      Paint()..color = AppColors.cyan.withValues(alpha: 0.15));
  for (final p in sim.darts) {
    canvas.drawCircle(o + Offset(p.dx * side, (1 - p.dy) * side), 1.8,
        Paint()..color = p.distanceSquared <= 1 ? AppColors.pink : AppColors.blue.withValues(alpha: 0.6));
  }
  label(canvas, 'π ≈ ${sim.estimate.toStringAsFixed(4)}', Offset(o.dx + side + 12, 34),
      size: 18, color: AppColors.pink, align: TextAlign.left);
  label(canvas, '${sim.total} darts', Offset(o.dx + side + 12, 60),
      size: 12, color: AppColors.muted, align: TextAlign.left);
  label(canvas, 'error ${(sim.estimate - math.pi).abs().toStringAsFixed(4)}', Offset(o.dx + side + 12, 82),
      size: 12, color: AppColors.muted, align: TextAlign.left);
  // Estimate over time.
  final plot = Plot(Rect.fromLTRB(16, side + 40, w - 16, h - 24),
      x0: 0, x1: math.max(100, sim.estimates.length).toDouble(), y0: 2.6, y1: 3.7);
  dashedLine(canvas, plot.at(0, math.pi), plot.at(plot.x1, math.pi), AppColors.ink);
  if (sim.estimates.length > 1) {
    final path = Path()..moveTo(plot.x(0), plot.y(sim.estimates.first.clamp(2.6, 3.7)));
    for (var i = 1; i < sim.estimates.length; i++) {
      path.lineTo(plot.x(i.toDouble()), plot.y(sim.estimates[i].clamp(2.6, 3.7)));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.pink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
  label(canvas, 'estimate over time (dashed = π)', Offset(16, side + 30),
      size: 10, color: AppColors.muted, align: TextAlign.left);
}

final LessonSpec monteCarloLesson = LessonSpec(
  id: 'monte_carlo',
  chapterLabel: 'Ch 16 · Stats in the real world',
  title: const [
    TitlePart('Finding '),
    TitlePart('π', AppColors.pink),
    TitlePart(' by throwing darts'),
  ],
  subtitle: 'Monte Carlo simulation · 2-minute animated lesson',
  createSim: () => MonteCarloSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<MonteCarloSim>(sim, _paintMonteCarlo),
  stats: (sim) {
    final s = sim as MonteCarloSim;
    return [
      StatChip('darts', '${s.total}', AppColors.yellow),
      StatChip('inside', '${s.inside}', AppColors.pink),
      StatChip('π ≈', s.estimate.toStringAsFixed(3), AppColors.violet),
    ];
  },
  bigIdea: 'Throw random darts at a square holding a quarter circle. The share that '
      'lands inside matches the share of area: π/4. So 4 × (inside ÷ total) '
      'estimates π. That\'s Monte Carlo: answer a hard question by simulating many '
      'random trials. It powers weather forecasts, finance and game AI. The catch: '
      'error shrinks like 1/√n, so each extra digit costs 100× more darts.',
  formula: (sim) {
    final s = sim as MonteCarloSim;
    return 'π ≈ 4 × ${s.inside}/${s.total} = ${s.estimate.toStringAsFixed(4)}';
  },
  tryItTitle: 'Try it: throw a lot more',
  buildTryIt: (sim) {
    final s = sim as MonteCarloSim;
    return ControlRow(children: [
      ActionButton('Throw 20,000', () => s.runMany(1000)),
      ActionButton('Start over', s.reset),
    ]);
  },
  quiz: const [
    QuizQuestion(
      prompt: '7,850 of 10,000 random darts land inside the quarter circle. Estimate of π?',
      options: ['3.14', '0.785', '7.85', '31.4'],
      answer: 0,
      explanation: '4 × 0.785 = 3.14.',
    ),
    QuizQuestion(
      prompt: 'To make a Monte Carlo estimate 10 times more precise, you need about…',
      options: ['10× more trials', '100× more trials', '2× more trials', 'The same'],
      answer: 1,
      explanation: 'Error ∝ 1/√n, so 10× precision needs 10² = 100× trials.',
    ),
    QuizQuestion(
      prompt: 'Monte Carlo methods work by…',
      options: ['Exact algebra', 'Repeated random simulation', 'Asking experts', 'Sorting data'],
      answer: 1,
      explanation: 'Simulate many random outcomes and average.',
    ),
  ],
);

// ===========================================================================
// Random walks
// ===========================================================================

class RandomWalkSim extends TickSim {
  RandomWalkSim({super.rng}) {
    restart();
  }

  static const int walkers = 30, maxSteps = 200;
  bool twoD = false;
  late List<List<Offset>> paths;

  int get steps => paths.first.length - 1;

  double get rmsDistance => math.sqrt(meanOf(paths.map((p) => p.last.distanceSquared)));

  @override
  double get interval => 0.04;

  @override
  void tick() {
    if (steps >= maxSteps) {
      restart();
      return;
    }
    for (final p in paths) {
      final last = p.last;
      if (twoD) {
        final a = rng.nextDouble() * 2 * math.pi;
        p.add(last + Offset(math.cos(a), math.sin(a)));
      } else {
        p.add(Offset(last.dx + 1, last.dy + (rng.nextBool() ? 1 : -1)));
      }
    }
  }

  @override
  void restart() => paths = List.generate(twoD ? 8 : walkers, (_) => [Offset.zero]);
}

void _paintWalk(Canvas canvas, Size size, RandomWalkSim sim) {
  final w = size.width;
  final h = size.height;
  if (sim.twoD) {
    final c = Offset(w / 2, h / 2 - 10);
    final scale = (math.min(w, h) / 2 - 20) / 30;
    ring(canvas, c, math.sqrt(sim.steps.toDouble()) * scale, AppColors.pink, width: 2);
    for (var i = 0; i < sim.paths.length; i++) {
      final path = Path()..moveTo(c.dx, c.dy);
      for (final p in sim.paths[i]) {
        path.lineTo(c.dx + p.dx * scale, c.dy + p.dy * scale);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.rainbow[i % 7].withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
    canvas.drawCircle(c, 5, Paint()..color = AppColors.ink);
    label(canvas, 'pink circle: radius √steps', Offset(w / 2, h - 12), size: 11, color: AppColors.pink);
    return;
  }
  final plot =
      Plot(Rect.fromLTRB(36, 16, w - 16, h - 34), x0: 0, x1: RandomWalkSim.maxSteps.toDouble(), y0: -40, y1: 40);
  plot.curve(canvas, (x) => math.sqrt(x), AppColors.pink, width: 2);
  plot.curve(canvas, (x) => -math.sqrt(x), AppColors.pink, width: 2);
  for (var i = 0; i < sim.paths.length; i++) {
    final path = Path()..moveTo(plot.x(0), plot.y(0));
    for (final p in sim.paths[i]) {
      path.lineTo(plot.x(p.dx), plot.y(p.dy.clamp(-40, 40)));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.violet.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }
  for (final t in [-40.0, -20.0, 20.0, 40.0]) {
    label(canvas, t.round().toString(), Offset(30, plot.y(t)), size: 9, color: AppColors.muted, align: TextAlign.right);
  }
  plot.axis(canvas, [0, 50, 100, 150, 200], title: 'steps');
  label(canvas, 'pink: ±√steps', Offset(w - 16, 22), size: 11, color: AppColors.pink, align: TextAlign.right);
}

final LessonSpec randomWalksLesson = LessonSpec(
  id: 'random_walks',
  chapterLabel: 'Ch 16 · Stats in the real world',
  title: const [
    TitlePart('Random steps drift '),
    TitlePart('√n', AppColors.pink),
    TitlePart(' away'),
  ],
  subtitle: 'Random walks · 2-minute animated lesson',
  createSim: () => RandomWalkSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<RandomWalkSim>(sim, _paintWalk),
  stats: (sim) {
    final s = sim as RandomWalkSim;
    return [
      StatChip('steps', '${s.steps}', AppColors.yellow),
      StatChip('typical distance', s.rmsDistance.toStringAsFixed(1), AppColors.violet),
      StatChip('√steps', math.sqrt(s.steps.toDouble()).toStringAsFixed(1), AppColors.pink),
    ];
  },
  bigIdea: 'Each walker takes a random step left or right, again and again. On average '
      'they go nowhere: the mean position stays 0. But they spread out, and the '
      'typical distance from the start grows like √n, not n: after 100 steps, '
      'about 10 away. Random walks describe pollen jiggling in water, stock prices, '
      'and a gambler\'s bankroll.',
  formula: (sim) {
    final s = sim as RandomWalkSim;
    return 'E[position] = 0   typical distance = √n = √${s.steps} = ${math.sqrt(s.steps.toDouble()).toStringAsFixed(1)}';
  },
  tryItTitle: 'Try it: walk in a line or on a plane',
  buildTryIt: (sim) {
    final s = sim as RandomWalkSim;
    return watch(
      s,
      () => ChoiceRow<bool>(
        options: const {false: '1D: left / right', true: '2D: any direction'},
        selected: s.twoD,
        onSelected: (v) => s.change(() => s.twoD = v),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'After 400 random ±1 steps, how far from the start is a walker typically?',
      options: ['0', 'About 20', 'About 200', '400'],
      answer: 1,
      explanation: '√400 = 20.',
    ),
    QuizQuestion(
      prompt: 'Where is a random walker\'s expected position after many steps?',
      options: ['Far right', 'At the start', 'Far left', 'Undefined'],
      answer: 1,
      explanation: 'Left and right steps balance on average, even though each walker wanders.',
    ),
    QuizQuestion(
      prompt: 'Which is often modelled as a random walk?',
      options: ['A train timetable', 'Daily changes in a stock price', 'Shoe sizes', 'Exam marks'],
      answer: 1,
      explanation: 'Each day\'s price change is roughly a random step.',
    ),
  ],
);

// ===========================================================================
// Markov chains
// ===========================================================================

class MarkovSim extends TickSim {
  MarkovSim({super.rng});

  static const names = ['Sunny', 'Cloudy', 'Rainy'];
  static const colors = [AppColors.yellow, AppColors.peg, AppColors.blue];
  double stay = 0.6;
  int state = 0;
  int days = 0;
  List<int> visits = [0, 0, 0];

  List<List<double>> get matrix => [
        [stay, (1 - stay) * 0.6, (1 - stay) * 0.4],
        [0.3, 0.4, 0.3],
        [0.2, 0.4, 0.4],
      ];

  /// Long-run shares, by repeatedly applying the matrix.
  List<double> get stationary {
    var v = [1 / 3, 1 / 3, 1 / 3];
    final m = matrix;
    for (var k = 0; k < 200; k++) {
      v = [for (var j = 0; j < 3; j++) v[0] * m[0][j] + v[1] * m[1][j] + v[2] * m[2][j]];
    }
    return v;
  }

  @override
  double get interval => days < 10 ? 0.7 : 0.08;

  @override
  void tick() {
    var r = rng.nextDouble();
    final row = matrix[state];
    var next = 0;
    while (next < 2 && r > row[next]) {
      r -= row[next];
      next++;
    }
    state = next;
    visits[state]++;
    days++;
  }

  @override
  void restart() {
    state = 0;
    days = 0;
    visits = [0, 0, 0];
  }
}

void _paintMarkov(Canvas canvas, Size size, MarkovSim sim) {
  final w = size.width;
  final h = size.height;
  final centres = [Offset(w / 2, 50), Offset(w * 0.2, h * 0.5), Offset(w * 0.8, h * 0.5)];
  final m = sim.matrix;
  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 3; j++) {
      if (i == j) continue;
      final a = centres[i], b = centres[j];
      final dir = (b - a) / (b - a).distance;
      final normal = Offset(-dir.dy, dir.dx) * 7;
      line(canvas, a + dir * 32 + normal, b - dir * 32 + normal, AppColors.ink.withValues(alpha: 0.25 + m[i][j]),
          width: 1 + m[i][j] * 5);
      label(canvas, m[i][j].toStringAsFixed(2), (a + b) / 2 + normal * 2.4, size: 10, color: AppColors.muted);
    }
  }
  for (var i = 0; i < 3; i++) {
    final c = centres[i];
    canvas.drawCircle(c, 28, Paint()..color = MarkovSim.colors[i].withValues(alpha: 0.85));
    if (i == sim.state && sim.days > 0) ring(canvas, c, 34, AppColors.pink, width: 4);
    label(canvas, MarkovSim.names[i], c, size: 11);
    label(canvas, 'stay ${m[i][i].toStringAsFixed(2)}', c.translate(0, 42), size: 10, color: AppColors.muted);
  }
  // Visit shares vs long-run shares.
  final st = sim.stationary;
  final barTop = h * 0.5 + 64;
  final barW = (w - 48) / 3;
  final total = math.max(1, sim.days);
  for (var i = 0; i < 3; i++) {
    final x = 16 + i * (barW + 8);
    final maxH = h - barTop - 30;
    roundRect(canvas, Rect.fromLTWH(x, h - 24 - maxH * sim.visits[i] / total, barW, maxH * sim.visits[i] / total),
        MarkovSim.colors[i],
        radius: 6);
    final y = h - 24 - maxH * st[i];
    line(canvas, Offset(x - 2, y), Offset(x + barW + 2, y), AppColors.pink, width: 3);
    label(
        canvas,
        '${(sim.visits[i] / total * 100).toStringAsFixed(0)}% (long run ${(st[i] * 100).toStringAsFixed(0)}%)',
        Offset(x + barW / 2, h - 12),
        size: 9);
  }
}

final LessonSpec markovChainsLesson = LessonSpec(
  id: 'markov_chains',
  chapterLabel: 'Ch 16 · Stats in the real world',
  title: const [
    TitlePart('Tomorrow depends only on '),
    TitlePart('today', AppColors.yellow),
  ],
  subtitle: 'Markov chains · 3-minute animated lesson',
  createSim: () => MarkovSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<MarkovSim>(sim, _paintMarkov),
  stats: (sim) {
    final s = sim as MarkovSim;
    return [
      StatChip('days', '${s.days}', AppColors.yellow),
      StatChip('today', MarkovSim.names[s.state], AppColors.blue),
    ];
  },
  bigIdea: 'A Markov chain hops between states with fixed chances that depend only on '
      'where it is now, not on how it got there. Tomorrow\'s weather depends on '
      'today\'s. Run it for a long time and the share of days in each state settles '
      'to a long-run (stationary) distribution, whatever day you started on: the '
      'pink lines. Google\'s original PageRank and many text generators are Markov chains.',
  formula: (sim) {
    final s = sim as MarkovSim;
    final st = s.stationary;
    return 'long run π = πP: sunny ${st[0].toStringAsFixed(2)}, cloudy ${st[1].toStringAsFixed(2)}, '
        'rainy ${st[2].toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: make sunny spells last longer',
  buildTryIt: (sim) {
    final s = sim as MarkovSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'P(sunny → sunny)',
            right: '',
            value: s.stay,
            min: 0.1,
            max: 0.9,
            divisions: 8,
            label: s.stay.toStringAsFixed(1),
            onChanged: (v) => s.change(() => s.stay = v),
          ),
          ControlRow(children: [ActionButton('Simulate 2,000 days', () => s.runMany(2000))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'The Markov property says the next state depends on…',
      options: ['The whole history', 'Only the current state', 'Nothing', 'The first state'],
      answer: 1,
      explanation: 'The past matters only through where you are now.',
    ),
    QuizQuestion(
      prompt: 'Each row of a transition matrix must add up to…',
      options: ['0', '1', 'The number of states', 'Anything'],
      answer: 1,
      explanation: 'From any state, you must go somewhere next.',
    ),
    QuizQuestion(
      prompt: 'The stationary distribution describes…',
      options: [
        'The first day',
        'The long-run share of time in each state',
        'The most likely next state',
        'The transition chances',
      ],
      answer: 1,
      explanation: 'After many steps the chain spends these fractions of time in each state.',
    ),
  ],
);

// ===========================================================================
// Probability in AI & ML
// ===========================================================================

class NextWordSim extends TickSim {
  NextWordSim({super.rng});

  static const words = ['mat', 'sofa', 'floor', 'roof', 'moon'];
  static const scores = [3.0, 2.2, 2.0, 1.0, -0.5];
  double temperature = 1;
  List<int> counts = List.filled(5, 0);
  int last = 0;

  List<double> get probs {
    final e = [for (final s in scores) math.exp(s / temperature)];
    final total = e.reduce((a, b) => a + b);
    return [for (final x in e) x / total];
  }

  int get samples => counts.fold(0, (a, b) => a + b);

  @override
  double get interval => samples < 6 ? 0.9 : 0.12;

  @override
  void tick() {
    var r = rng.nextDouble();
    final p = probs;
    var i = 0;
    while (i < 4 && r > p[i]) {
      r -= p[i];
      i++;
    }
    last = i;
    counts[i]++;
  }

  @override
  void restart() => counts = List.filled(5, 0);
}

void _paintNextWord(Canvas canvas, Size size, NextWordSim sim) {
  final w = size.width;
  final h = size.height;
  label(canvas, 'The cat sat on the …', Offset(w / 2, 20), size: 18);
  if (sim.samples > 0) {
    label(canvas, NextWordSim.words[sim.last], Offset(w / 2, 46), size: 18, color: AppColors.pink);
  }
  final p = sim.probs;
  final rowH = (h - 90) / 5;
  final barW = w - 130;
  for (var i = 0; i < 5; i++) {
    final y = 76 + i * rowH;
    label(canvas, NextWordSim.words[i], Offset(70, y + rowH * 0.35), size: 13, align: TextAlign.right);
    roundRect(canvas, Rect.fromLTWH(78, y + 4, barW * p[i], rowH * 0.4), AppColors.violet, radius: 5);
    final seen = sim.samples == 0 ? 0 : sim.counts[i] / sim.samples;
    roundRect(
        canvas, Rect.fromLTWH(78, y + rowH * 0.48, barW * seen, rowH * 0.22), AppColors.pink.withValues(alpha: 0.7),
        radius: 4);
    label(canvas, '${(p[i] * 100).toStringAsFixed(0)}%', Offset(84 + barW * p[i], y + rowH * 0.24),
        size: 11, align: TextAlign.left);
  }
  label(canvas, 'purple: model probability · pink: how often it was picked', Offset(w / 2, h - 10),
      size: 10, color: AppColors.muted);
}

final LessonSpec aiMlLesson = LessonSpec(
  id: 'ai_ml',
  chapterLabel: 'Ch 16 · Stats in the real world',
  title: const [
    TitlePart('How a chatbot '),
    TitlePart('picks', AppColors.violet),
    TitlePart(' its next word'),
  ],
  subtitle: 'Probability in AI & ML · 3-minute animated lesson',
  createSim: () => NextWordSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<NextWordSim>(sim, _paintNextWord),
  stats: (sim) {
    final s = sim as NextWordSim;
    return [
      StatChip('temperature', s.temperature.toStringAsFixed(1), AppColors.orange),
      StatChip('samples', '${s.samples}', AppColors.yellow),
    ];
  },
  bigIdea: 'A language model scores every possible next word, then turns the scores into '
      'probabilities with the softmax function, and finally samples one word at '
      'random. Temperature controls how bold it is: low temperature sharpens the '
      'odds so it almost always picks "mat"; high temperature flattens them so '
      'rarer words like "moon" appear. Almost all of modern AI, from spam filters '
      'to image generators, is probability under the hood.',
  formula: (sim) {
    final s = sim as NextWordSim;
    return 'P(word) = e^(score/T) / Σ e^(score/T),   T = ${s.temperature.toStringAsFixed(1)}';
  },
  tryItTitle: 'Try it: turn the temperature up and down',
  buildTryIt: (sim) {
    final s = sim as NextWordSim;
    return watch(
      s,
      () => LabeledSlider(
        left: 'safe',
        right: 'wild',
        value: s.temperature,
        min: 0.2,
        max: 3,
        divisions: 14,
        label: 'T = ${s.temperature.toStringAsFixed(1)}',
        onChanged: (v) => s.change(() => s.temperature = v),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'What does the softmax function do?',
      options: [
        'Sorts words alphabetically',
        'Turns scores into probabilities that add up to 1',
        'Removes rare words',
        'Counts letters',
      ],
      answer: 1,
      explanation: 'Exponentiate each score and divide by the total.',
    ),
    QuizQuestion(
      prompt: 'Lowering the temperature makes a model\'s output…',
      options: ['More random', 'More predictable', 'Longer', 'Shorter'],
      answer: 1,
      explanation: 'The top choice gets an even bigger share of probability.',
    ),
    QuizQuestion(
      prompt: 'Why can the same prompt give different answers each time?',
      options: ['A bug', 'The next word is sampled at random from probabilities', 'The internet changes', 'It can\'t'],
      answer: 1,
      explanation: 'Sampling means less likely words are sometimes chosen.',
    ),
  ],
);
