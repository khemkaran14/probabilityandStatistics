import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Two tests on different scales, morphing onto one standard scale and back.
class ZScoreSim extends LessonSim {
  static const double cycle = 8;

  // Maths: mean 60, sd 12. English: mean 72, sd 5.
  static const double mathsMean = 60, mathsSd = 12;
  static const double englishMean = 72, englishSd = 5;

  double maths = 78;
  double english = 80;

  /// Seconds into the loop.
  double t = 0;

  double get zMaths => (maths - mathsMean) / mathsSd;
  double get zEnglish => (english - englishMean) / englishSd;

  /// 0 = raw marks, 1 = standardised.
  double get morph {
    final s = t % cycle;
    if (s < 2) return 0;
    if (s < 4) return Curves.easeInOut.transform((s - 2) / 2);
    if (s < 6) return 1;
    return 1 - Curves.easeInOut.transform((s - 6) / 2);
  }

  @override
  void advance(double dt) {
    t = (t + dt) % cycle;
    notifyListeners();
  }

  @override
  void step() {
    t = ((t ~/ 2) * 2 + 2.0) % cycle;
    notifyListeners();
  }

  @override
  void reset() {
    t = 0;
    notifyListeners();
  }

  void setScores({double? maths, double? english}) {
    this.maths = maths ?? this.maths;
    this.english = english ?? this.english;
    notifyListeners();
  }
}

void _paintZ(Canvas canvas, Size size, ZScoreSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 14.0;
  final right = w - 14;
  final m = sim.morph;

  // Raw axis covers marks 20–100; z axis covers −3.5 … 3.5.
  double rawX(double mark) => left + (mark - 20) / 80 * (right - left);
  double zX(double z) => left + (z + 3.5) / 7 * (right - left);

  void curve(double mean, double sd, double top, double height, Color color, double score, String name) {
    final baseline = top + height;
    final path = Path();
    for (var i = 0; i <= 120; i++) {
      final z = -3.5 + 7 * i / 120;
      final x = rawX(mean + z * sd) * (1 - m) + zX(z) * m;
      // Peak height shrinks with sd on the raw scale (area stays 1); equal when standardised.
      final peakRaw = height * 5 / sd * 0.95;
      final peak = math.min(height * 0.95, peakRaw) * (1 - m) + height * 0.95 * m;
      final y = baseline - peak * math.exp(-z * z / 2);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    line(canvas, Offset(left, baseline), Offset(right, baseline), AppColors.peg);
    final z = (score - mean) / sd;
    final sx = rawX(score) * (1 - m) + zX(z) * m;
    line(canvas, Offset(sx, top + 4), Offset(sx, baseline), AppColors.ink, width: 2.5);
    canvas.drawCircle(Offset(sx, top + 4), 6, Paint()..color = AppColors.ink);
    final mx = rawX(mean) * (1 - m) + zX(0) * m;
    dashedLine(canvas, Offset(mx, top + 10), Offset(mx, baseline), color.withValues(alpha: 0.7));
    final text = m < 0.5 ? '$name ${score.round()} (avg ${mean.round()})' : '$name z = ${z.toStringAsFixed(2)}';
    label(canvas, text, Offset(left, top - 6), size: 13, color: color, align: TextAlign.left);
  }

  final panel = (h - 60) / 2;
  curve(ZScoreSim.mathsMean, ZScoreSim.mathsSd, 26, panel - 26, AppColors.blue, sim.maths, 'Maths');
  curve(ZScoreSim.englishMean, ZScoreSim.englishSd, 26 + panel, panel - 26, AppColors.pink, sim.english, 'English');

  // Axis labels morph between marks and z.
  final axisY = h - 18;
  if (m < 0.5) {
    for (var mark = 20; mark <= 100; mark += 20) {
      label(canvas, '$mark', Offset(rawX(mark.toDouble()), axisY), size: 11, color: AppColors.muted);
    }
  } else {
    for (var z = -3; z <= 3; z++) {
      label(canvas, z == 0 ? '0' : '${z > 0 ? '+' : ''}$z', Offset(zX(z.toDouble()), axisY),
          size: 11, color: AppColors.muted);
    }
  }
  label(canvas, m < 0.5 ? 'marks' : 'standard deviations from average', Offset(w - 16, axisY - 16),
      size: 10, color: AppColors.muted, align: TextAlign.right);
}

final LessonSpec zScoresLesson = LessonSpec(
  id: 'zscores',
  chapterLabel: 'Ch 1 · Data & averages',
  title: const [
    TitlePart('78 in Maths or 80 in English: which is '),
    TitlePart('better', AppColors.violet),
    TitlePart('?'),
  ],
  subtitle: 'Z-scores · 2-minute animated lesson',
  createSim: () => ZScoreSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<ZScoreSim>(sim, _paintZ),
  stats: (sim) {
    final z = sim as ZScoreSim;
    return [
      StatChip('Maths z', z.zMaths.toStringAsFixed(2), AppColors.blue),
      StatChip('English z', z.zEnglish.toStringAsFixed(2), AppColors.pink),
      StatChip('better', z.zMaths >= z.zEnglish ? 'Maths' : 'English', AppColors.yellow),
    ];
  },
  bigIdea: 'Raw marks from different tests can\'t be compared directly: the averages '
      'and spreads differ. A z-score asks "how many standard deviations above '
      'average is this?" Subtract the mean, divide by the sd, and both tests land '
      'on the same standard scale, where the higher z-score is the more impressive '
      'result.',
  formula: (sim) {
    final z = sim as ZScoreSim;
    return 'z = (x − μ) / σ\nMaths (${z.maths.round()} − 60) / 12 = ${z.zMaths.toStringAsFixed(2)} · '
        'English (${z.english.round()} − 72) / 5 = ${z.zEnglish.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: change the two scores',
  buildTryIt: (sim) {
    final z = sim as ZScoreSim;
    return watch(
      z,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Maths: ${z.maths.round()}  (avg 60, sd 12)', style: const TextStyle(fontWeight: FontWeight.w800)),
          Slider(value: z.maths, min: 30, max: 99, divisions: 69, onChanged: (v) => z.setScores(maths: v)),
          Text('English: ${z.english.round()}  (avg 72, sd 5)', style: const TextStyle(fontWeight: FontWeight.w800)),
          Slider(value: z.english, min: 55, max: 90, divisions: 35, onChanged: (v) => z.setScores(english: v)),
          const TryNote('English marks are bunched together, so each extra mark counts for more.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A test has mean 50 and sd 10. What is the z-score of 65?',
      options: ['0.65', '1.5', '15', '6.5'],
      answer: 1,
      explanation: '(65 − 50) / 10 = 1.5 standard deviations above average.',
    ),
    QuizQuestion(
      prompt: 'A z-score of 0 means…',
      options: ['The value is zero', 'The value equals the mean', 'The data has no spread', 'It is an outlier'],
      answer: 1,
      explanation: 'Zero standard deviations from the mean: exactly average.',
    ),
    QuizQuestion(
      prompt: 'Riya: 80 on a test with mean 70, sd 5. Sam: 85 on a test with mean 75, sd 10. '
          'Who did relatively better?',
      options: ['Sam', 'Riya', 'Equal', 'Can\'t tell'],
      answer: 1,
      explanation: 'Riya z = 10/5 = 2. Sam z = 10/10 = 1. Riya was further above her '
          'class average.',
    ),
  ],
);
