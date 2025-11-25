import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/insights/domain/nudge.dart';
import 'package:eisen/features/insights/domain/nudge_controller.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NudgesSection extends ConsumerWidget {
  const NudgesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(uiPrefsProvider);
    if (!prefs.advancedInsightsEnabled) {
      return EisenCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            EisenSectionHeader(title: 'Recomendaciones inteligentes'),
            SizedBox(height: EisenSpacing.sm),
            Text(
                'Activa insights avanzados en IA y personalización para ver recomendaciones.'),
          ],
        ),
      );
    }

    ref.read(nudgeControllerProvider.notifier).loadNudges();
    final nudgesAsync = ref.watch(nudgeControllerProvider);
    final nudges = nudgesAsync.value?.nudges ?? const <Nudge>[];
    final showLoading = nudgesAsync.isLoading;

    return EisenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EisenSectionHeader(title: 'Recomendaciones inteligentes'),
          const SizedBox(height: EisenSpacing.sm),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: showLoading
                ? const LinearProgressIndicator(minHeight: 2)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: EisenSpacing.sm),
          if (nudges.isEmpty && !showLoading)
            Text(
              'Sin nudges activos por ahora. Sigue protegiendo tus bloques de foco.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          for (final n in nudges.take(3)) ...[
            _NudgeTile(nudge: n),
            const SizedBox(height: EisenSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _NudgeTile extends ConsumerWidget {
  const _NudgeTile({required this.nudge});
  final Nudge nudge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final controller = ref.read(nudgeControllerProvider.notifier);
    final badgeColor = switch (nudge.severity) {
      NudgeSeverity.high => cs.error,
      NudgeSeverity.mediumHigh => cs.primary,
      NudgeSeverity.medium => cs.secondary,
      NudgeSeverity.low => cs.outlineVariant,
    };
    final contextLine = _contextualLine(nudge);

    return EisenCard(
      padding: const EdgeInsets.all(EisenSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: cs.primary),
          const SizedBox(width: EisenSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        nudge.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: EisenSpacing.sm,
                          vertical: EisenSpacing.xs),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(EisenRadius.md),
                      ),
                      child: Text(
                        _severityLabel(nudge.severity),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: badgeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: EisenSpacing.sm),
                Text(
                  nudge.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (contextLine != null) ...[
                  const SizedBox(height: EisenSpacing.xs),
                  Text(
                    contextLine,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: EisenSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _showWhyDialog(context, nudge),
                    child: const Text('¿Por qué veo esto?'),
                  ),
                ),
                const SizedBox(height: EisenSpacing.xs),
                Wrap(
                  spacing: EisenSpacing.sm,
                  runSpacing: EisenSpacing.xs,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        if (nudge.actions.isNotEmpty) {
                          await controller.executeAction(
                              nudge.actions.first, nudge, GoRouter.of(context));
                        } else {
                          await controller.markUseful(nudge);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Gracias por tu feedback, ajustaremos futuras recomendaciones.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text('Útil'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await controller.dismissNudge(nudge);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Gracias por tu feedback, ocultamos esta recomendación.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text('No relevante'),
                    ),
                    if (nudge.actions.isNotEmpty)
                      ...nudge.actions.take(2).map((action) {
                        return FilledButton.tonal(
                          onPressed: () {
                            controller.executeAction(
                                action, nudge, GoRouter.of(context));
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: EisenSpacing.md,
                              vertical: EisenSpacing.xs,
                            ),
                          ),
                          child: Text(action.label),
                        );
                      }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _severityLabel(NudgeSeverity s) {
  switch (s) {
    case NudgeSeverity.high:
      return 'Alta';
    case NudgeSeverity.mediumHigh:
      return 'Media-Alta';
    case NudgeSeverity.medium:
      return 'Media';
    case NudgeSeverity.low:
      return 'Baja';
  }
}

String? _contextualLine(Nudge n) {
  switch (n.type) {
    case NudgeType.lowQ2:
      final share = (n.metadata['q2Share'] as num?)?.toDouble();
      final sample = n.metadata['sample'] as int?;
      if (share == null || sample == null) return null;
      return 'Solo ${(share * 100).toStringAsFixed(1)}% de $sample tareas recientes fueron Q2.';
    case NudgeType.excessiveReschedules:
      final res = n.metadata['rescheduled'] as int?;
      final total = n.metadata['total'] as int?;
      if (res == null || total == null || total == 0) return null;
      final ratio = (res / total) * 100;
      return 'Reprogramaste $res de $total tareas (${ratio.toStringAsFixed(1)}%).';
    case NudgeType.overload:
    case NudgeType.dailyOverload:
      final due =
          n.metadata['q1Today'] as int? ?? n.metadata['dueToday'] as int?;
      final threshold = n.metadata['threshold'] as int?;
      if (due == null) return null;
      return threshold != null
          ? 'Tienes $due tareas urgentes (umbral $threshold).'
          : 'Tienes $due tareas urgentes.';
    case NudgeType.procrastination:
      final count = n.metadata['bigTasksCount'] as int?;
      final days = n.metadata['oldestDays'] as int?;
      if (count == null || days == null) return null;
      return '$count tareas grandes llevan estancadas $days+ días.';
    case NudgeType.quadrantImbalance:
      final share = (n.metadata['share'] as num?)?.toDouble();
      final total = n.metadata['total'] as int?;
      if (share == null || total == null) return null;
      return 'Desbalance: ${(share * 100).toStringAsFixed(0)}% en un solo cuadrante de $total tareas.';
    case NudgeType.noProject:
      final noProject = n.metadata['noProject'] as int?;
      final total = n.metadata['total'] as int?;
      if (noProject == null || total == null) return null;
      final ratio = (noProject / total) * 100;
      return '$noProject de $total tareas sin proyecto (${ratio.toStringAsFixed(0)}%).';
    case NudgeType.noFocusSessions:
      final days = n.metadata['daysSinceLastSession'] as int?;
      if (days == null) return null;
      return 'Hace $days días sin sesiones de foco registradas.';
    case NudgeType.lateNightWork:
      final tasks = n.metadata['lateNightTasks'] as int?;
      final nights = n.metadata['distinctNights'] as int?;
      if (tasks == null || nights == null) return null;
      return '$tasks tareas completadas después de medianoche en $nights noches.';
  }
}

void _showWhyDialog(BuildContext context, Nudge n) {
  final desc =
      _contextualLine(n) ?? 'Basado en tus patrones recientes de actividad.';
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Por qué ves esta recomendación'),
      content: Text(desc),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
