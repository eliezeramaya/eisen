import 'dart:math' as math;

import 'package:eisen/features/atlas/domain/atlas_layout_rect.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:eisen/features/atlas/domain/atlas_semantic_zoom.dart';
import 'package:eisen/features/atlas/domain/atlas_visual_encoding.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';

const int atlasCustomPainterNodeThreshold = 300;

bool shouldUseAtlasCustomPainter(
  List<AtlasNode> nodes, {
  int threshold = atlasCustomPainterNodeThreshold,
}) {
  return countAtlasRenderableNodes(nodes) >= threshold;
}

int countAtlasRenderableNodes(List<AtlasNode> nodes) {
  var count = 0;
  for (final node in nodes) {
    count++;
    count += countAtlasRenderableNodes(node.children);
  }
  return count;
}

AtlasNode? findAtlasNodeAt({
  required List<AtlasLayoutRect> rects,
  required Map<String, AtlasNode> nodeById,
  required Offset position,
}) {
  for (final layout in rects.reversed) {
    if (!layout.rect.contains(position)) continue;
    final node = nodeById[layout.nodeId];
    if (node != null) return node;
  }
  return null;
}

class AtlasPainterCanvas extends StatefulWidget {
  const AtlasPainterCanvas({
    super.key,
    required this.rects,
    required this.nodeById,
    required this.focusedTaskIds,
    this.insightTaskIds = const <String>{},
    required this.selectedTaskId,
    required this.onTaskSelected,
    required this.onTaskLongPress,
    this.largeDatasetThreshold = atlasCustomPainterNodeThreshold,
    this.semanticLevel = AtlasSemanticLevel.task,
    this.onGroupTap,
    this.exportMode = false,
  });

  final List<AtlasLayoutRect> rects;
  final Map<String, AtlasNode> nodeById;
  final Set<String> focusedTaskIds;
  final Set<String> insightTaskIds;
  final String? selectedTaskId;
  final ValueChanged<Task> onTaskSelected;
  final ValueChanged<Task> onTaskLongPress;
  final int largeDatasetThreshold;
  final AtlasSemanticLevel semanticLevel;
  final ValueChanged<AtlasNode>? onGroupTap;
  final bool exportMode;

  @override
  State<AtlasPainterCanvas> createState() => _AtlasPainterCanvasState();
}

class _AtlasPainterCanvasState extends State<AtlasPainterCanvas> {
  String? _hoveredNodeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveHoveredNodeId = widget.exportMode ? null : _hoveredNodeId;
    return SizedBox.expand(
      child: MouseRegion(
        cursor: effectiveHoveredNodeId == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onHover: widget.exportMode
            ? null
            : (event) {
                final hovered = findAtlasNodeAt(
                  rects: widget.rects,
                  nodeById: widget.nodeById,
                  position: event.localPosition,
                );
                if (hovered?.id != _hoveredNodeId) {
                  setState(() => _hoveredNodeId = hovered?.id);
                }
              },
        onExit: (_) {
          if (_hoveredNodeId != null) {
            setState(() => _hoveredNodeId = null);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _activate(details.localPosition),
          onLongPressStart: (details) => _longPress(details.localPosition),
          onSecondaryTapUp: (details) => _longPress(details.localPosition),
          child: CustomPaint(
            painter: AtlasTreemapPainter(
              rects: widget.rects,
              nodeById: widget.nodeById,
              focusedTaskIds: widget.focusedTaskIds,
              insightTaskIds: widget.insightTaskIds,
              selectedTaskId: widget.selectedTaskId,
              hoveredNodeId: effectiveHoveredNodeId,
              largeDatasetThreshold: widget.largeDatasetThreshold,
              semanticLevel: widget.semanticLevel,
              theme: theme,
            ),
          ),
        ),
      ),
    );
  }

  void _activate(Offset position) {
    final node = findAtlasNodeAt(
      rects: widget.rects,
      nodeById: widget.nodeById,
      position: position,
    );
    if (node == null) return;
    final task = node.task;
    if (task != null) {
      widget.onTaskSelected(task);
    } else {
      widget.onGroupTap?.call(node);
    }
  }

  void _longPress(Offset position) {
    final node = findAtlasNodeAt(
      rects: widget.rects,
      nodeById: widget.nodeById,
      position: position,
    );
    if (node == null) return;
    final task = node.task;
    if (task != null) {
      widget.onTaskLongPress(task);
    } else {
      widget.onGroupTap?.call(node);
    }
  }
}

class AtlasTreemapPainter extends CustomPainter {
  const AtlasTreemapPainter({
    required this.rects,
    required this.nodeById,
    required this.focusedTaskIds,
    required this.insightTaskIds,
    required this.selectedTaskId,
    required this.hoveredNodeId,
    required this.largeDatasetThreshold,
    required this.semanticLevel,
    required this.theme,
  });

  final List<AtlasLayoutRect> rects;
  final Map<String, AtlasNode> nodeById;
  final Set<String> focusedTaskIds;
  final Set<String> insightTaskIds;
  final String? selectedTaskId;
  final String? hoveredNodeId;
  final int largeDatasetThreshold;
  final AtlasSemanticLevel semanticLevel;
  final ThemeData theme;

  bool get _isLargeDataset => rects.length >= largeDatasetThreshold;

  @override
  void paint(Canvas canvas, Size size) {
    for (final layout in rects) {
      final node = nodeById[layout.nodeId];
      if (node == null || layout.rect.width <= 0 || layout.rect.height <= 0) {
        continue;
      }
      if (node.type == AtlasNodeType.group) {
        _paintGroup(canvas, layout.rect, node);
      } else {
        _paintTask(canvas, layout.rect, node);
      }
    }
  }

  void _paintGroup(Canvas canvas, Rect rect, AtlasNode node) {
    final hovered = node.id == hoveredNodeId;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: hovered ? 0.54 : 0.34,
        ),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hovered ? 1.4 : 1
        ..color = theme.colorScheme.outlineVariant.withValues(
          alpha: hovered ? 0.88 : 0.58,
        ),
    );
    if (rect.width >= 80 && rect.height >= 26) {
      _paintText(
        canvas: canvas,
        text: node.label,
        rect: rect.deflate(7),
        color: theme.colorScheme.onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        maxLines: 1,
      );
      if (rect.width >= 132) {
        _paintText(
          canvas: canvas,
          text: node.weight.toStringAsFixed(0),
          rect: Rect.fromLTWH(rect.right - 42, rect.top + 6, 34, 14),
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
          textAlign: TextAlign.right,
        );
      }
    }
  }

  void _paintTask(Canvas canvas, Rect rect, AtlasNode node) {
    final task = node.task;
    if (task == null) return;

    final selected = task.id == selectedTaskId;
    final hovered = node.id == hoveredNodeId;
    final focused = focusedTaskIds.contains(task.id);
    final insightHighlighted = insightTaskIds.contains(task.id);
    final encoding = resolveAtlasVisualEncoding(
      task: task,
      theme: theme,
      isFocused: focused,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    if (focused) {
      canvas.drawRRect(
        rrect.inflate(2),
        Paint()
          ..color = theme.colorScheme.primary.withValues(alpha: 0.26)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawRRect(
      rrect,
      Paint()..color = encoding.fillColor.withValues(alpha: encoding.opacity),
    );

    if (hovered) {
      canvas.drawRRect(
        rrect,
        Paint()..color = Colors.white.withValues(alpha: 0.10),
      );
    }

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected
            ? 2.4
            : insightHighlighted
                ? 2
                : encoding.showConfidenceBorder
                    ? 1.6
                    : 0.8
        ..color = selected
            ? theme.colorScheme.primary
            : insightHighlighted
                ? theme.colorScheme.tertiary
                : encoding.borderColor,
    );

    if (insightHighlighted && rect.width >= 34 && rect.height >= 24) {
      canvas.drawCircle(
        Offset(rect.left + 9, rect.bottom - 9),
        3,
        Paint()..color = theme.colorScheme.tertiary,
      );
    }

    final onlyBlock = rect.width < 36 || rect.height < 24;
    if (onlyBlock || _isLargeDataset || !semanticLevel.showRichTaskContent) {
      return;
    }

    final showFullText = rect.width >= 92 && rect.height >= 52;
    final showShortText = rect.width >= 60 && rect.height >= 36;
    if (!showFullText && !showShortText) return;

    final textRect = rect.deflate(7);
    _paintText(
      canvas: canvas,
      text: showFullText ? task.title : _shortLabel(task.title),
      rect: textRect,
      color: encoding.labelColor,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      maxLines: showFullText ? 3 : 1,
    );

    if (showFullText && rect.height >= 72) {
      _paintText(
        canvas: canvas,
        text: 'P${task.priority}   ${task.minutes}m',
        rect: Rect.fromLTWH(
          textRect.left,
          math.max(textRect.top, textRect.bottom - 14),
          textRect.width,
          14,
        ),
        color: encoding.labelColor.withValues(alpha: 0.9),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      );
    }
  }

  void _paintText({
    required Canvas canvas,
    required String text,
    required Rect rect,
    required Color color,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w500,
    int maxLines = 1,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.05,
        ),
      ),
      maxLines: maxLines,
      ellipsis: '…',
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(0, rect.width));
    if (painter.width <= 0 || painter.height <= 0) return;
    canvas.save();
    canvas.clipRect(rect);
    painter.paint(canvas, rect.topLeft);
    canvas.restore();
  }

  String _shortLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 12) return trimmed;
    return '${trimmed.substring(0, 11)}…';
  }

  @override
  bool shouldRepaint(covariant AtlasTreemapPainter oldDelegate) {
    return oldDelegate.rects != rects ||
        oldDelegate.nodeById != nodeById ||
        oldDelegate.focusedTaskIds != focusedTaskIds ||
        oldDelegate.selectedTaskId != selectedTaskId ||
        oldDelegate.hoveredNodeId != hoveredNodeId ||
        oldDelegate.theme != theme;
  }
}
