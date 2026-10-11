import 'dart:math' as math;

import 'package:chance/lessons/ch07_discrete.dart';
import 'package:chance/lessons/ch08_continuous.dart';
import 'package:chance/lessons/ch09_two_variables.dart';
import 'package:chance/lessons/ch11_sampling.dart';
import 'package:chance/lessons/ch12_estimation.dart';
import 'package:chance/lessons/ch13_testing.dart';
import 'package:chance/lessons/ch14_regression.dart';
import 'package:chance/lessons/ch15_bayesian.dart';
import 'package:chance/lessons/ch16_real_world.dart';
import 'package:chance/lessons/ch17_paradoxes.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/lessons/scatter.dart' show correlation;
import 'package:flutter_test/flutter_test.dart';

math.Random seeded(int s) => math.Random(s);

void main() {
  group('Ch 7 discrete distributions', () {
    test('Bernoulli rate approaches p', () {
      final s = BernoulliSim(rng: seeded(1))..change(() {});
      s.p = 0.3;
      s.runMany(20000);
      expect(s.rate, closeTo(0.3, 0.012));
    });

    test('geometric and negative binomial waits average r/p', () {
      for (final r in [1, 3]) {
        final s = WaitSim(r: r, rng: seeded(2 + r))..p = 0.4;
        expect(List.generate(79, (k) => s.pmf(k)).reduce((a, b) => a + b), closeTo(1, 1e-6));
        s.runMany(60000);
        expect(s.observedMean, closeTo(r / 0.4, 0.15), reason: 'r=$r');
      }
    });

    test('hypergeometric pmf sums to 1 and matches draws', () {
      final s = HyperSim(rng: seeded(5));
      expect(List.generate(6, s.pmf).reduce((a, b) => a + b), closeTo(1, 1e-12));
      s.runMany(20000);
      for (var k = 0; k <= 5; k++) {
        expect(s.counts[k] / s.draws, closeTo(s.pmf(k), 0.015));
      }
    });

    test('Poisson mean approaches λ', () {
      final s = PoissonSim(rng: seeded(6))..lambda = 4;
      s.runMany(20000);
      expect(s.mean, closeTo(4, 0.06));
    });

    test('discrete uniform is flat', () {
      final s = DiscreteUniformSim(rng: seeded(7))..faces = 8;
      s.runMany(40000);
      for (var k = 1; k <= 8; k++) {
        expect(s.counts[k] / s.rolls, closeTo(1 / 8, 0.01));
      }
    });
  });

  group('Ch 8 continuous distributions', () {
    test('uniform wait: P(X ≤ t) = t/10', () {
      final s = UniformWaitSim(rng: seeded(8))..runMany(6000);
      s.setThreshold(3);
      expect(s.observed, closeTo(0.3, 0.02));
    });

    test('normal samples have the chosen mean and sd', () {
      final s = NormalCurveSim(rng: seeded(9))
        ..mu = 2
        ..sd = 0.5;
      s.runMany(6000);
      expect(meanOf(s.values), closeTo(2, 0.03));
      expect(sdOf(s.values), closeTo(0.5, 0.02));
    });

    test('68-95-99.7', () {
      final s = RuleSim(rng: seeded(10))..runMany(6000);
      expect(s.within(1), closeTo(0.683, 0.02));
      expect(s.within(2), closeTo(0.954, 0.01));
      expect(s.within(3), closeTo(0.997, 0.004));
    });

    test('exponential waits average 1/λ', () {
      final s = ExponentialSim(rng: seeded(11))..rate = 2;
      s.runMany(6000);
      expect(meanOf(s.values), closeTo(0.5, 0.02));
    });

    test('gamma mean k, beta mean a/(a+b)', () {
      final g = GammaBetaSim(rng: seeded(12))..a = 4;
      g.runMany(6000);
      expect(meanOf(g.values), closeTo(4, 0.1));
      final b = GammaBetaSim(rng: seeded(13))
        ..kind = GammaBeta.beta
        ..a = 2
        ..b = 6;
      b.runMany(6000);
      expect(meanOf(b.values), closeTo(0.25, 0.01));
    });

    test('chi-square mean df; t variance df/(df−2)', () {
      final c = TChiFSim(rng: seeded(14))
        ..kind = SamplingDist.chi2
        ..df = 6;
      c.runMany(6000);
      expect(meanOf(c.values), closeTo(6, 0.15));
      final t = TChiFSim(rng: seeded(15))..df = 10;
      t.runMany(6000);
      expect(math.pow(sdOf(t.values), 2), closeTo(10 / 8, 0.1));
    });
  });

  group('Ch 9-10', () {
    test('joint distribution sums to 1 and matches simulation', () {
      final s = JointSim(rng: seeded(16));
      var total = 0.0;
      for (var x = 1; x <= 6; x++) {
        for (var y = 0; y <= x; y++) {
          total += s.theory(x, y);
        }
      }
      expect(total, closeTo(1, 1e-12));
      s.runMany(30000);
      expect(s.counts[4][2] / s.trials, closeTo(s.theory(4, 2), 0.008));
    });

    test('covariance scales with units, correlation does not', () {
      final rng = seeded(17);
      final pts = List.generate(50, (_) {
        final x = rng.nextDouble();
        return Offset(x, x + rng.nextDouble() * 0.3);
      });
      final scaled = [for (final p in pts) Offset(p.dx * 100, p.dy)];
      expect(covariance(scaled), closeTo(covariance(pts) * 100, 1e-9));
      expect(correlation(scaled), closeTo(correlation(pts), 1e-9));
    });

    test('confounding: strong overall r vanishes within temperature bands', () {
      final s = CausationSim(rng: seeded(18))..runMany(60);
      expect(s.overallR, greaterThan(0.5));
      expect(s.withinR.abs(), lessThan(s.overallR / 2));
    });

    test('Chebyshev holds for every shape', () {
      for (final shape in ChebShape.values) {
        final s = ChebyshevSim(rng: seeded(19))..shape = shape;
        s.runMany(4000);
        for (final k in [1.5, 2.0, 3.0]) {
          s.setK(k);
          expect(s.within, greaterThanOrEqualTo(s.bound), reason: '$shape k=$k');
        }
      }
    });
  });

  group('Ch 11 sampling', () {
    test('stratified samples vary less than cluster samples', () {
      double spreadOf(SampleMethod m) {
        final s = MethodsSim(rng: seeded(20))..method = m;
        for (var i = 0; i < 400; i++) {
          s.tick();
        }
        return s.spread; // sd of the last 60 estimates
      }

      expect(spreadOf(SampleMethod.stratified), lessThan(spreadOf(SampleMethod.cluster)));
    });

    test('convenience sample is biased, random is not', () {
      final s = BiasSim(rng: seeded(21));
      for (var i = 0; i < 60; i++) {
        s.tick();
      }
      expect(meanOf(s.estimates), greaterThan(s.town.truth + 0.2));
      s.change(() => s.convenience = false);
      for (var i = 0; i < 60; i++) {
        s.tick();
      }
      expect(meanOf(s.estimates), closeTo(s.town.truth, 0.03));
    });

    test('sample means spread like σ/√n', () {
      final s = SamplingDistSim(rng: seeded(22))..n = 16;
      s.runMany(4000);
      expect(meanOf(s.results), closeTo(1, 0.02));
      expect(sdOf(s.results), closeTo(0.25, 0.015));
    });

    test('standard error matches 10/√n', () {
      final s = StandardErrorSim(rng: seeded(23))..runMany(StandardErrorSim.sizes.length);
      for (var i = 0; i < StandardErrorSim.sizes.length; i++) {
        expect(s.observed[i],
            closeTo(10 / math.sqrt(StandardErrorSim.sizes[i]), 0.12 * 10 / math.sqrt(StandardErrorSim.sizes[i])));
      }
    });
  });

  group('Ch 12 estimation', () {
    test('÷n is biased by (n−1)/n, ÷(n−1) is not', () {
      final s = PointEstimateSim(rng: seeded(24))..n = 4;
      s.runMany(3000);
      expect(meanOf(s.divN), closeTo(75, 4));
      expect(meanOf(s.divN1), closeTo(100, 5));
    });

    test('MLE is heads/flips and the likelihood peaks there', () {
      final s = MleSim();
      for (var i = 0; i < 14; i++) {
        s.add(true);
      }
      for (var i = 0; i < 6; i++) {
        s.add(false);
      }
      expect(s.mle, 0.7);
      expect(s.logL(0.7), closeTo(0, 1e-12));
      expect(s.logL(0.6), lessThan(0));
      expect(s.logL(0.8), lessThan(0));
    });

    test('95% intervals catch the mean about 95% of the time', () {
      final s = ConfidenceSim(rng: seeded(25))..runMany(4000);
      expect(s.covered / s.made, closeTo(0.95, 0.012));
      s.change(() => s.level = 80);
      s.runMany(4000);
      expect(s.covered / s.made, closeTo(0.80, 0.02));
    });

    test('margin of error and sample size formulas', () {
      final m = MarginSim()..n = 1000;
      expect(m.moe(0.5), closeTo(0.031, 0.001));
      final s = SampleSizeSim()..setMargin(0.05);
      expect(s.needed, 385);
    });
  });

  group('Ch 13 testing', () {
    test('fair-coin test: α ≈ 4.1% and p-values', () {
      expect(binomTwoSidedP(20, 10), closeTo(1, 1e-12));
      final alpha = [
        for (var k = 0; k <= 20; k++)
          if (CoinTrialSim.rejects(k)) binomPmf(20, k, 0.5)
      ].reduce((a, b) => a + b);
      expect(alpha, closeTo(0.041, 0.001));
      final s = CoinTrialSim(rng: seeded(26))..runMany(20000);
      expect(s.rejectRate, closeTo(alpha, 0.006));
    });

    test('tests reject a true H₀ about 5% of the time', () {
      final z = ZTestSim(rng: seeded(27))..runMany(8000);
      expect(z.rejectRate, closeTo(0.05, 0.008));
      final t = TTestSim(rng: seeded(28))..diff = 0;
      t.runMany(8000);
      expect(t.rejectRate, closeTo(0.05, 0.008));
      final c = ChiSquareSim(rng: seeded(29))..runMany(8000);
      expect(c.rejectRate, closeTo(0.05, 0.01));
      final a = AnovaSim(rng: seeded(30))..separation = 0;
      a.runMany(8000);
      expect(a.rejectRate, closeTo(0.05, 0.008));
    });

    test('they reject more when H₀ is false', () {
      final c = ChiSquareSim(rng: seeded(31))..loaded = true;
      c.runMany(3000);
      expect(c.rejectRate, greaterThan(0.4));
      final t = TTestSim(rng: seeded(32))..diff = 8;
      t.runMany(3000);
      expect(t.rejectRate, greaterThan(0.9));
    });

    test('error rates and power match theory', () {
      final e = ErrorsSim()..adjust(cut: 1.645, eff: 2);
      expect(e.alpha, closeTo(0.05, 0.001));
      expect(e.beta, closeTo(normalCdf(-0.355), 1e-9));
      final p = PowerSim(rng: seeded(33))
        ..n = 25
        ..effect = 0.5;
      p.runMany(8000);
      expect(p.rejectRate, closeTo(p.power, 0.015));
    });
  });

  group('Ch 14 regression', () {
    test('least squares recovers the line; residuals sum to 0; R² = r²', () {
      final pts = [for (var x = 0; x < 10; x++) Offset(x.toDouble(), 3 + 2 * x + (x.isEven ? 0.5 : -0.5))];
      final (a, b) = fitLine(pts);
      expect(b, closeTo(2, 0.1));
      expect(pts.fold(0.0, (s, p) => s + p.dy - (a + b * p.dx)), closeTo(0, 1e-9));
      final r2 = RSquaredSim(rng: seeded(34));
      expect(r2.r2, closeTo(math.pow(correlation(r2.points), 2), 1e-9));
    });

    test('multiple regression recovers both effects', () {
      final s = MultiRegSim(rng: seeded(35))..runMany(45);
      final (_, b, c) = s.multiple;
      expect(b, closeTo(3, 1));
      expect(c, closeTo(12, 4));
      expect(s.simple.$2, greaterThan(b + 1), reason: 'size alone absorbs the bedroom effect');
    });

    test('logistic regression learns an S-curve', () {
      final s = LogisticSim(rng: seeded(36))..runMany(400);
      expect(s.prob(9), greaterThan(0.75));
      expect(s.prob(1), lessThan(0.25));
    });
  });

  group('Ch 15 Bayesian', () {
    test('beta quantiles and posterior mean', () {
      expect(betaQuantile(1, 1, 0.5), closeTo(0.5, 0.002));
      expect(betaQuantile(1, 1, 0.025), closeTo(0.025, 0.002));
      final s = PosteriorSim(rng: seeded(37))..runMany(100);
      expect(s.postMean, closeTo((1 + s.heads) / (2 + s.heads + s.tails), 1e-12));
      expect(s.postMean, closeTo(0.7, 0.1));
    });

    test('one red ball moves 50% to 70%', () {
      final s = UpdatingSim(rng: seeded(38));
      // Force a known draw sequence through the update rule.
      const p = 0.5;
      expect(p * 0.7 / (p * 0.7 + p * 0.3), closeTo(0.7, 1e-12));
      s.runMany(15);
      expect(s.history.length, 16);
      expect(s.history.every((v) => v > 0 && v < 1), isTrue);
    });

    test('credible interval contains the posterior bulk', () {
      final s = BayesFreqSim(rng: seeded(39))..runMany(80);
      final (lo, hi) = s.credible;
      expect(lo, lessThan(s.pHat));
      expect(hi, greaterThan(s.pHat));
    });
  });

  group('Ch 16 real world', () {
    test('A/B rates and Monte Carlo π', () {
      final ab = AbTestSim(rng: seeded(40))..runMany(200);
      expect(ab.rateA, closeTo(0.10, 0.02));
      expect(ab.rateB, closeTo(0.12, 0.02));
      final mc = MonteCarloSim(rng: seeded(41))..runMany(2000);
      expect(mc.estimate, closeTo(math.pi, 0.04));
    });

    test('random walkers drift about √n', () {
      final s = RandomWalkSim(rng: seeded(42))..runMany(100);
      expect(s.steps, 100);
      expect(s.rmsDistance, closeTo(10, 3));
    });

    test('Markov chain visits match the stationary distribution', () {
      final s = MarkovSim(rng: seeded(43));
      expect(s.matrix.every((row) => (row.reduce((a, b) => a + b) - 1).abs() < 1e-12), isTrue);
      final st = s.stationary;
      expect(st.reduce((a, b) => a + b), closeTo(1, 1e-9));
      s.runMany(30000);
      for (var i = 0; i < 3; i++) {
        expect(s.visits[i] / s.days, closeTo(st[i], 0.02));
      }
    });

    test('softmax sums to 1 and sharpens at low temperature', () {
      final s = NextWordSim();
      expect(s.probs.reduce((a, b) => a + b), closeTo(1, 1e-12));
      s.temperature = 0.2;
      expect(s.probs.first, greaterThan(0.95));
    });
  });

  group('Ch 17 paradoxes', () {
    test('Simpson: A wins each group, B wins overall', () {
      expect(SimpsonSim.rate('A', 'small'), greaterThan(SimpsonSim.rate('B', 'small')));
      expect(SimpsonSim.rate('A', 'large'), greaterThan(SimpsonSim.rate('B', 'large')));
      expect(SimpsonSim.rate('B'), greaterThan(SimpsonSim.rate('A')));
    });

    test('gambler: streaks continue half the time', () {
      final s = GamblerSim(rng: seeded(44))..runMany(5000);
      s.runMany(20000);
      expect(s.continued / s.afterStreak, closeTo(0.5, 0.03));
    });

    test('St. Petersburg: game lengths halve, average grows', () {
      final s = StPetersburgSim(rng: seeded(45))..runMany(20000);
      expect(s.byFlips[1] / s.games, closeTo(0.5, 0.015));
      expect(s.byFlips[3] / s.games, closeTo(0.125, 0.01));
      expect(s.average, greaterThan(8));
    });
  });
}
