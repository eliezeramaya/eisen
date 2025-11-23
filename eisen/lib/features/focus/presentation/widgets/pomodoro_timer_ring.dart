import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:eisen/core/design_system/eisen_tokens.dart';

/// Circular timer ring widget with animated progress
class PomodoroTimerRing extends StatelessWidget {
  final Duration total;
  final Duration remaining;
  final bool isRunning;
  final bool isBreak;
  final bool reduceAnimations;

  const PomodoroTimerRing({
    super.key,
    required this.total,
    required this.remaining,
    this.isRunning = false,
    this.isBreak = false,
    this.reduceAnimations = false,
  });

  @override
  Widget build(BuildContext context) {
    return reduceAnimations ? _buildStatic(context) : _buildAnimated(context);
  }

  Widget _buildAnimated(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.98, end: 1.0),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: isRunning ? scale : 1.0,
          child: _buildRing(context),
        );
      },
    );
  }

  Widget _buildStatic(BuildContext context) {
    return _buildRing(context);
  }

  Widget _buildRing(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total.inSeconds > 0
        ? 1.0 - (remaining.inSeconds / total.inSeconds)
        : 0.0;

    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: CircularProgressPainter(
          progress: progress,
          isBreak: isBreak,
          colorScheme: theme.colorScheme,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(remaining),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 56,
                ),
              ),
              SizedBox(height: EisenSpacing.sm),
              Text(
                isBreak ? 'BREAK' : 'FOCUS',
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for circular progress indicator
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isBreak;
  final ColorScheme colorScheme;

  CircularProgressPainter({
    required this.progress,
    required this.isBreak,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Background circle (track)
    final trackPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round;

    // Use different colors for focus vs break
    if (isBreak) {
      progressPaint.color = colorScheme.secondary;
    } else {
      // Gradient effect for focus phase
      final rect = Rect.fromCircle(center: center, radius: radius);
      progressPaint.shader = LinearGradient(
        colors: [
          colorScheme.primary,
          colorScheme.secondary,
        ],
      ).createShader(rect);
    }

    // Draw arc from top (-90 degrees) clockwise
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Optional: Draw a subtle glow effect when running
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = (isBreak ? colorScheme.secondary : colorScheme.primary)
            .withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isBreak != isBreak ||
        oldDelegate.colorScheme != colorScheme;
  }
}
