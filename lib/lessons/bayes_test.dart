import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

/// 1,000 people take a medical test. Counts are exact for the chosen rates;
/// only who is who is shuffled.
class BayesSim extends LessonSim {
  BayesSim({int seed = 7}) : _seed = seed {
    _build();
  }

  static const int people = 1000;
  static const int cols = 40;
  static const int rows = people ~/ cols;

  /// Choices offered by the sliders.
  static const List<double> prevalences = [0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5];
  static const List<double> falsePositiveRates = [0.01, 0.02, 0.05, 0.09, 0.2];

  /// Chance a sick person tests positive.
  static const double sensitivity = 0.9;

  int _seed;
  double prevalence = 0.01;
  double falsePositiveRate = 0.09;

  late List<bool> sick;
  late List<bool> positive;

  /// People tested so far (fractional while animating).
  double tested = 0;

  /// 0 → 1 fade of negative results once everyone is tested.
  double focus = 0;

  int get sickCount => (people * prevalence).round();
  int get truePositives => (sickCount * sensitivity).round();
  int get falsePositives => ((people - sickCount) * falsePositiveRate).round();
  int get positives => truePositives + falsePositives;

  /// P(sick | positive test), from the counts.
  double get sickGivenPositive => positives == 0 ? 0 : truePositives / positives;

  int get testedCount => tested.floor().clamp(0, people);

  /// Results visible so far.
  int get positivesSoFar {
    var n = 0;
    for (var i = 0; i < testedCount; i++) {
      if (positive[i]) n++;
    }
    return n;
  }

  void _build() {
    final order = List<int>.generate(people, (i) => i)..shuffle(math.Random(_seed));
    sick = List<bool>.filled(people, false);
    positive = List<bool>.filled(people, false);
    final s = sickCount;
    for (var k = 0; k < s; k++) {
      sick[order[k]] = true;
      if (k < truePositives) positive[order[k]] = true;
    }
    for (var k = 0; k < falsePositives; k++) {
      positive[order[s + k]] = true;
    }
  }

  @override
  void advance(double dt) {
    if (tested < people) {
      // Slow for the first row so each test is visible, then fast.
      final rate = tested < cols ? 20 : 220;
      tested = math.min(people.toDouble(), tested + dt * rate);
    } else if (focus < 1) {
      focus = math.min(1, focus + dt * 1.2);
    }
    notifyListeners();
  }

  void setRates({double? prevalence, double? falsePositiveRate}) {
    this.prevalence = prevalence ?? this.prevalence;
    this.falsePositiveRate = falsePositiveRate ?? this.falsePositiveRate;
    _seed++;
    _build();
    // Jump straight to the result so the effect of the slider is instant.
    tested = people.toDouble();
    focus = 1;
    notifyListeners();
  }

  @override
  void step() {
    if (tested < people) {
      tested = math.min(people.toDouble(), (tested / cols).floor() * cols + cols.toDouble());
    } else {
      focus = 1;
    }
    notifyListeners();
  }

  @override
  void reset() {
    tested = 0;
    focus = 0;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class BayesPainter extends CustomPainter {
  BayesPainter(this.sim) : super(repaint: sim);

  final BayesSim sim;

  static const double aspectRatio = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const pad = 12.0;
    final cell = (w - pad * 2) / BayesSim.cols;
    final gridTop = 26.0;
    final dotR = cell * 0.34;
    final done = sim.testedCount;

    _text(canvas, '1,000 people · ${sim.sickCount} sick (pink) · ring = tested positive', Offset(w / 2, 13), 11,
        AppColors.muted);

    for (var i = 0; i < BayesSim.people; i++) {
      final c = Offset(pad + (i % BayesSim.cols + 0.5) * cell, gridTop + (i ~/ BayesSim.cols + 0.5) * cell);
      final isTested = i < done;
      final isPos = sim.positive[i];
      final fade = isTested && !isPos ? 1 - sim.focus * 0.75 : 1.0;
      // Sick people are always shown, so the learner sees how few there are.
      if (sim.sick[i]) {
        canvas.drawCircle(c, dotR * 1.45, Paint()..color = AppColors.pink.withValues(alpha: fade));
      } else {
        canvas.drawCircle(c, dotR, Paint()..color = AppColors.peg.withValues(alpha: (isTested ? 0.9 : 0.35) * fade));
      }
      if (isTested && isPos) {
        canvas.drawCircle(
          c,
          dotR + cell * 0.12,
          Paint()
            ..color = AppColors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.2, cell * 0.12),
        );
      }
    }

    // Result bar: everyone who tested positive, split by who is really sick.
    final barTop = gridTop + BayesSim.rows * cell + 22;
    final barH = math.max(18.0, math.min(34.0, h - barTop - 30));
    final barW = w - pad * 2;
    final tp = sim.truePositives;
    final fp = sim.falsePositives;
    final shown = sim.focus;
    _text(canvas, 'Everyone who tested positive (${sim.positives})', Offset(w / 2, barTop - 10), 12, AppColors.ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(pad, barTop, barW, barH), const Radius.circular(10)),
      Paint()..color = Colors.white,
    );
    if (sim.positives > 0 && shown > 0) {
      final sickW = barW * tp / sim.positives * shown;
      final healthyW = barW * fp / sim.positives * shown;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(pad, barTop, sickW, barH), const Radius.circular(10)),
        Paint()..color = AppColors.pink,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(pad + barW - healthyW, barTop, healthyW, barH), const Radius.circular(10)),
        Paint()..color = AppColors.peg,
      );
      if (shown >= 1) {
        _text(canvas, '$tp sick', Offset(pad + 34, barTop + barH + 14), 12, AppColors.pink);
        _text(canvas, '$fp healthy', Offset(w - pad - 44, barTop + barH + 14), 12, AppColors.muted);
        _text(canvas, '${(sim.sickGivenPositive * 100).toStringAsFixed(0)}% are really sick',
            Offset(w / 2, barTop + barH / 2), 13, AppColors.ink);
      }
    }
  }

  void _text(Canvas canvas, String text, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant BayesPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

String _pct(double v) => v < 0.01 ? '${(v * 100).toStringAsFixed(1)}%' : '${(v * 100).round()}%';

final LessonSpec bayesLesson = LessonSpec(
  id: 'bayes',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('You tested '),
    TitlePart('positive', AppColors.pink),
    TitlePart('. Are you '),
    TitlePart('really', AppColors.violet),
    TitlePart(' sick?'),
  ],
  subtitle: "Bayes' theorem: the medical test · 3-minute animated lesson",
  createSim: () => BayesSim(),
  visualAspectRatio: BayesPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: BayesPainter(sim as BayesSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final b = sim as BayesSim;
    return [
      StatChip('tested', '${b.testedCount}', AppColors.yellow),
      StatChip('positive', '${b.positivesSoFar}', AppColors.violet),
      StatChip('sick if +', b.focus > 0 ? _pct(b.sickGivenPositive) : '…', AppColors.pink),
    ];
  },
  bigIdea: 'The test catches 90% of sick people and wrongly flags 9% of healthy '
      'ones. That sounds accurate, but healthy people vastly outnumber sick ones, '
      'so 9% of a huge group beats 90% of a tiny one. Most positive results come '
      'from healthy people. How rare the disease is (the base rate) matters as '
      'much as how good the test is.',
  formula: (sim) {
    final b = sim as BayesSim;
    return 'P(sick | +) = true + / all +\n= ${b.truePositives} / (${b.truePositives} + ${b.falsePositives}) '
        '= ${_pct(b.sickGivenPositive)}';
  },
  tryItTitle: 'Try it: change how rare the disease is',
  buildTryIt: (sim) => _BayesControls(sim: sim as BayesSim),
  quiz: const [
    QuizQuestion(
      prompt: 'A disease affects 1 in 100 people. A test catches 90% of cases and '
          'falsely flags 9% of healthy people. You test positive. Roughly how likely '
          'are you to be sick?',
      options: ['About 90%', 'About 50%', 'About 10%', 'About 1%'],
      answer: 2,
      explanation: 'Out of 1,000 people: 9 sick people test positive and about 89 '
          'healthy people do too. 9 / 98 ≈ 9%.',
    ),
    QuizQuestion(
      prompt: 'The disease becomes much more common (20% of people). Your positive '
          'result now means…',
      options: [
        'You are more likely to be sick',
        'You are less likely to be sick',
        'Nothing changes',
        'The test is broken',
      ],
      answer: 0,
      explanation: 'With more sick people, true positives grow and false positives '
          'shrink. The same test result becomes much more convincing.',
    ),
    QuizQuestion(
      prompt: 'What is the best next step after one positive result for a rare disease?',
      options: [
        'Assume you are sick',
        'Ignore it completely',
        'Take a second, independent test',
        'Take the same test less often',
      ],
      answer: 2,
      explanation: 'A second positive from an independent test multiplies the '
          'evidence. That is why doctors confirm screening results.',
    ),
  ],
);

class _BayesControls extends StatelessWidget {
  const _BayesControls({required this.sim});
  final BayesSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) {
        final pi = BayesSim.prevalences.indexOf(sim.prevalence);
        final fi = BayesSim.falsePositiveRates.indexOf(sim.falsePositiveRate);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Disease affects ${_pct(sim.prevalence)} of people',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Slider(
              value: pi.toDouble(),
              min: 0,
              max: BayesSim.prevalences.length - 1.0,
              divisions: BayesSim.prevalences.length - 1,
              label: _pct(sim.prevalence),
              onChanged: (v) => sim.setRates(prevalence: BayesSim.prevalences[v.round()]),
            ),
            Text('Test wrongly flags ${_pct(sim.falsePositiveRate)} of healthy people',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Slider(
              value: fi.toDouble(),
              min: 0,
              max: BayesSim.falsePositiveRates.length - 1.0,
              divisions: BayesSim.falsePositiveRates.length - 1,
              label: _pct(sim.falsePositiveRate),
              onChanged: (v) => sim.setRates(falsePositiveRate: BayesSim.falsePositiveRates[v.round()]),
            ),
            const Text(
              'Rare disease + a few false alarms = most positives are healthy. '
              'Make the disease common and watch the pink share grow.',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        );
      },
    );
  }
}
