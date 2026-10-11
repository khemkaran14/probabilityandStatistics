import 'package:flutter/material.dart';

import 'package:chance/data/catalogue.dart';
import 'package:chance/lessons/registry.dart';
import 'package:chance/screens/lesson_screen.dart';
import 'package:chance/state/progress.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Row(
                children: [
                  _Logo(),
                  SizedBox(width: 10),
                  Text('Chance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  Spacer(),
                  XpChip(),
                ],
              ),
              const SizedBox(height: 22),
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Master '),
                    TextSpan(text: 'probability', style: TextStyle(color: AppColors.pink)),
                    TextSpan(text: ' & '),
                    TextSpan(text: 'statistics', style: TextStyle(color: AppColors.violet)),
                    TextSpan(text: ' by watching it happen.'),
                  ],
                ),
                style: kDisplay.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 20),
              const _ContinueCard(),
              const SizedBox(height: 26),
              Text(
                '${kChapters.length} CHAPTERS · $kLessonCount LESSONS',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              for (final chapter in kChapters) ...[
                _ChapterCard(chapter: chapter),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void openLesson(BuildContext context, Lesson lesson) {
  final spec = lesson.id == null ? null : lessonRegistry[lesson.id];
  if (spec == null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${lesson.title}" is being animated. Coming soon!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => LessonScreen(spec: spec)),
  );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    // Three dots of a die face, in brand colours.
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Stack(
        children: [
          Align(alignment: Alignment.topLeft, child: _Dot(AppColors.pink)),
          Align(alignment: Alignment.center, child: _Dot(AppColors.yellow)),
          Align(alignment: Alignment.bottomRight, child: _Dot(AppColors.cyan)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard();

  static const _galton = Lesson('Binomial: the Galton board', id: 'galton');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pink,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => openLesson(context, _galton),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRY THE FIRST LESSON',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Why does everything end up as a bell?',
                      style: TextStyle(
                        fontSize: 21,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Galton board · 2 min',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, size: 34, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterCard extends StatefulWidget {
  const _ChapterCard({required this.chapter});
  final Chapter chapter;

  @override
  State<_ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<_ChapterCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.chapter;
    final hasBuilt = c.lessons.any((l) => l.id != null && lessonRegistry.containsKey(l.id));

    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${c.number}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          '${c.lessons.length} lessons · ${c.tagline}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (c.free)
                    const _Tag(text: 'FREE', color: AppColors.green)
                  else if (hasBuilt)
                    const _Tag(text: 'PREVIEW', color: AppColors.yellow)
                  else
                    const Icon(Icons.lock_rounded, color: AppColors.muted, size: 20),
                  Icon(
                    _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: Progress.completed,
                      builder: (context, done, _) => Column(
                        children: [
                          for (final lesson in c.lessons)
                            _LessonRow(
                              lesson: lesson,
                              color: c.color,
                              built: lesson.id != null && lessonRegistry.containsKey(lesson.id),
                              done: lesson.id != null && done.contains(lesson.id),
                            ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.ink),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.color,
    required this.built,
    required this.done,
  });

  final Lesson lesson;
  final Color color;
  final bool built;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => openLesson(context, lesson),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.circle,
              size: done ? 20 : 10,
              color: done ? AppColors.green : color,
            ),
            SizedBox(width: done ? 10 : 15),
            Expanded(
              child: Text(
                lesson.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: built ? FontWeight.w800 : FontWeight.w500,
                  color: built ? AppColors.ink : AppColors.muted,
                ),
              ),
            ),
            if (built)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
                child: const Text(
                  'Play',
                  style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
              )
            else
              const Text('soon', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
