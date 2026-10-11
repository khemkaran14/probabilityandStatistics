import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

class PercentileSim extends TickSim {
  PercentileSim({super.rng}) {
    restart();
  }

  static const int n = 21;

  List<int> values = [];

  /// Bubble-sort position: comparing values[j] and values[j + 1] in pass [pass].
  int pass = 0;
  int j = 0;
  bool sorted = false;

  /// Percentile picked with the slider (0–100).
  double percentile = 75;

  @override
  double get interval => sorted ? 1 : 0.035;

  @override
  void tick() {
    if (sorted) return;
    if (values[j] > values[j + 1]) {
      final t = values[j];
      values[j] = values[j + 1];
      values[j + 1] = t;
    }
    j++;
    if (j >= n - 1 - pass) {
      j = 0;
      pass++;
      if (pass >= n - 1) sorted = true;
    }
  }

  /// Finishes the sort instantly.
  void sortNow() {
    values.sort();
    sorted = true;
    notifyListeners();
  }

  @override
  void restart() {
    values = List.generate(n, (_) => 10 + rng.nextInt(90));
    pass = 0;
    j = 0;
    sorted = false;
  }

  void setPercentile(double p) {
    percentile = p;
    notifyListeners();
  }

  double quantile(double q) => quantileOf(values, q);
}

void _paintPercentiles(Canvas canvas, Size size, PercentileSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 14.0;
  final right = w - 14;
  final baseline = h - 56;
  const top = 34.0;
  final slot = (right - left) / PercentileSim.n;
  final pos = sim.percentile / 100 * (PercentileSim.n - 1);

  label(canvas, sim.sorted ? 'sorted smallest → largest' : 'sorting…', Offset(w / 2, 14),
      size: 12, color: AppColors.muted);

  for (var i = 0; i < PercentileSim.n; i++) {
    final v = sim.values[i];
    final comparing = !sim.sorted && (i == sim.j || i == sim.j + 1);
    final settled = sim.sorted || i >= PercentileSim.n - sim.pass;
    Color color;
    if (comparing) {
      color = AppColors.orange;
    } else if (sim.sorted && i <= pos + 1e-9) {
      color = AppColors.violet;
    } else if (settled) {
      color = AppColors.cyan;
    } else {
      color = AppColors.peg;
    }
    bar(canvas, left + slot * (i + 0.5), slot * 0.78, baseline, (baseline - top) * v / 100, color);
    if (sim.sorted || comparing) {
      label(canvas, '$v', Offset(left + slot * (i + 0.5), baseline + 10), size: 9, color: AppColors.muted);
    }
  }

  if (!sim.sorted) return;

  // Quartile markers under the bars.
  for (final (name, q, color) in [
    ('Q1', 0.25, AppColors.green),
    ('median', 0.5, AppColors.pink),
    ('Q3', 0.75, AppColors.green),
  ]) {
    final x = left + slot * (q * (PercentileSim.n - 1) + 0.5);
    line(canvas, Offset(x, baseline + 18), Offset(x, baseline + 30), color, width: 3);
    label(canvas, '$name ${sim.quantile(q).toStringAsFixed(0)}', Offset(x, baseline + 42), size: 11, color: color);
  }

  // Percentile line across the chart.
  final pv = sim.quantile(sim.percentile / 100);
  final y = baseline - (baseline - top) * pv / 100;
  dashedLine(canvas, Offset(left, y), Offset(right, y), AppColors.violet, width: 2);
  label(canvas, 'P${sim.percentile.round()} = ${pv.toStringAsFixed(1)}', Offset(left + 4, y - 10),
      size: 12, color: AppColors.violet, align: TextAlign.left);
}

final LessonSpec percentilesLesson = LessonSpec(
  id: 'percentiles',
  chapterLabel: 'Ch 1 · Data & averages',
  title: const [
    TitlePart('Line everyone up, then '),
    TitlePart('cut', AppColors.violet),
    TitlePart(' the line'),
  ],
  subtitle: 'Percentiles & quartiles · 2-minute animated lesson',
  createSim: () => PercentileSim(),
  visualAspectRatio: 1.0,
  buildVisual: (sim) => simCanvas<PercentileSim>(sim, _paintPercentiles),
  stats: (sim) {
    final p = sim as PercentileSim;
    return [
      StatChip('Q1', p.sorted ? p.quantile(.25).toStringAsFixed(0) : '…', AppColors.green),
      StatChip('median', p.sorted ? p.quantile(.5).toStringAsFixed(0) : '…', AppColors.pink),
      StatChip('Q3', p.sorted ? p.quantile(.75).toStringAsFixed(0) : '…', AppColors.green),
    ];
  },
  bigIdea: 'Sort the data. The value 75% of the way along the line is the 75th '
      'percentile: three quarters of the data sit at or below it. The quartiles '
      'cut the line into four equal groups: Q1 at 25%, the median at 50%, Q3 at '
      '75%. Scoring in the 90th percentile means beating 90% of people, not '
      'scoring 90%.',
  formula: (sim) {
    final p = sim as PercentileSim;
    final pos = p.percentile / 100 * (PercentileSim.n - 1);
    return 'P${p.percentile.round()}: position = ${(p.percentile / 100).toStringAsFixed(2)} × (n − 1) '
        '= ${pos.toStringAsFixed(1)} in the sorted list';
  },
  tryItTitle: 'Try it: pick a percentile',
  buildTryIt: (sim) {
    final p = sim as PercentileSim;
    return watch(
      p,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '0',
            right: '100',
            value: p.percentile,
            min: 0,
            max: 100,
            divisions: 20,
            label: 'P${p.percentile.round()}',
            onChanged: p.setPercentile,
          ),
          ControlRow(
            children: [
              ValueTag(
                  'P${p.percentile.round()} = ${p.sorted ? p.quantile(p.percentile / 100).toStringAsFixed(1) : '…'}'),
              if (!p.sorted) ActionButton('Finish sorting', p.sortNow) else ActionButton('New data', p.reset),
            ],
          ),
          const SizedBox(height: 8),
          const TryNote('Purple bars are the ones at or below your percentile.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'You score in the 90th percentile on a test. What does that mean?',
      options: [
        'You got 90% of the marks',
        'You did as well as or better than about 90% of test takers',
        'You were 90th in the class',
        'You need 10% more to pass',
      ],
      answer: 1,
      explanation: 'Percentiles describe position in the sorted list, not the score '
          'itself.',
    ),
    QuizQuestion(
      prompt: 'Which percentile is the median?',
      options: ['25th', '50th', '75th', '100th'],
      answer: 1,
      explanation: 'Half the data lies at or below the median.',
    ),
    QuizQuestion(
      prompt: 'Q1 = 40 and Q3 = 70. What share of the data lies between 40 and 70?',
      options: ['25%', '50%', '70%', '75%'],
      answer: 1,
      explanation: 'From the 25th to the 75th percentile is the middle half of the '
          'data. Its width (30) is the interquartile range.',
    ),
  ],
);
