import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

// Chapter 11 · Sampling.

/// A 20 × 20 town where each person answers yes or no.
class Town {
  Town(double Function(int row, int col) yesRate, {int seed = 11}) {
    final rng = math.Random(seed);
    yes = List.generate(size * size, (i) => rng.nextDouble() < yesRate(i ~/ size, i % size));
  }

  static const int size = 20;
  late final List<bool> yes;

  double get truth => yes.where((y) => y).length / yes.length;
  double shareYes(Iterable<int> people) => people.isEmpty ? 0 : people.where((i) => yes[i]).length / people.length;
}

/// Draws the town; [picked] people are highlighted.
void paintTown(Canvas canvas, Rect area, Town town, Set<int> picked, {Color Function(int i)? tint}) {
  final cell = area.width / Town.size;
  for (var i = 0; i < Town.size * Town.size; i++) {
    final c = Offset(area.left + cell * (i % Town.size + 0.5), area.top + cell * (i ~/ Town.size + 0.5));
    final isPicked = picked.contains(i);
    final base = town.yes[i] ? AppColors.green : AppColors.pink;
    if (tint != null) {
      canvas.drawRect(Rect.fromCenter(center: c, width: cell, height: cell), Paint()..color = tint(i));
    }
    canvas.drawCircle(c, cell * (isPicked ? 0.42 : 0.26), Paint()..color = base.withValues(alpha: isPicked ? 1 : 0.3));
    if (isPicked) ring(canvas, c, cell * 0.48, AppColors.ink, width: 1.2);
  }
}

/// Dot strip of recent estimates around the true value.
void paintEstimates(Canvas canvas, Rect area, List<double> estimates, double truth, {String unit = '%'}) {
  final plot = Plot(area, x0: 0, x1: 1, y1: 1);
  line(canvas, Offset(area.left, area.center.dy), Offset(area.right, area.center.dy), AppColors.peg);
  for (var i = 0; i < estimates.length; i++) {
    final isNew = i == estimates.length - 1;
    canvas.drawCircle(Offset(plot.x(estimates[i]), area.center.dy + ((i * 7) % 9 - 4) * 2.0), isNew ? 6 : 4,
        Paint()..color = isNew ? AppColors.orange : AppColors.blue.withValues(alpha: 0.5));
  }
  line(canvas, Offset(plot.x(truth), area.top), Offset(plot.x(truth), area.bottom), AppColors.ink, width: 2.5);
  label(canvas, 'truth ${(truth * 100).toStringAsFixed(0)}$unit', Offset(plot.x(truth), area.top - 8), size: 10);
  for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
    label(canvas, '${(t * 100).round()}', Offset(plot.x(t), area.bottom + 8), size: 9, color: AppColors.muted);
  }
}

/// Shared shell: a town, a way to pick a sample, and the estimates it gives.
abstract class TownSampleSim extends TickSim {
  TownSampleSim({super.rng});

  Town get town;
  Set<int> picked = {};
  final List<double> estimates = [];

  Set<int> pick();

  @override
  double get interval => estimates.length < 5 ? 1.2 : 0.3;

  @override
  void tick() {
    picked = pick();
    estimates.add(town.shareYes(picked));
    if (estimates.length > 60) estimates.removeAt(0);
  }

  @override
  void restart() {
    picked = {};
    estimates.clear();
  }

  Set<int> randomPeople(int n, [List<int>? from]) {
    final pool = [...(from ?? List<int>.generate(Town.size * Town.size, (i) => i))]..shuffle(rng);
    return pool.take(n).toSet();
  }

  double get spread => sdOf(estimates);
}

// ===========================================================================
// Population vs sample
// ===========================================================================

class PopulationSim extends TownSampleSim {
  PopulationSim({super.rng});

  @override
  final Town town = Town((r, c) => 0.62);
  int n = 25;

  @override
  Set<int> pick() => randomPeople(n);
}

void _paintPopulation(Canvas canvas, Size size, TownSampleSim sim) {
  final w = size.width;
  final h = size.height;
  final side = math.min(w - 32, h - 110);
  final area = Rect.fromLTWH((w - side) / 2, 18, side, side);
  label(canvas, 'Population: all ${Town.size * Town.size} people · green = yes', Offset(w / 2, 8),
      size: 11, color: AppColors.muted);
  paintTown(canvas, area, sim.town, sim.picked);
  if (sim.picked.isNotEmpty) {
    label(
        canvas,
        'This sample of ${sim.picked.length}: ${(sim.town.shareYes(sim.picked) * 100).toStringAsFixed(0)}% yes',
        Offset(w / 2, area.bottom + 14),
        size: 13,
        color: AppColors.orange);
  }
  paintEstimates(canvas, Rect.fromLTRB(20, area.bottom + 40, w - 20, h - 14), sim.estimates, sim.town.truth);
}

final LessonSpec populationSampleLesson = LessonSpec(
  id: 'population_sample',
  chapterLabel: 'Ch 11 · Sampling',
  title: const [
    TitlePart('Ask a '),
    TitlePart('few', AppColors.orange),
    TitlePart(', learn about '),
    TitlePart('everyone', AppColors.green),
  ],
  subtitle: 'Population vs sample · 2-minute animated lesson',
  createSim: () => PopulationSim(),
  visualAspectRatio: 0.8,
  buildVisual: (sim) => simCanvas<TownSampleSim>(sim, _paintPopulation),
  stats: (sim) {
    final s = sim as PopulationSim;
    return [
      StatChip('true yes', '${(s.town.truth * 100).toStringAsFixed(1)}%', AppColors.green),
      StatChip('samples', '${s.estimates.length}', AppColors.yellow),
      StatChip('typical miss', '±${(s.spread * 100).toStringAsFixed(1)}%', AppColors.orange),
    ];
  },
  bigIdea: 'The population is everyone you care about; usually you can\'t ask them all. '
      'A sample is the few you do ask. The population\'s true share is a fixed '
      'number (a parameter); each sample gives a slightly different estimate (a '
      'statistic). Random samples scatter around the truth, and bigger samples '
      'scatter less.',
  formula: (sim) {
    final s = sim as PopulationSim;
    return 'parameter p = ${s.town.truth.toStringAsFixed(3)}   statistic p̂ = yes in sample / ${s.n}';
  },
  tryItTitle: 'Try it: change the sample size',
  buildTryIt: (sim) {
    final s = sim as PopulationSim;
    return watch(
      s,
      () => LabeledSlider(
        left: 'n = ${s.n}',
        right: '200',
        value: s.n.toDouble(),
        min: 5,
        max: 200,
        divisions: 39,
        onChanged: (v) => s.change(() => s.n = v.round()),
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A school surveys 50 of its 900 students about lunch. The 900 students are the…',
      options: ['Sample', 'Population', 'Statistic', 'Parameter'],
      answer: 1,
      explanation: 'The population is the whole group you want to learn about.',
    ),
    QuizQuestion(
      prompt: '"38% of the 50 surveyed liked lunch." This 38% is a…',
      options: ['Parameter', 'Statistic', 'Population', 'Guarantee'],
      answer: 1,
      explanation: 'A number calculated from a sample is a statistic.',
    ),
    QuizQuestion(
      prompt: 'Why do two random samples from the same population give different results?',
      options: [
        'Someone made a mistake',
        'Sampling variation: different people get picked',
        'The population changed',
        'They shouldn\'t'
      ],
      answer: 1,
      explanation: 'Chance decides who is in each sample, so estimates wobble.',
    ),
  ],
);

// ===========================================================================
// Sampling methods
// ===========================================================================

enum SampleMethod { random, systematic, stratified, cluster }

const Map<SampleMethod, String> kMethodNames = {
  SampleMethod.random: 'Simple random',
  SampleMethod.systematic: 'Systematic',
  SampleMethod.stratified: 'Stratified',
  SampleMethod.cluster: 'Cluster',
};

class MethodsSim extends TownSampleSim {
  MethodsSim({super.rng});

  /// Four neighbourhoods (5 rows each) with different opinions.
  static const rates = [0.85, 0.65, 0.45, 0.25];

  @override
  final Town town = Town((r, c) => rates[r ~/ 5], seed: 21);

  SampleMethod method = SampleMethod.stratified;
  static const int n = 24;

  @override
  Set<int> pick() {
    const all = Town.size * Town.size;
    switch (method) {
      case SampleMethod.random:
        return randomPeople(n);
      case SampleMethod.systematic:
        final step = all ~/ n;
        final start = rng.nextInt(step);
        return {for (var k = 0; k < n; k++) start + k * step};
      case SampleMethod.stratified:
        return {
          for (var s = 0; s < 4; s++) ...randomPeople(n ~/ 4, [for (var i = s * 100; i < (s + 1) * 100; i++) i]),
        };
      case SampleMethod.cluster:
        // One random 5 × 5 block (25 people).
        final br = rng.nextInt(4), bc = rng.nextInt(4);
        return {
          for (var r = br * 5; r < br * 5 + 5; r++)
            for (var c = bc * 5; c < bc * 5 + 5; c++) r * Town.size + c,
        };
    }
  }
}

void _paintMethods(Canvas canvas, Size size, MethodsSim sim) {
  final w = size.width;
  final h = size.height;
  final side = math.min(w - 60, h - 110);
  final area = Rect.fromLTWH((w - side) / 2 + 16, 18, side, side);
  label(canvas, '4 neighbourhoods with different views', Offset(w / 2, 8), size: 11, color: AppColors.muted);
  const tints = [AppColors.yellow, AppColors.cyan, AppColors.violet, AppColors.orange];
  paintTown(canvas, area, sim.town, sim.picked, tint: (i) => tints[(i ~/ Town.size) ~/ 5].withValues(alpha: 0.1));
  for (var s = 0; s < 4; s++) {
    label(canvas, '${(MethodsSim.rates[s] * 100).round()}%', Offset(area.left - 18, area.top + side * (s + 0.5) / 4),
        size: 10, color: AppColors.muted);
  }
  if (sim.picked.isNotEmpty) {
    label(canvas, '${kMethodNames[sim.method]}: ${(sim.town.shareYes(sim.picked) * 100).toStringAsFixed(0)}% yes',
        Offset(w / 2, area.bottom + 14),
        size: 13, color: AppColors.orange);
  }
  paintEstimates(canvas, Rect.fromLTRB(20, area.bottom + 40, w - 20, h - 14), sim.estimates, sim.town.truth);
}

final LessonSpec samplingMethodsLesson = LessonSpec(
  id: 'sampling_methods',
  chapterLabel: 'Ch 11 · Sampling',
  title: const [
    TitlePart('Four ways to '),
    TitlePart('pick', AppColors.orange),
    TitlePart(' who to ask'),
  ],
  subtitle: 'Sampling methods · 3-minute animated lesson',
  createSim: () => MethodsSim(),
  visualAspectRatio: 0.8,
  buildVisual: (sim) => simCanvas<MethodsSim>(sim, _paintMethods),
  stats: (sim) {
    final s = sim as MethodsSim;
    return [
      StatChip('samples', '${s.estimates.length}', AppColors.yellow),
      StatChip(
          'typical miss', s.estimates.length < 3 ? '…' : '±${(s.spread * 100).toStringAsFixed(1)}%', AppColors.orange),
    ];
  },
  bigIdea: 'Simple random: everyone equally likely. Systematic: every k-th person on a '
      'list. Stratified: split into groups (here, neighbourhoods) and sample each '
      'one in proportion, which guarantees every group is represented and gives '
      'the tightest estimates. Cluster: pick whole blocks at random; cheap, but '
      'people in one block think alike, so estimates swing wildly. Each sample '
      'here has about 24 people.',
  formula: (sim) {
    final s = sim as MethodsSim;
    return '${kMethodNames[s.method]} · spread of estimates (sd) = ${(s.spread * 100).toStringAsFixed(1)} points';
  },
  tryItTitle: 'Try it: compare the methods',
  buildTryIt: (sim) {
    final s = sim as MethodsSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<SampleMethod>(
              options: kMethodNames, selected: s.method, onSelected: (v) => s.change(() => s.method = v)),
          const SizedBox(height: 8),
          ControlRow(children: [ActionButton('Take 50 samples', () => s.runMany(50))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A school picks 10 students from each year group at random. This is…',
      options: ['Cluster sampling', 'Stratified sampling', 'Systematic sampling', 'Convenience sampling'],
      answer: 1,
      explanation: 'The year groups are strata, each sampled separately.',
    ),
    QuizQuestion(
      prompt: 'Why do cluster samples often vary more?',
      options: [
        'They are always smaller',
        'People in the same cluster tend to be similar',
        'Clusters are chosen by hand',
        'They don\'t',
      ],
      answer: 1,
      explanation: 'One cluster gives less variety than the same number of people spread out.',
    ),
    QuizQuestion(
      prompt: 'A factory checks every 50th item off the line. This is…',
      options: ['Systematic sampling', 'Stratified sampling', 'Simple random sampling', 'A census'],
      answer: 0,
      explanation: 'A fixed step through an ordered list.',
    ),
  ],
);

// ===========================================================================
// Sampling bias
// ===========================================================================

class BiasSim extends TownSampleSim {
  BiasSim({super.rng});

  /// People near the mall (top-left quarter) love the new mall.
  @override
  final Town town = Town((r, c) => r < 10 && c < 10 ? 0.9 : 0.4, seed: 31);

  bool convenience = true;
  int n = 30;

  static final List<int> nearMall = [
    for (var r = 0; r < 10; r++)
      for (var c = 0; c < 10; c++) r * Town.size + c,
  ];

  @override
  Set<int> pick() => randomPeople(n, convenience ? nearMall : null);
}

void _paintBias(Canvas canvas, Size size, BiasSim sim) {
  final w = size.width;
  final h = size.height;
  final side = math.min(w - 32, h - 110);
  final area = Rect.fromLTWH((w - side) / 2, 18, side, side);
  label(canvas, 'Should the town build a second mall?', Offset(w / 2, 8), size: 11, color: AppColors.muted);
  paintTown(canvas, area, sim.town, sim.picked,
      tint: (i) => BiasSim.nearMall.contains(i) ? AppColors.yellow.withValues(alpha: 0.2) : Colors.transparent);
  label(canvas, '🛍 mall', Offset(area.left + side * 0.25, area.top + side * 0.25), size: 14);
  paintEstimates(canvas, Rect.fromLTRB(20, area.bottom + 40, w - 20, h - 14), sim.estimates, sim.town.truth);
  if (sim.estimates.isNotEmpty) {
    label(canvas, 'average estimate ${(meanOf(sim.estimates) * 100).toStringAsFixed(0)}%',
        Offset(w / 2, area.bottom + 14),
        size: 13, color: AppColors.orange);
  }
}

final LessonSpec samplingBiasLesson = LessonSpec(
  id: 'sampling_bias',
  chapterLabel: 'Ch 11 · Sampling',
  title: const [
    TitlePart('Asking '),
    TitlePart('more', AppColors.orange),
    TitlePart(' of the '),
    TitlePart('wrong', AppColors.pink),
    TitlePart(' people'),
  ],
  subtitle: 'Sampling bias · 2-minute animated lesson',
  createSim: () => BiasSim(),
  visualAspectRatio: 0.8,
  buildVisual: (sim) => simCanvas<BiasSim>(sim, _paintBias),
  stats: (sim) {
    final s = sim as BiasSim;
    return [
      StatChip('true yes', '${(s.town.truth * 100).toStringAsFixed(0)}%', AppColors.green),
      StatChip('avg estimate', s.estimates.isEmpty ? '…' : '${(meanOf(s.estimates) * 100).toStringAsFixed(0)}%',
          AppColors.orange),
    ];
  },
  bigIdea: 'Standing outside the mall and asking shoppers is easy, but shoppers near the '
      'mall love malls. That convenience sample is biased: every estimate lands '
      'far from the truth, in the same direction. Asking more shoppers only makes '
      'you more confident in the wrong answer. Random sampling from the whole town '
      'removes the bias; size then reduces the wobble.',
  formula: (sim) {
    final s = sim as BiasSim;
    return 'bias = average estimate − truth = ${((meanOf(s.estimates) - s.town.truth) * 100).toStringAsFixed(1)} points';
  },
  tryItTitle: 'Try it: bigger sample vs better sample',
  buildTryIt: (sim) {
    final s = sim as BiasSim;
    return watch(
      s,
      () => Column(
        children: [
          ChoiceRow<bool>(
            options: const {true: 'Ask shoppers at the mall', false: 'Random people in town'},
            selected: s.convenience,
            onSelected: (v) => s.change(() => s.convenience = v),
          ),
          LabeledSlider(
            left: 'n = ${s.n}',
            right: '100',
            value: s.n.toDouble(),
            min: 10,
            max: 100,
            divisions: 9,
            onChanged: (v) => s.change(() => s.n = v.round()),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'An online poll about internet use only reaches internet users. This is an example of…',
      options: ['Random error', 'Selection bias', 'A census', 'Stratified sampling'],
      answer: 1,
      explanation: 'Who could answer was decided by the very thing being measured.',
    ),
    QuizQuestion(
      prompt: 'A biased sample gets 10 times bigger. The bias…',
      options: ['Disappears', 'Shrinks a lot', 'Stays about the same', 'Doubles'],
      answer: 2,
      explanation: 'More of the same kind of people just narrows the scatter around the wrong value.',
    ),
    QuizQuestion(
      prompt: 'Only 20% of people mailed a survey return it. The main risk is…',
      options: ['Non-response bias', 'Too much data', 'Rounding errors', 'None'],
      answer: 0,
      explanation: 'People who reply may differ from those who don\'t.',
    ),
  ],
);

// ===========================================================================
// Sampling distributions
// ===========================================================================

enum Statistic { mean, median, max }

class SamplingDistSim extends TickSim {
  SamplingDistSim({super.rng});

  Statistic stat = Statistic.mean;
  int n = 10;
  List<double> sample = [];
  final List<double> results = [];

  /// Skewed population (like incomes, mean 1).
  double _person() => expDraw(rng, 1);

  @override
  double get interval => results.length < 6 ? 0.9 : 0.05;

  @override
  void tick() {
    sample = List.generate(n, (_) => _person());
    final v = switch (stat) {
      Statistic.mean => meanOf(sample),
      Statistic.median => quantileOf(sample, 0.5),
      Statistic.max => sample.reduce(math.max),
    };
    if (results.length < 4000) results.add(v);
  }

  @override
  void restart() {
    sample = [];
    results.clear();
  }
}

void _paintSamplingDist(Canvas canvas, Size size, SamplingDistSim sim) {
  final w = size.width;
  final h = size.height;
  // Population shape.
  final pop = Plot(Rect.fromLTRB(16, 24, w - 16, h * 0.3), x0: 0, x1: 6, y1: 1.05);
  label(canvas, 'Population (skewed, mean 1)', Offset(16, 10), size: 11, color: AppColors.muted, align: TextAlign.left);
  pop.curve(canvas, (x) => math.exp(-x), AppColors.peg, fill: true, width: 2);
  for (final v in sim.sample) {
    canvas.drawCircle(pop.at(v.clamp(0, 6), 0.05), 4, Paint()..color = AppColors.orange);
  }
  pop.axis(canvas, [0, 1, 2, 3, 4, 5, 6]);
  // Distribution of the statistic.
  final name =
      switch (sim.stat) { Statistic.mean => 'means', Statistic.median => 'medians', Statistic.max => 'maximums' };
  final hi = sim.stat == Statistic.max ? 8.0 : 3.0;
  final counts = binCounts(sim.results, 0, hi, 40);
  final peak = sim.results.isEmpty ? 1.0 : counts.reduce(math.max) / (sim.results.length * hi / 40);
  final plot = Plot(Rect.fromLTRB(16, h * 0.3 + 46, w - 16, h - 30), x0: 0, x1: hi, y1: math.max(peak * 1.15, 0.5));
  label(canvas, 'Sampling distribution: ${sim.results.length} sample $name (n = ${sim.n})', Offset(16, h * 0.3 + 32),
      size: 12, align: TextAlign.left);
  plot.densityBars(canvas, counts, 0, hi, AppColors.violet.withValues(alpha: 0.6), total: sim.results.length);
  if (sim.stat == Statistic.mean && sim.results.length > 30) {
    plot.curve(canvas, (x) => normalPdf(x, 1, 1 / math.sqrt(sim.n)), AppColors.pink);
  }
  plot.axis(canvas, [for (var t = 0.0; t <= hi; t += 1) t]);
}

final LessonSpec samplingDistributionsLesson = LessonSpec(
  id: 'sampling_distributions',
  chapterLabel: 'Ch 11 · Sampling',
  title: const [
    TitlePart('The distribution of a '),
    TitlePart('statistic', AppColors.violet),
  ],
  subtitle: 'Sampling distributions · 3-minute animated lesson',
  createSim: () => SamplingDistSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<SamplingDistSim>(sim, _paintSamplingDist),
  stats: (sim) {
    final s = sim as SamplingDistSim;
    return [
      StatChip('samples', '${s.results.length}', AppColors.yellow),
      StatChip('centre', meanOf(s.results).toStringAsFixed(2), AppColors.violet),
      StatChip('spread', sdOf(s.results).toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'Take a sample, compute a number from it (the mean, median, or maximum), and '
      'write it down. Do it thousands of times and those numbers form their own '
      'distribution: the sampling distribution. It tells you how much a statistic '
      'wobbles from sample to sample. For the mean it\'s centred on the truth and '
      'turns into a bell, even though the population is skewed (the CLT). The '
      'maximum is skewed and sits above the typical value.',
  formula: (sim) {
    final s = sim as SamplingDistSim;
    return s.stat == Statistic.mean
        ? 'mean of x̄ = μ = 1   sd of x̄ = σ/√n = 1/√${s.n} = ${(1 / math.sqrt(s.n)).toStringAsFixed(2)}'
        : 'each sample of ${s.n} → one value; repeat → its distribution';
  },
  tryItTitle: 'Try it: change the statistic and n',
  buildTryIt: (sim) {
    final s = sim as SamplingDistSim;
    return watch(
      s,
      () => Column(
        children: [
          ChoiceRow<Statistic>(
            options: const {Statistic.mean: 'Mean', Statistic.median: 'Median', Statistic.max: 'Maximum'},
            selected: s.stat,
            onSelected: (v) => s.change(() => s.stat = v),
          ),
          LabeledSlider(
            left: 'n = ${s.n}',
            right: '50',
            value: s.n.toDouble(),
            min: 2,
            max: 50,
            divisions: 48,
            onChanged: (v) => s.change(() => s.n = v.round()),
          ),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A sampling distribution describes…',
      options: [
        'The values in one sample',
        'How a statistic varies across many samples',
        'The population itself',
        'The sampling method',
      ],
      answer: 1,
      explanation: 'It is the distribution of the statistic, sample after sample.',
    ),
    QuizQuestion(
      prompt: 'The population is skewed. The sampling distribution of the mean for n = 40 is…',
      options: ['Equally skewed', 'Roughly normal', 'Flat', 'Bimodal'],
      answer: 1,
      explanation: 'The Central Limit Theorem: means of large samples are close to normal.',
    ),
    QuizQuestion(
      prompt: 'As n grows, the sampling distribution of the mean gets…',
      options: ['Wider', 'Narrower', 'Further from μ', 'More skewed'],
      answer: 1,
      explanation: 'Its sd is σ/√n, which shrinks as n grows.',
    ),
  ],
);

// ===========================================================================
// Standard error
// ===========================================================================

class StandardErrorSim extends TickSim {
  StandardErrorSim({super.rng});

  static const List<int> sizes = [4, 9, 16, 25, 36, 49, 64, 81, 100];
  static const double sigma = 10;
  static const int reps = 300;

  /// Observed sd of sample means for each size done so far.
  final List<double> observed = [];
  List<double> lastMeans = [];

  @override
  double get interval => 0.9;

  @override
  void tick() {
    if (observed.length >= sizes.length) {
      restart();
      return;
    }
    final n = sizes[observed.length];
    lastMeans = List.generate(reps, (_) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += 50 + sigma * normalDraw(rng);
      }
      return s / n;
    });
    observed.add(sdOf(lastMeans));
  }

  @override
  void restart() {
    observed.clear();
    lastMeans = [];
  }
}

void _paintSE(Canvas canvas, Size size, StandardErrorSim sim) {
  final w = size.width;
  final h = size.height;
  final plot = Plot(Rect.fromLTRB(36, 20, w - 16, h * 0.62), x0: 0, x1: 105, y1: 6);
  label(canvas, 'standard error ↑', Offset(36, 8), size: 11, color: AppColors.muted, align: TextAlign.left);
  plot.curve(canvas, (n) => n < 2 ? 6 : StandardErrorSim.sigma / math.sqrt(n), AppColors.pink, from: 2.8, to: 105);
  label(canvas, 'σ/√n', plot.at(14, 10 / math.sqrt(14)).translate(26, -4), size: 13, color: AppColors.pink);
  for (var i = 0; i < sim.observed.length; i++) {
    canvas.drawCircle(
        plot.at(StandardErrorSim.sizes[i].toDouble(), sim.observed[i]), 6, Paint()..color = AppColors.violet);
  }
  for (final t in [1.0, 2.0, 3.0, 4.0, 5.0]) {
    label(canvas, '${t.round()}', Offset(28, plot.y(t)), size: 9, color: AppColors.muted, align: TextAlign.right);
  }
  plot.axis(canvas, [4, 25, 49, 64, 100], title: 'sample size n');
  // The 300 means for the latest n.
  if (sim.lastMeans.isNotEmpty) {
    final n = StandardErrorSim.sizes[sim.observed.length - 1];
    final strip = Plot(Rect.fromLTRB(16, h * 0.62 + 46, w - 16, h - 24), x0: 35, x1: 65, y1: 1);
    label(canvas, '300 sample means with n = $n', Offset(16, h * 0.62 + 34), size: 11, align: TextAlign.left);
    for (var i = 0; i < sim.lastMeans.length; i++) {
      canvas.drawCircle(strip.at(sim.lastMeans[i].clamp(35, 65), (i % 9) / 9 + 0.05), 2.4,
          Paint()..color = AppColors.violet.withValues(alpha: 0.5));
    }
    strip.axis(canvas, [35, 40, 45, 50, 55, 60, 65]);
  }
}

final LessonSpec standardErrorLesson = LessonSpec(
  id: 'standard_error',
  chapterLabel: 'Ch 11 · Sampling',
  title: const [
    TitlePart('Four times the data, '),
    TitlePart('half', AppColors.pink),
    TitlePart(' the error'),
  ],
  subtitle: 'Standard error · 2-minute animated lesson',
  createSim: () => StandardErrorSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<StandardErrorSim>(sim, _paintSE),
  stats: (sim) {
    final s = sim as StandardErrorSim;
    final i = s.observed.length - 1;
    return [
      StatChip('n', i < 0 ? '…' : '${StandardErrorSim.sizes[i]}', AppColors.yellow),
      StatChip('SE seen', i < 0 ? '…' : s.observed[i].toStringAsFixed(2), AppColors.violet),
      StatChip('σ/√n', i < 0 ? '…' : (10 / math.sqrt(StandardErrorSim.sizes[i])).toStringAsFixed(2), AppColors.pink),
    ];
  },
  bigIdea: 'The standard error is the standard deviation of an estimate: how far a '
      'sample mean typically lands from the true mean. It equals σ/√n. The square '
      'root is the catch: to halve the error you need four times as many people, '
      'and to cut it to a tenth you need a hundred times as many. That\'s why '
      'polls rarely go beyond a few thousand people.',
  formula: (sim) {
    final s = sim as StandardErrorSim;
    final i = s.observed.length - 1;
    return i < 0
        ? 'SE = σ / √n'
        : 'SE = 10 / √${StandardErrorSim.sizes[i]} = ${(10 / math.sqrt(StandardErrorSim.sizes[i])).toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: run all sizes at once',
  buildTryIt: (sim) {
    final s = sim as StandardErrorSim;
    return ControlRow(children: [
      ActionButton('Simulate every n', () {
        s.reset();
        s.runMany(StandardErrorSim.sizes.length);
      }),
    ]);
  },
  quiz: const [
    QuizQuestion(
      prompt: 'σ = 20 and n = 100. What is the standard error of the mean?',
      options: ['0.2', '2', '20', '200'],
      answer: 1,
      explanation: '20 / √100 = 20 / 10 = 2.',
    ),
    QuizQuestion(
      prompt: 'To halve the standard error, you need…',
      options: ['Twice the sample', 'Four times the sample', 'Half the sample', '√2 times the sample'],
      answer: 1,
      explanation: 'SE ∝ 1/√n, so n must grow by 2² = 4.',
    ),
    QuizQuestion(
      prompt: 'Standard deviation vs standard error: the SE describes…',
      options: [
        'Spread of individual values',
        'Spread of an estimate like the sample mean',
        'The population size',
        'The same thing',
      ],
      answer: 1,
      explanation: 'The sd is about people; the SE is about how much the average wobbles.',
    ),
  ],
);
