import 'package:flutter/material.dart';

import 'package:chance/data/practice_bank.dart';
import 'package:chance/screens/quiz_screen.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  void _startChallenge(BuildContext context) {
    final state = AppScope.read(context);
    final questions = dailyChallengeFor(state.clock());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          title: 'Daily challenge',
          questions: questions,
          onFinish: state.completeChallenge,
          noXpNote: 'You already claimed today\'s bonus. Come back tomorrow!',
          shareText: (correct) => 'Chance daily challenge ${state.today}: '
              '$correct/${questions.length} ${'🟩' * correct}${'⬜' * (questions.length - correct)}',
        ),
      ),
    );
  }

  void _startPractice(BuildContext context) {
    final state = AppScope.read(context);
    final questions = practiceSet(state.completed);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          title: 'Practice',
          questions: questions,
          onFinish: state.completePractice,
          noXpNote: 'Keep going, every right answer earns XP.',
          shareText: (correct) => 'I scored $correct/${questions.length} in a probability '
              'practice round on Chance!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final done = state.challengeDoneToday;
    return SafeArea(
      child: PhoneWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Practice',
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
            const SizedBox(height: 20),
            Material(
              color: done ? AppColors.green : AppColors.orange,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                key: const ValueKey('daily-challenge'),
                borderRadius: BorderRadius.circular(28),
                onTap: () => _startChallenge(context),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DAILY CHALLENGE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              done ? 'Done for today!' : '5 questions · up to ${challengeReward(5)} XP',
                              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              done
                                  ? 'Replay it for fun, or come back tomorrow for a new set.'
                                  : 'A fresh mix every day, same questions for everyone.',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          done ? Icons.check_rounded : Icons.bolt_rounded,
                          size: 32,
                          color: done ? AppColors.green : AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Free practice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    state.completed.isEmpty
                        ? 'Mixed questions on the basics. Finish lessons to add their questions here.'
                        : 'Mixed questions from your ${state.completed.length} finished '
                            '${state.completed.length == 1 ? 'lesson' : 'lessons'} and the basics.',
                    style: const TextStyle(color: AppColors.muted, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  BigButton(
                    label: 'Start a round · $kPracticeXpPerCorrect XP each',
                    color: AppColors.blue,
                    onPressed: () => _startPractice(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SoftCard(
              color: AppColors.cyan.withValues(alpha: 0.16),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: AppColors.cyan, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Challenges finished: ${state.challengesDone}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
