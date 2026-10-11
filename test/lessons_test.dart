import 'dart:math' as math;

import 'package:chance/data/catalogue.dart';
import 'package:chance/lessons/averages.dart';
import 'package:chance/lessons/bayes_test.dart';
import 'package:chance/data/practice_bank.dart';
import 'package:chance/lessons/clt_dice.dart';
import 'package:chance/lessons/coin_flips.dart';
import 'package:chance/lessons/galton_board.dart';
import 'package:chance/lessons/monty_hall.dart';
import 'package:chance/data/why.dart';
import 'package:chance/lessons/registry.dart';
import 'package:chance/lessons/spread.dart';
import 'package:chance/lessons/venn.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catalogue & registry', () {
    test('every built lesson is listed in the catalogue', () {
      for (final id in lessonRegistry.keys) {
        expect(kLessonsById.containsKey(id), isTrue, reason: id);
      }
    });

    test('every catalogue id has a built lesson', () {
      for (final id in kLessonsById.keys) {
        expect(lessonRegistry.containsKey(id), isTrue, reason: id);
      }
    });

    test('every lesson has a "why" explanation, and nothing else does', () {
      expect(kWhy.keys.toSet(), lessonRegistry.keys.toSet());
      for (final text in kWhy.values) {
        expect(text.length, greaterThan(150));
      }
    });

    test('every quiz answer index is valid', () {
      for (final q in allQuestions) {
        expect(q.options.length, inInclusiveRange(2, 4), reason: q.prompt);
        expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: q.prompt);
      }
    });

    test('daily challenge is stable within a day and has 5 questions', () {
      final a = dailyChallengeFor(DateTime(2026, 5, 1, 8));
      final b = dailyChallengeFor(DateTime(2026, 5, 1, 22));
      final c = dailyChallengeFor(DateTime(2026, 5, 2, 8));
      expect(a.length, 5);
      expect(a.map((q) => q.prompt), b.map((q) => q.prompt));
      expect(a.map((q) => q.prompt), isNot(c.map((q) => q.prompt)));
    });
  });

  group('Galton board', () {
    test('every ball lands in a bin', () {
      final sim = GaltonSim();
      for (var i = 0; i < 2000; i++) {
        sim.advance(1 / 60);
      }
      expect(sim.bins.fold(0, (a, b) => a + b), sim.landed);
      expect(sim.landed, greaterThan(50));
    });
  });

  group('Coin flips', () {
    test('share of heads converges to p', () {
      final sim = CoinFlipSim(rng: math.Random(1))..setP(0.7);
      sim.flipMany(20000);
      expect(sim.flips, 20000);
      expect(sim.proportion, closeTo(0.7, 0.02));
    });

    test('history stays bounded and ends at the current share', () {
      final sim = CoinFlipSim(rng: math.Random(2));
      sim.flipMany(10000);
      expect(sim.history.length, lessThan(CoinFlipSim.maxHistory));
      expect(sim.history.length * sim.historyEvery, lessThanOrEqualTo(sim.flips));
      expect(sim.recent.length, CoinFlipSim.recentCount);
    });
  });

  group('Monty Hall', () {
    test('host never opens the pick or the car', () {
      final rng = math.Random(3);
      for (var i = 0; i < 500; i++) {
        final r = MontyRound(rng);
        expect(r.opened, isNot(r.pick));
        expect(r.opened, isNot(r.car));
        expect(r.switchTo, isNot(r.pick));
        expect(r.switchTo, isNot(r.opened));
        expect(r.stayWins != r.switchWins, isTrue, reason: 'exactly one strategy wins');
      }
    });

    test('switching wins about 2/3 of the time', () {
      final sim = MontyHallSim(rng: math.Random(4));
      sim.playMany(30000);
      expect(sim.switchRate, closeTo(2 / 3, 0.015));
      expect(sim.stayRate + sim.switchRate, closeTo(1, 1e-9));
    });

    test('step walks through the phases', () {
      final sim = MontyHallSim(rng: math.Random(5));
      final seen = [sim.phase];
      for (var i = 0; i < 3; i++) {
        sim.step();
        seen.add(sim.phase);
      }
      expect(seen, MontyPhase.values);
      sim.step();
      expect(sim.games, 1);
      expect(sim.phase, MontyPhase.pick);
    });
  });

  group('Central Limit Theorem', () {
    test('sample means centre on 3.5 with sd σ/√n', () {
      for (final n in [1, 4, 9]) {
        final sim = CltSim(dice: n, rng: math.Random(n));
        sim.rollMany(20000);
        expect(sim.observedMean, closeTo(3.5, 0.03), reason: 'n=$n');
        expect(sim.observedSd, closeTo(kDieSigma / math.sqrt(n), 0.03), reason: 'n=$n');
      }
    });

    test('changing n resets the histogram size', () {
      final sim = CltSim(rng: math.Random(7))..rollMany(100);
      sim.setDice(5);
      expect(sim.samples, 0);
      expect(sim.counts.length, 26);
      expect(sim.faces.length, 5);
    });
  });

  group('Mean, median, mode', () {
    test('dots arrive up to the target and the averages are right', () {
      final sim = AveragesSim(rng: math.Random(8));
      for (var i = 0; i < 2000; i++) {
        sim.advance(1 / 30);
      }
      expect(sim.values.length, AveragesSim.target);
      final sorted = [...sim.values]..sort();
      expect(sim.mean, closeTo(sorted.fold(0, (a, b) => a + b) / sorted.length, 1e-9));
      expect(sim.median, (sorted[19] + sorted[20]) / 2);
      final mode = sim.mode!;
      final modeCount = sim.values.where((v) => v == mode).length;
      for (var v = 0; v <= AveragesSim.maxValue; v++) {
        expect(sim.values.where((x) => x == v).length, lessThanOrEqualTo(modeCount));
      }
    });

    test('an outlier moves the mean far more than the median', () {
      final sim = AveragesSim(rng: math.Random(9));
      for (var i = 0; i < AveragesSim.target; i++) {
        sim.step();
      }
      final mean0 = sim.mean, median0 = sim.median;
      sim.addOutlier();
      expect(sim.mean - mean0, greaterThan(3));
      expect((sim.median - median0).abs(), lessThanOrEqualTo(1));
    });

    test('a long tail puts the mean above the median', () {
      final sim = AveragesSim(rng: math.Random(10))..setShape(DataShape.skewed);
      for (var i = 0; i < AveragesSim.target; i++) {
        sim.step();
      }
      expect(sim.mean, greaterThan(sim.median));
    });
  });

  group('Standard deviation', () {
    test('sd matches the formula and tracks the chosen spread', () {
      final sim = SpreadSim(rng: math.Random(11));
      final m = sim.values.reduce((a, b) => a + b) / sim.values.length;
      final ss = sim.values.fold(0.0, (a, v) => a + (v - m) * (v - m));
      expect(sim.sd, closeTo(math.sqrt(ss / (SpreadSim.size - 1)), 1e-9));

      // Averaged over many samples, the sd lands near the target.
      for (final target in [4.0, 16.0]) {
        sim.setSpread(target);
        var total = 0.0;
        for (var i = 0; i < 400; i++) {
          sim.reset();
          total += sim.sd;
        }
        expect(total / 400, closeTo(target, target * 0.12), reason: 'target $target');
      }
    });

    test('step replaces exactly one value', () {
      final sim = SpreadSim(rng: math.Random(12));
      final before = [...sim.values];
      sim.step();
      final changed = [
        for (var i = 0; i < before.length; i++)
          if (before[i] != sim.values[i]) i
      ];
      expect(changed, [0]);
    });
  });

  group('Venn diagram', () {
    test('circles stay inside the sample space at every separation', () {
      final sim = VennSim();
      for (final d in [0.08, 0.3, VennSim.maxSeparation]) {
        sim.setSeparation(d);
        expect(sim.centreA.dx - VennSim.radius, greaterThanOrEqualTo(-1e-9));
        expect(sim.centreB.dx + VennSim.radius, lessThanOrEqualTo(1 + 1e-9));
      }
    });

    test('dart estimates match the exact areas', () {
      final sim = VennSim(rng: math.Random(13))..setSeparation(0.26);
      sim.throwMany(60000);
      expect(sim.estA, closeTo(sim.pA, 0.01));
      expect(sim.estBoth, closeTo(sim.pBoth, 0.01));
      expect(sim.estEither, closeTo(sim.pEither, 0.01));
      expect(sim.estEither, closeTo(sim.estA + sim.estB - sim.estBoth, 1e-9));
    });

    test('pulled apart, the events are mutually exclusive', () {
      final sim = VennSim(rng: math.Random(14))..setSeparation(0.44);
      expect(sim.mutuallyExclusive, isTrue);
      expect(sim.pBoth, 0);
      sim.throwMany(5000);
      expect(sim.inBoth, 0);
    });
  });

  group("Bayes' medical test", () {
    test('counts follow the rates and match Bayes\' formula', () {
      final sim = BayesSim();
      expect(sim.sickCount, 10);
      expect(sim.truePositives, 9);
      expect(sim.falsePositives, 89);
      expect(sim.sick.where((s) => s).length, sim.sickCount);
      expect(sim.positive.where((p) => p).length, sim.positives);
      var tp = 0;
      for (var i = 0; i < BayesSim.people; i++) {
        if (sim.sick[i] && sim.positive[i]) tp++;
      }
      expect(tp, sim.truePositives);

      const prev = 0.01, sens = BayesSim.sensitivity, fpr = 0.09;
      final bayes = sens * prev / (sens * prev + fpr * (1 - prev));
      expect(sim.sickGivenPositive, closeTo(bayes, 0.005));
    });

    test('every slider setting builds a valid population', () {
      final sim = BayesSim();
      for (final p in BayesSim.prevalences) {
        for (final f in BayesSim.falsePositiveRates) {
          sim.setRates(prevalence: p, falsePositiveRate: f);
          expect(sim.positive.where((x) => x).length, sim.positives, reason: 'p=$p f=$f');
        }
      }
    });

    test('a more common disease makes a positive more convincing', () {
      final sim = BayesSim();
      final rare = sim.sickGivenPositive;
      sim.setRates(prevalence: 0.2);
      expect(sim.sickGivenPositive, greaterThan(rare * 5));
    });

    test('the animation tests everyone, then focuses', () {
      final sim = BayesSim();
      for (var i = 0; i < 600; i++) {
        sim.advance(1 / 60);
      }
      expect(sim.testedCount, BayesSim.people);
      expect(sim.focus, 1);
      expect(sim.positivesSoFar, sim.positives);
    });
  });
}
