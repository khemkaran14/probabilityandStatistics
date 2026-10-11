import 'dart:math' as math;

import 'package:chance/lessons/kit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Midpoint-rule integral.
double integrate(double Function(double) f, double a, double b, [int n = 20000]) {
  final h = (b - a) / n;
  var s = 0.0;
  for (var i = 0; i < n; i++) {
    s += f(a + (i + 0.5) * h);
  }
  return s * h;
}

void main() {
  test('lgamma matches factorials', () {
    expect(lgamma(5), closeTo(math.log(24), 1e-10));
    expect(lgamma(0.5), closeTo(math.log(math.sqrt(math.pi)), 1e-10));
    expect(lgamma(30), closeTo(math.log(8841761993739701954543616000000.0), 1e-8));
  });

  test('normal cdf', () {
    expect(normalCdf(0), closeTo(0.5, 1e-7));
    expect(normalCdf(1.96), closeTo(0.975, 1e-4));
    expect(normalCdf(-1), closeTo(0.158655, 1e-5));
  });

  test('pmfs sum to 1', () {
    expect(List.generate(21, (k) => binomPmf(20, k, 0.3)).reduce((a, b) => a + b), closeTo(1, 1e-9));
    expect(binomPmf(8, 4, 0.5), closeTo(70 / 256, 1e-12));
    expect(List.generate(60, (k) => poissonPmf(4, k)).reduce((a, b) => a + b), closeTo(1, 1e-9));
    expect(poissonPmf(2, 0), closeTo(math.exp(-2), 1e-12));
  });

  test('pdfs integrate to 1', () {
    expect(integrate((x) => normalPdf(x, 3, 2), -20, 26), closeTo(1, 1e-6));
    expect(integrate((x) => gammaPdf(x, 3, 1), 0, 60), closeTo(1, 1e-6));
    expect(integrate((x) => betaPdf(x, 2, 5), 0, 1), closeTo(1, 1e-5));
    expect(integrate((x) => tPdf(x, 5), -200, 200, 200000), closeTo(1, 1e-3));
    expect(integrate((x) => chi2Pdf(x, 4), 0, 80), closeTo(1, 1e-6));
    expect(integrate((x) => fPdf(x, 5, 10), 0, 200, 200000), closeTo(1, 1e-3));
  });

  test('known critical values', () {
    // 95% of t(14) lies within ±2.145.
    expect(integrate((x) => tPdf(x, 14), -2.145, 2.145), closeTo(0.95, 1e-3));
    // 5% of χ²(5) lies above 11.07.
    expect(integrate((x) => chi2Pdf(x, 5), 11.07, 80), closeTo(0.05, 1e-3));
    // 5% of F(2, 21) lies above 3.47.
    expect(integrate((x) => fPdf(x, 2, 21), 3.47, 300, 200000), closeTo(0.05, 1e-3));
  });

  test('random draws', () {
    final rng = math.Random(1);
    final p = List.generate(20000, (_) => poissonDraw(rng, 3));
    expect(meanOf(p), closeTo(3, 0.05));
    final e = List.generate(20000, (_) => expDraw(rng, 2));
    expect(meanOf(e), closeTo(0.5, 0.01));
    expect(binCounts([0.1, 0.5, 0.99, 1.0, -1], 0, 1, 2), [1, 2]);
  });
}
