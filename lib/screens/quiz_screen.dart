import 'package:flutter/material.dart';

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/state/progress.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.spec});
  final LessonSpec spec;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int? _picked;
  int _score = 0;
  bool _finished = false;

  static const _optionColors = [AppColors.pink, AppColors.orange, AppColors.blue, AppColors.violet];

  List<QuizQuestion> get _quiz => widget.spec.quiz;

  void _pick(int option) {
    if (_picked != null) return;
    setState(() {
      _picked = option;
      if (option == _quiz[_index].answer) _score++;
    });
  }

  void _next() {
    if (_index + 1 < _quiz.length) {
      setState(() {
        _index++;
        _picked = null;
      });
    } else {
      Progress.complete(widget.spec.id, 10 + _score * 10);
      setState(() => _finished = true);
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
        Text(
          'QUESTION ${_index + 1} OF ${_quiz.length}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: AppColors.muted,
          ),
        ),
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
                  color: correct
                      ? AppColors.green.withValues(alpha: 0.16)
                      : AppColors.orange.withValues(alpha: 0.16),
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
          perfect ? 'Perfect score!' : 'Lesson complete!',
          textAlign: TextAlign.center,
          style: kDisplay,
        ),
        const SizedBox(height: 8),
        Text(
          'You got $_score of ${_quiz.length} right · +${10 + _score * 10} XP',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.muted),
        ),
        const SizedBox(height: 32),
        BigButton(
          label: 'Back to lessons',
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
