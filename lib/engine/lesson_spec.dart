import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_sim.dart';

/// A piece of the lesson title; [color] highlights a word.
class TitlePart {
  const TitlePart(this.text, [this.color]);
  final String text;
  final Color? color;
}

class StatChip {
  const StatChip(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  final String prompt;
  final List<String> options;
  final int answer;
  final String explanation;
}

/// Everything the generic lesson screen needs to show one lesson:
/// watch (visual) → understand (big idea) → play (try it) → check (quiz).
class LessonSpec {
  const LessonSpec({
    required this.id,
    required this.chapterLabel,
    required this.title,
    required this.subtitle,
    required this.createSim,
    required this.buildVisual,
    required this.visualAspectRatio,
    required this.stats,
    required this.bigIdea,
    required this.formula,
    required this.tryItTitle,
    required this.buildTryIt,
    required this.quiz,
  });

  final String id;
  final String chapterLabel;
  final List<TitlePart> title;
  final String subtitle;

  final LessonSim Function() createSim;
  final Widget Function(LessonSim sim) buildVisual;

  /// width / height of the animation stage.
  final double visualAspectRatio;

  final List<StatChip> Function(LessonSim sim) stats;
  final String bigIdea;
  final String Function(LessonSim sim) formula;
  final String tryItTitle;
  final Widget Function(LessonSim sim) buildTryIt;
  final List<QuizQuestion> quiz;
}
