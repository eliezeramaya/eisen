import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/eisen_matrix/domain/category_colors.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';

class TreemapTileTooltip extends StatelessWidget {
  const TreemapTileTooltip({
    required this.task,
    required this.position,
    required this.screenSize,
    this.categoryColorService,
    this.showConfidenceIndicators = true,
    this.showAutoTags = true,
  });

  final Task task;
  final Offset position;
  final Size screenSize;
  final CategoryColorService? categoryColorService;
  final bool showConfidenceIndicators;
  final bool showAutoTags;

  @override
  Widget build(BuildContext context) {
    const tooltipWidth = 320.0;
    const tooltipMaxHeight = 400.0;
    const padding = 16.0;

    // Position tooltip near cursor, but ensure it stays on screen
    double left = position.dx + 20;
    double top = position.dy - 20;

    // Adjust if would go off right edge
    if (left + tooltipWidth > screenSize.width - padding) {
      left = position.dx - tooltipWidth - 20;
    }

    // Adjust if would go off bottom
    if (top + tooltipMaxHeight > screenSize.height - padding) {
      top = screenSize.height - tooltipMaxHeight - padding;
    }

    // Adjust if would go off top
    if (top < padding) {
      top = padding;
    }

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          shadowColor: Colors.black45,
          child: Container(
            width: tooltipWidth,
            constraints: const BoxConstraints(maxHeight: tooltipMaxHeight),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Quadrant
                  _TooltipRow(
                    icon: Icons.grid_view_rounded,
                    label: 'Quadrant',
                    value: task.quadrant.name.toUpperCase(),
                  ),
                  const SizedBox(height: 8),

                  // Priority & Time
                  Row(
                    children: [
                      Expanded(
                        child: _TooltipRow(
                          icon: Icons.priority_high,
                          label: 'Priority',
                          value: '${task.priority}/10',
                        ),
                      ),
                      Expanded(
                        child: _TooltipRow(
                          icon: Icons.timer_outlined,
                          label: 'Time',
                          value: '${task.minutes}m',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Due date
                  if (task.due != null) ...[
                    _TooltipRow(
                      icon: Icons.calendar_today,
                      label: 'Due',
                      value: _formatFullDate(task.due!),
                      isUrgent: task.due!.isBefore(DateTime.now()) ||
                          task.due!.difference(DateTime.now()).inDays <= 1,
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Category
                  if (_categoryNameForTask(task) != null &&
                      _categoryNameForTask(task)!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: (categoryColorService ??
                                    const CategoryColorService())
                                .getLightVariant(_categoryNameForTask(task)!),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (categoryColorService ??
                                      const CategoryColorService())
                                  .getDarkVariant(_categoryNameForTask(task)!),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _categoryNameForTask(task)!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (showConfidenceIndicators &&
                      task.classificationConfidence == ConfidenceLevel.low) ...[
                    _TooltipRow(
                      icon: Icons.warning_amber_rounded,
                      label: 'Clasificación',
                      value: 'Baja confianza',
                      isUrgent: true,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Tags
                  if (_displayTagsForTask(
                    task,
                    showAutoTags: showAutoTags,
                  ).isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _displayTagsForTask(
                              task,
                              showAutoTags: showAutoTags,
                            )
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tag,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Notes preview
                  if (task.notes != null && task.notes!.isNotEmpty) ...[
                    const Divider(height: 16),
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff < 0) return 'Overdue (${date.day}/${date.month}/${date.year})';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

String? _categoryNameForTask(Task task) {
  final category = task.category ?? task.categoryId;
  if (category == null) return null;
  final trimmed = category.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _displayTagsForTask(
  Task task, {
  bool showAutoTags = true,
}) {
  return <String>[
    ...task.tags,
    if (showAutoTags) ...task.autoTags,
  ];
}

/// Helper widget for tooltip rows
class _TooltipRow extends StatelessWidget {
  const _TooltipRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isUrgent = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isUrgent
              ? Colors.redAccent
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isUrgent
                    ? Colors.redAccent
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}

