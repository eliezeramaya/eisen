import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/presentation/widgets/confidence_badge.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_recommendations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClassificationPreviewCard extends ConsumerWidget {
  const ClassificationPreviewCard({
    super.key,
    required this.metadata,
    required this.categories,
    this.title = 'Preview live',
    this.subtitle,
    this.compact = false,
    this.onTapCategory,
    this.onTapKind,
  });

  final ClassificationMetadata metadata;
  final List<CategoryConfig> categories;
  final String title;
  final String? subtitle;
  final bool compact;
  final VoidCallback? onTapCategory;
  final VoidCallback? onTapKind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    CategoryConfig? category;
    if (metadata.categoryId != null) {
      for (final item in categories) {
        if (item.id == metadata.categoryId) {
          category = item;
          break;
        }
      }
    }
    final suggestedQuadrant = metadata.suggestedQuadrant;
    final labelStyle =
        ref.watch(uiPrefsProvider.select((prefs) => prefs.quadrantLabelStyle));
    final quadrantLabel = suggestedQuadrant == null
        ? null
        : getQuadrantLabel(suggestedQuadrant, labelStyle);

    return EisenCard(
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              ConfidenceBadge(
                level: metadata.confidenceLevel,
                score: metadata.confidenceScore,
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 16),
          if (metadata.inputText.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 10 : 14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                metadata.inputText,
                maxLines: compact ? 2 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            SizedBox(height: compact ? 10 : 14),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PreviewAction(
                label: 'Categoría',
                value: category?.name ?? 'Sin categoría',
                onTap: onTapCategory,
                icon: Icons.category_outlined,
              ),
              _PreviewAction(
                label: 'Tipo',
                value: metadata.entryKind.label,
                onTap: onTapKind,
                icon: Icons.layers_outlined,
              ),
              _PreviewStat(
                label: 'Horizonte',
                value: metadata.timeHorizon.label,
              ),
              _PreviewStat(
                label: 'Energía',
                value: metadata.energyLevel.label,
              ),
              _PreviewStat(
                label: 'Prioridad',
                value: metadata.priorityLevel.label,
              ),
              _PreviewStat(
                label: 'Confianza',
                value: metadata.confidenceLevel.label,
              ),
              if (quadrantLabel != null)
                _PreviewStat(
                  label: 'Cuadrante sugerido',
                  value: quadrantLabel.title,
                  detail: quadrantLabel.subtitle,
                  icon: Icons.grid_view_outlined,
                ),
              if (suggestedQuadrant != null)
                _PreviewStat(
                  label: 'Recomendación',
                  value: getQuadrantRecommendation(suggestedQuadrant),
                  icon: Icons.tips_and_updates_outlined,
                ),
            ],
          ),
          if (metadata.reasons.isNotEmpty) ...[
            SizedBox(height: compact ? 12 : 16),
            Text(
              'Señales detectadas',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            for (final reason in metadata.reasons.take(compact ? 2 : 3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.subdirectory_arrow_right, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(reason)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PreviewAction extends StatelessWidget {
  const _PreviewAction({
    required this.label,
    required this.value,
    this.onTap,
    this.icon,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = _PreviewStat(
      label: label,
      value: value,
      icon: icon,
    );
    if (onTap == null) {
      return child;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: child,
    );
  }
}

class _PreviewStat extends StatelessWidget {
  const _PreviewStat({
    required this.label,
    required this.value,
    this.detail,
    this.icon,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(
              detail!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
