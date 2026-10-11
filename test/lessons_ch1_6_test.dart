import 'dart:math' as math;

import 'package:chance/lessons/arrangements_repeats.dart';
import 'package:chance/lessons/bar_pie.dart';
import 'package:chance/lessons/birthday.dart';
import 'package:chance/lessons/box_plots.dart';
import 'package:chance/lessons/combinations.dart';
import 'package:chance/lessons/complement.dart';
import 'package:chance/lessons/conditional.dart';
import 'package:chance/lessons/discrete_continuous.dart';
import 'package:chance/lessons/events.dart';
import 'package:chance/lessons/expected_value.dart';
import 'package:chance/lessons/graphs_lie.dart';
import 'package:chance/lessons/histograms.dart';
import 'package:chance/lessons/independence.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/lessons/linearity.dart';
import 'package:chance/lessons/multiplication_principle.dart';
import 'package:chance/lessons/multiplication_rule.dart';
import 'package:chance/lessons/mutually_exclusive.dart';
import 'package:chance/lessons/outliers.dart';
import 'package:chance/lessons/percentiles.dart';
import 'package:chance/lessons/permutations.dart';
import 'package:chance/lessons/pigeonhole.dart';
import 'package:chance/lessons/pmf_cdf.dart';
import 'package:chance/lessons/scatter.dart';
import 'package:chance/lessons/skew.dart';
import 'package:chance/lessons/stem_leaf.dart';
import 'package:chance/lessons/total_probability.dart';
import 'package:chance/lessons/tree_diagrams.dart';
import 'package:chance/lessons/types_of_data.dart';
import 'package:chance/lessons/variance_rv.dart';
import 'package:chance/lessons/zscores.dart';
import 'package:flutter_test/flutter_test.dart';

math.Random seeded(int s) => math.Random(s);

void main() {
  group('kit', () {
    test('quantiles, sd and counting helpers', () {
      expect(quantileOf([1, 2, 3, 4], 0.5), 2.5);
      expect(quantileOf([5, 1, 3], 0), 1);
      expect(sdOf([2, 4, 4, 4, 5, 5, 7, 9]), closeTo(2.138, 0.001));
      expect(permutations(8, 3), 336);
      expect(combinations(10, 3), 120);
      expect(factorial(5), 120);
    });
  });

  group('Ch 1', () {
    test('types of data: every example is sorted into its bin', () {
      final sim = TypesOfDataSim()..runMany(kDataExamples.length);
      expect(sim.counts.values.reduce((a, b) => a + b), kDataExamples.length);
      expect(sim.counts.values.every((c) => c == 4), isTrue);
    });

    test('percentiles: the bubble sort finishes sorted', () {
      final sim = PercentileSim(rng: seeded(1));
      final original = [...sim.values]..sort();
      sim.runMany(400);
      expect(sim.sorted, isTrue);
      expect(sim.values, original);
      expect(sim.quantile(0.5), original[10]);
    });

    test('skew: the tail pulls the mean its way', () {
      for (final (shape, sign) in [(SkewShape.rightSkew, 1), (SkewShape.leftSkew, -1)]) {
        final sim = SkewSim(rng: seeded(2))..change(() {});
        sim.shape = shape;
        sim.runMany(1500);
        expect((sim.mean - sim.median).sign, sign, reason: '$shape');
      }
      final sym = SkewSim(rng: seeded(3))
        ..shape = SkewShape.symmetric
        ..runMany(1500);
      expect((sym.mean - sym.median).abs(), lessThan(0.01));
    });

    test('outliers: fences follow Q1 − k·IQR and catch an extreme value', () {
      final sim = OutlierSim(rng: seeded(4))..runMany(30);
      expect(sim.lowFence, closeTo(sim.q1 - 1.5 * sim.iqr, 1e-9));
      final before = sim.outlierCount;
      sim.addExtreme();
      expect(sim.outlierCount, greaterThanOrEqualTo(before));
      expect(sim.isOutlier(sim.points.last.$1), isTrue);
      sim.setK(3);
      expect(sim.highFence, closeTo(sim.q3 + 3 * sim.iqr, 1e-9));
    });

    test('z-scores: (x − μ) / σ', () {
      final sim = ZScoreSim()..setScores(maths: 84, english: 82);
      expect(sim.zMaths, closeTo(2.0, 1e-9));
      expect(sim.zEnglish, closeTo(2.0, 1e-9));
    });
  });

  group('Ch 2', () {
    test('bar & pie: vote shares approach the weights', () {
      final sim = BarPieSim(rng: seeded(5))..runMany(300);
      expect(sim.total, 300);
      expect(kFruits[sim.leader], 'Mango');
    });

    test('histograms: every value is counted for any bin count', () {
      final sim = HistogramSim(rng: seeded(6))..runMany(150);
      for (final b in [3, 10, 40]) {
        sim.setBins(b);
        expect(sim.counts.reduce((a, c) => a + c), sim.values.length);
      }
    });

    test('box plots: dots, then median, box and whiskers', () {
      final sim = BoxPlotSim(rng: seeded(7))..runMany(40);
      expect(sim.full, isTrue);
      sim.runMany(10);
      expect(sim.stage, 3);
    });

    test('scatter: correlation of a perfect line, and sign follows strength', () {
      expect(correlation([for (var i = 0; i < 10; i++) Offset(i / 10, 1 - i / 10)]), closeTo(-1, 1e-9));
      for (final s in [0.8, -0.8]) {
        final sim = ScatterSim(rng: seeded(8))..change(() => {});
        sim.strength = s;
        sim.runMany(40);
        expect(sim.r.sign, s.sign);
      }
    });

    test('stem and leaf: rows rebuild the data', () {
      final sim = StemLeafSim(rng: seeded(9))..runMany(StemLeafSim.n);
      final rebuilt = [
        for (final e in sim.rows.entries)
          for (final leaf in e.value) e.key * 10 + leaf,
      ]..sort();
      expect(rebuilt, [...sim.data]..sort());
    });

    test('how graphs lie: exaggeration grows as the axis starts higher', () {
      final sim = GraphsLieSim()..setStart(0);
      expect(sim.looksLike, closeTo(55 / 52, 1e-9));
      sim.setStart(50);
      expect(sim.looksLike, closeTo(2.5, 1e-9));
    });
  });

  group('Ch 3', () {
    test('events: frequency approaches |E| / |S|', () {
      final sim = EventsSim(rng: seeded(10))..runMany(30000);
      expect(sim.freq, closeTo(0.5, 0.01));
      expect(sim.faceCounts.reduce((a, b) => a + b), sim.rolls);
    });

    test('complement: 1 − (5/6)^n matches the dice', () {
      final sim = ComplementSim(rng: seeded(11))..runMany(30000);
      expect(sim.theory, closeTo(1 - math.pow(5 / 6, 4), 1e-12));
      expect(sim.observed, closeTo(sim.theory, 0.012));
    });

    test('mutually exclusive: card counts', () {
      final sim = MutualSim();
      expect((sim.countA, sim.countB, sim.countBoth, sim.exclusive), (13, 13, 0, true));
      sim.pair = CardPair.heartsKings;
      expect((sim.countA, sim.countB, sim.countBoth), (13, 4, 1));
      sim.pair = CardPair.redFace;
      expect((sim.countA, sim.countB, sim.countBoth), (26, 12, 6));
    });
  });

  group('Ch 4', () {
    test('multiplication principle: the tree has s × t × k leaves', () {
      final sim = OutfitSim()
        ..shirts = 4
        ..trousers = 3
        ..shoes = 3;
      expect(sim.total, 36);
      sim.runMany(36);
      expect(sim.revealed, 36);
    });

    test('permutations: random races eventually show every podium', () {
      final sim = PermutationSim(rng: seeded(12))
        ..n = 4
        ..r = 2;
      expect(sim.total, 12);
      sim.runMany(3000);
      expect(sim.seen.length, 12);
    });

    test('combinations: nPr / r! for every size', () {
      final sim = CombinationSim();
      for (var n = 3; n <= 5; n++) {
        for (var r = 1; r <= 3; r++) {
          sim.setSizes(n: n, r: r);
          expect(sim.perms, permutations(n, r));
          expect(sim.combos, combinations(n, r));
        }
      }
    });

    test('arrangements with repeats: n! / (k₁!·k₂!…)', () {
      final sim = RepeatsSim(rng: seeded(13));
      final expected = {'BOOK': 12, 'LEVEL': 30, 'APPLE': 60, 'BANANA': 60, 'LETTER': 180};
      for (final e in expected.entries) {
        sim.change(() => sim.word = e.key);
        expect(sim.total, e.value, reason: e.key);
      }
      sim.change(() => sim.word = 'BOOK');
      sim.runMany(2000);
      expect(sim.seen.length, 12);
    });

    test('pigeonhole: more pigeons than holes always share', () {
      final sim = PigeonholeSim(rng: seeded(14))..change(() {});
      sim
        ..holes = 4
        ..pigeons = 5;
      sim.runMany(2000);
      expect(sim.rounds, greaterThan(50));
      expect(sim.roundsShared, sim.rounds);
      sim.change(() => sim.pigeons = 3);
      expect(sim.theory, closeTo(1 - (4 * 3 * 2) / (4 * 4 * 4), 1e-12));
    });

    test('birthday: 23 people pass 50%', () {
      expect(birthdayChance(23), closeTo(0.507, 0.001));
      expect(birthdayChance(22), lessThan(0.5));
      final sim = BirthdaySim(rng: seeded(15))..runMany(23 * 2000);
      expect(sim.roomsWithMatch / sim.rooms, closeTo(0.507, 0.05));
    });
  });

  group('Ch 5', () {
    test('conditional: counts and P(A | B)', () {
      final sim = ConditionalSim();
      for (final both in [0, 12, 30]) {
        sim.setBoth(both);
        expect(sim.glasses.where((g) => g).length, ConditionalSim.glassesCount);
        expect(sim.cricket.where((c) => c).length, ConditionalSim.cricketCount);
        var b = 0;
        for (var i = 0; i < ConditionalSim.people; i++) {
          if (sim.glasses[i] && sim.cricket[i]) b++;
        }
        expect(b, both);
        expect(sim.pCricketGivenGlasses, both / 40);
      }
    });

    test('independence: fair coins match, sticky coins split', () {
      final fair = IndependenceSim(rng: seeded(16))..runMany(20000);
      expect((fair.headsAfterHeads - fair.headsAfterTails).abs(), lessThan(0.03));
      final sticky = IndependenceSim(rng: seeded(17))..sticky = 0.8;
      sticky.runMany(20000);
      expect(sticky.headsAfterHeads, closeTo(0.9, 0.02));
      expect(sticky.headsAfterTails, closeTo(0.1, 0.02));
    });

    test('tree diagrams: leaf probabilities sum to 1 and match the draws', () {
      for (final replace in [false, true]) {
        final sim = TreeSim(rng: seeded(18))..replace = replace;
        expect(sim.theory.reduce((a, b) => a + b), closeTo(1, 1e-12));
        sim.runMany(30000);
        for (var i = 0; i < 4; i++) {
          expect(sim.counts[i] / sim.trials, closeTo(sim.theory[i], 0.012));
        }
      }
      expect(TreeSim().theory[0], closeTo(0.3, 1e-12));
    });

    test('multiplication rule: darts match P(A) × P(B | A)', () {
      final sim = MultRuleSim(rng: seeded(19))..runMany(40000);
      expect(sim.inAB / sim.total, closeTo(sim.pAB, 0.01));
    });

    test('total probability: Σ P(F) P(D | F) matches production', () {
      final sim = TotalProbSim(rng: seeded(20));
      expect(sim.theory, closeTo(0.5 * 0.04 + 0.3 * 0.06 + 0.2 * 0.15, 1e-12));
      sim.runMany(40000);
      expect(sim.totalFaulty / sim.total, closeTo(sim.theory, 0.006));
    });
  });

  group('Ch 6', () {
    test('discrete vs continuous: spins spread evenly over 0–1', () {
      final sim = DiscreteContinuousSim(rng: seeded(21))..runMany(4000);
      final inMiddle = sim.spins.where((s) => s >= 0.4 && s <= 0.6).length / sim.spins.length;
      expect(inMiddle, closeTo(0.2, 0.025));
    });

    test('PMF and CDF of two dice', () {
      final sim = PmfCdfSim();
      expect(kTwoDiceWays.reduce((a, b) => a + b), 36);
      expect(sim.cdf(12), closeTo(1, 1e-12));
      expect(sim.cdf(7), closeTo(21 / 36, 1e-12));
      expect(sim.waysUpTo(4), 6);
    });

    test('expected value: weights sum to 1 and the average converges', () {
      final sim = ExpectedValueSim(rng: seeded(22));
      for (final j in [0.01, 0.05, 0.1]) {
        sim.change(() => sim.jackpot = j);
        expect(sim.chances.reduce((a, b) => a + b), closeTo(1, 1e-12));
      }
      sim.change(() => sim.jackpot = 0.05);
      expect(sim.expected, closeTo(-0.5, 1e-9));
      sim.runMany(60000);
      expect(sim.average, closeTo(sim.expected, 0.3));
    });

    test('variance: risky game has mean 0 and variance k', () {
      final sim = VarianceSim(rng: seeded(23))..k = 9;
      sim.reset();
      sim.runMany(VarianceSim.maxRounds);
      final finals = [for (final p in sim.risky) p.last];
      // Expected sd of the total after 60 rounds is √(9 × 60) ≈ 23.
      expect(sdOf(finals), inInclusiveRange(10, 40));
      expect(sim.steady.every((p) => p.length == VarianceSim.maxRounds + 1), isTrue);
    });

    test('linearity: on average one person gets their own hat', () {
      for (final n in [3, 12]) {
        final sim = LinearitySim(rng: seeded(24 + n))..change(() {});
        sim.change(() => sim.n = n);
        sim.runMany(20000);
        expect(sim.average, closeTo(1, 0.04), reason: 'n=$n');
      }
    });
  });
}
