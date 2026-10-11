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

// ---------------------------------------------------------------------------
// Distributions
// ---------------------------------------------------------------------------

/// log Γ(x) for x > 0 (Lanczos approximation).
double lgamma(double x) {
  if (x < 0.5) return math.log(math.pi / math.sin(math.pi * x)) - lgamma(1 - x);
  const g = 7.0;
  const c = [
    0.99999999999980993,
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
  ];
  x -= 1;
  var a = c[0];
  final t = x + g + 0.5;
  for (var i = 1; i < 9; i++) {
    a += c[i] / (x + i);
  }
  return 0.5 * math.log(2 * math.pi) + (x + 0.5) * math.log(t) - t + math.log(a);
}

double normalPdf(double x, [double mu = 0, double sd = 1]) =>
    math.exp(-0.5 * math.pow((x - mu) / sd, 2)) / (sd * math.sqrt(2 * math.pi));

/// Φ(z), accurate to about 1e-7 (Abramowitz & Stegun 7.1.26 on erf).
double normalCdf(double z) {
  final x = z.abs() / math.sqrt2;
  final t = 1 / (1 + 0.3275911 * x);
  final erf = 1 -
      (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) *
          t *
          math.exp(-x * x);
  return z >= 0 ? 0.5 * (1 + erf) : 0.5 * (1 - erf);
}

double binomPmf(int n, int k, double p) {
  if (k < 0 || k > n) return 0;
  final logC = lgamma(n + 1.0) - lgamma(k + 1.0) - lgamma(n - k + 1.0);
  if (p == 0) return k == 0 ? 1 : 0;
  if (p == 1) return k == n ? 1 : 0;
  return math.exp(logC + k * math.log(p) + (n - k) * math.log(1 - p));
}

double poissonPmf(double lambda, int k) => math.exp(k * math.log(lambda) - lambda - lgamma(k + 1.0));

double gammaPdf(double x, double shape, [double rate = 1]) =>
    x <= 0 ? 0 : math.exp(shape * math.log(rate) + (shape - 1) * math.log(x) - rate * x - lgamma(shape));

double betaPdf(double x, double a, double b) => x <= 0 || x >= 1
    ? 0
    : math.exp((a - 1) * math.log(x) + (b - 1) * math.log(1 - x) + lgamma(a + b) - lgamma(a) - lgamma(b));

double tPdf(double x, double df) => math.exp(
    lgamma((df + 1) / 2) - lgamma(df / 2) - 0.5 * math.log(df * math.pi) - (df + 1) / 2 * math.log(1 + x * x / df));

double chi2Pdf(double x, double df) => gammaPdf(x, df / 2, 0.5);

double fPdf(double x, double d1, double d2) => x <= 0
    ? 0
    : math.exp(0.5 * (d1 * math.log(d1 * x) + d2 * math.log(d2) - (d1 + d2) * math.log(d1 * x + d2)) -
        math.log(x) -
        (lgamma(d1 / 2) + lgamma(d2 / 2) - lgamma((d1 + d2) / 2)));

/// Exponential draw with the given rate.
double expDraw(math.Random rng, double rate) => -math.log(1 - rng.nextDouble()) / rate;

/// Poisson draw (Knuth's method; fine for small λ).
int poissonDraw(math.Random rng, double lambda) {
  final l = math.exp(-lambda);
  var k = 0;
  var p = 1.0;
  do {
    k++;
    p *= rng.nextDouble();
  } while (p > l);
  return k - 1;
}

/// Counts of [values] in [bins] equal bins over [lo, hi); out-of-range values are dropped.
List<int> binCounts(Iterable<double> values, double lo, double hi, int bins) {
  final c = List.filled(bins, 0);
  final w = (hi - lo) / bins;
  for (final v in values) {
    if (v < lo || v >= hi) continue;
    c[((v - lo) / w).floor().clamp(0, bins - 1)]++;
  }
  return c;
}

// ---------------------------------------------------------------------------
// Plotting
// ---------------------------------------------------------------------------

/// Maps data coordinates into a rectangle on the canvas.
class Plot {
  Plot(this.rect, {required this.x0, required this.x1, this.y0 = 0, required this.y1});

  final Rect rect;
  final double x0, x1, y0, y1;

  double x(double v) => rect.left + (v - x0) / (x1 - x0) * rect.width;
  double y(double v) => rect.bottom - (v - y0) / (y1 - y0) * rect.height;
  Offset at(double vx, double vy) => Offset(x(vx), y(vy));

  /// Baseline with tick labels under it.
  void axis(Canvas canvas, List<double> ticks, {String Function(double)? format, String? title}) {
    line(canvas, Offset(rect.left, rect.bottom), Offset(rect.right, rect.bottom), AppColors.peg);
    for (final t in ticks) {
      label(canvas, format?.call(t) ?? _trim(t), Offset(x(t), rect.bottom + 10), size: 10, color: AppColors.muted);
    }
    if (title != null) {
      label(canvas, title, Offset(rect.right, rect.bottom + 24),
          size: 10, color: AppColors.muted, align: TextAlign.right);
    }
  }

  /// y = f(x) across the plot; optional translucent fill under it.
  void curve(Canvas canvas, double Function(double) f, Color color,
      {double width = 2.5, bool fill = false, double? from, double? to, int steps = 160}) {
    final a = from ?? x0, b = to ?? x1;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final vx = a + (b - a) * i / steps;
      final vy = f(vx).clamp(y0, y1 * 1.2).toDouble();
      final p = Offset(x(vx), math.max(rect.top - 6, y(vy)));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    if (fill) {
      final area = Path.from(path)
        ..lineTo(x(b), y(y0))
        ..lineTo(x(a), y(y0))
        ..close();
      canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.25));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Histogram scaled as a density (area 1), so a pdf can be drawn on top.
  void densityBars(Canvas canvas, List<int> counts, double lo, double hi, Color color, {int? total}) {
    final n = total ?? counts.fold<int>(0, (a, b) => a + b);
    if (n == 0) return;
    final w = (hi - lo) / counts.length;
    for (var i = 0; i < counts.length; i++) {
      final d = counts[i] / (n * w);
      final top = math.max(rect.top, y(d));
      canvas.drawRect(
        Rect.fromLTRB(x(lo + i * w) + 0.5, top, x(lo + (i + 1) * w) - 0.5, y(y0)),
        Paint()..color = color,
      );
    }
  }

  /// Bars of height [values] centred on the integers [first], first + 1, …
  void intBars(Canvas canvas, List<double> values, int first, Color Function(int k) color, {double widthFrac = 0.7}) {
    final w = (x(1) - x(0)) * widthFrac;
    for (var i = 0; i < values.length; i++) {
      bar(canvas, x((first + i).toDouble()), w, y(y0), y(y0) - y(values[i].clamp(y0, y1)), color(first + i));
    }
  }

  /// Dots marking theoretical values on top of [intBars].
  void intDots(Canvas canvas, List<double> values, int first, Color color) {
    for (var i = 0; i < values.length; i++) {
      final c = at((first + i).toDouble(), values[i].clamp(y0, y1));
      canvas.drawCircle(c, 4, Paint()..color = color);
      ring(canvas, c, 4, Colors.white, width: 1.5);
    }
  }
}

String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
