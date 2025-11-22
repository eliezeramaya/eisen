import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/insights/domain/nudge.dart';
import 'package:eisen/features/insights/domain/nudge_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NudgesSection extends ConsumerWidget {
  const NudgesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(nudgeControllerProvider.notifier).loadNudges();
    final nudgesAsync = ref.watch(nudgeControllerProvider);
    final nudges = nudgesAsync.value?.nudges ?? const <Nudge>[];
    final showLoading = nudgesAsync.isLoading;

    return EisenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EisenSectionHeader(title: 'Insights de la semana'),
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
                        borderRadius:
                            BorderRadius.circular(EisenRadius.md),
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
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => controller.dismissNudge(nudge),
                    child: const Text('Descartar'),
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
      final due = n.metadata['dueToday'] as int?;
      final threshold = n.metadata['threshold'] as int?;
      if (due == null || threshold == null) return null;
      return 'Tienes $due tareas para hoy (umbral $threshold).';
  }
}
