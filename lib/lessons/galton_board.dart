import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

class _Ball {
  _Ball(this.path, this.color);

  /// One entry per row: true = bounced right.
  final List<bool> path;
  final Color color;

  /// Progress in rows (0 → rows). Fraction = position between rows.
  double t = 0;

  int rightsBefore(int row) {
    var count = 0;
    for (var i = 0; i < row && i < path.length; i++) {
      if (path[i]) count++;
    }
    return count;
  }
}

class GaltonSim extends LessonSim {
  GaltonSim({this.rows = 8}) : bins = List<int>.filled(rows + 1, 0);

  final int rows;

  /// Probability of bouncing right at each peg ("tilt").
  double p = 0.5;

  final List<_Ball> balls = [];
  List<int> bins;
  int landed = 0;

  static const double rowTime = 0.11; // seconds per row at 1×
  static const double spawnEvery = 0.16;

  final math.Random _rng = math.Random();
  double _spawnTimer = spawnEvery;
  int _colorIndex = 0;

  double get observedMean {
    if (landed == 0) return 0;
    var sum = 0;
    for (var b = 0; b < bins.length; b++) {
      sum += b * bins[b];
    }
    return sum / landed;
  }

  double get expectedMean => rows * p;

  @override
  void advance(double dt) {
    _spawnTimer += dt;
    while (_spawnTimer >= spawnEvery) {
      _spawnTimer -= spawnEvery;
      _spawn();
    }
    final rowsMoved = dt / rowTime;
    for (final ball in balls) {
      ball.t += rowsMoved;
    }
    balls.removeWhere((ball) {
      if (ball.t < rows) return false;
      bins[ball.rightsBefore(rows)]++;
      landed++;
      return true;
    });
    notifyListeners();
  }

  void _spawn() {
    final path = List<bool>.generate(rows, (_) => _rng.nextDouble() < p);
    final color = AppColors.rainbow[_colorIndex % AppColors.rainbow.length];
    _colorIndex++;
    balls.add(_Ball(path, color));
  }

  @override
  void step() => advance(rowTime);

  @override
  void reset() {
    balls.clear();
    bins = List<int>.filled(rows + 1, 0);
    landed = 0;
    _spawnTimer = spawnEvery;
    notifyListeners();
  }

  void setP(double value) {
    p = value;
    reset();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class GaltonPainter extends CustomPainter {
  GaltonPainter(this.sim) : super(repaint: sim);

  final GaltonSim sim;

  static const double aspectRatio = 0.80; // width / height

  @override
  void paint(Canvas canvas, Size size) {
    final n = sim.rows;
    final w = size.width;
    final h = size.height;
    final dx = w / (n + 2);
    final dy = dx * 0.78;
    final cx = w / 2;
    final boardTop = dx * 0.7;
    final boardBottom = boardTop + n * dy;
    final histTop = boardBottom + dx * 0.15;
    final histBottom = h - 24;
    final pegR = math.max(2.5, dx * 0.09);
    final ballR = math.max(4.0, dx * 0.19);

    double xFor(double unitsFromCentre) => cx + unitsFromCentre * dx;

    // Bin dividers (faint).
    final divider = Paint()
      ..color = AppColors.peg.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (var b = 0; b <= n + 1; b++) {
      final x = xFor(b - n / 2 - 0.5);
      canvas.drawLine(Offset(x, histTop), Offset(x, histBottom), divider);
    }

    // Pegs.
    final pegPaint = Paint()..color = AppColors.peg;
    for (var r = 0; r < n; r++) {
      for (var i = 0; i <= r; i++) {
        canvas.drawCircle(Offset(xFor(i - r / 2), boardTop + r * dy), pegR, pegPaint);
      }
    }

    // Histogram bars.
    var maxBin = 0;
    for (final c in sim.bins) {
      maxBin = math.max(maxBin, c);
    }
    final sigma = math.sqrt(n * sim.p * (1 - sim.p));
    final mu = n * sim.p;
    final curvePeak = sigma > 0.15 ? sim.landed / (sigma * math.sqrt(2 * math.pi)) : 0.0;
    final scaleMax = math.max(10.0, math.max(maxBin.toDouble(), curvePeak) * 1.08);
    final histH = histBottom - histTop;
    final barW = dx * 0.78;

    for (var b = 0; b <= n; b++) {
      final count = sim.bins[b];
      if (count == 0) continue;
      final barH = count / scaleMax * histH;
      final x = xFor(b - n / 2);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x - barW / 2, histBottom - barH, barW, barH),
        topLeft: Radius.circular(barW * 0.3),
        topRight: Radius.circular(barW * 0.3),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = AppColors.rainbow[b % AppColors.rainbow.length],
      );
    }

    // Expected bell curve once there's enough data.
    if (sim.landed >= 20 && sigma > 0.15) {
      final path = Path();
      var first = true;
      for (var x = -0.5; x <= n + 0.5; x += 0.05) {
        final density = math.exp(-math.pow(x - mu, 2) / (2 * sigma * sigma)) /
            (sigma * math.sqrt(2 * math.pi));
        final y = histBottom - sim.landed * density / scaleMax * histH;
        final px = xFor(x - n / 2);
        if (first) {
          path.moveTo(px, y);
          first = false;
        } else {
          path.lineTo(px, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Falling balls (with a little bounce between pegs).
    for (final ball in sim.balls) {
      final k = math.min(ball.t.floor(), n - 1);
      final f = (ball.t - k).clamp(0.0, 1.0);
      final eased = Curves.easeInOut.transform(f);
      final x0 = ball.rightsBefore(k) - k / 2;
      final x1 = ball.rightsBefore(k + 1) - (k + 1) / 2;
      final ux = x0 + (x1 - x0) * eased;
      final hop = math.sin(math.pi * f) * 0.35;
      final y = boardTop + (k + f - hop) * dy - pegR - ballR;
      final centre = Offset(xFor(ux), y);
      canvas.drawCircle(
        centre,
        ballR * 1.7,
        Paint()
          ..color = ball.color.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(centre, ballR, Paint()..color = ball.color);
    }

    // Axis labels.
    _label(canvas, '0 rights', Offset(xFor(-n / 2), h - 12));
    _label(canvas, '${n ~/ 2}', Offset(cx, h - 12));
    _label(canvas, '$n rights', Offset(xFor(n / 2), h - 12));
  }

  void _label(Canvas canvas, String text, Offset centre) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant GaltonPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec galtonLesson = LessonSpec(
  id: 'galton',
  chapterLabel: 'Ch 7 · Discrete distributions',
  title: const [
    TitlePart('Why does '),
    TitlePart('everything', AppColors.pink),
    TitlePart(' end up as a '),
    TitlePart('bell', AppColors.violet),
    TitlePart('?'),
  ],
  subtitle: 'The Galton board · 2-minute animated lesson',
  createSim: () => GaltonSim(),
  visualAspectRatio: GaltonPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: GaltonPainter(sim as GaltonSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final g = sim as GaltonSim;
    return [
      StatChip('balls landed', '${g.landed}', AppColors.yellow),
      StatChip('avg rights', g.observedMean.toStringAsFixed(2), AppColors.cyan),
      StatChip('rows', '${g.rows}', AppColors.pink),
    ];
  },
  bigIdea: 'Every ball makes 8 coin-flip choices: left or right. Getting all 8 '
      'the same way is rare, so most balls pile up in the middle. That pile '
      'is the binomial distribution, and it looks like a bell.',
  formula: (sim) {
    final g = sim as GaltonSim;
    return 'μ = n·p = ${g.rows} × ${g.p.toStringAsFixed(2)} = '
        '${g.expectedMean.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: tilt the board',
  buildTryIt: (sim) => _TiltControl(sim: sim as GaltonSim),
  quiz: const [
    QuizQuestion(
      prompt: 'Each ball bounces off 8 pegs, 50/50 left or right. '
          'Which bin collects the most balls?',
      options: ['The far-left bin', 'The middle bin (4 rights)', 'All bins equally', 'The far-right bin'],
      answer: 1,
      explanation: '70 different paths lead to 4 rights, but only 1 path leads '
          'to 0 rights. More paths means more balls.',
    ),
    QuizQuestion(
      prompt: 'You tilt the board so p(right) = 0.75. What happens to the bell?',
      options: ['It gets taller', 'It slides to the right', 'It becomes flat', 'Nothing changes'],
      answer: 1,
      explanation: 'The centre moves to μ = 8 × 0.75 = 6, so the pile shifts right.',
    ),
    QuizQuestion(
      prompt: 'How many different paths lead to the far-left bin (0 rights)?',
      options: ['0', '1', '8', '70'],
      answer: 1,
      explanation: 'All 8 bounces must go left. There is exactly one way to do '
          'that: C(8, 0) = 1.',
    ),
  ],
);

class _TiltControl extends StatelessWidget {
  const _TiltControl({required this.sim});
  final GaltonSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('left', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              Expanded(
                child: Slider(
                  value: sim.p,
                  min: 0.1,
                  max: 0.9,
                  divisions: 16,
                  label: sim.p.toStringAsFixed(2),
                  onChanged: sim.setP,
                ),
              ),
              const Text('right', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'p(right) = ${sim.p.toStringAsFixed(2)}',
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag it and watch the bell slide sideways.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
