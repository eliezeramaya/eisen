import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/completed_tasks/domain/project_category.dart';
import 'package:eisen/features/stats/domain/models.dart';
import 'package:flutter/material.dart';

class NudgesSection extends StatelessWidget {
  const NudgesSection({
    super.key,
    required this.weekly,
    required this.range,
    required this.project,
  });

  final WeeklyStats? weekly;
  final StatsRange range;
  final ProjectCategory project;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = weekly;

    final msgs = <String>[];
    if (w != null) {
      final completed = w.tasksDone.toDouble();
      final planned = completed + w.tasksReplanned;
      final completedRate =
          planned <= 0 ? 0.0 : (completed / planned).clamp(0.0, 1.0);

      const weeklyGoal = 2400; // 40h de foco por 7 días; escalamos por rango
      final scaledGoal =
          (weeklyGoal * (range.days / 7.0)).round().clamp(1, 100000);
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

      if (focus < scaledGoal * 0.5) {
        msgs.add(
          'Tu foco en este periodo está por debajo de tu meta. Bloquea una o dos sesiones cortas extra.',
        );
      }

      if (w.tasksReplanned > w.tasksDone) {
        msgs.add(
          'Replanificas más de lo que completas. Considera priorizar solo lo esencial.',
        );
      }

      if (w.daysActive >= 3 && msgs.isEmpty) {
        msgs.add(
          'Vas bien encaminado. Revisa tu Q2 y protege esos bloques de foco.',
        );
      }
    }

    if (msgs.isEmpty) {
      msgs.add(
        'Empieza con una pequeña sesión de foco hoy. Un solo bloque ya marca la diferencia.',
      );
    }

    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final projectLabel = switch (project) {
      ProjectCategory.all => isEs ? 'todos los proyectos' : 'all projects',
      _ => project.displayName,
    };

    return EisenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EisenSectionHeader(
            title: isEs ? 'Insights' : 'Insights',
            subtitle: isEs
                ? 'Período: ${range.days} días · Proyecto: $projectLabel'
                : 'Period: last ${range.days} days · Project: $projectLabel',
          ),
          const SizedBox(height: 4),
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
