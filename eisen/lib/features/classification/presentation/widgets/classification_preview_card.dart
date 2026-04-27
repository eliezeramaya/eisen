import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/presentation/widgets/category_chip.dart';
import 'package:eisen/features/classification/presentation/widgets/confidence_badge.dart';
import 'package:flutter/material.dart';

class ClassificationPreviewCard extends StatelessWidget {
  const ClassificationPreviewCard({
    super.key,
    required this.metadata,
    required this.categories,
    this.title = 'Preview live',
    this.subtitle,
  });

  final ClassificationMetadata metadata;
  final List<CategoryConfig> categories;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    CategoryConfig? category;
    if (metadata.categoryId != null) {
      for (final item in categories) {
        if (item.id == metadata.categoryId) {
          category = item;
          break;
        }
      }
    }

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
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              metadata.inputText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (category != null)
                CategoryChip(category: category, selected: true),
              _PreviewStat(
                label: 'Tipo',
                value: metadata.entryKind.label,
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
            ],
          ),
          if (metadata.reasons.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Señales detectadas',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            for (final reason in metadata.reasons.take(3))
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

class _PreviewStat extends StatelessWidget {
  const _PreviewStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
