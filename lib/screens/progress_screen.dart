import 'package:flutter/material.dart';

import 'package:chance/data/achievements.dart';
import 'package:chance/lessons/registry.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final earned = kAchievements.where((a) => a.earned(s)).length;
    return SafeArea(
      child: PhoneWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Progress',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                XpChip(),
              ],
            ),
            const SizedBox(height: 20),
            // Level card.
            SoftCard(
              color: AppColors.violet,
              child: Row(
                children: [
                  ProgressRing(
                    value: s.levelProgress,
                    color: AppColors.yellow,
                    size: 76,
                    stroke: 9,
                    child: Text(
                      '${s.level}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${s.level}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Text(
                          '${s.xpToNextLevel} XP to level ${s.level + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: [
                _Stat('Total XP', '${s.xp}', Icons.bolt_rounded, AppColors.yellow),
                _Stat('Streak', '${s.currentStreak} days', Icons.local_fire_department_rounded, AppColors.orange),
                _Stat(
                    'Lessons', '${s.completed.length}/${lessonRegistry.length}', Icons.school_rounded, AppColors.green),
                _Stat('Best streak', '${s.bestStreak} days', Icons.whatshot_rounded, AppColors.pink),
              ],
            ),
            const SizedBox(height: 22),
            const SectionLabel('Last 7 days'),
            const SizedBox(height: 10),
            _WeekChart(days: s.recentDays(7), goal: s.dailyGoal),
            const SizedBox(height: 22),
            SectionLabel('Badges · $earned of ${kAchievements.length}'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: [for (final a in kAchievements) _BadgeTile(a, earned: a.earned(s))],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
                Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days, required this.goal});
  final List<MapEntry<DateTime, int>> days;
  final int goal;

  static const _names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxXp = days.fold<int>(goal, (m, d) => d.value > m ? d.value : m);
    return SoftCard(
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        days[i].value > 0 ? '${days[i].value}' : '',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        height: 4 + 96 * days[i].value / maxXp,
                        decoration: BoxDecoration(
                          color: days[i].value >= goal
                              ? AppColors.green
                              : days[i].value > 0
                                  ? AppColors.cyan
                                  : AppColors.chip,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _names[days[i].key.weekday - 1],
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: i == days.length - 1 ? AppColors.ink : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile(this.achievement, {required this.earned});
  final Achievement achievement;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: achievement.description,
      triggerMode: TooltipTriggerMode.tap,
      child: SoftCard(
        padding: const EdgeInsets.all(10),
        radius: 20,
        color: earned ? AppColors.card : AppColors.chip,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: earned ? achievement.color : AppColors.peg.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                earned ? achievement.icon : Icons.lock_rounded,
                color: earned ? Colors.white : AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: earned ? AppColors.ink : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
