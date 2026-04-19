import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:flutter/material.dart';

class PomodoroControlsRow extends StatelessWidget {
  const PomodoroControlsRow({
    super.key,
    required this.isRunning,
    required this.isPaused,
    required this.onStartOrResume,
    required this.onPause,
    required this.onReset,
    this.onSkip,
  });

  final bool isRunning;
  final bool isPaused;
  final VoidCallback onStartOrResume;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final startLabel = isPaused ? 'Resume' : 'Start';

    return Wrap(
      spacing: EisenSpacing.sm,
      runSpacing: EisenSpacing.sm,
      children: [
        _ControlButton(
          label: startLabel,
          icon: Icons.play_arrow,
          color: cs.primary,
          foreground: cs.onPrimary,
          onTap: onStartOrResume,
          disabled: isRunning && !isPaused,
        ),
        _ControlButton(
          label: 'Pause',
          icon: Icons.pause,
          color: cs.surfaceContainerHighest,
          foreground: cs.onSurface,
          onTap: onPause,
          disabled: !isRunning,
        ),
        _ControlButton(
          label: 'Reset',
          icon: Icons.stop_circle_outlined,
          color: cs.onSurface.withValues(alpha: 0.06),
          foreground: cs.onSurface,
          onTap: onReset,
        ),
        if (onSkip != null)
          _ControlButton(
            label: 'Skip break',
            icon: Icons.skip_next,
            color: cs.secondary.withValues(alpha: 0.18),
            foreground: cs.onSurface,
            onTap: onSkip!,
          ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.foreground,
    required this.onTap,
    this.disabled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color foreground;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = disabled ? color.withValues(alpha: 0.4) : color;

    return Opacity(
      opacity: disabled ? 0.6 : 1.0,
      child: Material(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EisenSpacing.lg,
              vertical: EisenSpacing.sm + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: EisenSpacing.sm),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
