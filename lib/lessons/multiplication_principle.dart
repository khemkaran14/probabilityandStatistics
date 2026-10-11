import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

/// Outfits: shirts × trousers × shoes, revealed one leaf at a time.
class OutfitSim extends TickSim {
  OutfitSim({super.rng});

  int shirts = 3, trousers = 2, shoes = 2;
  int revealed = 0;

  int get total => shirts * trousers * shoes;

  @override
  double get interval => total > 18 ? 0.18 : 0.4;

  @override
  void tick() {
    revealed++;
    if (revealed > total + 6) revealed = 0; // hold the full tree, then grow again
  }

  @override
  void restart() => revealed = 0;
}

const _shirtColors = [AppColors.pink, AppColors.blue, AppColors.green, AppColors.orange];
const _trouserNames = ['jeans', 'chinos', 'shorts'];
const _shoeNames = ['sneakers', 'sandals', 'boots'];

void _paintOutfits(Canvas canvas, Size size, OutfitSim sim) {
  final w = size.width;
  final h = size.height;
  final total = sim.total;
  const top = 28.0;
  final bottom = h - 10;
  final leafGap = (bottom - top) / total;
  double leafY(int i) => top + leafGap * (i + 0.5);

  final x0 = 18.0, x1 = w * 0.3, x2 = w * 0.58, x3 = w * 0.84;
  label(canvas, 'shirt', Offset(x1, 12), size: 11, color: AppColors.muted);
  label(canvas, 'trousers', Offset(x2, 12), size: 11, color: AppColors.muted);
  label(canvas, 'shoes', Offset(x3, 12), size: 11, color: AppColors.muted);

  final perShirt = sim.trousers * sim.shoes;
  final rootY = (top + bottom) / 2;
  final shown = sim.revealed.clamp(0, total);
  canvas.drawCircle(Offset(x0, rootY), 6, Paint()..color = AppColors.ink);

  for (var s = 0; s < sim.shirts; s++) {
    final firstLeaf = s * perShirt;
    if (shown <= firstLeaf) continue;
    final sy = (leafY(firstLeaf) + leafY(firstLeaf + perShirt - 1)) / 2;
    final color = _shirtColors[s];
    line(canvas, Offset(x0, rootY), Offset(x1, sy), color.withValues(alpha: 0.6), width: 2.5);
    canvas.drawCircle(Offset(x1, sy), 9, Paint()..color = color);
    for (var t = 0; t < sim.trousers; t++) {
      final tFirst = firstLeaf + t * sim.shoes;
      if (shown <= tFirst) continue;
      final ty = (leafY(tFirst) + leafY(tFirst + sim.shoes - 1)) / 2;
      line(canvas, Offset(x1, sy), Offset(x2, ty), color.withValues(alpha: 0.45), width: 2);
      canvas.drawCircle(Offset(x2, ty), 6, Paint()..color = color.withValues(alpha: 0.7));
      if (leafGap * sim.shoes > 14) {
        label(canvas, _trouserNames[t], Offset(x2 - 8, ty - 10),
            size: 9, color: AppColors.muted, align: TextAlign.right);
      }
      for (var k = 0; k < sim.shoes; k++) {
        final leaf = tFirst + k;
        if (shown <= leaf) continue;
        final ly = leafY(leaf);
        line(canvas, Offset(x2, ty), Offset(x3, ly), color.withValues(alpha: 0.3), width: 1.5);
        final isNew = leaf == shown - 1 && sim.revealed <= total;
        canvas.drawCircle(Offset(x3, ly), isNew ? 6 : 4, Paint()..color = isNew ? AppColors.ink : color);
        if (leafGap > 11) {
          label(canvas, _shoeNames[k], Offset(x3 + 9, ly), size: 9, color: AppColors.muted, align: TextAlign.left);
        }
      }
    }
  }
  label(canvas, '$shown', Offset(w - 10, h - 12), size: 16, color: AppColors.ink, align: TextAlign.right);
}

final LessonSpec multiplicationPrincipleLesson = LessonSpec(
  id: 'multiplication_principle',
  chapterLabel: 'Ch 4 · Counting',
  title: const [
    TitlePart('3 shirts, 2 trousers, 2 shoes: how many '),
    TitlePart('outfits', AppColors.pink),
    TitlePart('?'),
  ],
  subtitle: 'The multiplication principle · 2-minute animated lesson',
  createSim: () => OutfitSim(),
  visualAspectRatio: 0.9,
  buildVisual: (sim) => simCanvas<OutfitSim>(sim, _paintOutfits),
  stats: (sim) {
    final o = sim as OutfitSim;
    return [
      StatChip('outfits so far', '${o.revealed.clamp(0, o.total)}', AppColors.yellow),
      StatChip('total', '${o.total}', AppColors.pink),
    ];
  },
  bigIdea: 'Every shirt can go with every pair of trousers, so each shirt branch '
      'splits into the same number of trouser branches, and each of those splits '
      'again for shoes. When choices are made one after another and don\'t limit '
      'each other, multiply the number of options at each step.',
  formula: (sim) {
    final o = sim as OutfitSim;
    return '${o.shirts} × ${o.trousers} × ${o.shoes} = ${o.total} outfits';
  },
  tryItTitle: 'Try it: change your wardrobe',
  buildTryIt: (sim) {
    final o = sim as OutfitSim;
    Widget row(String name, int value, int max, void Function(int) set) => LabeledSlider(
          left: '$name ${value.toString().padLeft(1)}',
          right: '$max',
          value: value.toDouble(),
          min: 1,
          max: max.toDouble(),
          divisions: max - 1,
          onChanged: (v) => o.change(() => set(v.round())),
        );
    return watch(
      o,
      () => Column(
        children: [
          row('shirts', o.shirts, 4, (v) => o.shirts = v),
          row('trousers', o.trousers, 3, (v) => o.trousers = v),
          row('shoes', o.shoes, 3, (v) => o.shoes = v),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'A café offers 4 drinks and 3 snacks. How many drink-and-snack combos?',
      options: ['7', '12', '43', '64'],
      answer: 1,
      explanation: 'Each of the 4 drinks pairs with each of the 3 snacks: 4 × 3 = 12.',
    ),
    QuizQuestion(
      prompt: 'A PIN has 4 digits, each 0–9. How many PINs are possible?',
      options: ['40', '1,000', '10,000', '5,040'],
      answer: 2,
      explanation: '10 choices for each of 4 digits: 10 × 10 × 10 × 10 = 10,000.',
    ),
    QuizQuestion(
      prompt: 'Number plates use 2 letters (A–Z) then 2 digits. How many plates?',
      options: ['52', '676', '67,600', '1,000,000'],
      answer: 2,
      explanation: '26 × 26 × 10 × 10 = 67,600.',
    ),
  ],
);
