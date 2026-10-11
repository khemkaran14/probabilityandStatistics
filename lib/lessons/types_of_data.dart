import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/kit.dart';
import 'package:chance/theme/app_theme.dart';

enum DataKind { nominal, ordinal, discrete, continuous }

const Map<DataKind, String> kDataKindNames = {
  DataKind.nominal: 'Categories',
  DataKind.ordinal: 'Ordered categories',
  DataKind.discrete: 'Counts',
  DataKind.continuous: 'Measurements',
};

const Map<DataKind, Color> kDataKindColors = {
  DataKind.nominal: AppColors.pink,
  DataKind.ordinal: AppColors.orange,
  DataKind.discrete: AppColors.green,
  DataKind.continuous: AppColors.blue,
};

/// Example values with their kind.
const List<(String, DataKind)> kDataExamples = [
  ('Eye colour: brown', DataKind.nominal),
  ('T-shirt size: M', DataKind.ordinal),
  ('Siblings: 2', DataKind.discrete),
  ('Height: 172.4 cm', DataKind.continuous),
  ('Blood group: O+', DataKind.nominal),
  ('Rating: ★★★★', DataKind.ordinal),
  ('Goals scored: 3', DataKind.discrete),
  ('Time: 9.58 s', DataKind.continuous),
  ('City: Pune', DataKind.nominal),
  ('Grade: B+', DataKind.ordinal),
  ('Cars owned: 1', DataKind.discrete),
  ('Weight: 61.2 kg', DataKind.continuous),
  ('Favourite fruit: mango', DataKind.nominal),
  ('Spice level: hot', DataKind.ordinal),
  ('Emails today: 14', DataKind.discrete),
  ('Temperature: 31.6 °C', DataKind.continuous),
];

class TypesOfDataSim extends TickSim {
  TypesOfDataSim({super.rng});

  /// How many examples have been sorted.
  int sorted = 0;

  @override
  double get interval => 1.3;

  (String, DataKind) get current => kDataExamples[sorted % kDataExamples.length];

  Map<DataKind, int> get counts {
    final c = {for (final k in DataKind.values) k: 0};
    for (var i = 0; i < sorted; i++) {
      final k = kDataExamples[i % kDataExamples.length].$2;
      c[k] = c[k]! + 1;
    }
    return c;
  }

  @override
  void tick() => sorted++;

  @override
  void restart() => sorted = 0;
}

void _paintTypes(Canvas canvas, Size size, TypesOfDataSim sim) {
  final w = size.width;
  final h = size.height;
  final binTop = h * 0.5;
  final binW = (w - 30) / 2;
  final binH = (h - binTop - 16) / 2;

  // Four bins in a 2×2 grid: categorical on top, numerical below.
  final bins = <DataKind, Rect>{};
  for (var i = 0; i < 4; i++) {
    final kind = DataKind.values[i];
    final r = Rect.fromLTWH(10 + (i % 2) * (binW + 10), binTop + (i ~/ 2) * (binH + 8), binW, binH);
    bins[kind] = r;
    roundRect(canvas, r, kDataKindColors[kind]!.withValues(alpha: 0.18), radius: 14);
    label(canvas, kDataKindNames[kind]!, Offset(r.center.dx, r.top + 14), size: 12, color: kDataKindColors[kind]!);
    label(canvas, '${sim.counts[kind]}', r.center.translate(0, 8), size: 26, color: kDataKindColors[kind]!);
  }
  label(canvas, 'CATEGORICAL: words / labels', Offset(w / 2, binTop - 10), size: 11, color: AppColors.muted);
  label(canvas, 'NUMERICAL: numbers you can add', Offset(w / 2, binTop + binH + 4), size: 10, color: AppColors.muted);

  // The card in flight: from the top centre into its bin.
  final (text, kind) = sim.current;
  final t = Curves.easeInOutCubic.transform(math.min(1, sim.phase * 1.4));
  final from = Offset(w / 2, h * 0.16);
  final to = bins[kind]!.center;
  final pos = Offset.lerp(from, to, t)!;
  final scale = 1 - 0.5 * t;
  final cardW = w * 0.7 * scale;
  final cardH = 46.0 * scale;
  final card = Rect.fromCenter(center: pos, width: cardW, height: cardH);
  canvas.drawRRect(
    RRect.fromRectAndRadius(card.shift(const Offset(0, 3)), const Radius.circular(12)),
    Paint()..color = AppColors.ink.withValues(alpha: 0.08),
  );
  roundRect(canvas, card, Colors.white, radius: 12);
  canvas.drawRRect(
    RRect.fromRectAndRadius(card, const Radius.circular(12)),
    Paint()
      ..color = kDataKindColors[kind]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );
  label(canvas, text, pos, size: 15 * scale);
  if (t < 0.15) {
    label(canvas, '→ ${kDataKindNames[kind]}', Offset(w / 2, h * 0.32), size: 13, color: kDataKindColors[kind]!);
  }
}

final LessonSpec typesOfDataLesson = LessonSpec(
  id: 'types_of_data',
  chapterLabel: 'Ch 1 · Data & averages',
  title: const [
    TitlePart('Labels', AppColors.pink),
    TitlePart(' or '),
    TitlePart('numbers', AppColors.blue),
    TitlePart('? It changes everything'),
  ],
  subtitle: 'Types of data · 2-minute animated lesson',
  createSim: () => TypesOfDataSim(),
  visualAspectRatio: 0.95,
  buildVisual: (sim) => simCanvas<TypesOfDataSim>(sim, _paintTypes),
  stats: (sim) {
    final c = (sim as TypesOfDataSim).counts;
    return [
      StatChip('sorted', '${sim.sorted}', AppColors.yellow),
      StatChip('categorical', '${c[DataKind.nominal]! + c[DataKind.ordinal]!}', AppColors.pink),
      StatChip('numerical', '${c[DataKind.discrete]! + c[DataKind.continuous]!}', AppColors.blue),
    ];
  },
  bigIdea: 'Categorical data are labels: you can count them but not average them. '
      'Some labels have a natural order (small, medium, large). Numerical data '
      'are real numbers: counts jump in whole steps, measurements can take any '
      'value in between. The type decides which charts and averages make sense.',
  formula: (_) => 'Can you add it? → numerical.  Can you order it? → ordinal.',
  tryItTitle: 'Try it: sort these yourself',
  buildTryIt: (_) => const _SortGame(),
  quiz: const [
    QuizQuestion(
      prompt: 'Which of these is continuous data?',
      options: ['Number of pets', 'Shoe brand', 'Time to run 100 m', 'Exam grade A–F'],
      answer: 2,
      explanation: 'Time can be measured ever more finely (11.2 s, 11.23 s…). Pets '
          'are counted in whole numbers.',
    ),
    QuizQuestion(
      prompt: 'Survey answers "poor, fair, good, excellent" are…',
      options: ['Nominal', 'Ordinal', 'Discrete', 'Continuous'],
      answer: 1,
      explanation: 'They are labels with a natural order, but the gaps between them '
          'are not measurable numbers.',
    ),
    QuizQuestion(
      prompt: 'Why can\'t you take the mean of PIN codes?',
      options: [
        'They are too long',
        'They are labels that just look like numbers',
        'They are always even',
        'You can',
      ],
      answer: 1,
      explanation: 'A PIN code names a place. Adding two PIN codes means nothing, '
          'so they are categorical.',
    ),
  ],
);

class _SortGame extends StatefulWidget {
  const _SortGame();

  @override
  State<_SortGame> createState() => _SortGameState();
}

class _SortGameState extends State<_SortGame> {
  final _rng = math.Random();
  late int _item = _rng.nextInt(kDataExamples.length);
  DataKind? _picked;
  int _right = 0;
  int _total = 0;

  void _pick(DataKind k) {
    if (_picked != null) return;
    setState(() {
      _picked = k;
      _total++;
      if (k == kDataExamples[_item].$2) _right++;
    });
  }

  void _next() => setState(() {
        _picked = null;
        _item = (_item + 1 + _rng.nextInt(kDataExamples.length - 1)) % kDataExamples.length;
      });

  @override
  Widget build(BuildContext context) {
    final (text, kind) = kDataExamples[_item];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in DataKind.values)
              ChoiceChip(
                label: Text(kDataKindNames[k]!, style: const TextStyle(fontWeight: FontWeight.w800)),
                selected: _picked == k,
                selectedColor: k == kind ? AppColors.green : AppColors.orange,
                onSelected: (_) => _pick(k),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                _picked == null
                    ? 'Score: $_right / $_total'
                    : _picked == kind
                        ? 'Right! Score: $_right / $_total'
                        : 'It\'s ${kDataKindNames[kind]}. Score: $_right / $_total',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (_picked != null) ActionButton('Next', _next),
          ],
        ),
      ],
    );
  }
}
