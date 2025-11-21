import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/stats/domain/models.dart';
import 'package:flutter/material.dart';

class WeeklySummarySection extends StatelessWidget {
  const WeeklySummarySection({
    super.key,
    required this.weekly,
    required this.range,
    this.focusGoalMinutes = 2400,
  });

  final WeeklyStats? weekly;
   final StatsRange range;
  final int focusGoalMinutes;

  @override
  Widget build(BuildContext context) {
    final w = weekly;
    final cs = Theme.of(context).colorScheme;

    final focus = w?.focusMinutes ?? 0;
    // Base goal is defined for a 7-day window; scale with range.
    final baseGoal = focusGoalMinutes.clamp(1, 100000);
    final scaledGoal =
        (baseGoal * (range.days / 7.0)).round().clamp(1, 100000);
    final goal = scaledGoal;
    final pct = (focus / goal).clamp(0.0, 1.0);

    final completed = (w?.tasksDone ?? 0).toDouble();
    final planned = completed + (w?.tasksReplanned ?? 0);
    final completedRate =
        planned <= 0 ? 0.0 : (completed / planned).clamp(0.0, 1.0);
    final completedText = (completedRate * 100).toStringAsFixed(
        completedRate >= 0.995 ? 0 : 1); // 0..1 decimal

    final streak = w?.daysActive ?? 0;

    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final title = switch (range) {
      StatsRange.last7Days =>
        isEs ? 'Resumen semanal' : 'Weekly summary',
      StatsRange.last14Days =>
        isEs ? 'Resumen 14 días' : '14-day summary',
      StatsRange.last30Days =>
        isEs ? 'Resumen 30 días' : '30-day summary',
    };
    final focusLabel = switch (range) {
      StatsRange.last7Days =>
        isEs ? 'Foco semanal' : 'Weekly focus',
      StatsRange.last14Days =>
        isEs ? 'Foco (14 días)' : 'Focus (14 days)',
      StatsRange.last30Days =>
        isEs ? 'Foco (30 días)' : 'Focus (30 days)',
    };

    return EisenCard(
      padding: const EdgeInsets.all(EisenSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EisenSectionHeader(title: title, subtitle: focusLabel),
          const SizedBox(height: 4),
          Text(
            '$focus / $goal min',
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
