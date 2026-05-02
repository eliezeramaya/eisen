import 'package:eisen/features/atlas/application/atlas_animation_controller.dart';
import 'package:eisen/features/atlas/application/atlas_layout_engine.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:eisen/features/atlas/domain/atlas_responsive_config.dart';
import 'package:eisen/features/atlas/domain/atlas_semantic_zoom.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_empty_state.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_painter.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_tile.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';

class AtlasCanvas extends StatefulWidget {
  const AtlasCanvas({
    super.key,
    required this.nodes,
    required this.focusedTaskIds,
    this.insightTaskIds = const <String>{},
    required this.selectedTaskId,
    required this.emptyStateKind,
    required this.onTaskSelected,
    required this.onTaskLongPress,
    this.zoomState,
    this.onZoomChanged,
    this.onZoomIn,
    this.onZoomOut,
    this.onZoomReset,
    this.onGroupTap,
    this.exportMode = false,
  });

  final List<AtlasNode> nodes;
  final Set<String> focusedTaskIds;
  final Set<String> insightTaskIds;
  final String? selectedTaskId;
  final AtlasEmptyStateKind emptyStateKind;
  final ValueChanged<Task> onTaskSelected;
  final ValueChanged<Task> onTaskLongPress;
  final AtlasZoomState? zoomState;
  final void Function(double scale, Offset offset)? onZoomChanged;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomReset;
  final ValueChanged<AtlasNode>? onGroupTap;
  final bool exportMode;

  @override
  State<AtlasCanvas> createState() => _AtlasCanvasState();
}

class _AtlasCanvasState extends State<AtlasCanvas> {
  late final TransformationController _transformController;

  AtlasZoomState get _zoom => widget.zoomState ?? AtlasZoomState.initial();

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController(_matrixFor(_zoom));
  }

  @override
  void didUpdateWidget(covariant AtlasCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoomState != widget.zoomState) {
      _syncTransformController();
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return AtlasEmptyState(kind: widget.emptyStateKind);
    }

    final theme = Theme.of(context);
    final config =
        atlasResponsiveConfigForWidth(MediaQuery.sizeOf(context).width);
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
              nodes: widget.nodes,
              size: size,
              padding: config.canvasPadding,
              gap: config.tileGap,
              groupHeaderHeight: config.groupHeaderHeight,
              minInteractiveTileSize: config.minInteractiveTileSize,
              maxDepth: _zoom.semanticLevel.maxLayoutDepth,
            );
            final renderableNodeCount = countAtlasRenderableNodes(widget.nodes);
            final compactMode =
                renderableNodeCount > config.maxWidgetTilesBeforeCompact ||
                    !_zoom.semanticLevel.showRichTaskContent;
            final nodeById = <String, AtlasNode>{};
            for (final node in widget.nodes) {
              _collectNodes(node, nodeById);
            }

            final content = shouldUseAtlasCustomPainter(
              widget.nodes,
              threshold: config.maxWidgetTilesBeforePainter,
            )
                ? AtlasPainterCanvas(
                    rects: rects,
                    nodeById: nodeById,
                    focusedTaskIds: widget.focusedTaskIds,
                    insightTaskIds: widget.insightTaskIds,
                    selectedTaskId: widget.selectedTaskId,
                    onTaskSelected: widget.onTaskSelected,
                    onTaskLongPress: widget.onTaskLongPress,
                    largeDatasetThreshold: config.maxWidgetTilesBeforePainter,
                    semanticLevel: _zoom.semanticLevel,
                    exportMode: widget.exportMode,
                    onGroupTap: widget.onGroupTap,
                  )
                : Stack(
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
                              minReadableSize: config.minReadableTileSize,
                              compactMode: compactMode,
                              enableHover:
                                  config.enableHover && !widget.exportMode,
                              exportMode: widget.exportMode,
                              semanticLevel: _zoom.semanticLevel,
                              isSelected:
                                  node.task?.id == widget.selectedTaskId,
                              isFocused: node.task != null &&
                                  widget.focusedTaskIds.contains(node.task!.id),
                              isInsightHighlighted: node.task != null &&
                                  widget.insightTaskIds.contains(node.task!.id),
                              onTap: node.task != null
                                  ? () => widget.onTaskSelected(node.task!)
                                  : () => widget.onGroupTap?.call(node),
                              onLongPress: node.task != null
                                  ? () => widget.onTaskLongPress(node.task!)
                                  : () => widget.onGroupTap?.call(node),
                            ),
                          ),
                    ],
                  );

            return Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 1,
                  maxScale: 4,
                  boundaryMargin: const EdgeInsets.all(96),
                  constrained: false,
                  onInteractionUpdate: (_) => _notifyZoomChanged(),
                  onInteractionEnd: (_) => _notifyZoomChanged(),
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: content,
                  ),
                ),
                if (!widget.exportMode &&
                    (widget.onZoomIn != null ||
                        widget.onZoomOut != null ||
                        widget.onZoomReset != null))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _AtlasZoomControls(
                      onZoomIn: widget.onZoomIn,
                      onZoomOut: widget.onZoomOut,
                      onZoomReset: widget.onZoomReset,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _notifyZoomChanged() {
    final callback = widget.onZoomChanged;
    if (callback == null) return;
    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();
    callback(scale, Offset(translation.x, translation.y));
  }

  void _syncTransformController() {
    final target = _matrixFor(_zoom);
    final current = _transformController.value;
    final currentScale = current.getMaxScaleOnAxis();
    final currentTranslation = current.getTranslation();
    if ((currentScale - _zoom.scale).abs() < 0.001 &&
        (currentTranslation.x - _zoom.offset.dx).abs() < 0.5 &&
        (currentTranslation.y - _zoom.offset.dy).abs() < 0.5) {
      return;
    }
    _transformController.value = target;
  }

  Matrix4 _matrixFor(AtlasZoomState zoom) {
    return Matrix4.identity()
      ..setEntry(0, 0, zoom.scale)
      ..setEntry(1, 1, zoom.scale)
      ..setEntry(0, 3, zoom.offset.dx)
      ..setEntry(1, 3, zoom.offset.dy);
  }

  void _collectNodes(AtlasNode node, Map<String, AtlasNode> out) {
    out[node.id] = node;
    for (final child in node.children) {
      _collectNodes(child, out);
    }
  }
}

class _AtlasZoomControls extends StatelessWidget {
  const _AtlasZoomControls({
    this.onZoomIn,
    this.onZoomOut,
    this.onZoomReset,
  });

  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Alejar',
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            tooltip: 'Restablecer zoom',
            onPressed: onZoomReset,
            icon: const Icon(Icons.center_focus_strong),
          ),
          IconButton(
            tooltip: 'Acercar',
            onPressed: onZoomIn,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
