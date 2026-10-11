import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

class CoinFlipSim extends LessonSim {
  CoinFlipSim({math.Random? rng}) : _rng = rng ?? math.Random();

  /// Chance of heads on each flip.
  double p = 0.5;

  int flips = 0;
  int heads = 0;

  /// Running share of heads, sampled every [historyEvery] flips: entry i is
  /// the share after (i + 1) × [historyEvery] flips. Thinned as it grows so
  /// memory stays bounded however long the lesson runs.
  final List<double> history = [];
  int historyEvery = 1;

  /// Most recent results, newest last: true = heads.
  final List<bool> recent = [];

  /// 0 → 1 spin of the big coin for the flip in progress.
  double spin = 0;
  bool lastHeads = true;

  static const int maxHistory = 2000;
  static const int recentCount = 14;

  final math.Random _rng;

  /// Flips per second at 1×. Starts slow so single flips are visible, then
  /// speeds up so the long-run line appears within a minute.
  double get _rate => flips < 20 ? 3 : (flips < 100 ? 12 : 40);

  double get proportion => flips == 0 ? 0 : heads / flips;

  @override
  void advance(double dt) {
    spin += dt * _rate;
    while (spin >= 1) {
      spin -= 1;
      _flip();
    }
    notifyListeners();
  }

  void _flip() {
    final h = _rng.nextDouble() < p;
    flips++;
    if (h) heads++;
    lastHeads = h;
    recent.add(h);
    if (recent.length > recentCount) recent.removeAt(0);
    _record();
  }

  void _record() {
    if (flips % historyEvery != 0) return;
    history.add(proportion);
    if (history.length >= maxHistory) {
      // Keep entries at multiples of 2 × historyEvery.
      final thinned = [for (var i = 1; i < history.length; i += 2) history[i]];
      history
        ..clear()
        ..addAll(thinned);
      historyEvery *= 2;
    }
  }

  /// Instantly flips [count] coins (the "flip 100" button).
  void flipMany(int count) {
    for (var i = 0; i < count; i++) {
      _flip();
    }
    notifyListeners();
  }

  @override
  void step() {
    spin = 0;
    _flip();
    notifyListeners();
  }

  @override
  void reset() {
    flips = 0;
    heads = 0;
    spin = 0;
    history.clear();
    historyEvery = 1;
    recent.clear();
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

class CoinFlipPainter extends CustomPainter {
  CoinFlipPainter(this.sim) : super(repaint: sim);

  final CoinFlipSim sim;

  static const double aspectRatio = 0.85;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Big spinning coin -------------------------------------------------
    final coinR = w * 0.12;
    final coinC = Offset(w * 0.2, h * 0.17);
    final squash = math.cos(sim.spin * math.pi * 2).abs().clamp(0.08, 1.0);
    final showHeads = sim.spin < 0.25 || sim.spin > 0.75 ? sim.lastHeads : !sim.lastHeads;
    final coinColor = showHeads ? AppColors.yellow : AppColors.cyan;
    canvas.save();
    canvas.translate(coinC.dx, coinC.dy - math.sin(sim.spin * math.pi) * coinR * 0.5);
    canvas.scale(1, squash);
    canvas.drawCircle(Offset.zero, coinR, Paint()..color = coinColor);
    canvas.drawCircle(
      Offset.zero,
      coinR * 0.8,
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.restore();
    if (squash > 0.35) {
      _text(canvas, showHeads ? 'H' : 'T', coinC.translate(0, -math.sin(sim.spin * math.pi) * coinR * 0.5),
          size: coinR * 0.9 * squash, color: AppColors.ink, weight: FontWeight.w900);
    }

    // --- Recent results strip ---------------------------------------------
    final stripLeft = w * 0.38;
    final dotR = math.min(w * 0.026, 9.0);
    final gap = (w - stripLeft - 12) / CoinFlipSim.recentCount;
    for (var i = 0; i < sim.recent.length; i++) {
      final isH = sim.recent[i];
      final c = Offset(stripLeft + gap * (i + 0.5), h * 0.13);
      canvas.drawCircle(c, dotR, Paint()..color = isH ? AppColors.yellow : AppColors.cyan);
      _text(canvas, isH ? 'H' : 'T', c, size: dotR * 1.1, color: AppColors.ink, weight: FontWeight.w900);
    }
    _text(canvas, 'last ${CoinFlipSim.recentCount} flips', Offset(stripLeft + (w - stripLeft) / 2, h * 0.22),
        size: 11, color: AppColors.muted);

    // --- Running proportion chart ------------------------------------------
    const left = 34.0;
    final top = h * 0.33;
    final right = w - 14;
    final bottom = h - 26;
    final chartH = bottom - top;
    double yFor(double v) => bottom - v * chartH;

    final grid = Paint()
      ..color = AppColors.peg.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (final v in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      canvas.drawLine(Offset(left, yFor(v)), Offset(right, yFor(v)), grid);
      _text(canvas, v.toStringAsFixed(v == 0 || v == 1 ? 0 : 2), Offset(left - 16, yFor(v)),
          size: 10, color: AppColors.muted);
    }

    // True probability line (dashed).
    final target = Paint()
      ..color = AppColors.pink
      ..strokeWidth = 2.5;
    for (var x = left; x < right; x += 10) {
      canvas.drawLine(Offset(x, yFor(sim.p)), Offset(math.min(x + 5, right), yFor(sim.p)), target);
    }

    final n = sim.history.length;
    if (n > 1) {
      // x axis grows with the data so early wobble stays visible.
      final span = math.max(50, sim.flips).toDouble();
      double xAt(int i) => left + ((i + 1) * sim.historyEvery / span) * (right - left);
      final path = Path()..moveTo(xAt(0), yFor(sim.history.first));
      final stride = math.max(1, n ~/ 400);
      for (var i = stride; i < n; i += stride) {
        path.lineTo(xAt(i), yFor(sim.history[i]));
      }
      path.lineTo(xAt(n - 1), yFor(sim.history.last));
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.violet
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );
      final tip = Offset(xAt(n - 1), yFor(sim.history.last));
      canvas.drawCircle(tip, 5, Paint()..color = AppColors.violet);
    }

    _text(canvas, 'share of heads →', Offset(left + 52, top - 10), size: 11, color: AppColors.muted);
    _text(canvas, 'number of flips →', Offset((left + right) / 2, h - 11), size: 11, color: AppColors.muted);
  }

  void _text(
    Canvas canvas,
    String text,
    Offset centre, {
    double size = 12,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w700,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CoinFlipPainter oldDelegate) => oldDelegate.sim != sim;
}

// ---------------------------------------------------------------------------
// Lesson definition
// ---------------------------------------------------------------------------

final LessonSpec coinFlipsLesson = LessonSpec(
  id: 'coin_flips',
  chapterLabel: 'Ch 3 · Probability basics',
  title: const [
    TitlePart('Flip a coin '),
    TitlePart('enough', AppColors.orange),
    TitlePart(' times and the '),
    TitlePart('luck', AppColors.cyan),
    TitlePart(' washes out'),
  ],
  subtitle: 'Law of Large Numbers · 2-minute animated lesson',
  createSim: () => CoinFlipSim(),
  visualAspectRatio: CoinFlipPainter.aspectRatio,
  buildVisual: (sim) => CustomPaint(
    painter: CoinFlipPainter(sim as CoinFlipSim),
    child: const SizedBox.expand(),
  ),
  stats: (sim) {
    final c = sim as CoinFlipSim;
    return [
      StatChip('flips', '${c.flips}', AppColors.yellow),
      StatChip('heads', '${c.heads}', AppColors.orange),
      StatChip('share', c.proportion.toStringAsFixed(3), AppColors.violet),
    ];
  },
  bigIdea: 'Ten flips can easily give 7 heads. But the more you flip, the '
      'closer the share of heads gets to the true chance. Each flip is still '
      'random; it is the average that settles down.',
  formula: (sim) {
    final c = sim as CoinFlipSim;
    return 'heads / flips = ${c.heads} / ${c.flips} → p = ${c.p.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: load the coin',
  buildTryIt: (sim) => _CoinControls(sim: sim as CoinFlipSim),
  quiz: const [
    QuizQuestion(
      prompt: 'You flip a fair coin 10 times and get 7 heads. What best describes this?',
      options: ['The coin must be unfair', 'Normal luck for only 10 flips', 'Tails is now "due"', 'Impossible'],
      answer: 1,
      explanation: 'With only 10 flips, 7 heads happens about 12% of the time. '
          'Small samples wobble a lot.',
    ),
    QuizQuestion(
      prompt: 'After 10,000 flips of a fair coin, the share of heads will most likely be…',
      options: ['Exactly 0.5000', 'Very close to 0.5', 'Anywhere from 0 to 1', 'Above 0.6'],
      answer: 1,
      explanation: 'The Law of Large Numbers: the average gets close to the true '
          'probability, though rarely exactly equal to it.',
    ),
    QuizQuestion(
      prompt: 'You just saw 5 tails in a row on a fair coin. Chance the next flip is heads?',
      options: ['Higher than 50%', 'Lower than 50%', 'Exactly 50%', 'It depends on the last 100 flips'],
      answer: 2,
      explanation: 'Coins have no memory. The long-run average evens out by '
          'drowning past streaks in new flips, not by "correcting" them.',
    ),
  ],
);

class _CoinControls extends StatelessWidget {
  const _CoinControls({required this.sim});
  final CoinFlipSim sim;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('tails', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
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
              const Text('heads', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ],
          ),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'p(heads) = ${sim.p.toStringAsFixed(2)}',
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => sim.flipMany(100),
                child: const Text('Flip 100', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Load the coin and watch the purple line home in on the pink one.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
