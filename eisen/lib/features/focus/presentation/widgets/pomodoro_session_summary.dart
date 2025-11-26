import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/features/focus/presentation/widgets/pomodoro_timer_card.dart';
import 'package:flutter/material.dart';

class PomodoroSessionSummary extends StatelessWidget {
  const PomodoroSessionSummary({
    super.key,
    this.taskTitle,
    required this.elapsed,
    required this.cycle,
    required this.phase,
  });

  final String? taskTitle;
  final Duration elapsed;
  final int cycle;
  final PomodoroPhase phase;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EisenCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: EisenSpacing.sm),
          _RowItem(
            label: 'Estado',
            value: _phaseLabel(phase),
            color: cs.onSurface,
          ),
          _RowItem(
            label: 'Ciclo',
            value: '$cycle',
            color: cs.onSurfaceVariant,
          ),
          _RowItem(
            label: 'Tiempo invertido',
            value: _format(elapsed),
            color: cs.onSurfaceVariant,
          ),
          if (taskTitle != null)
            _RowItem(
              label: 'Tarea',
              value: taskTitle!,
              color: cs.onSurface,
            ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    return hours > 0 ? '$hours h $minutes m' : '$minutes min';
  }

  String _phaseLabel(PomodoroPhase phase) {
    return switch (phase) {
      PomodoroPhase.focus => 'Focus',
      PomodoroPhase.shortBreak => 'Break',
      PomodoroPhase.longBreak => 'Long break',
    };
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EisenSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withOpacity(0.8),
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
