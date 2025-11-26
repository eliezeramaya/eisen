import 'dart:math' as math;

import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:flutter/material.dart';

enum PomodoroPhase { focus, shortBreak, longBreak }

class PomodoroTimerCard extends StatelessWidget {
  const PomodoroTimerCard({
    super.key,
    required this.remaining,
    required this.total,
    required this.phase,
    required this.cycle,
    this.presetLabel,
    this.taskTitle,
    this.isRunning = false,
  });

  final Duration remaining;
  final Duration total;
  final PomodoroPhase phase;
  final int cycle;
  final String? presetLabel;
  final String? taskTitle;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = total.inSeconds == 0
        ? 0.0
        : 1 - (remaining.inSeconds / total.inSeconds);

    final phaseLabel = switch (phase) {
      PomodoroPhase.focus => 'FOCUS',
      PomodoroPhase.shortBreak => 'SHORT BREAK',
      PomodoroPhase.longBreak => 'LONG BREAK',
    };

    return EisenCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Pill(label: 'FOCUS SESSION'),
          const SizedBox(height: EisenSpacing.lg),
          Center(
            child: SizedBox(
              height: 240,
              width: 240,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: progress, end: progress),
                builder: (_, value, __) {
                  return CustomPaint(
                    painter: _TimerArcPainter(
                      progress: value,
                      colorScheme: cs,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Text(
                              _format(remaining),
                              key: ValueKey(remaining.inSeconds),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 58,
                                  ),
                            ),
                          ),
                          const SizedBox(height: EisenSpacing.xs),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              phaseLabel,
                              key: ValueKey(phaseLabel),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    letterSpacing: 2,
                                    color: cs.onSurface.withOpacity(0.72),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: EisenSpacing.lg),
          Row(
            children: [
              Icon(
                isRunning ? Icons.play_arrow : Icons.pause_circle,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: EisenSpacing.sm),
              Text(
                isRunning ? 'En curso' : 'Pausado',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              Text(
                'Ciclo $cycle',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          if (presetLabel != null || taskTitle != null) ...[
            const SizedBox(height: EisenSpacing.sm),
            Text(
              [
                if (presetLabel != null) presetLabel,
                if (taskTitle != null) '• $taskTitle',
              ].join(' '),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.8),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _TimerArcPainter extends CustomPainter {
  _TimerArcPainter({
    required this.progress,
    required this.colorScheme,
  });

  final double progress;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    final track = Paint()
      ..color = colorScheme.surfaceContainerHighest.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          colorScheme.primary,
          colorScheme.tertiary,
          colorScheme.primary,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );

    final knobAngle = -math.pi / 2 + sweep;
    final knobOffset = Offset(
      center.dx + radius * math.cos(knobAngle),
      center.dy + radius * math.sin(knobAngle),
    );
    final knob = Paint()
      ..color = colorScheme.onSurface
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(knobOffset, 6, knob);
  }

  @override
  bool shouldRepaint(covariant _TimerArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EisenSpacing.lg,
        vertical: EisenSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.onSurface.withOpacity(0.04)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 1.5,
              color: cs.onSurface.withOpacity(0.8),
            ),
      ),
    );
  }
}
