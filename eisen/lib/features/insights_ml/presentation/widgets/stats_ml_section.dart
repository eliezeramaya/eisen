import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scores.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scoring_service.dart';
import 'package:eisen/features/stats/domain/stats_trends_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsMlSection extends ConsumerWidget {
  const StatsMlSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(statsTrendsControllerProvider);
    final scoring = ref.read(productivityScoringServiceProvider);

    return trendsAsync.when(
      loading: () => const EisenCard(
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final overload = data.overloadRisk;
        final focus = data.focusWindows;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EisenCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EisenSectionHeader(title: 'Riesgo de sobrecarga'),
                  const SizedBox(height: 8),
                  _OverloadBar(risk: overload),
                  const SizedBox(height: 6),
                  Text(
                    'Calculado con tus tareas creadas/completadas recientes.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            EisenCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EisenSectionHeader(title: 'Mejores franjas de foco'),
                  const SizedBox(height: 8),
                  if (focus.isEmpty)
                    FutureBuilder<List<FocusWindowSuggestion>>(
                      future: scoring.computeFocusWindows(),
                      builder: (context, snapshot) {
                        final list = snapshot.data ?? const [];
                        if (list.isEmpty) {
                          return Text(
                            'Aún no tenemos datos suficientes de foco.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          );
                        }
                        return _FocusChips(list: list);
                      },
                    )
                  else
                    _FocusChips(list: focus),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/focus'),
                      icon: const Icon(Icons.timer),
                      label: const Text('Crear bloque fijo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverloadBar extends StatelessWidget {
  const _OverloadBar({required this.risk});
  final OverloadRisk? risk;

  @override
  Widget build(BuildContext context) {
    final score = risk?.score ?? 0.0;
    final tier = score >= 0.75
        ? 'Alto'
        : score >= 0.45
            ? 'Medio'
            : 'Bajo';
    final color = score >= 0.75
        ? Colors.redAccent
        : score >= 0.45
            ? Colors.amber
            : Colors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: score.clamp(0.0, 1.0),
                  minHeight: 10,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tier,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Parece que tu día está ${tier.toLowerCase()}. Ajusta prioridades si es necesario.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FocusChips extends StatelessWidget {
  const _FocusChips({required this.list});
  final List<FocusWindowSuggestion> list;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: list.map((fw) {
        final start =
            '${fw.start.hour.toString().padLeft(2, '0')}:${fw.start.minute.toString().padLeft(2, '0')}';
        final end =
            '${fw.end.hour.toString().padLeft(2, '0')}:${fw.end.minute.toString().padLeft(2, '0')}';
        final conf = (fw.confidence * 100).clamp(0, 100).toStringAsFixed(0);
        return Chip(
          label: Text('Mejor hora: $start–$end • $conf%'),
          avatar: const Icon(Icons.schedule, size: 18),
        );
      }).toList(),
    );
  }
}
