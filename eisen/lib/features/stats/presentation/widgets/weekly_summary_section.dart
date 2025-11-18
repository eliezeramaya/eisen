import 'package:eisen/features/stats/domain/models.dart';
import 'package:flutter/material.dart';

class WeeklySummarySection extends StatelessWidget {
  const WeeklySummarySection({
    super.key,
    required this.weekly,
    this.focusGoalMinutes = 2400,
  });

  final WeeklyStats? weekly;
  final int focusGoalMinutes;

  @override
  Widget build(BuildContext context) {
    final w = weekly;
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceContainerLow;
    final radius = BorderRadius.circular(12);

    final focus = w?.focusMinutes ?? 0;
    final goal = focusGoalMinutes.clamp(1, 100000);
    final pct = (focus / goal).clamp(0.0, 1.0);

    final completed = (w?.tasksDone ?? 0).toDouble();
    final planned = completed + (w?.tasksReplanned ?? 0);
    final completedRate =
        planned <= 0 ? 0.0 : (completed / planned).clamp(0.0, 1.0);
    final completedText = (completedRate * 100).toStringAsFixed(
        completedRate >= 0.995 ? 0 : 1); // 0..1 decimal

    final streak = w?.daysActive ?? 0;

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
            'Resumen semanal',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Foco semanal: $focus / $goal min',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Completadas: $completedText %',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                'Streak: $streak días',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

