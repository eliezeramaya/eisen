import 'package:flutter/material.dart';
import '../../domain/models.dart';

class CardWeek extends StatelessWidget {
  final WeeklyStats? weekly;
  const CardWeek({super.key, this.weekly});

  @override
  Widget build(BuildContext context) {
    final w = weekly;
    return Card(
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Semana', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (w == null) const Text('Cargando…') else ...[
              Text('Completadas: ${w.tasksDone}'),
              Text('Replanificadas: ${w.tasksReplanned}'),
              Text('Foco: ${w.focusMinutes} min'),
              Text('Lead time (mediana): ${w.leadTimeHoursMedian.toStringAsFixed(1)} h'),
            ],
          ],
        ),
      ),
    );
  }
}

