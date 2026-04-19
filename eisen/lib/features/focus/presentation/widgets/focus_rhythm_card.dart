import 'dart:math' as math;

import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/features/focus/domain/focus_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FocusRhythmCard extends ConsumerWidget {
  const FocusRhythmCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusDashboardControllerProvider);
    final cs = Theme.of(context).colorScheme;

    return EisenCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Pill(label: 'FOCUS RHYTHM'),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: Text(
                    state.focusScore.toString(),
                    key: ValueKey(state.focusScore),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          height: 1.05,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    state.focusLabel,
                    key: ValueKey(state.focusLabel),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.72),
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FocusRhythmDial(
            progress: state.currentHourPosition,
          ),
        ],
      ),
    );
  }
}

class FocusRhythmDial extends StatelessWidget {
  const FocusRhythmDial({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: CustomPaint(
              key: ValueKey(progress),
              painter: _DialPainter(
                progress: progress,
                trackColor: cs.onSurfaceVariant.withValues(alpha: 0.25),
                accentStart: cs.primary,
                accentEnd: cs.tertiary,
                handleColor: cs.onSurface,
              ),
              child: Center(
                child: Text(
                  'Low focus → Deep focus',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: EisenSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _DialLabel('7 AM'),
              _DialLabel('9 AM'),
              _DialLabel('11 AM'),
              _DialLabel('1 PM'),
              _DialLabel('3 PM'),
              _DialLabel('5 PM'),
              _DialLabel('7 PM'),
              _DialLabel('11 PM'),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialLabel extends StatelessWidget {
  const _DialLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
          ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.progress,
    required this.trackColor,
    required this.accentStart,
    required this.accentEnd,
    required this.handleColor,
  });

  final double progress;
  final Color trackColor;
  final Color accentStart;
  final Color accentEnd;
  final Color handleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final radius = math.min(width / 2 - 12, height - 12);
    final center = Offset(width / 2, height - 8);

    final startAngle = math.pi;
    final sweep = math.pi;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      track,
    );

    final effectiveProgress = progress.clamp(0.0, 1.0);
    final sweepAngle = sweep * effectiveProgress;

    final arc = Paint()
      ..shader = LinearGradient(
        colors: [accentStart, accentEnd],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arc,
    );

    final angle = startAngle + sweepAngle;
    final handleOffset = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    final handlePaint = Paint()
      ..color = handleColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(handleOffset, 6, handlePaint);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.accentStart != accentStart ||
        oldDelegate.accentEnd != accentEnd;
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.04)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 1.5,
              color: cs.onSurface.withValues(alpha: 0.8),
            ),
      ),
    );
  }
}
