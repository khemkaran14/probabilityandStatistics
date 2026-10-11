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
