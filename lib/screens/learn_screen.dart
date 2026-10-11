import 'package:flutter/material.dart';

import 'package:chance/data/catalogue.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/registry.dart';
import 'package:chance/screens/lesson_screen.dart';
import 'package:chance/screens/paywall_screen.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      child: PhoneWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Row(
              children: [
                AppLogo(),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                StreakChip(),
                SizedBox(width: 8),
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
            const _DailyGoalCard(),
            const SizedBox(height: 12),
            const _ContinueCard(),
            if (!state.premium) ...[
              const SizedBox(height: 12),
              const _UnlockBanner(),
            ],
            const SizedBox(height: 26),
            SectionLabel('${kChapters.length} chapters · $kLessonCount lessons'),
            const SizedBox(height: 12),
            for (final chapter in kChapters) ...[
              _ChapterCard(key: ValueKey(chapter.number), chapter: chapter),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opens a lesson, or explains why it can't be opened yet.
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
  if (!AppScope.read(context).canOpen(spec.id)) {
    Navigator.of(context).push(PaywallScreen.route(reason: lesson.title));
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => LessonScreen(spec: spec)),
  );
}

/// The lesson to suggest next: the first built, openable lesson not yet
/// finished, in catalogue order. Falls back to the first built lesson.
LessonSpec nextLessonFor(AppState state) {
  for (final c in kChapters) {
    for (final l in c.lessons) {
      final spec = lessonRegistry[l.id];
      if (spec != null && state.canOpen(spec.id) && !state.completed.contains(spec.id)) return spec;
    }
  }
  return lessonRegistry[kLessonsById.keys.firstWhere(lessonRegistry.containsKey)]!;
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    // Three dots of a die face, in brand colours.
    final dot = size * 0.175;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.175),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Stack(
        children: [
          Align(alignment: Alignment.topLeft, child: _Dot(AppColors.pink, dot)),
          Align(alignment: Alignment.center, child: _Dot(AppColors.yellow, dot)),
          Align(alignment: Alignment.bottomRight, child: _Dot(AppColors.cyan, dot)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color, this.size);
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final left = s.dailyGoal - s.todayXp;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ProgressRing(
            value: s.todayXp / s.dailyGoal,
            color: AppColors.green,
            size: 52,
            stroke: 7,
            child: Icon(
              s.goalMetToday ? Icons.check_rounded : Icons.flag_rounded,
              color: s.goalMetToday ? AppColors.green : AppColors.muted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.goalMetToday ? 'Daily goal done. Nice!' : 'Today: $left XP to your goal',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.todayXp} / ${s.dailyGoal} XP · level ${s.level}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final spec = nextLessonFor(state);
    final started = state.completed.isNotEmpty;
    final ref = kLessonsById[spec.id]!;
    return Material(
      color: AppColors.pink,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => openLesson(context, ref.lesson),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      started ? 'UP NEXT' : 'TRY THE FIRST LESSON',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spec.title.map((t) => t.text).join(),
                      style: const TextStyle(
                        fontSize: 21,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spec.subtitle.split('·').first.trim(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

class _UnlockBanner extends StatelessWidget {
  const _UnlockBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.violet.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(PaywallScreen.route()),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.lock_open_rounded, color: AppColors.violet),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unlock all 17 chapters with one purchase',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.violet),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterCard extends StatefulWidget {
  const _ChapterCard({super.key, required this.chapter});
  final Chapter chapter;

  @override
  State<_ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<_ChapterCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.chapter;
    final state = AppScope.of(context);
    final hasPreview = c.lessons.any((l) => l.preview && lessonRegistry.containsKey(l.id));
    final builtIds = {
      for (final l in c.lessons)
        if (lessonRegistry.containsKey(l.id)) l.id!
    };
    final doneCount = builtIds.where(state.completed.contains).length;

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
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink),
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
                          builtIds.isEmpty
                              ? '${c.lessons.length} lessons · ${c.tagline}'
                              : '$doneCount/${builtIds.length} played · ${c.tagline}',
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
                  else if (state.premium)
                    const SizedBox.shrink()
                  else if (hasPreview)
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
                    child: Column(
                      children: [
                        for (final lesson in c.lessons)
                          _LessonRow(
                            lesson: lesson,
                            color: c.color,
                            built: lessonRegistry.containsKey(lesson.id),
                            locked: !(state.premium || lesson.isFreeIn(c)),
                            done: lesson.id != null && state.completed.contains(lesson.id),
                          ),
                      ],
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
    required this.locked,
    required this.done,
  });

  final Lesson lesson;
  final Color color;
  final bool built;
  final bool locked;
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
            if (built && locked)
              const Icon(Icons.lock_rounded, size: 18, color: AppColors.muted)
            else if (built)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
                child: Text(
                  done ? 'Replay' : 'Play',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink),
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
