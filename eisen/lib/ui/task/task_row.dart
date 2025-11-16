import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/theme/density.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact single-line task item suitable for dense desktop lists.
class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    this.onToggle,
    this.onOpen,
    this.selected = false,
  });
  final Task task;
  final VoidCallback? onToggle;
  final VoidCallback? onOpen;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = t.extension<SpacingTokens>();
    final borderColor = t.dividerColor;
    final done = task.completedAt != null;

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
                        color: t.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      )
                    : t.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _MetaChip('P${task.priority}', t),
          if (task.due != null) SizedBox(width: s?.insetXs ?? 4),
          if (task.due != null) _MetaChip(_dueLabel(task.due!), t),
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
              ? t.colorScheme.primary.withOpacity(0.06)
              : Colors.transparent,
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

Widget _MetaChip(String label, ThemeData t) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      border: Border.all(width: 0.8, color: t.dividerColor),
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
