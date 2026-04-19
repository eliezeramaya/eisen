import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/stats/domain/models.dart';
import 'package:flutter/material.dart';

class WeeklyFocusTrendSection extends StatelessWidget {
  const WeeklyFocusTrendSection({
    super.key,
    this.trend,
    required this.range,
  });

  final List<TrendPoint>? trend;
  final StatsRange range;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final points = (trend ?? const <TrendPoint>[]).toList();

    final isEs = Localizations.localeOf(context).languageCode == 'es';
    String dayLabel(DateTime d) {
      switch (d.weekday) {
        case DateTime.monday:
          return isEs ? 'L' : 'M';
        case DateTime.tuesday:
          return isEs ? 'M' : 'T';
        case DateTime.wednesday:
          return isEs ? 'X' : 'W';
        case DateTime.thursday:
          return isEs ? 'J' : 'T';
        case DateTime.friday:
          return isEs ? 'V' : 'F';
        case DateTime.saturday:
          return isEs ? 'S' : 'S';
        case DateTime.sunday:
        default:
          return isEs ? 'D' : 'S';
      }
    }

    final labels =
        points.map((p) => dayLabel(p.day)).toList(growable: false);
    final focusPerDay =
        points.map((p) => p.focusMinutes).toList(growable: false);
    final maxV = focusPerDay.fold<int>(0, (a, b) => b > a ? b : a);

    // Top 1–2 días con más foco.
    final topIndices = List<int>.generate(focusPerDay.length, (i) => i)
      ..sort((a, b) => focusPerDay[b].compareTo(focusPerDay[a]));
    final topDays = <String>[];
    for (final idx in topIndices.take(2)) {
      if (idx >= 0 && idx < labels.length && focusPerDay[idx] > 0) {
        topDays.add(labels[idx]);
      }
    }

    final rangeLabel = switch (range) {
      StatsRange.last7Days =>
        isEs ? 'esta semana' : 'this week',
      StatsRange.last14Days =>
        isEs ? 'estos 14 días' : 'these 14 days',
      StatsRange.last30Days =>
        isEs ? 'estos 30 días' : 'these 30 days',
    };

    final topText = topDays.isEmpty
        ? ''
        : (isEs
            ? 'Tus días más fuertes en $rangeLabel: ${topDays.join(', ')}.'
            : 'Your strongest days in $rangeLabel: ${topDays.join(', ')}.');

    return EisenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EisenSectionHeader(
            title: isEs ? 'Foco por día' : 'Daily focus',
            subtitle: rangeLabel,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(focusPerDay.length, (i) {
                final v = focusPerDay[i];
                final h = maxV == 0 ? 0.0 : (v / maxV).clamp(0.0, 1.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: 8,
                              height: (60 * h).clamp(0.0, 60.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: cs.primary.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[i],
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          if (topText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              topText,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
