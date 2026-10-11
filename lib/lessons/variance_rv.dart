import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Two zero-average games played by many players, round after round.
/// Steady: win or lose ₹1 on a coin. Risky: win ₹k with chance 1/(k+1),
/// otherwise lose ₹1. Same mean (0), very different spread.
class VarianceSim extends TickSim {
  VarianceSim({super.rng}) {
    restart();
  }

  static const int players = 24;
  static const int maxRounds = 60;

  int k = 9;
  int round = 0;
  late List<List<double>> steady;
  late List<List<double>> risky;

  double get varSteady => 1;
  double get varRisky => k.toDouble(); // k²/(k+1) + 1·k/(k+1) = k

  double _sdOfFinal(List<List<double>> paths) => sdOf([for (final p in paths) p.last]);
  double get spreadSteady => _sdOfFinal(steady);
  double get spreadRisky => _sdOfFinal(risky);

  @override
  double get interval => 0.12;

  @override
  void tick() {
    if (round >= maxRounds + 15) {
      restart();
      return;
    }
    if (round < maxRounds) {
      for (final p in steady) {
        p.add(p.last + (rng.nextBool() ? 1 : -1));
      }
      for (final p in risky) {
        p.add(p.last + (rng.nextDouble() < 1 / (k + 1) ? k : -1));
      }
    }
    round++;
  }

  @override
  void restart() {
    round = 0;
    steady = List.generate(players, (_) => [0.0]);
    risky = List.generate(players, (_) => [0.0]);
  }
}

void _paintVariance(Canvas canvas, Size size, VarianceSim sim) {
  final w = size.width;
  final h = size.height;
  const left = 40.0;
  final right = w - 12;

  void panel(List<List<double>> paths, double top, double bottom, Color color, String name, double variance) {
    final range = math.max(12.0, 2.6 * math.sqrt(variance * VarianceSim.maxRounds));
    double yFor(double v) => (top + bottom) / 2 - v.clamp(-range, range) / range * (bottom - top) / 2;
    double xFor(int i) => left + i / VarianceSim.maxRounds * (right - left);
    label(canvas, name, Offset(left, top - 8), size: 12, color: color, align: TextAlign.left);
    line(canvas, Offset(left, yFor(0)), Offset(right, yFor(0)), AppColors.ink.withValues(alpha: 0.5));
    label(canvas, '₹0', Offset(left - 6, yFor(0)), size: 10, color: AppColors.muted, align: TextAlign.right);
    label(canvas, '+${range.round()}', Offset(left - 6, top + 4),
        size: 9, color: AppColors.muted, align: TextAlign.right);
    label(canvas, '−${range.round()}', Offset(left - 6, bottom - 4),
        size: 9, color: AppColors.muted, align: TextAlign.right);
    // ±1 sd envelope of the total after i rounds: sd·√i.
    final env = Path();
    for (var i = 0; i <= VarianceSim.maxRounds; i++) {
      final y = yFor(math.sqrt(variance * i));
      i == 0 ? env.moveTo(xFor(i), y) : env.lineTo(xFor(i), y);
    }
    for (var i = VarianceSim.maxRounds; i >= 0; i--) {
      env.lineTo(xFor(i), yFor(-math.sqrt(variance * i)));
    }
    canvas.drawPath(env, Paint()..color = color.withValues(alpha: 0.12));
    for (final p in paths) {
      final path = Path()..moveTo(xFor(0), yFor(p.first));
      for (var i = 1; i < p.length; i++) {
        path.lineTo(xFor(i), yFor(p[i]));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  final mid = h / 2;
  panel(sim.steady, 20, mid - 16, AppColors.blue, 'Steady: ±₹1 on a coin', sim.varSteady);
  panel(sim.risky, mid + 20, h - 26, AppColors.pink, 'Risky: +₹${sim.k} or −₹1', sim.varRisky);
  label(
      canvas,
      'round ${math.min(sim.round, VarianceSim.maxRounds)} of ${VarianceSim.maxRounds} · '
      '${VarianceSim.players} players each',
      Offset(w / 2, h - 10),
      size: 11,
      color: AppColors.muted);
}

final LessonSpec varianceRvLesson = LessonSpec(
  id: 'variance_rv',
  chapterLabel: 'Ch 6 · Random variables',
  title: const [
    TitlePart('Same average, very different '),
    TitlePart('ride', AppColors.pink),
  ],
  subtitle: 'Variance of a random variable · 2-minute animated lesson',
  createSim: () => VarianceSim(),
  visualAspectRatio: 0.85,
  buildVisual: (sim) => simCanvas<VarianceSim>(sim, _paintVariance),
  stats: (sim) {
    final v = sim as VarianceSim;
    return [
      StatChip('mean', '₹0 both', AppColors.yellow),
      StatChip('Var steady', v.varSteady.toStringAsFixed(0), AppColors.blue),
      StatChip('Var risky', v.varRisky.toStringAsFixed(0), AppColors.pink),
    ];
  },
  bigIdea: 'Both games average ₹0 a round, so their expected values match. But the '
      'risky game\'s results sit far from that average, so players\' totals fan '
      'out wildly: a few get rich, most slowly lose. Variance measures this: the '
      'expected squared distance from the mean. Its square root, the standard '
      'deviation, is in rupees. Spread after n rounds grows like sd × √n.',
  formula: (sim) {
    final v = sim as VarianceSim;
    return 'Var(X) = E[(X − μ)²] · risky: ${v.k}²×1/${v.k + 1} + 1²×${v.k}/${v.k + 1} = ${v.k} · '
        'sd = ${math.sqrt(v.k).toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: make the risky game riskier',
  buildTryIt: (sim) {
    final v = sim as VarianceSim;
    return watch(
      v,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            left: 'win ₹1',
            right: '₹20',
            value: v.k.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: 'win ₹${v.k}, 1 in ${v.k + 1}',
            onChanged: (x) => v.change(() => v.k = x.round()),
          ),
          TryNote('Win ₹${v.k} with chance 1/${v.k + 1}, otherwise lose ₹1: still ₹0 on average. '
              'At ₹1 the two games are identical.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'Two investments both average 8% a year. A has variance 1, B has variance 25. '
          'Which is riskier?',
      options: ['A', 'B', 'Same risk', 'Can\'t tell'],
      answer: 1,
      explanation: 'Same mean, but B\'s results swing much further from it.',
    ),
    QuizQuestion(
      prompt: 'X is +1 or −1 with equal chance. What is Var(X)?',
      options: ['0', '0.5', '1', '2'],
      answer: 2,
      explanation: 'The mean is 0, and both values are 1 away from it: (1² + 1²)/2 = 1.',
    ),
    QuizQuestion(
      prompt: 'If a variance is 16, the standard deviation is…',
      options: ['4', '8', '16', '256'],
      answer: 0,
      explanation: 'The sd is the square root of the variance: √16 = 4.',
    ),
  ],
);
