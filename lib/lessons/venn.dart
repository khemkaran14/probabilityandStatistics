import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

/// Darts land uniformly in a unit square holding two circles, A and B.
class VennSim extends LessonSim {
  VennSim({math.Random? rng}) : _rng = rng ?? math.Random();

  /// Small enough that both circles stay inside the square at [maxSeparation].
  static const double radius = 0.22;
  static const double maxSeparation = 0.56;

  /// Most darts kept for drawing; counting continues beyond this.
  static const int maxDrawn = 700;

  final math.Random _rng;

  /// Distance between the circle centres (0 = same circle).
  double separation = 0.26;

  final List<Offset> darts = [];
  int total = 0;
  int inA = 0;
  int inB = 0;
  int inBoth = 0;

  double _timer = 0;

  Offset get centreA => Offset(0.5 - separation / 2, 0.5);
  Offset get centreB => Offset(0.5 + separation / 2, 0.5);

  bool isInA(Offset p) => (p - centreA).distance <= radius;
  bool isInB(Offset p) => (p - centreB).distance <= radius;

  /// Exact areas (the true probabilities).
  double get pA => math.pi * radius * radius;
  double get pBoth {
    final d = separation;
    if (mutuallyExclusive) return 0;
    if (d == 0) return pA;
    final r = radius;
    return 2 * r * r * math.acos(d / (2 * r)) - d / 2 * math.sqrt(4 * r * r - d * d);
  }

  double get pEither => 2 * pA - pBoth;

  bool get mutuallyExclusive => separation >= 2 * radius - 1e-9;

  double get estA => total == 0 ? 0 : inA / total;
  double get estB => total == 0 ? 0 : inB / total;
  double get estBoth => total == 0 ? 0 : inBoth / total;
  double get estEither => total == 0 ? 0 : (inA + inB - inBoth) / total;

  double get _rate => total < 30 ? 6 : (total < 200 ? 30 : 90);

  @override
  void advance(double dt) {
    _timer += dt * _rate;
    while (_timer >= 1) {
      _timer -= 1;
      _throw();
    }
    notifyListeners();
  }

  void _throw() {
    final p = Offset(_rng.nextDouble(), _rng.nextDouble());
    total++;
    final a = isInA(p);
    final b = isInB(p);
    if (a) inA++;
    if (b) inB++;
    if (a && b) inBoth++;
    if (darts.length < maxDrawn) darts.add(p);
  }

  void throwMany(int count) {
    for (var i = 0; i < count; i++) {
      _throw();
    }
    notifyListeners();
  }

  void setSeparation(double value) {
    separation = value;
    reset();
  }

  @override
  void step() {
    _throw();
    notifyListeners();
  }

  @override
  void reset() {
    darts.clear();
    total = inA = inB = inBoth = 0;
    _timer = 0;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class VennPainter extends CustomPainter {
  VennPainter(this.sim) : super(repaint: sim);

  final VennSim sim;

  static const double aspectRatio = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 14.0;
    final side = math.min(size.width, size.height) - pad * 2;
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    Offset toCanvas(Offset p) => origin + Offset(p.dx * side, p.dy * side);

    // Sample space.
    canvas.drawRRect(
      RRect.fromRectAndRadius(origin & Size(side, side), const Radius.circular(14)),
      Paint()..color = Colors.white,
    );
    _text(canvas, 'everything that can happen', origin + Offset(side / 2, 14), 11, AppColors.muted);

    // Circles.
    final r = VennSim.radius * side;
    for (final (c, color) in [(sim.centreA, AppColors.pink), (sim.centreB, AppColors.cyan)]) {
      canvas.drawCircle(toCanvas(c), r, Paint()..color = color.withValues(alpha: 0.18));
      canvas.drawCircle(
        toCanvas(c),
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Darts.
    final dotR = math.max(1.8, side * 0.007);
    for (final p in sim.darts) {
      final a = sim.isInA(p);
      final b = sim.isInB(p);
      final color = a && b
          ? AppColors.violet
          : a
              ? AppColors.pink
              : b
                  ? AppColors.cyan
                  : AppColors.peg.withValues(alpha: 0.7);
      canvas.drawCircle(toCanvas(p), dotR, Paint()..color = color);
    }

    // Labels.
    _text(canvas, 'A', toCanvas(sim.centreA) - Offset(r * 0.55, r * 0.75), 22, AppColors.pink);
    _text(canvas, 'B', toCanvas(sim.centreB) + Offset(r * 0.55, -r * 0.75), 22, AppColors.cyan);
    if (!sim.mutuallyExclusive) {
      _text(canvas, 'A and B', toCanvas(const Offset(0.5, 0.5)) + Offset(0, r * 1.25), 13, AppColors.violet);
    } else {
      _text(canvas, 'no overlap: mutually exclusive', origin + Offset(side / 2, side - 18), 12, AppColors.violet);
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
  bool shouldRepaint(covariant VennPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec vennLesson = LessonSpec(
  id: 'venn',
  chapterLabel: 'Ch 3 · Probability basics',
  title: const [
    TitlePart('Why '),
    TitlePart('A or B', AppColors.pink),
    TitlePart(' isn\'t just '),
    TitlePart('A + B', AppColors.cyan),
  ],
  subtitle: 'Addition rule & Venn diagrams · 2-minute animated lesson',
  createSim: () => VennSim(),
  visualAspectRatio: VennPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: VennPainter(sim as VennSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final v = sim as VennSim;
    return [
      StatChip('darts', '${v.total}', AppColors.yellow),
      StatChip('in A or B', '${(v.estEither * 100).toStringAsFixed(1)}%', AppColors.pink),
      StatChip('in both', '${(v.estBoth * 100).toStringAsFixed(1)}%', AppColors.violet),
    ];
  },
  bigIdea: 'Each dart is one random outcome, so the share of darts in a region is '
      'its probability. Add the darts in A to the darts in B and every purple '
      'dart in the overlap gets counted twice. Subtract the overlap once and the '
      'count is right. If the circles don\'t touch, there is nothing to subtract.',
  formula: (sim) {
    final v = sim as VennSim;
    return 'P(A or B) = P(A) + P(B) − P(A and B)\n'
        '= ${v.estA.toStringAsFixed(3)} + ${v.estB.toStringAsFixed(3)} − ${v.estBoth.toStringAsFixed(3)} '
        '= ${v.estEither.toStringAsFixed(3)}  (true ${v.pEither.toStringAsFixed(3)})';
  },
  tryItTitle: 'Try it: pull the circles apart',
  buildTryIt: (sim) => _VennControls(sim: sim as VennSim),
  quiz: const [
    QuizQuestion(
      prompt: 'In a class, 60% play cricket, 40% play football and 25% play both. '
          'What share plays at least one?',
      options: ['100%', '75%', '65%', '25%'],
      answer: 1,
      explanation: '60% + 40% − 25% = 75%. The 25% who play both were counted twice.',
    ),
    QuizQuestion(
      prompt: 'When can you simply add P(A) + P(B)?',
      options: [
        'Always',
        'When A and B can\'t happen together',
        'When P(A) = P(B)',
        'When both are below 50%',
      ],
      answer: 1,
      explanation: 'Mutually exclusive events have no overlap, so P(A and B) = 0 and '
          'there is nothing to subtract.',
    ),
    QuizQuestion(
      prompt: 'Roll one die. A = "even", B = "greater than 3". What is P(A or B)?',
      options: ['1/2', '2/3', '5/6', '1'],
      answer: 1,
      explanation: 'A = {2,4,6}, B = {4,5,6}, both = {4,6}. 3/6 + 3/6 − 2/6 = 4/6 = 2/3: '
          'the outcomes 2, 4, 5, 6.',
    ),
  ],
);

class _VennControls extends StatelessWidget {
  const _VennControls({required this.sim});
  final VennSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('overlap', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              Expanded(
                child: Slider(
                  value: sim.separation,
                  min: 0.08,
                  max: VennSim.maxSeparation,
                  divisions: 8,
                  onChanged: sim.setSeparation,
                ),
              ),
              const Text('apart', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ],
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  sim.mutuallyExclusive ? 'Mutually exclusive!' : 'Overlap: ${(sim.pBoth * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => sim.throwMany(500),
                child: const Text('Throw 500', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
