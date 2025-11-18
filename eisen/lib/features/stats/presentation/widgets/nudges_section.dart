import 'package:eisen/features/stats/domain/models.dart';
import 'package:flutter/material.dart';

class NudgesSection extends StatelessWidget {
  const NudgesSection({super.key, required this.weekly});

  final WeeklyStats? weekly;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceContainerLow;
    final radius = BorderRadius.circular(12);
    final w = weekly;

    final msgs = <String>[];
    if (w != null) {
      final completed = w.tasksDone.toDouble();
      final planned = completed + w.tasksReplanned;
      final completedRate =
          planned <= 0 ? 0.0 : (completed / planned).clamp(0.0, 1.0);

      const weeklyGoal = 2400; // 40h de foco; se puede hacer configurable
      final focus = w.focusMinutes;

      if (completedRate > 0.8 && focus >= weeklyGoal * 0.5) {
        msgs.add(
          'Estás dedicando tiempo constante a lo importante. Mantén este ritmo.',
        );
      } else if (completedRate < 0.5) {
        msgs.add(
          'Estás completando menos de la mitad de lo planificado. Prueba a planear menos tareas por día.',
        );
      }

      if (focus < weeklyGoal * 0.5) {
        msgs.add(
          'Tu foco semanal está por debajo de tu meta. Bloquea una o dos sesiones cortas extra.',
        );
      }

      if (w.tasksReplanned > w.tasksDone) {
        msgs.add(
          'Replanificas más de lo que completas. Considera priorizar solo lo esencial.',
        );
      }

      if (w.daysActive >= 3 && msgs.isEmpty) {
        msgs.add(
          'Tu semana va bien encaminada. Revisa tu Q2 y protege esos bloques de foco.',
        );
      }
    }

    if (msgs.isEmpty) {
      msgs.add(
        'Empieza con una pequeña sesión de foco hoy. Un solo bloque ya marca la diferencia.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nudges',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (final m in msgs.take(3))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      m,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

