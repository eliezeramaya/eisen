import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';

/// Individual card for displaying a completed task.
///
/// Shows:
/// - Task title
/// - Priority badge
/// - Duration badge
/// - Completion date
/// - Category (if present)
///
/// Optimized for list views with const constructor.
class CompletedTaskCard extends StatelessWidget {
  const CompletedTaskCard({
    super.key,
    required this.task,
    required this.zoomFactor,
    this.onTap,
    this.isSelected = false,
  });

  final Task task;
  final double zoomFactor;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Scale sizes based on zoom
    final titleSize = 14.0 * zoomFactor;
    final metaSize = 11.0 * zoomFactor;
    final padding = 12.0 * zoomFactor;
    final spacing = 8.0 * zoomFactor;

    // Quadrant color
    final quadrantColor = _getQuadrantColor(task.quadrant, colorScheme);

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8 * zoomFactor),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : quadrantColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8 * zoomFactor),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                task.title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: spacing),

              // Metadata row
              Row(
                children: [
                  // Priority badge
                  _Badge(
                    label: 'P${task.priority}',
                    color: _getPriorityColor(task.priority, colorScheme),
                    fontSize: metaSize,
                  ),
                  SizedBox(width: spacing / 2),

                  // Duration badge
                  _Badge(
                    label: '${task.minutes}m',
                    color: colorScheme.tertiaryContainer,
                    fontSize: metaSize,
                  ),

                  const Spacer(),

                  // Completion date
                  if (task.completedAt != null)
                    Text(
                      _formatCompletedDate(task.completedAt!),
                      style: TextStyle(
                        fontSize: metaSize,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),

              // Category (if present)
              if (task.category != null && task.category!.isNotEmpty) ...[
                SizedBox(height: spacing / 2),
                Text(
                  task.category!,
                  style: TextStyle(
                    fontSize: metaSize,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getQuadrantColor(Quadrant q, ColorScheme cs) => switch (q) {
    Quadrant.q1 => cs.error,
    Quadrant.q2 => cs.primary,
    Quadrant.q3 => cs.tertiary,
    Quadrant.q4 => cs.outline,
  };

  Color _getPriorityColor(int priority, ColorScheme cs) {
    if (priority >= 8) return cs.errorContainer;
    if (priority >= 5) return cs.primaryContainer;
    return cs.surfaceContainerHigh;
  }

  String _formatCompletedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Hoy ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (taskDate == yesterday) {
      return 'Ayer ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Simple badge widget for metadata
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.fontSize,
  });

  final String label;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
    );
  }
}
