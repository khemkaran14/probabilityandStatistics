import 'dart:math' as math;

import 'package:chance/data/catalogue.dart';
import 'package:chance/data/practice_bank.dart';
import 'package:chance/lessons/clt_dice.dart';
import 'package:chance/lessons/coin_flips.dart';
import 'package:chance/lessons/galton_board.dart';
import 'package:chance/lessons/monty_hall.dart';
import 'package:chance/lessons/registry.dart';
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
}
