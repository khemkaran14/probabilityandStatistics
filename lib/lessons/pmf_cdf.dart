import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Ways to roll each total 2–12 with two dice (out of 36).
const List<int> kTwoDiceWays = [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1];

/// A cursor sweeps across the totals 2–12, building the CDF from the PMF.
class PmfCdfSim extends LessonSim {
  double t = 0;

  /// Chosen with the slider; null while sweeping on its own.
  int? manual;

  static const double perStep = 0.7;

  /// Sweeps 2 → 12, pauses on 12 for an extra step, then starts again.
  int get cursor => manual ?? math.min(12, 2 + (t / perStep).floor() % 12);

  double pmf(int x) => (x < 2 || x > 12) ? 0 : kTwoDiceWays[x - 2] / 36;

  double cdf(int x) {
    var s = 0.0;
    for (var k = 2; k <= x; k++) {
      s += pmf(k);
    }
    return s;
  }

  int waysUpTo(int x) => [for (var k = 2; k <= math.min(x, 12); k++) kTwoDiceWays[k - 2]].fold(0, (a, b) => a + b);

  @override
  void advance(double dt) {
    if (manual == null) t += dt;
    notifyListeners();
  }

  @override
  void step() {
    manual = null;
    t = ((t / perStep).floor() + 1) * perStep;
    notifyListeners();
  }

  @override
  void reset() {
    manual = null;
    t = 0;
    notifyListeners();
  }

  void setCursor(int x) {
    manual = x;
    notifyListeners();
  }
}

void _paintPmfCdf(Canvas canvas, Size size, PmfCdfSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 34.0;
  final right = w - 12;
  final slot = (right - left) / 11;
  double xFor(int total) => left + slot * (total - 2 + 0.5);
  final x = sim.cursor;

  // PMF.
  label(canvas, 'PMF: P(total = x)', Offset(left, 12), size: 12, color: AppColors.orange, align: TextAlign.left);
  final pBase = h * 0.44;
  const pTop = 30.0;
  for (var k = 2; k <= 12; k++) {
    final included = k <= x;
    bar(canvas, xFor(k), slot * 0.7, pBase, (pBase - pTop) * sim.pmf(k) / (6 / 36),
        included ? AppColors.orange : AppColors.peg.withValues(alpha: 0.6));
    label(canvas, '${kTwoDiceWays[k - 2]}', Offset(xFor(k), pBase - (pBase - pTop) * sim.pmf(k) / (6 / 36) - 8),
        size: 9, color: AppColors.muted);
    label(canvas, '$k', Offset(xFor(k), pBase + 10), size: 10, color: AppColors.muted);
  }

  // CDF: a staircase.
  final cTop = pBase + 40;
  final cBase = h - 26;
  label(canvas, 'CDF: P(total ≤ x)', Offset(left, cTop - 14), size: 12, color: AppColors.violet, align: TextAlign.left);
  double yFor(double p) => cBase - p * (cBase - cTop);
  line(canvas, Offset(left, cBase), Offset(right, cBase), AppColors.peg);
  for (final p in [0.5, 1.0]) {
    dashedLine(canvas, Offset(left, yFor(p)), Offset(right, yFor(p)), AppColors.peg.withValues(alpha: 0.6), width: 1);
    label(canvas, p.toStringAsFixed(1), Offset(left - 6, yFor(p)),
        size: 10, color: AppColors.muted, align: TextAlign.right);
  }
  for (var k = 2; k <= 12; k++) {
    final y = yFor(sim.cdf(k));
    final x0 = left + slot * (k - 2), x1 = left + slot * (k - 1);
    line(canvas, Offset(x0, y), Offset(x1, y), k <= x ? AppColors.violet : AppColors.peg, width: 3.5);
    canvas.drawCircle(Offset(x0, y), 3.5, Paint()..color = k <= x ? AppColors.violet : AppColors.peg);
  }
  // Cursor.
  final cx = left + slot * (x - 1);
  line(canvas, Offset(cx, pTop), Offset(cx, cBase), AppColors.pink, width: 2);
  label(canvas, 'P(total ≤ $x) = ${sim.waysUpTo(x)}/36 = ${sim.cdf(x).toStringAsFixed(2)}', Offset(w / 2, h - 10),
      size: 13, color: AppColors.pink);
}

final LessonSpec pmfCdfLesson = LessonSpec(
  id: 'pmf_cdf',
  chapterLabel: 'Ch 6 · Random variables',
  title: const [
    TitlePart('Bars', AppColors.orange),
    TitlePart(' that stack into a '),
    TitlePart('staircase', AppColors.violet),
  ],
  subtitle: 'PMF, PDF & CDF · 2-minute animated lesson',
  createSim: () => PmfCdfSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<PmfCdfSim>(sim, _paintPmfCdf),
  stats: (sim) {
    final s = sim as PmfCdfSim;
    return [
      StatChip('x', '${s.cursor}', AppColors.pink),
      StatChip('P(X = x)', '${kTwoDiceWays[s.cursor - 2]}/36', AppColors.orange),
      StatChip('P(X ≤ x)', s.cdf(s.cursor).toStringAsFixed(2), AppColors.violet),
    ];
  },
  bigIdea: 'Roll two dice and add them. The PMF (probability mass function) gives the '
      'chance of each exact total: 7 is likeliest because 6 of the 36 rolls make '
      'it. The CDF (cumulative distribution function) adds up every bar to the '
      'left: the chance of getting x or less. It climbs in steps from 0 to 1. For '
      'continuous variables, the bars melt into a smooth curve called a PDF, '
      'and the CDF becomes a smooth S-shaped ramp.',
  formula: (sim) {
    final s = sim as PmfCdfSim;
    return 'F(${s.cursor}) = Σ p(k) for k ≤ ${s.cursor} = ${s.waysUpTo(s.cursor)}/36';
  },
  tryItTitle: 'Try it: move x yourself',
  buildTryIt: (sim) {
    final s = sim as PmfCdfSim;
    return watch(
      s,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: '2',
            right: '12',
            value: s.cursor.toDouble(),
            min: 2,
            max: 12,
            divisions: 10,
            label: 'x = ${s.cursor}',
            onChanged: (v) => s.setCursor(v.round()),
          ),
          TryNote('P(total > ${s.cursor}) = 1 − F(${s.cursor}) = ${(1 - s.cdf(s.cursor)).toStringAsFixed(2)}'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'With two dice, what is P(total = 7)?',
      options: ['1/36', '1/11', '6/36', '7/36'],
      answer: 2,
      explanation: '(1,6), (2,5), (3,4), (4,3), (5,2), (6,1): 6 of 36 rolls.',
    ),
    QuizQuestion(
      prompt: 'A CDF value F(5) = 0.28 means…',
      options: [
        'P(X = 5) = 0.28',
        'P(X ≤ 5) = 0.28',
        'P(X > 5) = 0.28',
        '28% of values equal 5',
      ],
      answer: 1,
      explanation: 'The CDF is cumulative: everything up to and including 5.',
    ),
    QuizQuestion(
      prompt: 'Which is always true of a CDF?',
      options: [
        'It goes up and down',
        'It never decreases and ends at 1',
        'It peaks at the mean',
        'It is always a straight line',
      ],
      answer: 1,
      explanation: 'Adding more probability can only keep it level or push it up, '
          'until everything is included.',
    ),
  ],
);
