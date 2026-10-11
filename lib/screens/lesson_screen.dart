import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:chance/engine/lesson_sim.dart';
import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/screens/quiz_screen.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';

/// Generic lesson page. Any [LessonSpec] plugs into this layout:
/// header → title → animated stage + controls → big idea → try it → quiz.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.spec});
  final LessonSpec spec;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  late final LessonSim _sim;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _sim = widget.spec.createSim();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_sim.playing) {
      // Clamp so a dropped frame doesn't teleport everything.
      _sim.advance(math.min(dt, 0.05) * _sim.speed);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _Header(label: spec.chapterLabel),
              const SizedBox(height: 18),
              Text.rich(
                TextSpan(
                  children: [
                    for (final part in spec.title)
                      TextSpan(
                        text: part.text,
                        style: TextStyle(color: part.color ?? AppColors.ink),
                      ),
                  ],
                ),
                style: kDisplay,
              ),
              const SizedBox(height: 6),
              Text(
                spec.subtitle,
                style: const TextStyle(fontSize: 15, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              _StageCard(spec: spec, sim: _sim),
              const SizedBox(height: 16),
              _BigIdeaCard(spec: spec, sim: _sim),
              const SizedBox(height: 16),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.tryItTitle,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    spec.buildTryIt(_sim),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              BigButton(
                label: 'Quick check · ${spec.quiz.length} questions',
                color: AppColors.pink,
                onPressed: () {
                  if (_sim.playing) _sim.togglePlay();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => QuizScreen(spec: spec)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          child: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label.toUpperCase(),
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: AppColors.muted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const XpChip(),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.spec, required this.sim});
  final LessonSpec spec;
  final LessonSim sim;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          ListenableBuilder(
            listenable: sim,
            builder: (context, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in spec.stats(sim)) _StatPill(stat: s),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ColoredBox(
              color: AppColors.board,
              child: AspectRatio(
                aspectRatio: spec.visualAspectRatio,
                child: spec.buildVisual(sim),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Controls(sim: sim),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.stat});
  final StatChip stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${stat.label} ',
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
            TextSpan(
              text: stat.value,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.sim});
  final LessonSim sim;

  static const _speeds = <double>[0.5, 1, 3];
  static const _speedLabels = <String>['½×', '1×', '3×'];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) => Row(
        children: [
          _SquareButton(
            icon: Icons.replay_rounded,
            tooltip: 'Reset',
            onTap: sim.reset,
          ),
          const SizedBox(width: 10),
          _SquareButton(
            icon: sim.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            tooltip: sim.playing ? 'Pause' : 'Play',
            onTap: sim.togglePlay,
            size: 62,
            color: AppColors.pink,
            iconColor: Colors.white,
          ),
          const SizedBox(width: 10),
          _SquareButton(
            icon: Icons.skip_next_rounded,
            tooltip: 'Step',
            onTap: () {
              if (sim.playing) sim.togglePlay();
              sim.step();
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.chip,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _speeds.length; i++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => sim.setSpeed(_speeds[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sim.speed == _speeds[i]
                                ? AppColors.cyan
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _speedLabels[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: sim.speed == _speeds[i]
                                  ? AppColors.ink
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 48,
    this.color = AppColors.chip,
    this.iconColor = AppColors.ink,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.33),
        child: InkWell(
          borderRadius: BorderRadius.circular(size * 0.33),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: iconColor, size: size * 0.48),
          ),
        ),
      ),
    );
  }
}

class _BigIdeaCard extends StatelessWidget {
  const _BigIdeaCard({required this.spec, required this.sim});
  final LessonSpec spec;
  final LessonSim sim;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: AppColors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THE BIG IDEA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            spec.bigIdea,
            style: const TextStyle(
              fontSize: 17,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: sim,
            builder: (context, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                spec.formula(sim),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
