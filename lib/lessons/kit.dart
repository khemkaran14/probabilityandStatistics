import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/theme/app_theme.dart';

/// Shared building blocks for lessons: a sim that ticks at a fixed rate,
/// canvas helpers, and the small controls used in "Try it" cards.

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

/// A sim that does one discrete thing ([tick]) every [interval] seconds.
abstract class TickSim extends LessonSim {
  TickSim({math.Random? rng}) : rng = rng ?? math.Random();

  final math.Random rng;
  double _timer = 0;

  /// Seconds per tick at 1×. May change as the lesson goes on.
  double get interval;

  /// 0 → 1 progress towards the next tick, for easing animations.
  double get phase => (_timer / interval).clamp(0.0, 1.0);

  /// Advance the lesson by one discrete step.
  void tick();

  /// Back to the starting state (timer already cleared).
  void restart();

  @override
  void advance(double dt) {
    _timer += dt;
    var guard = 0;
    while (_timer >= interval && guard++ < 500) {
      _timer -= interval;
      tick();
    }
    notifyListeners();
  }

  @override
  void step() {
    _timer = 0;
    tick();
    notifyListeners();
  }

  @override
  void reset() {
    _timer = 0;
    restart();
    notifyListeners();
  }

  /// Runs [count] ticks at once (the "do 100" buttons).
  void runMany(int count) {
    for (var i = 0; i < count; i++) {
      tick();
    }
    notifyListeners();
  }

  /// Applies a settings change and starts over.
  void change(VoidCallback update) {
    update();
    reset();
  }
}

/// Sample statistics shared by several lessons.
double meanOf(Iterable<num> xs) => xs.isEmpty ? 0 : xs.fold<double>(0, (a, b) => a + b) / xs.length;

/// Quantile with linear interpolation (the spreadsheet / numpy default).
double quantileOf(List<num> xs, double q) {
  if (xs.isEmpty) return 0;
  final s = [...xs]..sort();
  final pos = q * (s.length - 1);
  final lo = pos.floor();
  final hi = pos.ceil();
  return s[lo] + (s[hi] - s[lo]) * (pos - lo);
}

double sdOf(List<num> xs) {
  if (xs.length < 2) return 0;
  final m = meanOf(xs);
  return math.sqrt(xs.fold<double>(0, (a, x) => a + (x - m) * (x - m)) / (xs.length - 1));
}

/// Standard normal draw (Box–Muller).
double normalDraw(math.Random rng) {
  final u1 = 1 - rng.nextDouble();
  final u2 = rng.nextDouble();
  return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
}

int factorial(int n) => n <= 1 ? 1 : n * factorial(n - 1);

int permutations(int n, int r) {
  var p = 1;
  for (var i = 0; i < r; i++) {
    p *= n - i;
  }
  return p;
}

int combinations(int n, int r) => permutations(n, r) ~/ factorial(r);

// ---------------------------------------------------------------------------
// Canvas helpers
// ---------------------------------------------------------------------------

/// Draws [text] anchored at [at]: centred by default, or starting / ending
/// there for [TextAlign.left] / [TextAlign.right].
void label(
  Canvas canvas,
  String text,
  Offset at, {
  double size = 12,
  Color color = AppColors.ink,
  FontWeight weight = FontWeight.w800,
  TextAlign align = TextAlign.center,
  double? maxWidth,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color)),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: maxWidth == null ? 1 : 3,
  )..layout(maxWidth: maxWidth ?? double.infinity);
  final dx = switch (align) {
    TextAlign.left => 0.0,
    TextAlign.right => tp.width,
    _ => tp.width / 2,
  };
  tp.paint(canvas, at - Offset(dx, tp.height / 2));
}

void roundRect(Canvas canvas, Rect rect, Color color, {double radius = 8}) {
  canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), Paint()..color = color);
}

/// A vertical bar standing on [baseline] with rounded top corners.
void bar(Canvas canvas, double centreX, double width, double baseline, double height, Color color) {
  if (height <= 0) return;
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      Rect.fromLTWH(centreX - width / 2, baseline - height, width, height),
      topLeft: Radius.circular(math.min(width * 0.3, 8)),
      topRight: Radius.circular(math.min(width * 0.3, 8)),
    ),
    Paint()..color = color,
  );
}

void line(Canvas canvas, Offset a, Offset b, Color color, {double width = 2}) {
  canvas.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );
}

void dashedLine(Canvas canvas, Offset a, Offset b, Color color, {double width = 2, double dash = 6}) {
  final total = (b - a).distance;
  if (total == 0) return;
  final dir = (b - a) / total;
  for (var d = 0.0; d < total; d += dash * 2) {
    line(canvas, a + dir * d, a + dir * math.min(d + dash, total), color, width: width);
  }
}

void ring(Canvas canvas, Offset c, double r, Color color, {double width = 2}) {
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width,
  );
}

/// Draws a die face centred at [c].
void paintDie(Canvas canvas, Offset c, double size, int face, Color color) {
  final rect = Rect.fromCenter(center: c, width: size, height: size);
  canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(size * 0.2)), Paint()..color = color);
  const pips = <int, List<Offset>>{
    1: [Offset(0, 0)],
    2: [Offset(-1, -1), Offset(1, 1)],
    3: [Offset(-1, -1), Offset(0, 0), Offset(1, 1)],
    4: [Offset(-1, -1), Offset(1, -1), Offset(-1, 1), Offset(1, 1)],
    5: [Offset(-1, -1), Offset(1, -1), Offset(0, 0), Offset(-1, 1), Offset(1, 1)],
    6: [Offset(-1, -1), Offset(1, -1), Offset(-1, 0), Offset(1, 0), Offset(-1, 1), Offset(1, 1)],
  };
  for (final p in pips[face]!) {
    canvas.drawCircle(c + p * (size * 0.25), size * 0.085, Paint()..color = AppColors.ink);
  }
}

/// A [CustomPainter] that repaints whenever [sim] changes and delegates
/// drawing to a function, so lessons don't need a painter class each.
class SimPainter<T extends LessonSim> extends CustomPainter {
  SimPainter(this.sim, this.draw) : super(repaint: sim);

  final T sim;
  final void Function(Canvas canvas, Size size, T sim) draw;

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size, sim);

  @override
  bool shouldRepaint(covariant SimPainter<T> oldDelegate) => oldDelegate.sim != sim;
}

/// The lesson stage for a sim drawn by [draw].
Widget simCanvas<T extends LessonSim>(LessonSim sim, void Function(Canvas, Size, T) draw) =>
    CustomPaint(painter: SimPainter<T>(sim as T, draw), child: const SizedBox.expand());

// ---------------------------------------------------------------------------
// Try-it controls
// ---------------------------------------------------------------------------

/// A slider with words at each end.
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.left,
    required this.right,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.label,
  });

  final String left;
  final String right;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700);
    return Row(
      children: [
        Text(left, style: style),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: onChanged,
          ),
        ),
        Text(right, style: style),
      ],
    );
  }
}

/// Yellow monospace pill showing the current setting.
class ValueTag extends StatelessWidget {
  const ValueTag(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800)),
    );
  }
}

/// Grey hint under the controls.
class TryNote extends StatelessWidget {
  const TryNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: AppColors.muted, height: 1.35));
}

/// A tonal action button for "do it many times".
class ActionButton extends StatelessWidget {
  const ActionButton(this.text, this.onPressed, {super.key});
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.tonal(
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      );
}

/// Single-choice chips that wrap on narrow screens.
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({super.key, required this.options, required this.selected, required this.onSelected});

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in options.entries)
          ChoiceChip(
            label: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w800)),
            selected: e.key == selected,
            selectedColor: AppColors.yellow,
            onSelected: (_) => onSelected(e.key),
          ),
      ],
    );
  }
}

/// Rebuilds [builder] whenever [sim] changes.
Widget watch(LessonSim sim, Widget Function() builder) =>
    ListenableBuilder(listenable: sim, builder: (_, __) => builder());

/// A tag and buttons side by side, wrapping onto two lines on narrow phones.
class ControlRow extends StatelessWidget {
  const ControlRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: children,
      );
}
