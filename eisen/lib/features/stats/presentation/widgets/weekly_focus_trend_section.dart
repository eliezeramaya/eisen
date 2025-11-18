import 'package:eisen/features/stats/domain/models.dart';
import 'package:flutter/material.dart';

class WeeklyFocusTrendSection extends StatelessWidget {
  const WeeklyFocusTrendSection({super.key, this.trend});

  final List<TrendPoint>? trend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceContainerLow;
    final radius = BorderRadius.circular(12);
    final points = (trend ?? const <TrendPoint>[]).take(7).toList();

    final labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
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

    final topText = topDays.isEmpty
        ? ''
        : 'Tus días más fuertes esta semana: ${topDays.join(', ')}.';

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
            'Foco esta semana',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = i < focusPerDay.length ? focusPerDay[i] : 0;
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

