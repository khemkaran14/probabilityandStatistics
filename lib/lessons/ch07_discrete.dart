import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

// Chapter 7 · Discrete distributions (the Galton board lives in galton_board.dart).

// ===========================================================================
// Bernoulli trials
// ===========================================================================

class BernoulliSim extends TickSim {
  BernoulliSim({super.rng});

  double p = 0.3;
  final List<bool> recent = [];
  int successes = 0, trials = 0;

  double get rate => trials == 0 ? 0 : successes / trials;

  @override
  double get interval => trials < 10 ? 0.5 : 0.06;

  @override
  void tick() {
    final s = rng.nextDouble() < p;
    trials++;
    if (s) successes++;
    recent.add(s);
    if (recent.length > 120) recent.removeAt(0);
  }

  @override
  void restart() {
    recent.clear();
    successes = trials = 0;
  }
}

void _paintBernoulli(Canvas canvas, Size size, BernoulliSim sim) {
  final w = size.width;
  final h = size.height;
  label(canvas, 'Each square is one trial: success (1) or failure (0)', Offset(w / 2, 12),
      size: 11, color: AppColors.muted);
  const cols = 15;
  final cell = (w - 30) / cols;
  for (var i = 0; i < sim.recent.length; i++) {
    final r = Rect.fromLTWH(15 + (i % cols) * cell + 1, 26 + (i ~/ cols) * cell + 1, cell - 2, cell - 2);
    final isNew = i == sim.recent.length - 1;
    roundRect(canvas, r, sim.recent[i] ? AppColors.green : AppColors.peg.withValues(alpha: 0.45), radius: 4);
    if (isNew) ring(canvas, r.center, cell * 0.55, AppColors.ink, width: 2);
  }
  final plot = Plot(Rect.fromLTWH(w * 0.25, 26 + 8 * cell + 30, w * 0.5, h - (26 + 8 * cell + 30) - 28),
      x0: -0.6, x1: 1.6, y1: 1);
  final obs = [1 - sim.rate, sim.rate];
  plot.intBars(canvas, sim.trials == 0 ? [0, 0] : obs, 0, (k) => k == 1 ? AppColors.green : AppColors.peg);
  plot.intDots(canvas, [1 - sim.p, sim.p], 0, AppColors.pink);
  plot.axis(canvas, [0, 1], format: (v) => v == 0 ? '0 fail' : '1 success');
  label(canvas, '● theory', Offset(w * 0.78, plot.rect.top + 8),
      size: 11, color: AppColors.pink, align: TextAlign.left);
}

final LessonSpec bernoulliLesson = LessonSpec(
  id: 'bernoulli',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('Yes', AppColors.green),
    TitlePart(' or '),
    TitlePart('no', AppColors.muted),
    TitlePart(': the atom of probability'),
  ],
  subtitle: 'Bernoulli trials · 2-minute animated lesson',
  createSim: () => BernoulliSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<BernoulliSim>(sim, _paintBernoulli),
  stats: (sim) {
    final b = sim as BernoulliSim;
    return [
      StatChip('trials', '${b.trials}', AppColors.yellow),
      StatChip('successes', '${b.successes}', AppColors.green),
      StatChip('rate', b.rate.toStringAsFixed(3), AppColors.pink),
    ];
  },
  bigIdea: 'A Bernoulli trial has exactly two results: success (1) with chance p, or '
      'failure (0). A free throw, a coin flip, whether a customer buys. It is the '
      'building block of most distributions in this chapter: count successes in n '
      'trials and you get the binomial; count trials until the first success and '
      'you get the geometric.',
  formula: (sim) {
    final b = sim as BernoulliSim;
    return 'P(X = 1) = p = ${b.p.toStringAsFixed(2)} · E[X] = p · Var(X) = p(1 − p) = '
        '${(b.p * (1 - b.p)).toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: change the success chance',
  buildTryIt: (sim) {
    final b = sim as BernoulliSim;
    return watch(
      b,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'p 0.05',
            right: '0.95',
            value: b.p,
            min: 0.05,
            max: 0.95,
            divisions: 18,
            label: 'p = ${b.p.toStringAsFixed(2)}',
            onChanged: (v) => b.change(() => b.p = v),
          ),
          const TryNote('Variance p(1 − p) is largest at p = 0.5, when the result is hardest to predict.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Which is a Bernoulli trial?',
      options: [
        'Rolling a die and noting the number',
        'Whether a penalty kick scores',
        'Measuring height',
        'Counting cars'
      ],
      answer: 1,
      explanation: 'Exactly two outcomes: goal or no goal.',
    ),
    QuizQuestion(
      prompt: 'A Bernoulli variable has p = 0.2. What is its expected value?',
      options: ['0', '0.2', '0.5', '0.8'],
      answer: 1,
      explanation: 'E[X] = 1 × 0.2 + 0 × 0.8 = 0.2.',
    ),
    QuizQuestion(
      prompt: 'For which p is a Bernoulli trial most unpredictable (largest variance)?',
      options: ['0.1', '0.5', '0.9', '1'],
      answer: 1,
      explanation: 'p(1 − p) peaks at 0.25 when p = 0.5.',
    ),
  ],
);

// ===========================================================================
// Waiting for successes: geometric (r = 1) and negative binomial
// ===========================================================================

class WaitSim extends TickSim {
  WaitSim({this.r = 1, super.rng});

  int r;
  double p = 0.3;
  List<bool> run = [];
  int _hold = 0;
  List<int> counts = List.filled(80, 0);
  int runs = 0;

  int get successesInRun => run.where((s) => s).length;
  bool get runDone => successesInRun >= r;

  double pmf(int k) => k < r ? 0 : binomPmf(k - 1, r - 1, p) * p;

  double get mean => r / p;

  double get observedMean {
    var s = 0;
    for (var k = 0; k < counts.length; k++) {
      s += k * counts[k];
    }
    return runs == 0 ? 0 : s / runs;
  }

  @override
  double get interval => runs < 3 ? 0.3 : 0.03;

  @override
  void tick() {
    if (!runDone) {
      run.add(rng.nextDouble() < p);
      if (runDone) {
        runs++;
        counts[math.min(run.length, counts.length - 1)]++;
      }
    } else if (++_hold > (runs < 3 ? 6 : 0)) {
      _hold = 0;
      run = [];
    }
  }

  @override
  void restart() {
    run = [];
    counts = List.filled(80, 0);
    runs = 0;
    _hold = 0;
  }
}

void _paintWait(Canvas canvas, Size size, WaitSim sim) {
  final w = size.width;
  final h = size.height;
  final need = sim.r == 1 ? 'the first success' : '${sim.r} successes';
  label(canvas, 'Trials until $need', Offset(15, 12), size: 12, align: TextAlign.left);
  const perRow = 20;
  final d = (w - 30) / perRow;
  for (var i = 0; i < math.min(sim.run.length, 60); i++) {
    final c = Offset(15 + d * (i % perRow + 0.5), 32 + (i ~/ perRow) * d);
    canvas.drawCircle(
        c, d * 0.36, Paint()..color = sim.run[i] ? AppColors.green : AppColors.peg.withValues(alpha: 0.5));
  }
  if (sim.runDone) {
    label(canvas, 'took ${sim.run.length} trials', Offset(w - 15, 12),
        size: 12, color: AppColors.green, align: TextAlign.right);
  }
  final maxK = sim.r + (sim.r * 3 / sim.p).round().clamp(10, 45);
  final top = 32 + 3 * d + 10;
  final total = math.max(1, sim.runs);
  final obs = [for (var k = sim.r; k <= maxK; k++) sim.counts[k] / total];
  final theory = [for (var k = sim.r; k <= maxK; k++) sim.pmf(k)];
  final yMax = math.max(theory.reduce(math.max), obs.reduce(math.max)) * 1.15;
  final plot = Plot(Rect.fromLTRB(15, top + 10, w - 15, h - 28), x0: sim.r - 0.6, x1: maxK + 0.6, y1: yMax);
  if (sim.runs > 0) plot.intBars(canvas, obs, sim.r, (_) => AppColors.cyan.withValues(alpha: 0.8), widthFrac: 0.8);
  plot.intDots(canvas, theory, sim.r, AppColors.pink);
  final step = ((maxK - sim.r) / 6).ceil().toDouble();
  plot.axis(canvas, [for (var k = sim.r.toDouble(); k <= maxK; k += step) k], title: 'trials needed');
  label(canvas, 'bars: seen · dots: theory', Offset(w - 15, top),
      size: 10, color: AppColors.muted, align: TextAlign.right);
}

Widget _waitControls(WaitSim s, {required bool showR}) => watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'p 0.1',
            right: '0.7',
            value: s.p,
            min: 0.1,
            max: 0.7,
            divisions: 12,
            label: 'p = ${s.p.toStringAsFixed(2)}',
            onChanged: (v) => s.change(() => s.p = v),
          ),
          if (showR)
            LabeledSlider(
              left: 'r = ${s.r}',
              right: '5',
              value: s.r.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) => s.change(() => s.r = v.round()),
            ),
          ControlRow(children: [
            ValueTag('average ${s.observedMean.toStringAsFixed(2)} vs r/p = ${s.mean.toStringAsFixed(2)}'),
            ActionButton('500 more runs', () => s.runMany(500 * (s.mean.ceil() + 2))),
          ]),
        ],
      ),
    );

final LessonSpec geometricLesson = LessonSpec(
  id: 'geometric',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('How long until the '),
    TitlePart('first success', AppColors.green),
    TitlePart('?'),
  ],
  subtitle: 'The geometric distribution · 2-minute animated lesson',
  createSim: () => WaitSim(r: 1),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<WaitSim>(sim, _paintWait),
  stats: (sim) {
    final s = sim as WaitSim;
    return [
      StatChip('runs', '${s.runs}', AppColors.yellow),
      StatChip('average wait', s.observedMean.toStringAsFixed(2), AppColors.cyan),
      StatChip('1/p', s.mean.toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'Keep trying until the first success: shooting until you score, calling '
      'until someone answers. Needing exactly k tries means k − 1 failures then a '
      'success, so each extra try multiplies the chance by (1 − p). The bars always '
      'fall away to the right, and on average you wait 1/p tries. Past failures '
      'don\'t make success "due": the wait starts afresh every time.',
  formula: (sim) {
    final s = sim as WaitSim;
    return 'P(X = k) = (1 − p)^(k−1) · p   E[X] = 1/p = ${s.mean.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: change the success chance',
  buildTryIt: (sim) => _waitControls(sim as WaitSim, showR: false),
  quiz: const [
    QuizQuestion(
      prompt: 'You roll a die until you get a 6. On average, how many rolls?',
      options: ['3', '3.5', '6', '36'],
      answer: 2,
      explanation: 'p = 1/6, so the expected wait is 1/p = 6 rolls.',
    ),
    QuizQuestion(
      prompt: 'Which single number of trials is the most likely for the first success?',
      options: ['1', 'Exactly 1/p', 'It depends on luck', 'The largest one'],
      answer: 0,
      explanation: 'P(X = 1) = p is the tallest bar; each later bar is (1 − p) times the one before.',
    ),
    QuizQuestion(
      prompt: 'p = 0.5. What is P(first success on try 3)?',
      options: ['1/2', '1/4', '1/8', '3/8'],
      answer: 2,
      explanation: 'Fail, fail, succeed: 0.5 × 0.5 × 0.5 = 1/8.',
    ),
  ],
);

final LessonSpec negativeBinomialLesson = LessonSpec(
  id: 'negative_binomial',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('Waiting for the '),
    TitlePart('r-th', AppColors.green),
    TitlePart(' success'),
  ],
  subtitle: 'The negative binomial distribution · 2-minute animated lesson',
  createSim: () => WaitSim(r: 3),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<WaitSim>(sim, _paintWait),
  stats: (sim) {
    final s = sim as WaitSim;
    return [
      StatChip('runs', '${s.runs}', AppColors.yellow),
      StatChip('average', s.observedMean.toStringAsFixed(2), AppColors.cyan),
      StatChip('r/p', s.mean.toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'Now keep going until r successes. A salesperson needs 3 sales; how many '
      'calls will it take? The last trial must be the r-th success, and the '
      'other r − 1 successes can be anywhere among the earlier k − 1 trials. '
      'It\'s really r geometric waits added together, so the average is r/p and '
      'the shape becomes more bell-like as r grows.',
  formula: (sim) {
    final s = sim as WaitSim;
    return 'P(X = k) = C(k−1, r−1) p^r (1−p)^(k−r)   E[X] = r/p = ${s.r}/${s.p.toStringAsFixed(2)} = '
        '${s.mean.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: need more successes',
  buildTryIt: (sim) => _waitControls(sim as WaitSim, showR: true),
  quiz: const [
    QuizQuestion(
      prompt: 'Each call makes a sale with p = 0.2. Expected calls for 3 sales?',
      options: ['3', '6', '15', '0.6'],
      answer: 2,
      explanation: 'r / p = 3 / 0.2 = 15 calls.',
    ),
    QuizQuestion(
      prompt: 'The negative binomial with r = 1 is the…',
      options: ['Binomial', 'Geometric', 'Poisson', 'Uniform'],
      answer: 1,
      explanation: 'Waiting for one success is exactly the geometric distribution.',
    ),
    QuizQuestion(
      prompt: 'Why must the last trial be a success?',
      options: [
        'Because trials are independent',
        'Because we stop the moment the r-th success arrives',
        'Because p > 0.5',
        'It doesn\'t have to be',
      ],
      answer: 1,
      explanation: 'The count ends on the r-th success, so it is always the final trial.',
    ),
  ],
);

// ===========================================================================
// Hypergeometric
// ===========================================================================

class HyperSim extends TickSim {
  HyperSim({super.rng}) {
    tick();
    draws = 0;
    counts = List.filled(n + 1, 0);
  }

  static const int total = 20, n = 5;
  int red = 8;
  List<int> drawn = [];
  int draws = 0;
  List<int> counts = List.filled(n + 1, 0);

  double pmf(int k) => k > red || n - k > total - red
      ? 0
      : combinations(red, k) * combinations(total - red, n - k) / combinations(total, n);

  @override
  double get interval => draws < 6 ? 1.0 : 0.08;

  @override
  void tick() {
    final order = List<int>.generate(total, (i) => i)..shuffle(rng);
    drawn = order.take(n).toList();
    draws++;
    counts[drawn.where((i) => i < red).length]++;
  }

  @override
  void restart() {
    draws = 0;
    counts = List.filled(n + 1, 0);
    drawn = [];
  }
}

void _paintHyper(Canvas canvas, Size size, HyperSim sim) {
  final w = size.width;
  final h = size.height;
  label(canvas, 'Bag of ${HyperSim.total}: ${sim.red} red · draw ${HyperSim.n} without putting back', Offset(w / 2, 12),
      size: 11, color: AppColors.muted);
  const cols = 10;
  final d = (w - 40) / cols;
  for (var i = 0; i < HyperSim.total; i++) {
    final c = Offset(20 + d * (i % cols + 0.5), 34 + (i ~/ cols) * d);
    final picked = sim.drawn.contains(i);
    canvas.drawCircle(c, d * 0.36,
        Paint()..color = (i < sim.red ? AppColors.pink : AppColors.blue).withValues(alpha: picked ? 1 : 0.3));
    if (picked) ring(canvas, c, d * 0.48, AppColors.ink, width: 2.5);
  }
  final redDrawn = sim.drawn.where((i) => i < sim.red).length;
  if (sim.drawn.isNotEmpty) {
    label(canvas, '$redDrawn red in this draw', Offset(w / 2, 34 + 2 * d), size: 13, color: AppColors.pink);
  }
  final top = 34 + 2 * d + 24;
  final obs = [for (var k = 0; k <= HyperSim.n; k++) sim.draws == 0 ? 0.0 : sim.counts[k] / sim.draws];
  final theory = [for (var k = 0; k <= HyperSim.n; k++) sim.pmf(k)];
  final binom = [for (var k = 0; k <= HyperSim.n; k++) binomPmf(HyperSim.n, k, sim.red / HyperSim.total)];
  final plot = Plot(Rect.fromLTRB(20, top, w - 20, h - 28),
      x0: -0.6, x1: HyperSim.n + 0.6, y1: math.max(theory.reduce(math.max), binom.reduce(math.max)) * 1.2);
  plot.intBars(canvas, obs, 0, (_) => AppColors.pink.withValues(alpha: 0.7));
  plot.intDots(canvas, binom, 0, AppColors.peg);
  plot.intDots(canvas, theory, 0, AppColors.ink);
  plot.axis(canvas, [for (var k = 0; k <= HyperSim.n; k++) k.toDouble()], title: 'red balls drawn');
  label(canvas, '● without replacement  ● with', Offset(w - 20, top),
      size: 10, color: AppColors.muted, align: TextAlign.right);
}

final LessonSpec hypergeometricLesson = LessonSpec(
  id: 'hypergeometric',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('Drawing '),
    TitlePart('without', AppColors.pink),
    TitlePart(' putting back'),
  ],
  subtitle: 'The hypergeometric distribution · 2-minute animated lesson',
  createSim: () => HyperSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<HyperSim>(sim, _paintHyper),
  stats: (sim) {
    final s = sim as HyperSim;
    return [
      StatChip('draws', '${s.draws}', AppColors.yellow),
      StatChip('mean red', (HyperSim.n * s.red / HyperSim.total).toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'Pick 5 balls from a bag of 20 and keep them out. Each red you take '
      'leaves fewer reds for the next pick, so the draws aren\'t independent and '
      'it isn\'t binomial. Count ways instead: choose which reds and which blues. '
      'The average is the same as with replacement, but the spread is smaller, '
      'because you can never draw the same ball twice. Card games and quality '
      'checks work like this.',
  formula: (sim) {
    final s = sim as HyperSim;
    return 'P(k red) = C(${s.red}, k) · C(${HyperSim.total - s.red}, 5 − k) / C(20, 5)';
  },
  tryItTitle: 'Try it: change how many are red',
  buildTryIt: (sim) {
    final s = sim as HyperSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'red ${s.red}',
            right: '15',
            value: s.red.toDouble(),
            min: 2,
            max: 15,
            divisions: 13,
            onChanged: (v) => s.change(() => s.red = v.round()),
          ),
          ControlRow(children: [ActionButton('Draw 500 times', () => s.runMany(500))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Which situation is hypergeometric, not binomial?',
      options: [
        'Flipping a coin 10 times',
        'Dealing 5 cards and counting hearts',
        'Rolling a die 6 times',
        'Asking 100 random people a question, with replacement',
      ],
      answer: 1,
      explanation: 'Dealt cards are not put back, so each draw changes the deck.',
    ),
    QuizQuestion(
      prompt: 'A box has 4 faulty and 6 good bulbs. You test 2 without replacement. P(both faulty)?',
      options: ['16/100', '12/90', '4/10', '2/10'],
      answer: 1,
      explanation: '4/10 × 3/9 = 12/90 = 2/15.',
    ),
    QuizQuestion(
      prompt: 'Compared with drawing WITH replacement, the hypergeometric spread is…',
      options: ['Larger', 'Smaller', 'The same', 'Zero'],
      answer: 1,
      explanation: 'Removing balls pushes the bag back towards balance, so extreme counts are rarer.',
    ),
  ],
);

// ===========================================================================
// Poisson
// ===========================================================================

class PoissonSim extends TickSim {
  PoissonSim({super.rng});

  double lambda = 3;

  /// Event times (fractions of a minute) for the last 8 minutes, newest last.
  final List<List<double>> minutes = [];
  List<int> counts = List.filled(20, 0);
  int observed = 0;

  double get mean {
    var s = 0;
    for (var k = 0; k < counts.length; k++) {
      s += k * counts[k];
    }
    return observed == 0 ? 0 : s / observed;
  }

  @override
  double get interval => observed < 6 ? 1.0 : 0.1;

  @override
  void tick() {
    final k = poissonDraw(rng, lambda);
    minutes.add(List.generate(k, (_) => rng.nextDouble()));
    if (minutes.length > 8) minutes.removeAt(0);
    counts[math.min(k, 19)]++;
    observed++;
  }

  @override
  void restart() {
    minutes.clear();
    counts = List.filled(20, 0);
    observed = 0;
  }
}

void _paintPoisson(Canvas canvas, Size size, PoissonSim sim) {
  final w = size.width;
  final h = size.height;
  label(canvas, 'Customers arriving · each box is one minute', Offset(15, 12),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  final boxW = (w - 30) / 8;
  for (var i = 0; i < sim.minutes.length; i++) {
    final r = Rect.fromLTWH(15 + i * boxW + 2, 26, boxW - 4, 56);
    final isNew = i == sim.minutes.length - 1;
    roundRect(canvas, r, isNew ? AppColors.yellow.withValues(alpha: 0.35) : Colors.white, radius: 8);
    final ev = sim.minutes[i];
    for (var j = 0; j < ev.length; j++) {
      canvas.drawCircle(Offset(r.left + 6 + ev[j] * (r.width - 12), r.top + 12 + (j % 4) * 10.0), 4,
          Paint()..color = AppColors.orange);
    }
    label(canvas, '${ev.length}', Offset(r.center.dx, r.bottom + 10),
        size: 12, color: isNew ? AppColors.ink : AppColors.muted);
  }
  final maxK = (sim.lambda * 2.6 + 4).ceil().clamp(6, 19);
  final obs = [for (var k = 0; k <= maxK; k++) sim.observed == 0 ? 0.0 : sim.counts[k] / sim.observed];
  final theory = [for (var k = 0; k <= maxK; k++) poissonPmf(sim.lambda, k)];
  final plot = Plot(Rect.fromLTRB(15, 120, w - 15, h - 28),
      x0: -0.6, x1: maxK + 0.6, y1: math.max(theory.reduce(math.max), obs.reduce(math.max)) * 1.15);
  plot.intBars(canvas, obs, 0, (_) => AppColors.orange.withValues(alpha: 0.75), widthFrac: 0.8);
  plot.intDots(canvas, theory, 0, AppColors.ink);
  plot.axis(canvas, [for (var k = 0; k <= maxK; k += maxK > 12 ? 2 : 1) k.toDouble()], title: 'customers in a minute');
}

final LessonSpec poissonLesson = LessonSpec(
  id: 'poisson',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('Counting '),
    TitlePart('random arrivals', AppColors.orange),
  ],
  subtitle: 'The Poisson distribution · 2-minute animated lesson',
  createSim: () => PoissonSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<PoissonSim>(sim, _paintPoisson),
  stats: (sim) {
    final s = sim as PoissonSim;
    return [
      StatChip('minutes', '${s.observed}', AppColors.yellow),
      StatChip('average', s.mean.toStringAsFixed(2), AppColors.orange),
      StatChip('λ', s.lambda.toStringAsFixed(1), AppColors.pink),
    ];
  },
  bigIdea: 'When events happen independently at a steady average rate (customers, '
      'calls, typos on a page), the number in a fixed window follows a Poisson '
      'distribution. One number describes it: λ, the average count. The variance is '
      'also λ. It\'s the binomial with a huge number of tiny chances: many people '
      'who each might, rarely, walk in.',
  formula: (sim) {
    final s = sim as PoissonSim;
    return 'P(X = k) = λ^k e^(−λ) / k!   P(0) = e^(−${s.lambda.toStringAsFixed(1)}) = '
        '${poissonPmf(s.lambda, 0).toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: change the arrival rate λ',
  buildTryIt: (sim) {
    final s = sim as PoissonSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'λ 0.5',
            right: '8',
            value: s.lambda,
            min: 0.5,
            max: 8,
            divisions: 15,
            label: 'λ = ${s.lambda}',
            onChanged: (v) => s.change(() => s.lambda = v),
          ),
          ControlRow(children: [ActionButton('Watch 1,000 minutes', () => s.runMany(1000))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A shop averages 2 customers a minute. What is P(no customers in a minute)?',
      options: ['0', 'e^(−2) ≈ 0.135', '0.5', '2/60'],
      answer: 1,
      explanation: 'P(0) = λ⁰e^(−λ)/0! = e^(−2).',
    ),
    QuizQuestion(
      prompt: 'A Poisson distribution has mean 5. Its variance is…',
      options: ['√5', '5', '25', '2.5'],
      answer: 1,
      explanation: 'For a Poisson, the variance equals the mean λ.',
    ),
    QuizQuestion(
      prompt: 'Which is best modelled by a Poisson distribution?',
      options: [
        'Heights of students',
        'Number of emails arriving in an hour',
        'Heads in 10 coin flips',
        'Time until a bulb fails',
      ],
      answer: 1,
      explanation: 'Independent arrivals counted in a fixed window. Heads in 10 flips is binomial.',
    ),
  ],
);

// ===========================================================================
// Discrete uniform
// ===========================================================================

class DiscreteUniformSim extends TickSim {
  DiscreteUniformSim({super.rng});

  int faces = 6;
  List<int> counts = List.filled(13, 0);
  int rolls = 0;
  int last = 1;

  @override
  double get interval => rolls < 8 ? 0.6 : 0.04;

  @override
  void tick() {
    last = 1 + rng.nextInt(faces);
    counts[last]++;
    rolls++;
  }

  @override
  void restart() {
    counts = List.filled(13, 0);
    rolls = 0;
  }
}

void _paintDU(Canvas canvas, Size size, DiscreteUniformSim sim) {
  final w = size.width;
  final h = size.height;
  // A spinner with n equal sectors.
  final c = Offset(w / 2, 62);
  const r = 48.0;
  for (var i = 0; i < sim.faces; i++) {
    final a0 = -math.pi / 2 + 2 * math.pi * i / sim.faces;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, 2 * math.pi / sim.faces, true,
        Paint()..color = AppColors.rainbow[i % 7].withValues(alpha: i + 1 == sim.last && sim.rolls > 0 ? 1 : 0.45));
    final mid = a0 + math.pi / sim.faces;
    label(canvas, '${i + 1}', c + Offset(math.cos(mid), math.sin(mid)) * r * 0.7, size: 10, color: AppColors.ink);
  }
  ring(canvas, c, r, Colors.white, width: 2);
  final obs = [for (var k = 1; k <= sim.faces; k++) sim.rolls == 0 ? 0.0 : sim.counts[k] / sim.rolls];
  final plot =
      Plot(Rect.fromLTRB(15, 130, w - 15, h - 28), x0: 0.4, x1: sim.faces + 0.6, y1: math.max(1.6 / sim.faces, 0.2));
  plot.intBars(canvas, obs, 1, (k) => AppColors.rainbow[(k - 1) % 7].withValues(alpha: 0.8), widthFrac: 0.75);
  dashedLine(canvas, plot.at(0.4, 1 / sim.faces), plot.at(sim.faces + 0.6, 1 / sim.faces), AppColors.ink);
  label(canvas, '1/${sim.faces}', plot.at(sim.faces + 0.6, 1 / sim.faces).translate(-2, -10),
      size: 11, align: TextAlign.right);
  plot.axis(canvas, [for (var k = 1; k <= sim.faces; k++) k.toDouble()]);
}

final LessonSpec discreteUniformLesson = LessonSpec(
  id: 'discrete_uniform',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('Every value '),
    TitlePart('equally likely', AppColors.violet),
  ],
  subtitle: 'The discrete uniform distribution · 2-minute animated lesson',
  createSim: () => DiscreteUniformSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<DiscreteUniformSim>(sim, _paintDU),
  stats: (sim) {
    final s = sim as DiscreteUniformSim;
    final mean =
        s.rolls == 0 ? 0 : [for (var k = 1; k <= s.faces; k++) k * s.counts[k]].reduce((a, b) => a + b) / s.rolls;
    return [
      StatChip('spins', '${s.rolls}', AppColors.yellow),
      StatChip('average', mean.toStringAsFixed(2), AppColors.violet),
      StatChip('(n+1)/2', ((s.faces + 1) / 2).toStringAsFixed(1), AppColors.pink),
    ];
  },
  bigIdea: 'A fair die, a lottery ball, a random seat: n outcomes, each with chance '
      '1/n. The bars are flat. The average sits in the middle at (n + 1)/2, and '
      'the variance (n² − 1)/12 grows quickly as more values are added, because '
      'the outer values are just as likely as the middle ones.',
  formula: (sim) {
    final s = sim as DiscreteUniformSim;
    final n = s.faces;
    return 'P(X = k) = 1/$n   E[X] = ${((n + 1) / 2).toStringAsFixed(1)}   Var = (n² − 1)/12 = '
        '${((n * n - 1) / 12).toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: more sectors',
  buildTryIt: (sim) {
    final s = sim as DiscreteUniformSim;
    return watch(
      s,
      () => Column(
        children: [
          LabeledSlider(
            left: 'n = ${s.faces}',
            right: '12',
            value: s.faces.toDouble(),
            min: 2,
            max: 12,
            divisions: 10,
            onChanged: (v) => s.change(() => s.faces = v.round()),
          ),
          ControlRow(children: [ActionButton('Spin 1,000 times', () => s.runMany(1000))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A spinner has 8 equal sectors numbered 1–8. P(landing on 3)?',
      options: ['1/3', '1/8', '3/8', '1/2'],
      answer: 1,
      explanation: 'Eight equally likely outcomes: 1/8 each.',
    ),
    QuizQuestion(
      prompt: 'What is the expected value of a fair 10-sided die (1–10)?',
      options: ['5', '5.5', '10', '1'],
      answer: 1,
      explanation: '(n + 1)/2 = 11/2 = 5.5.',
    ),
    QuizQuestion(
      prompt: 'Is the sum of two dice uniformly distributed?',
      options: ['Yes', 'No: middle totals are more likely', 'Only for fair dice', 'Only for 6-sided dice'],
      answer: 1,
      explanation: 'Each die is uniform, but more combinations make 7 than 2 or 12.',
    ),
  ],
);
