import 'package:flutter/material.dart';

import 'package:chance/data/catalogue.dart';
import 'package:chance/lessons/registry.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.earned,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool Function(AppState s) earned;
}

final List<Achievement> kAchievements = [
  Achievement(
    id: 'first_lesson',
    title: 'First steps',
    description: 'Finish your first lesson',
    icon: Icons.flag_rounded,
    color: AppColors.green,
    earned: (s) => s.completed.isNotEmpty,
  ),
  Achievement(
    id: 'perfect',
    title: 'Sharp mind',
    description: 'Get every quiz question right',
    icon: Icons.verified_rounded,
    color: AppColors.violet,
    earned: (s) => s.perfect.isNotEmpty,
  ),
  Achievement(
    id: 'free_tour',
    title: 'Free tour',
    description: 'Finish every free lesson',
    icon: Icons.map_rounded,
    color: AppColors.cyan,
    earned: (s) => lessonRegistry.keys.where(isLessonFree).every(s.completed.contains),
  ),
  Achievement(
    id: 'all_lessons',
    title: 'Completionist',
    description: 'Finish every animated lesson',
    icon: Icons.workspace_premium_rounded,
    color: AppColors.orange,
    earned: (s) => lessonRegistry.keys.every(s.completed.contains),
  ),
  Achievement(
    id: 'halfway',
    title: 'Halfway there',
    description: 'Finish half of all lessons',
    icon: Icons.hourglass_bottom_rounded,
    color: AppColors.blue,
    earned: (s) => lessonRegistry.keys.where(s.completed.contains).length * 2 >= lessonRegistry.length,
  ),
  for (final (title, description, icon, chapters) in _chapterBadges)
    Achievement(
      id: 'chapters_${chapters.join('_')}',
      title: title,
      description: description,
      icon: icon,
      color: kChapters[chapters.first - 1].color,
      earned: (s) => chapters.every((n) => chapterDone(s, n)),
    ),
  Achievement(
    id: 'streak3',
    title: 'On fire',
    description: 'Reach a 3-day streak',
    icon: Icons.local_fire_department_rounded,
    color: AppColors.orange,
    earned: (s) => s.bestStreak >= 3,
  ),
  Achievement(
    id: 'streak7',
    title: 'Week warrior',
    description: 'Reach a 7-day streak',
    icon: Icons.whatshot_rounded,
    color: AppColors.pink,
    earned: (s) => s.bestStreak >= 7,
  ),
  Achievement(
    id: 'challenge1',
    title: 'Challenger',
    description: 'Finish a daily challenge',
    icon: Icons.bolt_rounded,
    color: AppColors.yellow,
    earned: (s) => s.challengesDone >= 1,
  ),
  Achievement(
    id: 'challenge10',
    title: 'Regular',
    description: 'Finish 10 daily challenges',
    icon: Icons.event_available_rounded,
    color: AppColors.blue,
    earned: (s) => s.challengesDone >= 10,
  ),
  Achievement(
    id: 'xp500',
    title: 'Level climber',
    description: 'Earn 500 XP',
    icon: Icons.trending_up_rounded,
    color: AppColors.green,
    earned: (s) => s.xp >= 500,
  ),
  Achievement(
    id: 'supporter',
    title: 'Supporter',
    description: 'Unlock all lessons',
    icon: Icons.favorite_rounded,
    color: AppColors.pink,
    earned: (s) => s.premium,
  ),
];

/// True when every built lesson in chapter [number] is finished.
bool chapterDone(AppState s, int number) =>
    kChapters[number - 1].lessons.map((l) => l.id).whereType<String>().every(s.completed.contains);

/// Badges for finishing groups of chapters: (title, description, icon, chapters).
const List<(String, String, IconData, List<int>)> _chapterBadges = [
  ('Data detective', 'Finish chapters 1 and 2: data and charts', Icons.insights_rounded, [1, 2]),
  ('Counting pro', 'Finish chapters 3 and 4: probability and counting', Icons.casino_rounded, [3, 4]),
  ('Given that…', 'Finish chapters 5 and 6', Icons.account_tree_rounded, [5, 6]),
  ('Distribution expert', 'Finish chapters 7 and 8: every distribution', Icons.stacked_bar_chart_rounded, [7, 8]),
  ('Theorem tamer', 'Finish chapters 9 and 10', Icons.functions_rounded, [9, 10]),
  ('Poll master', 'Finish chapters 11 and 12: sampling and estimation', Icons.how_to_vote_rounded, [11, 12]),
  ('Hypothesis hunter', 'Finish chapter 13: hypothesis testing', Icons.science_rounded, [13]),
  ('Line drawer', 'Finish chapter 14: regression', Icons.show_chart_rounded, [14]),
  ('Bayesian', 'Finish chapter 15: Bayesian thinking', Icons.psychology_rounded, [15]),
  ('Real-world stats', 'Finish chapter 16', Icons.public_rounded, [16]),
  ('Paradox master', 'Finish chapter 17: paradoxes and puzzles', Icons.auto_awesome_rounded, [17]),
];
