import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/theme/density.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact single-line task item suitable for dense desktop lists.
///
/// Classification-related data ([categoryAccent], [showConfidenceIndicators],
/// [showAutoTags], [categoryName], [categoryNameLightBg], [categoryNameBorder])
/// are resolved by the *parent* (e.g., QuadrantList) so that we do not watch
/// global providers inside each row and cause all rows to rebuild on every
/// settings change.
class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    this.onToggle,
    this.onOpen,
    this.selected = false,
    this.categoryAccent,
    this.categoryName,
    this.categoryNameLightBg,
    this.categoryNameBorder,
    this.showConfidenceIndicators = true,
    this.showAutoTags = true,
  });
  final Task task;
  final VoidCallback? onToggle;
  final VoidCallback? onOpen;
  final bool selected;

  /// Accent color for the category dot/strip, or null if not coloring by category.
  final Color? categoryAccent;

  /// Human-readable category name chip label, or null.
  final String? categoryName;

  /// Light background color for the category name chip.
  final Color? categoryNameLightBg;

  /// Border color for the category name chip.
  final Color? categoryNameBorder;

  /// Whether to show the orange low-confidence indicator dot.
  final bool showConfidenceIndicators;

  /// Whether to show auto-tag chips.
  final bool showAutoTags;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = t.extension<SpacingTokens>();
    final borderColor = t.dividerColor;
    final done = task.completedAt != null;
    final lowConfidence = showConfidenceIndicators && task.classificationConfidence == ConfidenceLevel.low;

    final row = SizedBox(
      height: 32,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Checkbox(
              value: done,
              onChanged: (_) => onToggle?.call(),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),
          if (categoryAccent != null) ...[
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: categoryAccent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Tooltip(
              message: task.title,
              waitDuration: const Duration(milliseconds: 450),
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: done
                    ? t.textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: t.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      )
                    : t.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _metaChip('P${task.priority}', t),
          if (task.due != null) SizedBox(width: s?.insetXs ?? 4),
          if (task.due != null) _metaChip(_dueLabel(task.due!), t),
          if (categoryName != null) SizedBox(width: s?.insetXs ?? 4),
          if (categoryName != null)
            _metaChip(
              categoryName!,
              t,
              background: categoryNameLightBg,
              border: categoryNameBorder,
            ),
          if (lowConfidence) ...[
            SizedBox(width: s?.insetXs ?? 4),
            Tooltip(
              message: 'Clasificación de baja confianza',
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFB020),
                ),
              ),
            ),
          ],
          if (showAutoTags && task.autoTags.isNotEmpty) ...[
            SizedBox(width: s?.insetXs ?? 4),
            _metaChip(
              task.autoTags.first,
              t,
              background: const Color(0x332563EB),
              border: const Color(0x882563EB),
            ),
          ],
          SizedBox(width: s?.insetSm ?? 8),
          IconButton(
            onPressed: onOpen,
            icon: const Icon(Icons.more_horiz, size: 16),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
          ),
        ],
      ),
    );

    return FocusableActionDetector(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): const _OpenIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const _ToggleIntent(),
      },
      actions: <Type, Action<Intent>>{
        _OpenIntent: CallbackAction<_OpenIntent>(
          onInvoke: (_) {
            onOpen?.call();
            return null;
          },
        ),
        _ToggleIntent: CallbackAction<_ToggleIntent>(
          onInvoke: (_) {
            onToggle?.call();
            return null;
          },
        ),
      },
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? t.colorScheme.primary.withValues(alpha: 0.06)
              : categoryAccent?.withValues(alpha: 0.035) ?? Colors.transparent,
          border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
        ),
        padding: EdgeInsets.symmetric(horizontal: s?.insetSm ?? 8),
        child: row,
      ),
    );
  }
}

class _OpenIntent extends Intent {
  const _OpenIntent();
}

class _ToggleIntent extends Intent {
  const _ToggleIntent();
}

Widget _metaChip(
  String label,
  ThemeData t, {
  Color? background,
  Color? border,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(width: 0.8, color: border ?? t.dividerColor),
    ),
    child: Text(label, style: t.textTheme.labelMedium),
  );
}

String _dueLabel(DateTime d) {
  final now = DateTime.now();
  final delta = d.difference(now).inDays;
  if (delta <= 0) return 'Hoy';
  if (delta == 1) return 'Mañ';
  if (delta < 7) return '${delta}d';
  return '${(delta / 7).ceil()}w';
}
