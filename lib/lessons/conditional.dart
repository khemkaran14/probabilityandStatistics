import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

enum CondView { everyone, givenGlasses, givenCricket }

const Map<CondView, String> kCondViewNames = {
  CondView.everyone: 'Everyone',
  CondView.givenGlasses: 'Given glasses',
  CondView.givenCricket: 'Given cricket',
};

/// 100 people: who wears glasses, who plays cricket. Conditioning zooms in.
class ConditionalSim extends TickSim {
  ConditionalSim({super.rng}) {
    _build();
  }

  static const int people = 100;
  static const int glassesCount = 40;
  static const int cricketCount = 30;

  /// People who do both (0–30).
  int both = 12;

  late List<bool> glasses;
  late List<bool> cricket;

  CondView view = CondView.everyone;

  /// Picked by the learner: stops the automatic cycling.
  bool manual = false;

  /// 0 → 1 fade towards the current view.
  double focus = 1;

  @override
  double get interval => 3;

  void _build() {
    final order = List<int>.generate(people, (i) => i)..shuffle(math.Random(3));
    glasses = List.filled(people, false);
    cricket = List.filled(people, false);
    for (var k = 0; k < glassesCount; k++) {
      glasses[order[k]] = true;
    }
    // The first `both` glasses-wearers play cricket, then non-wearers make up the rest.
    for (var k = 0; k < both; k++) {
      cricket[order[k]] = true;
    }
    for (var k = 0; k < cricketCount - both; k++) {
      cricket[order[glassesCount + k]] = true;
    }
  }

  bool inView(int i) => switch (view) {
        CondView.everyone => true,
        CondView.givenGlasses => glasses[i],
        CondView.givenCricket => cricket[i],
      };

  double get pCricket => cricketCount / people;
  double get pCricketGivenGlasses => both / glassesCount;
  double get pGlassesGivenCricket => both / cricketCount;

  @override
  void advance(double dt) {
    focus = math.min(1, focus + dt * 2.5);
    super.advance(dt);
  }

  @override
  void tick() {
    if (manual) return;
    view = CondView.values[(view.index + 1) % CondView.values.length];
    focus = 0;
  }

  void choose(CondView v) {
    manual = true;
    view = v;
    focus = 0;
    notifyListeners();
  }

  void setBoth(int v) {
    both = v;
    _build();
    notifyListeners();
  }

  @override
  void restart() {
    manual = false;
    view = CondView.everyone;
    focus = 1;
  }
}

void _paintConditional(Canvas canvas, Size size, ConditionalSim sim) {
  final w = size.width;
  final h = size.height;
  const cols = 10;
  final cell = (w - 40) / cols;
  const top = 34.0;

  final title = switch (sim.view) {
    CondView.everyone => 'All 100 people',
    CondView.givenGlasses => 'Only the 40 who wear glasses',
    CondView.givenCricket => 'Only the 30 who play cricket',
  };
  label(canvas, title, Offset(w / 2, 14), size: 14, color: AppColors.violet);

  for (var i = 0; i < ConditionalSim.people; i++) {
    final c = Offset(20 + (i % cols + 0.5) * cell, top + (i ~/ cols + 0.5) * cell);
    final visible = sim.inView(i);
    final a = visible ? 1.0 : 1 - 0.88 * sim.focus;
    canvas.drawCircle(
        c, cell * 0.32, Paint()..color = (sim.cricket[i] ? AppColors.orange : AppColors.peg).withValues(alpha: a));
    if (sim.glasses[i]) {
      // Two little lenses.
      for (final dx in [-0.13, 0.13]) {
        ring(canvas, c.translate(cell * dx, -cell * 0.04), cell * 0.1, AppColors.ink.withValues(alpha: a), width: 1.8);
      }
    }
  }

  final y = top + 10 * cell + 18;
  final (p, text) = switch (sim.view) {
    CondView.everyone => (sim.pCricket, 'P(cricket) = 30 / 100'),
    CondView.givenGlasses => (sim.pCricketGivenGlasses, 'P(cricket | glasses) = ${sim.both} / 40'),
    CondView.givenCricket => (sim.pGlassesGivenCricket, 'P(glasses | cricket) = ${sim.both} / 30'),
  };
  label(canvas, '$text = ${p.toStringAsFixed(2)}', Offset(w / 2, y), size: 15);
  label(canvas, '● plays cricket   ⚬⚬ wears glasses', Offset(w / 2, h - 12), size: 11, color: AppColors.muted);
}

final LessonSpec conditionalLesson = LessonSpec(
  id: 'conditional',
  chapterLabel: 'Ch 5 · Conditional probability',
  title: const [
    TitlePart('"Given that…" '),
    TitlePart('shrinks', AppColors.violet),
    TitlePart(' the world'),
  ],
  subtitle: 'Conditional probability · 2-minute animated lesson',
  createSim: () => ConditionalSim(),
  visualAspectRatio: 0.84,
  buildVisual: (sim) => simCanvas<ConditionalSim>(sim, _paintConditional),
  stats: (sim) {
    final c = sim as ConditionalSim;
    return [
      StatChip('P(cricket)', c.pCricket.toStringAsFixed(2), AppColors.orange),
      StatChip('P(cricket | glasses)', c.pCricketGivenGlasses.toStringAsFixed(2), AppColors.violet),
    ];
  },
  bigIdea: 'P(A | B) reads "the chance of A given B". Knowing B happened throws '
      'away everyone outside B: the faded dots. Among the people left, count '
      'how many also have A. The order matters: the share of glasses-wearers who '
      'play cricket is not the share of cricketers who wear glasses.',
  formula: (sim) {
    final c = sim as ConditionalSim;
    return 'P(A | B) = P(A and B) / P(B)\n'
        'P(cricket | glasses) = ${c.both}/100 ÷ 40/100 = ${c.pCricketGivenGlasses.toStringAsFixed(2)}';
  },
  tryItTitle: 'Try it: condition on a group',
  buildTryIt: (sim) {
    final c = sim as ConditionalSim;
    return watch(
      c,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<CondView>(options: kCondViewNames, selected: c.view, onSelected: c.choose),
          const SizedBox(height: 8),
          LabeledSlider(
            left: 'overlap 0',
            right: '30',
            value: c.both.toDouble(),
            min: 0,
            max: 30,
            divisions: 30,
            label: '${c.both} do both',
            onChanged: (v) => c.setBoth(v.round()),
          ),
          TryNote('${c.both} people wear glasses and play cricket.'),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'In a class of 30, 12 students take music and 4 of them also take art. '
          'What is P(art | music)?',
      options: ['4/30', '4/12', '12/30', '4/16'],
      answer: 1,
      explanation: 'Given music, only those 12 students count; 4 of them take art.',
    ),
    QuizQuestion(
      prompt: 'Is P(A | B) always equal to P(B | A)?',
      options: ['Yes, always', 'No, they can be very different', 'Only for coins', 'Only when both are 0'],
      answer: 1,
      explanation: 'P(rich | lottery winner) is high; P(lottery winner | rich) is tiny.',
    ),
    QuizQuestion(
      prompt: 'P(A and B) = 0.1 and P(B) = 0.4. What is P(A | B)?',
      options: ['0.04', '0.25', '0.4', '0.5'],
      answer: 1,
      explanation: '0.1 / 0.4 = 0.25.',
    ),
  ],
);
