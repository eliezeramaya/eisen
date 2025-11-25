import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scores.dart';
import 'package:eisen/features/stats/domain/stats_trends_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsProductivityScoresSection extends ConsumerWidget {
  const StatsProductivityScoresSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(statsTrendsControllerProvider);
    return trendsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final latest = data.dailyScores.isNotEmpty ? data.dailyScores.last : null;
        final focusWindows = data.focusWindows;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EisenSectionHeader(title: 'Radar de productividad'),
            const SizedBox(height: EisenSpacing.sm),
            EisenCard(
              padding: const EdgeInsets.all(EisenSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (latest != null) ...[
                    _OverloadTile(score: latest.overloadScore),
                    const SizedBox(height: EisenSpacing.sm),
                    _q2RatioTile(context, latest.q2Ratio),
                    const SizedBox(height: EisenSpacing.sm),
                    _procrastinationTile(context, latest.procrastinationScore),
                    const SizedBox(height: EisenSpacing.sm),
                    _focusConsistencyTile(
                      context,
                      latest.focusConsistencyScore,
                    ),
                    const SizedBox(height: EisenSpacing.md),
                  ] else ...[
                    Text(
                      'Aún no hay datos suficientes para generar tu radar.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: EisenSpacing.md),
                  ],
                  _focusWindowsChips(context, focusWindows),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverloadTile extends StatelessWidget {
  const _OverloadTile({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final level = _OverloadLevel.fromScore(score);
    return Row(
      children: [
        Icon(level.icon, color: level.color(cs)),
        const SizedBox(width: EisenSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riesgo de sobrecarga',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                level.label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: level.color(cs)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverloadLevel {
  const _OverloadLevel(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color Function(ColorScheme) color;

  static _OverloadLevel fromScore(double s) {
    if (s >= 0.66) {
      return _OverloadLevel(
        'Alto: reduce compromisos hoy',
        Icons.priority_high,
        (cs) => cs.error,
      );
    }
    if (s >= 0.33) {
      return _OverloadLevel(
        'Medio: prioriza top 3 y replanifica',
        Icons.warning_amber_rounded,
        (cs) => cs.tertiary,
      );
    }
    return _OverloadLevel(
      'Bajo: ritmo sostenible',
      Icons.check_circle_outline,
      (cs) => cs.primary,
    );
  }
}

Widget _q2RatioTile(BuildContext context, double ratio) {
  final percent = (ratio * 100).clamp(0, 100).toStringAsFixed(0);
  final cs = Theme.of(context).colorScheme;
  final tone = ratio >= 0.25
      ? 'Buen balance en Q2.'
      : 'Refuerza más Q2 para prevenir urgencias.';
  return Row(
    children: [
      Icon(Icons.auto_awesome, color: cs.primary),
      const SizedBox(width: EisenSpacing.sm),
      Expanded(
        child: Text(
          'Últimos días: $percent% de tus tareas completadas fueron Q2. $tone',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}

Widget _procrastinationTile(BuildContext context, double score) {
  final cs = Theme.of(context).colorScheme;
  final label = score >= 0.5
      ? 'Procrastinación alta: replanificando demasiado.'
      : 'Procrastinación bajo control.';
  final icon = score >= 0.5 ? Icons.update : Icons.task_alt;
  final color = score >= 0.5 ? cs.error : cs.primary;
  return Row(
    children: [
      Icon(icon, color: color),
      const SizedBox(width: EisenSpacing.sm),
      Expanded(
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: color),
        ),
      ),
    ],
  );
}

Widget _focusConsistencyTile(BuildContext context, double score) {
  final cs = Theme.of(context).colorScheme;
  final label = score >= 1.0
      ? 'Consistencia de foco: Excelente'
      : score >= 0.6
          ? 'Consistencia de foco: Buena'
          : 'Consistencia de foco: Irregular';
  final color = score >= 0.6 ? cs.primary : cs.tertiary;
  return Row(
    children: [
      Icon(Icons.timer_outlined, color: color),
      const SizedBox(width: EisenSpacing.sm),
      Expanded(
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: color),
        ),
      ),
    ],
  );
}

Widget _focusWindowsChips(
  BuildContext context,
  List<FocusWindowSuggestion> focusWindows,
) {
  if (focusWindows.isEmpty) {
    return Text(
      'Aún no tenemos ventanas de foco recomendadas.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
  String fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Mejores ventanas de foco',
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: EisenSpacing.xs),
      Wrap(
        spacing: EisenSpacing.sm,
        runSpacing: EisenSpacing.xs,
        children: focusWindows.take(3).map((fw) {
          final label = '${fmt(fw.start)}–${fmt(fw.end)}';
          final conf = (fw.confidence * 100).clamp(0, 100).toStringAsFixed(0);
          return Chip(
            label: Text('$label · Confianza $conf%'),
            avatar: const Icon(Icons.schedule, size: 18),
          );
        }).toList(),
      ),
    ],
  );
}
