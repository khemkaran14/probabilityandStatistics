import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';

/// Runs a list of questions, then shows a result card.
///
/// [onFinish] records the result and returns the XP awarded (0 is fine,
/// e.g. on a lesson replay). [shareText] builds the brag message.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.onFinish,
    required this.shareText,
    this.noXpNote = 'Replays don\'t earn XP, but practice still counts.',
  });

  /// Quiz at the end of a lesson: first completion earns XP.
  factory QuizScreen.forLesson(LessonSpec spec, AppState state) {
    final name = spec.title.map((t) => t.text).join();
    return QuizScreen(
      title: 'Quick check',
      questions: spec.quiz,
      onFinish: (correct) => state.completeLesson(spec.id, correct: correct, total: spec.quiz.length),
      shareText: (correct) => 'I just learned "$name" on Chance and scored '
          '$correct/${spec.quiz.length} on the quiz. Probability, animated!',
    );
  }

  final String title;
  final List<QuizQuestion> questions;
  final int Function(int correct) onFinish;
  final String Function(int correct) shareText;
  final String noXpNote;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int? _picked;
  int _score = 0;
  bool _finished = false;
  int _reward = 0;

  static const _optionColors = [AppColors.pink, AppColors.orange, AppColors.blue, AppColors.violet];

  List<QuizQuestion> get _quiz => widget.questions;

  void _pick(int option) {
    if (_picked != null) return;
    final correct = option == _quiz[_index].answer;
    if (AppScope.read(context).haptics) {
      correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    }
    setState(() {
      _picked = option;
      if (correct) _score++;
    });
  }

  void _next() {
    if (_index + 1 < _quiz.length) {
      setState(() {
        _index++;
        _picked = null;
      });
    } else {
      final reward = widget.onFinish(_score);
      setState(() {
        _reward = reward;
        _finished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: _finished ? _buildResult(context) : _buildQuestion(context),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final q = _quiz[_index];
    final answered = _picked != null;
    final correct = _picked == q.answer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_index + (answered ? 1 : 0)) / _quiz.length,
                  minHeight: 10,
                  backgroundColor: AppColors.chip,
                  color: AppColors.green,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const XpChip(),
          ],
        ),
        const SizedBox(height: 24),
        SectionLabel('${widget.title} · question ${_index + 1} of ${_quiz.length}'),
        const SizedBox(height: 8),
        Text(q.prompt, style: kDisplay.copyWith(fontSize: 24)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: [
              for (var i = 0; i < q.options.length; i++) ...[
                _OptionTile(
                  text: q.options[i],
                  color: _optionColors[i % _optionColors.length],
                  state: !answered
                      ? _OptionState.idle
                      : i == q.answer
                          ? _OptionState.correct
                          : i == _picked
                              ? _OptionState.wrong
                              : _OptionState.dimmed,
                  onTap: () => _pick(i),
                ),
                const SizedBox(height: 10),
              ],
              if (answered) ...[
                const SizedBox(height: 6),
                SoftCard(
                  color: correct ? AppColors.green.withValues(alpha: 0.16) : AppColors.orange.withValues(alpha: 0.16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        correct ? 'Spot on!' : 'Not quite.',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(q.explanation, style: const TextStyle(fontSize: 15, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        BigButton(
          label: _index + 1 < _quiz.length ? 'Next' : 'Finish',
          color: AppColors.green,
          onPressed: answered ? _next : null,
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final state = AppScope.of(context);
    final perfect = _score == _quiz.length;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_rounded, size: 64, color: AppColors.ink),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          perfect ? 'Perfect score!' : 'Nice work!',
          textAlign: TextAlign.center,
          style: kDisplay,
        ),
        const SizedBox(height: 8),
        Text(
          'You got $_score of ${_quiz.length} right'
          '${_reward > 0 ? ' · +$_reward XP' : ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.muted),
        ),
        if (_reward == 0) ...[
          const SizedBox(height: 4),
          Text(
            widget.noXpNote,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 20),
        SoftCard(
          child: Row(
            children: [
              ProgressRing(
                value: state.todayXp / state.dailyGoal,
                color: AppColors.green,
                size: 56,
                child: Icon(
                  state.goalMetToday ? Icons.check_rounded : Icons.flag_rounded,
                  color: state.goalMetToday ? AppColors.green : AppColors.muted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.goalMetToday ? 'Daily goal reached!' : 'Daily goal',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${state.todayXp} / ${state.dailyGoal} XP today · '
                      '${state.currentStreak}-day streak',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        BigButton(
          label: 'Share my score',
          color: AppColors.violet,
          icon: Icons.ios_share_rounded,
          onPressed: () => state.share.shareText(widget.shareText(_score)),
        ),
        const SizedBox(height: 12),
        BigButton(
          label: 'Done',
          color: AppColors.pink,
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.color,
    required this.state,
    required this.onTap,
  });

  final String text;
  final Color color;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    IconData? icon;
    switch (state) {
      case _OptionState.idle:
        bg = AppColors.card;
        border = color;
      case _OptionState.correct:
        bg = AppColors.green.withValues(alpha: 0.18);
        border = AppColors.green;
        icon = Icons.check_circle_rounded;
      case _OptionState.wrong:
        bg = AppColors.orange.withValues(alpha: 0.18);
        border = AppColors.orange;
        icon = Icons.cancel_rounded;
      case _OptionState.dimmed:
        bg = AppColors.card;
        border = AppColors.chip;
    }

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border, width: 2.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: state == _OptionState.idle ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: state == _OptionState.dimmed ? AppColors.muted : AppColors.ink,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, color: border),
            ],
          ),
        ),
      ),
    );
  }
}
