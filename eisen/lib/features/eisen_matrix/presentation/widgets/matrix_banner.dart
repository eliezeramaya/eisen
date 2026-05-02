import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/theme/colors.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/insights/domain/nudge.dart';
import 'package:eisen/features/insights_adaptive/domain/cluster_models.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget buildMatrixBanner({
  required BuildContext context,
  required AsyncValue<DailyProductivityScore?> scoreAsync,
  required List<Task> tasks,
  required Nudge? nudge,
  OverloadRisk? overloadRisk,
  AsyncValue<UserProductivityProfile>? profileAsync,
  required VoidCallback onDismissNudge,
  required VoidCallback onOpenStats,
  required VoidCallback onOpenQ2Picker,
}) {
  final cs = Theme.of(context).colorScheme;

  DailyProductivityScore? score;
  scoreAsync.whenData((s) => score = s);

  Widget? banner;
  if (profileAsync != null && profileAsync.value?.cluster != null) {
    final cluster = profileAsync.value!.cluster;
    final bannerContent = _adaptiveBanner(cluster, onOpenStats, onOpenQ2Picker);
    if (bannerContent != null) {
      banner = bannerContent;
    }
  }
  if (banner == null && overloadRisk != null && overloadRisk.score >= 0.8) {
    banner = EisenCard(
      margin: const EdgeInsets.fromLTRB(
        EisenSpacing.md,
        EisenSpacing.md,
        EisenSpacing.md,
        EisenSpacing.sm,
      ),
      padding: const EdgeInsets.all(EisenSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.error),
          const SizedBox(width: EisenSpacing.sm),
          Expanded(
            child: Text(
              'Parece que tu día está sobrecargado. Reorganiza 1–2 tareas.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: onOpenStats,
            child: const Text('Reorganizar'),
          ),
        ],
      ),
    );
  } else if (score != null) {
    if (score!.overloadScore >= 0.66) {
      banner = EisenCard(
        margin: const EdgeInsets.fromLTRB(
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.sm,
        ),
        padding: const EdgeInsets.all(EisenSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.priority_high, color: cs.error),
            const SizedBox(width: EisenSpacing.sm),
            Expanded(
              child: Text(
                'Tu día de hoy parece muy cargado. Considera mover 1–2 tareas a mañana.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
              ),
            ),
            const SizedBox(width: EisenSpacing.sm),
            TextButton(
              onPressed: onOpenStats,
              child: const Text('Reorganizar hoy'),
            ),
          ],
        ),
      );
    } else if (score!.q2Ratio < 0.20) {
      banner = EisenCard(
        margin: const EdgeInsets.fromLTRB(
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.sm,
        ),
        padding: const EdgeInsets.all(EisenSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: cs.primary),
            const SizedBox(width: EisenSpacing.sm),
            Expanded(
              child: Text(
                'Muy poco tiempo en Q2 (importante no urgente). Elige 1 tarea Q2 para hoy.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: EisenSpacing.sm),
            TextButton(
              onPressed: onOpenQ2Picker,
              child: const Text('Elegir tarea Q2'),
            ),
          ],
        ),
      );
    }
  }

  // Si no hay banner de score, usar nudge existente.
  if (banner == null && nudge != null) {
    banner = EisenCard(
      key: ValueKey(nudge.id),
      margin: const EdgeInsets.fromLTRB(
        EisenSpacing.md,
        EisenSpacing.md,
        EisenSpacing.md,
        EisenSpacing.sm,
      ),
      padding: const EdgeInsets.all(EisenSpacing.sm),
      interactive: true,
      child: Row(
        children: [
          const Icon(
            Icons.insights_outlined,
            color: EisenColors.q2,
            size: 20,
          ),
          const SizedBox(width: EisenSpacing.sm),
          Expanded(child: Text(nudge.title)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismissNudge,
          ),
        ],
      ),
    );
  }

  return banner ?? const SizedBox.shrink();
}

void openQ2Picker(BuildContext context, List<Task> tasks) {
  final q2 = tasks.where((t) => t.completedAt == null && t.quadrant == Quadrant.q2).toList();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) {
      if (q2.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(EisenSpacing.lg),
          child: Text('No hay tareas Q2 pendientes.'),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(EisenSpacing.md),
        itemBuilder: (ctx, idx) {
          final t = q2[idx];
          return ListTile(
            leading: const Icon(Icons.star_outline),
            title: Text(t.title),
            subtitle: t.due != null
                ? Text(
                    'Vence: ${t.due}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  )
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tarea seleccionada: ${t.title}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: q2.length,
      );
    },
  );
}

Widget? _adaptiveBanner(
  ProductivityCluster cluster,
  VoidCallback onOpenStats,
  VoidCallback onOpenQ2Picker,
) {
  switch (cluster) {
    case ProductivityCluster.morningStrong:
      return EisenCard(
        margin: const EdgeInsets.fromLTRB(
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.sm,
        ),
        padding: const EdgeInsets.all(EisenSpacing.sm),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_outlined),
            const SizedBox(width: EisenSpacing.sm),
            const Expanded(
              child: Text('Tus mañanas rinden más. Mueve una tarea Q2 a primera hora.'),
            ),
            TextButton(
              onPressed: onOpenQ2Picker,
              child: const Text('Mover Q2'),
            ),
          ],
        ),
      );
    case ProductivityCluster.nightSprinter:
      return EisenCard(
        margin: const EdgeInsets.fromLTRB(
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.sm,
        ),
        padding: const EdgeInsets.all(EisenSpacing.sm),
        child: Row(
          children: [
            const Icon(Icons.nightlight_round),
            const SizedBox(width: EisenSpacing.sm),
            const Expanded(
              child: Text('Has trabajado tarde varios días. Prueba un cierre antes.'),
            ),
            TextButton(
              onPressed: onOpenStats,
              child: const Text('Configurar cierre'),
            ),
          ],
        ),
      );
    case ProductivityCluster.starterButNotFinisher:
      return EisenCard(
        margin: const EdgeInsets.fromLTRB(
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.sm,
        ),
        padding: const EdgeInsets.all(EisenSpacing.sm),
        child: Row(
          children: [
            const Icon(Icons.call_split),
            const SizedBox(width: EisenSpacing.sm),
            const Expanded(
              child: Text('Inicias muchas tareas. Divide una grande en pasos pequeños hoy.'),
            ),
            TextButton(
              onPressed: onOpenQ2Picker,
              child: const Text('Dividir'),
            ),
          ],
        ),
      );
    case ProductivityCluster.unknown:
      return null;
  }
}

double procrastinationScore(Task task) {
  double score = 0.2;
  score += task.replanCount * 0.15;
  if (task.minutes > 180) score += 0.15;
  if (task.quadrant == Quadrant.q4) score += 0.2;
  final title = task.title.toLowerCase();
  const vague = ['revisar', 'ver', 'checar', 'check', 'look', 'review'];
  if (vague.any(title.contains)) {
    score += 0.1;
  }
  return score.clamp(0.0, 1.0);
}
