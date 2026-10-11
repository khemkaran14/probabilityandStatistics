import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

// Chapter 15 · Bayesian thinking.

/// Quantile of Beta(a, b) by numerical integration on a fine grid.
double betaQuantile(double a, double b, double q) {
  const steps = 2000;
  var total = 0.0;
  final cdf = List<double>.filled(steps + 1, 0);
  for (var i = 1; i <= steps; i++) {
    final x = (i - 0.5) / steps;
    total += betaPdf(x, a, b) / steps;
    cdf[i] = total;
  }
  for (var i = 1; i <= steps; i++) {
    if (cdf[i] / total >= q) return i / steps;
  }
  return 1;
}

// ===========================================================================
// Prior to posterior
// ===========================================================================

enum Prior { flat, sceptical, optimistic }

const Map<Prior, (double, double)> kPriorParams = {
  Prior.flat: (1, 1),
  Prior.sceptical: (20, 20),
  Prior.optimistic: (8, 2),
};

const Map<Prior, String> kPriorNames = {
  Prior.flat: 'No idea (flat)',
  Prior.sceptical: 'Sure it\'s fair',
  Prior.optimistic: 'Expect heads',
};

class PosteriorSim extends TickSim {
  PosteriorSim({super.rng});

  static const double hidden = 0.7;
  Prior prior = Prior.flat;
  int heads = 0, tails = 0;

  double get a0 => kPriorParams[prior]!.$1;
  double get b0 => kPriorParams[prior]!.$2;
  double get a => a0 + heads;
  double get b => b0 + tails;
  double get postMean => a / (a + b);

  @override
  double get interval => heads + tails < 10 ? 0.7 : 0.2;

  @override
  void tick() {
    if (heads + tails >= 100) return;
    if (rng.nextDouble() < hidden) {
      heads++;
    } else {
      tails++;
    }
  }

  @override
  void restart() => heads = tails = 0;
}

void _paintPosterior(Canvas canvas, Size size, PosteriorSim sim) {
  final w = size.width;
  final h = size.height;
  var peak = 0.0;
  for (var i = 1; i < 200; i++) {
    final x = i / 200;
    peak = math.max(peak, math.max(betaPdf(x, sim.a, sim.b), betaPdf(x, sim.a0, sim.b0)));
  }
  final plot = Plot(Rect.fromLTRB(16, 34, w - 16, h - 34), x0: 0, x1: 1, y1: peak * 1.15);
  label(canvas, '${sim.heads} heads, ${sim.tails} tails so far', Offset(w / 2, 12), size: 13);
  plot.curve(canvas, (x) => betaPdf(x, sim.a0, sim.b0), AppColors.peg, width: 2.5);
  plot.curve(canvas, (x) => betaPdf(x, sim.a, sim.b), AppColors.violet, fill: true, width: 3);
  dashedLine(canvas, plot.at(sim.postMean, 0), plot.at(sim.postMean, peak), AppColors.violet);
  label(canvas, 'grey: prior · purple: posterior', Offset(w - 16, 30),
      size: 10, color: AppColors.muted, align: TextAlign.right);
  plot.axis(canvas, [0, 0.25, 0.5, 0.75, 1], title: 'chance of heads p');
}

final LessonSpec priorPosteriorLesson = LessonSpec(
  id: 'prior_posterior',
  chapterLabel: 'Ch 15 · Bayesian thinking',
  title: const [
    TitlePart('Start with a '),
    TitlePart('belief', AppColors.peg),
    TitlePart(', let data '),
    TitlePart('reshape', AppColors.violet),
    TitlePart(' it'),
  ],
  subtitle: 'Prior to posterior · 3-minute animated lesson',
  createSim: () => PosteriorSim(),
  visualAspectRatio: 1.1,
  buildVisual: (sim) => simCanvas<PosteriorSim>(sim, _paintPosterior),
  stats: (sim) {
    final s = sim as PosteriorSim;
    return [
      StatChip('flips', '${s.heads + s.tails}', AppColors.yellow),
      StatChip('best guess', s.postMean.toStringAsFixed(2), AppColors.violet),
      StatChip('real p', s.heads + s.tails >= 100 ? '0.70' : '?', AppColors.pink),
    ];
  },
  bigIdea: 'Bayesian statistics treats an unknown, like a coin\'s chance of heads, as '
      'something you hold beliefs about. The prior is your belief before data: '
      'flat if you have no idea, peaked at 0.5 if you\'re sure the coin is fair. '
      'Each flip updates it into the posterior. With little data the prior matters '
      'a lot; with lots of data, everyone\'s posterior ends up in the same place.',
  formula: (sim) {
    final s = sim as PosteriorSim;
    return 'Beta(${s.a0.round()}, ${s.b0.round()}) prior + ${s.heads}H, ${s.tails}T → Beta(${s.a.round()}, ${s.b.round()}) '
        'posterior, mean ${s.postMean.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: start from a different belief',
  buildTryIt: (sim) {
    final s = sim as PosteriorSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<Prior>(options: kPriorNames, selected: s.prior, onSelected: (v) => s.change(() => s.prior = v)),
          const SizedBox(height: 8),
          const TryNote('The sceptic needs many more flips before their belief moves to 0.7.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'In Bayesian statistics, the prior is…',
      options: ['The data', 'Your belief before seeing the data', 'The final answer', 'The p-value'],
      answer: 1,
      explanation: 'The posterior is the prior updated by the data.',
    ),
    QuizQuestion(
      prompt: 'Two people with different priors see a huge amount of the same data. Their posteriors…',
      options: ['Stay far apart', 'Become very similar', 'Swap', 'Become flat'],
      answer: 1,
      explanation: 'Enough data overwhelms the prior.',
    ),
    QuizQuestion(
      prompt: 'A flat prior, then 8 heads in 10 flips. Roughly where does the posterior peak?',
      options: ['0.5', '0.8', '0.2', '1'],
      answer: 1,
      explanation: 'With a flat prior the posterior peaks at the observed rate, 8/10.',
    ),
  ],
);

// ===========================================================================
// Updating with evidence
// ===========================================================================

class UpdatingSim extends TickSim {
  UpdatingSim({super.rng}) {
    restart();
  }

  /// Bag A is 70% red, bag B 30% red. One is picked at random each round.
  static const double redA = 0.7, redB = 0.3;
  double priorA = 0.5;
  late bool isA;
  final List<bool> draws = [];
  final List<double> history = [];
  int _hold = 0;

  double get current => history.last;

  @override
  double get interval => 0.6;

  @override
  void tick() {
    if (draws.length >= 15) {
      if (++_hold > 4) restart();
      return;
    }
    final red = rng.nextDouble() < (isA ? redA : redB);
    draws.add(red);
    final p = current;
    final la = red ? redA : 1 - redA, lb = red ? redB : 1 - redB;
    history.add(p * la / (p * la + (1 - p) * lb));
  }

  @override
  void restart() {
    isA = rng.nextBool();
    draws.clear();
    history
      ..clear()
      ..add(priorA);
    _hold = 0;
  }

  void setPrior(double v) {
    priorA = v;
    reset();
  }
}

void _paintUpdating(Canvas canvas, Size size, UpdatingSim sim) {
  final w = size.width;
  final h = size.height;
  // The drawn balls.
  label(canvas, 'Balls drawn (put back each time)', Offset(16, 12),
      size: 11, color: AppColors.muted, align: TextAlign.left);
  final d = (w - 32) / 15;
  for (var i = 0; i < sim.draws.length; i++) {
    canvas.drawCircle(
        Offset(16 + d * (i + 0.5), 34), d * 0.38, Paint()..color = sim.draws[i] ? AppColors.pink : AppColors.blue);
  }
  final plot = Plot(Rect.fromLTRB(40, 70, w - 16, h - 40), x0: 0, x1: 15, y1: 1);
  for (final p in [0.0, 0.5, 1.0]) {
    dashedLine(canvas, plot.at(0, p), plot.at(15, p), AppColors.peg.withValues(alpha: 0.6), width: 1);
    label(canvas, '${(p * 100).round()}%', Offset(34, plot.y(p)),
        size: 9, color: AppColors.muted, align: TextAlign.right);
  }
  final path = Path()..moveTo(plot.x(0), plot.y(sim.history.first));
  for (var i = 1; i < sim.history.length; i++) {
    path.lineTo(plot.x(i.toDouble()), plot.y(sim.history[i]));
  }
  canvas.drawPath(
    path,
    Paint()
      ..color = AppColors.violet
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );
  for (var i = 0; i < sim.history.length; i++) {
    canvas.drawCircle(plot.at(i.toDouble(), sim.history[i]), 3.5, Paint()..color = AppColors.violet);
  }
  label(canvas, 'P(bag A) ↑', Offset(40, 60), size: 11, color: AppColors.violet, align: TextAlign.left);
  plot.axis(canvas, [0, 5, 10, 15], title: 'draws');
  if (sim.draws.length >= 15) {
    label(canvas, 'It was bag ${sim.isA ? 'A' : 'B'}!', Offset(w / 2, h - 12),
        size: 14, color: (sim.current > 0.5) == sim.isA ? AppColors.green : AppColors.pink);
  }
}

final LessonSpec updatingEvidenceLesson = LessonSpec(
  id: 'updating_evidence',
  chapterLabel: 'Ch 15 · Bayesian thinking',
  title: const [
    TitlePart('Which bag is it? '),
    TitlePart('Update', AppColors.violet),
    TitlePart(' after every ball'),
  ],
  subtitle: 'Updating with evidence · 2-minute animated lesson',
  createSim: () => UpdatingSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<UpdatingSim>(sim, _paintUpdating),
  stats: (sim) {
    final s = sim as UpdatingSim;
    return [
      StatChip('draws', '${s.draws.length}', AppColors.yellow),
      StatChip('P(bag A)', s.current.toStringAsFixed(2), AppColors.violet),
    ];
  },
  bigIdea: 'Bag A is 70% red, bag B is 30% red, and you don\'t know which you\'re '
      'drawing from. Each red ball is a little evidence for A; each blue one for B. '
      'Bayes\' rule turns each ball into an update: yesterday\'s posterior becomes '
      'today\'s prior. No single draw settles it, but the evidence piles up and the '
      'belief heads towards 0% or 100%.',
  formula: (sim) {
    final s = sim as UpdatingSim;
    return 'P(A | red) = P(A)·0.7 / (P(A)·0.7 + P(B)·0.3)   now ${s.current.toStringAsFixed(3)}';
  },
  tryItTitle: 'Try it: start with a stronger hunch',
  buildTryIt: (sim) {
    final s = sim as UpdatingSim;
    return watch(
      s,
      () => LabeledSlider(
        left: 'prior A',
        right: '',
        value: s.priorA,
        min: 0.05,
        max: 0.95,
        divisions: 18,
        label: '${(s.priorA * 100).round()}%',
        onChanged: s.setPrior,
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'You start 50-50 between bags A (70% red) and B (30% red), then draw one red. P(A) becomes…',
      options: ['0.5', '0.7', '0.3', '1'],
      answer: 1,
      explanation: '0.5×0.7 / (0.5×0.7 + 0.5×0.3) = 0.35/0.5 = 0.7.',
    ),
    QuizQuestion(
      prompt: 'In sequential Bayesian updating, the posterior after one draw becomes…',
      options: ['The likelihood', 'The prior for the next draw', 'Zero', 'Irrelevant'],
      answer: 1,
      explanation: 'Each update builds on everything learned so far.',
    ),
    QuizQuestion(
      prompt: 'One red, then one blue. With a 50-50 start, P(A) is now…',
      options: ['0.5', '0.7', '0.3', '0.21'],
      answer: 0,
      explanation: 'The two pieces of evidence are equally strong and point opposite ways.',
    ),
  ],
);

// ===========================================================================
// Bayesian vs frequentist
// ===========================================================================

class BayesFreqSim extends TickSim {
  BayesFreqSim({super.rng});

  /// True click-through rate of a new advert.
  static const double hidden = 0.15;
  int clicks = 0, views = 0;

  double get pHat => views == 0 ? 0 : clicks / views;

  /// Frequentist 95% interval (Wald), clamped to 0–1.
  (double, double) get confidence {
    if (views == 0) return (0, 1);
    final m = 1.96 * math.sqrt(pHat * (1 - pHat) / views);
    return ((pHat - m).clamp(0.0, 1.0), (pHat + m).clamp(0.0, 1.0));
  }

  /// Bayesian 95% credible interval from a flat prior.
  (double, double) get credible => (
        betaQuantile(1.0 + clicks, 1.0 + views - clicks, 0.025),
        betaQuantile(1.0 + clicks, 1.0 + views - clicks, 0.975)
      );

  @override
  double get interval => views < 10 ? 0.6 : 0.25;

  @override
  void tick() {
    if (views >= 80) return;
    views++;
    if (rng.nextDouble() < hidden) clicks++;
  }

  @override
  void restart() => clicks = views = 0;
}

void _paintBayesFreq(Canvas canvas, Size size, BayesFreqSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(16, 40, w - 16, h * 0.58), x0: 0, x1: 0.6, y1: 1);
  label(canvas, '${sim.clicks} clicks out of ${sim.views} views', Offset(w / 2, 14), size: 13);
  var peak = 0.0;
  for (var i = 1; i < 200; i++) {
    peak = math.max(peak, betaPdf(0.6 * i / 200, 1.0 + sim.clicks, 1.0 + sim.views - sim.clicks));
  }
  final post = Plot(plot.rect, x0: 0, x1: 0.6, y1: math.max(peak * 1.1, 1));
  post.curve(canvas, (x) => betaPdf(x, 1.0 + sim.clicks, 1.0 + sim.views - sim.clicks), AppColors.violet, fill: true);
  label(canvas, 'posterior belief about the rate', Offset(w - 16, 34),
      size: 10, color: AppColors.violet, align: TextAlign.right);
  plot.axis(canvas, [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6], format: (v) => '${(v * 100).round()}%');
  void interval(double y, (double, double) ci, Color color, String name) {
    final (lo, hi) = ci;
    line(canvas, Offset(plot.x(lo.clamp(0, 0.6)), y), Offset(plot.x(hi.clamp(0, 0.6)), y), color, width: 6);
    label(canvas, '$name: ${(lo * 100).toStringAsFixed(0)}–${(hi * 100).toStringAsFixed(0)}%', Offset(16, y - 14),
        size: 12, color: color, align: TextAlign.left);
  }

  interval(h * 0.58 + 52, sim.confidence, AppColors.blue, '95% confidence interval');
  interval(h * 0.58 + 100, sim.credible, AppColors.violet, '95% credible interval');
  line(canvas, Offset(plot.x(BayesFreqSim.hidden), h * 0.58 + 30), Offset(plot.x(BayesFreqSim.hidden), h - 8),
      AppColors.ink.withValues(alpha: sim.views >= 80 ? 1 : 0),
      width: 2);
}

final LessonSpec bayesVsFrequentistLesson = LessonSpec(
  id: 'bayes_vs_frequentist',
  chapterLabel: 'Ch 15 · Bayesian thinking',
  title: const [
    TitlePart('Two schools, '),
    TitlePart('two kinds', AppColors.violet),
    TitlePart(' of interval'),
  ],
  subtitle: 'Bayesian vs frequentist · 3-minute animated lesson',
  createSim: () => BayesFreqSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<BayesFreqSim>(sim, _paintBayesFreq),
  stats: (sim) {
    final s = sim as BayesFreqSim;
    return [
      StatChip('views', '${s.views}', AppColors.yellow),
      StatChip('click rate', '${(s.pHat * 100).toStringAsFixed(1)}%', AppColors.pink),
    ];
  },
  bigIdea: 'A frequentist treats the true click rate as a fixed unknown number: a 95% '
      'confidence interval comes from a method that catches it 95% of the time. A '
      'Bayesian treats the rate as uncertain and gives a full belief curve: a 95% '
      'credible interval contains the rate with 95% probability, given the data and '
      'prior. With lots of data the two intervals nearly agree; with very little '
      'data they can differ, and the simple confidence interval can even be '
      'zero-width or run past 0%.',
  formula: (sim) {
    final s = sim as BayesFreqSim;
    return 'frequentist: p̂ ± 1.96√(p̂(1−p̂)/n)   Bayesian: Beta(1 + ${s.clicks}, 1 + ${s.views - s.clicks}) posterior';
  },
  tryItTitle: 'Try it: watch from the very first views',
  buildTryIt: (sim) {
    final s = sim as BayesFreqSim;
    return ControlRow(children: [
      ActionButton('Start over', s.reset),
      ActionButton('Show 80 views', () => s.runMany(80)),
    ]);
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Which statement fits a Bayesian 95% credible interval?',
      options: [
        'The method catches the truth 95% of the time',
        'Given the data and prior, the value lies inside with 95% probability',
        'It is always narrower',
        'It ignores the data',
      ],
      answer: 1,
      explanation: 'Bayesians put probabilities directly on the unknown value.',
    ),
    QuizQuestion(
      prompt: 'What does a Bayesian analysis need that a frequentist one doesn\'t?',
      options: ['Data', 'A prior distribution', 'A sample size', 'A computer'],
      answer: 1,
      explanation: 'The prior encodes belief before the data.',
    ),
    QuizQuestion(
      prompt: 'With a very large amount of data, Bayesian and frequentist intervals usually…',
      options: ['Disagree completely', 'Become nearly the same', 'Both become empty', 'Swap'],
      answer: 1,
      explanation: 'The data dominates any reasonable prior.',
    ),
  ],
);
