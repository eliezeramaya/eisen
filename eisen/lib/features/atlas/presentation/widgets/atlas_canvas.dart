import 'package:eisen/features/atlas/application/atlas_animation_controller.dart';
import 'package:eisen/features/atlas/application/atlas_layout_engine.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_empty_state.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_painter.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_tile.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';

class AtlasCanvas extends StatelessWidget {
  const AtlasCanvas({
    super.key,
    required this.nodes,
    required this.focusedTaskIds,
    required this.selectedTaskId,
    required this.emptyStateKind,
    required this.onTaskSelected,
    required this.onTaskLongPress,
    this.onGroupTap,
  });

  final List<AtlasNode> nodes;
  final Set<String> focusedTaskIds;
  final String? selectedTaskId;
  final AtlasEmptyStateKind emptyStateKind;
  final ValueChanged<Task> onTaskSelected;
  final ValueChanged<Task> onTaskLongPress;
  final ValueChanged<AtlasNode>? onGroupTap;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return AtlasEmptyState(kind: emptyStateKind);
    }

    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final rects = computeAtlasLayout(
              nodes: nodes,
              size: size,
              padding: const EdgeInsets.all(8),
            );
            final nodeById = <String, AtlasNode>{};
            for (final node in nodes) {
              _collectNodes(node, nodeById);
            }

            if (shouldUseAtlasCustomPainter(nodes)) {
              return AtlasPainterCanvas(
                rects: rects,
                nodeById: nodeById,
                focusedTaskIds: focusedTaskIds,
                selectedTaskId: selectedTaskId,
                onTaskSelected: onTaskSelected,
                onTaskLongPress: onTaskLongPress,
                onGroupTap: onGroupTap,
              );
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final layout in rects)
                  if (nodeById[layout.nodeId] case final node?)
                    AnimatedPositioned.fromRect(
                      key: ValueKey(node.id),
                      rect: layout.rect,
                      duration: AtlasAnimationTokens.position,
                      curve: AtlasAnimationTokens.curve,
                      child: AtlasTile(
                        node: node,
                        size: layout.rect.size,
                        isSelected: node.task?.id == selectedTaskId,
                        isFocused: node.task != null &&
                            focusedTaskIds.contains(node.task!.id),
                        onTap: node.task != null
                            ? () => onTaskSelected(node.task!)
                            : () => onGroupTap?.call(node),
                        onLongPress: node.task != null
                            ? () => onTaskLongPress(node.task!)
                            : () => onGroupTap?.call(node),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _collectNodes(AtlasNode node, Map<String, AtlasNode> out) {
    out[node.id] = node;
    for (final child in node.children) {
      _collectNodes(child, out);
    }
  }
}
