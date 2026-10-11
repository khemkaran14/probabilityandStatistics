import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

const List<String> kRepeatWords = ['BOOK', 'LEVEL', 'APPLE', 'BANANA', 'LETTER'];

/// Shuffles the letters of a word and collects the distinct words made.
class RepeatsSim extends TickSim {
  RepeatsSim({super.rng}) {
    restart();
  }

  String word = 'BANANA';
  late List<String> letters;
  final Set<String> seen = {};
  int shuffles = 0;

  Map<String, int> get letterCounts {
    final m = <String, int>{};
    for (final c in word.split('')) {
      m[c] = (m[c] ?? 0) + 1;
    }
    return m;
  }

  int get total {
    var t = factorial(word.length);
    for (final k in letterCounts.values) {
      t ~/= factorial(k);
    }
    return t;
  }

  @override
  double get interval => shuffles < 6 ? 0.8 : 0.12;

  @override
  void tick() {
    letters.shuffle(rng);
    shuffles++;
    seen.add(letters.join());
  }

  @override
  void restart() {
    letters = word.split('');
    seen.clear();
    shuffles = 0;
  }
}

void _paintRepeats(Canvas canvas, Size size, RepeatsSim sim) {
  final w = size.width;
  final h = size.height;
  final repeated = sim.letterCounts.entries.where((e) => e.value > 1).map((e) => e.key).toList();
  Color colorFor(String c) {
    final i = repeated.indexOf(c);
    return i < 0 ? AppColors.peg : [AppColors.pink, AppColors.blue, AppColors.green][i % 3];
  }

  // Tiles.
  final n = sim.letters.length;
  final tile = ((w - 40) / n).clamp(0.0, 52.0) - 6;
  final rowW = n * (tile + 6) - 6;
  for (var i = 0; i < n; i++) {
    final rect = Rect.fromLTWH((w - rowW) / 2 + i * (tile + 6), 20, tile, tile * 1.15);
    roundRect(canvas, rect, colorFor(sim.letters[i]), radius: 10);
    label(canvas, sim.letters[i], rect.center, size: tile * 0.55, color: Colors.white, weight: FontWeight.w900);
  }
  final legend = repeated.map((c) => '$c ×${sim.letterCounts[c]}').join('  ');
  label(canvas, legend.isEmpty ? 'no repeated letters' : 'repeated: $legend', Offset(w / 2, 34 + tile * 1.15),
      size: 12, color: AppColors.muted);

  // Progress.
  final y = 64 + tile * 1.15;
  final barW = w - 40;
  final frac = sim.seen.length / sim.total;
  label(canvas, 'Different words made', Offset(20, y), size: 12, align: TextAlign.left);
  roundRect(canvas, Rect.fromLTWH(20, y + 12, barW, 24), Colors.white, radius: 8);
  roundRect(canvas, Rect.fromLTWH(20, y + 12, barW * frac, 24), AppColors.violet, radius: 8);
  label(canvas, '${sim.seen.length} of ${sim.total}', Offset(w / 2, y + 24),
      size: 12, color: frac > 0.5 ? Colors.white : AppColors.ink);

  // Recent words.
  final recent = sim.seen.toList().reversed.take(12).toList();
  final colW = barW / 3;
  for (var i = 0; i < recent.length; i++) {
    label(canvas, recent[i], Offset(20 + colW * (i % 3) + colW / 2, y + 58 + (i ~/ 3) * 20.0),
        size: 13, color: i == 0 ? AppColors.ink : AppColors.muted);
  }
  label(canvas, '${sim.shuffles} shuffles', Offset(w - 20, h - 12),
      size: 11, color: AppColors.muted, align: TextAlign.right);
}

final LessonSpec repeatsLesson = LessonSpec(
  id: 'repeats',
  chapterLabel: 'Ch 4 · Counting',
  title: const [
    TitlePart('Why '),
    TitlePart('BANANA', AppColors.yellow),
    TitlePart(' has fewer arrangements than you think'),
  ],
  subtitle: 'Arrangements with repeats · 2-minute animated lesson',
  createSim: () => RepeatsSim(),
  visualAspectRatio: 1.05,
  buildVisual: (sim) => simCanvas<RepeatsSim>(sim, _paintRepeats),
  stats: (sim) {
    final r = sim as RepeatsSim;
    return [
      StatChip('letters', '${r.word.length}', AppColors.yellow),
      StatChip('if all different', '${factorial(r.word.length)}', AppColors.pink),
      StatChip('really', '${r.total}', AppColors.violet),
    ];
  },
  bigIdea: 'Six different letters can be arranged 6! = 720 ways. But BANANA\'s three '
      'A\'s are identical: swapping them changes nothing, so each word is counted '
      '3! = 6 times too often. The two N\'s add another 2! repeat. Divide out the '
      'repeats for each repeated letter.',
  formula: (sim) {
    final r = sim as RepeatsSim;
    final denominators = r.letterCounts.values.where((k) => k > 1).map((k) => '$k!').join(' × ');
    return denominators.isEmpty
        ? '${r.word.length}! = ${r.total}'
        : '${r.word.length}! / ($denominators) = ${factorial(r.word.length)} / '
            '${factorial(r.word.length) ~/ r.total} = ${r.total}';
  },
  tryItTitle: 'Try it: pick a word',
  buildTryIt: (sim) {
    final r = sim as RepeatsSim;
    return watch(
      r,
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceRow<String>(
            options: {for (final word in kRepeatWords) word: word},
            selected: r.word,
            onSelected: (v) => r.change(() => r.word = v),
          ),
          const SizedBox(height: 8),
          ControlRow(children: [ActionButton('Shuffle 500 times', () => r.runMany(500))]),
        ],
      ),
    );
  },
  quiz: const [
    QuizQuestion(
      prompt: 'How many different arrangements of the letters in "MOM"?',
      options: ['2', '3', '6', '9'],
      answer: 1,
      explanation: '3! / 2! = 3: MOM, MMO, OMM.',
    ),
    QuizQuestion(
      prompt: 'How many arrangements of "LEVEL" (two L\'s, two E\'s)?',
      options: ['30', '60', '120', '24'],
      answer: 0,
      explanation: '5! / (2! × 2!) = 120 / 4 = 30.',
    ),
    QuizQuestion(
      prompt: 'Why divide by 3! for a letter that appears three times?',
      options: [
        'Because there are three vowels',
        'The 3! orders of identical letters all give the same word',
        'To make the answer smaller',
        'Because 3! = 3',
      ],
      answer: 1,
      explanation: 'Identical letters can be swapped in 3! ways without changing the word.',
    ),
  ],
);
