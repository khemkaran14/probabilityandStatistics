import 'package:flutter/material.dart';

import 'package:chance/screens/learn_screen.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';

/// First-launch intro: what the app is, how lessons work, pick a goal.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  int _goal = 50;

  static const _pageCount = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _pages.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      AppScope.read(context).finishOnboarding(goal: _goal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < _pageCount; i++)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i <= _page ? AppColors.pink : AppColors.chip,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (p) => setState(() => _page = p),
                    children: [
                      const _WelcomePage(),
                      const _HowPage(),
                      _GoalPage(goal: _goal, onChanged: (g) => setState(() => _goal = g)),
                    ],
                  ),
                ),
                BigButton(
                  label: _page < _pageCount - 1 ? 'Continue' : 'Start learning',
                  color: _page < _pageCount - 1 ? AppColors.pink : AppColors.green,
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AppLogo(size: 96),
        const SizedBox(height: 28),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'See '),
              TextSpan(text: 'probability', style: TextStyle(color: AppColors.pink)),
              TextSpan(text: ' & '),
              TextSpan(text: 'statistics', style: TextStyle(color: AppColors.violet)),
              TextSpan(text: ' happen.'),
            ],
          ),
          textAlign: TextAlign.center,
          style: kDisplay.copyWith(fontSize: 34),
        ),
        const SizedBox(height: 14),
        const Text(
          'Short animated lessons that show why the formulas work, not just what they are.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, height: 1.4, color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _Chip('Galton board', AppColors.yellow),
            _Chip('Monty Hall', AppColors.pink),
            _Chip('Coin flips', AppColors.cyan),
            _Chip('Central Limit Theorem', AppColors.green),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      );
}

class _HowPage extends StatelessWidget {
  const _HowPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Every lesson, 4 steps', textAlign: TextAlign.center, style: kDisplay.copyWith(fontSize: 30)),
        const SizedBox(height: 24),
        const _Step(Icons.play_circle_fill_rounded, AppColors.pink, 'Watch', 'An animation plays the idea out.'),
        const _Step(Icons.lightbulb_rounded, AppColors.cyan, 'Understand', 'One big idea and the formula, live.'),
        const _Step(Icons.tune_rounded, AppColors.orange, 'Play', 'Change the settings, see what moves.'),
        const _Step(Icons.check_circle_rounded, AppColors.green, 'Check', 'A quick quiz earns you XP.'),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.icon, this.color, this.title, this.text);
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  Text(text, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({required this.goal, required this.onChanged});
  final int goal;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pick a daily goal', textAlign: TextAlign.center, style: kDisplay.copyWith(fontSize: 30)),
        const SizedBox(height: 8),
        const Text(
          'Hit it each day to build a streak. You can change it any time.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        DailyGoalPicker(goal: goal, onChanged: onChanged),
      ],
    );
  }
}

/// Three selectable goal cards. Also used in settings.
class DailyGoalPicker extends StatelessWidget {
  const DailyGoalPicker({super.key, required this.goal, required this.onChanged});
  final int goal;
  final ValueChanged<int> onChanged;

  static const _minutes = {20: '~3 min a day', 50: '~8 min a day', 100: '~15 min a day'};
  static const _colors = {20: AppColors.cyan, 50: AppColors.orange, 100: AppColors.pink};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in kDailyGoals.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: entry.key == goal ? _colors[entry.key]!.withValues(alpha: 0.18) : AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: entry.key == goal ? _colors[entry.key]! : AppColors.chip,
                  width: 2.5,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onChanged(entry.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                            Text(_minutes[entry.key]!, style: const TextStyle(color: AppColors.muted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${entry.key} XP', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
