import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/features/focus/presentation/pages/pomodoro_session_page.dart';
import 'package:flutter/material.dart';

class QuickFocusSection extends StatelessWidget {
  const QuickFocusSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick focus',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: EisenSpacing.sm),
        Wrap(
          spacing: EisenSpacing.sm,
          runSpacing: EisenSpacing.sm,
          children: [
            _QuickFocusButton(
              label: '25 min – Clásico',
              icon: Icons.timelapse,
              color: cs.primary.withOpacity(0.14),
              onTap: () => _startPomodoro(
                context,
                const Duration(minutes: 25),
                '25 min – Clásico',
              ),
            ),
            _QuickFocusButton(
              label: '50 min – Profundo',
              icon: Icons.bolt,
              color: cs.tertiary.withOpacity(0.16),
              onTap: () => _startPomodoro(
                context,
                const Duration(minutes: 50),
                '50 min – Profundo',
              ),
            ),
            _QuickFocusButton(
              label: '90 min – Deep work',
              icon: Icons.waves,
              color: cs.secondary.withOpacity(0.14),
              onTap: () => _startPomodoro(
                context,
                const Duration(minutes: 90),
                '90 min – Deep work',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _startPomodoro(
    BuildContext context,
    Duration duration,
    String presetLabel,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PomodoroSessionPage(
          initialDuration: duration,
          presetLabel: presetLabel,
        ),
      ),
    );
  }
}

class _QuickFocusButton extends StatelessWidget {
  const _QuickFocusButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EisenSpacing.lg,
            vertical: EisenSpacing.sm + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: cs.onSurface),
              const SizedBox(width: EisenSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurface,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
