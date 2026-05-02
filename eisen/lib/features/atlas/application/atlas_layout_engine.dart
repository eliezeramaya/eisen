import 'dart:math' as math;

import 'package:eisen/features/atlas/domain/atlas_layout_rect.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:flutter/widgets.dart';

List<AtlasLayoutRect> computeAtlasLayout({
  required List<AtlasNode> nodes,
  required Size size,
  required EdgeInsets padding,
  double gap = 4,
  double groupHeaderHeight = 24,
  Size minInteractiveTileSize = const Size(2, 2),
  int? maxDepth,
}) {
  if (nodes.isEmpty || size.width <= 0 || size.height <= 0) {
    return const <AtlasLayoutRect>[];
  }
  final rootRect = Rect.fromLTWH(
    padding.left,
    padding.top,
    math.max(0, size.width - padding.horizontal),
    math.max(0, size.height - padding.vertical),
  );
  if (rootRect.width <= 0 || rootRect.height <= 0) {
    return const <AtlasLayoutRect>[];
  }

  final rects = <AtlasLayoutRect>[];
  final options = _AtlasLayoutOptions(
    gap: gap,
    groupHeaderHeight: groupHeaderHeight,
    minInteractiveTileSize: minInteractiveTileSize,
    maxDepth: maxDepth,
  );
  _layoutNodes(
    nodes: _sorted(nodes),
    bounds: rootRect,
    depth: 0,
    rects: rects,
    options: options,
  );
  return rects;
}

void _layoutNodes({
  required List<AtlasNode> nodes,
  required Rect bounds,
  required int depth,
  required List<AtlasLayoutRect> rects,
  required _AtlasLayoutOptions options,
}) {
  if (nodes.isEmpty || bounds.width <= 0 || bounds.height <= 0) return;

  final safeNodes = nodes.where((node) => node.weight.isFinite).toList();
  if (safeNodes.isEmpty) return;
  final total = safeNodes.fold<double>(
    0,
    (sum, node) => sum + math.max(1.0, node.weight),
  );
  final area = bounds.width * bounds.height;
  if (total <= 0 || area <= 0) return;

  final weightedNodes = [
    for (final node in _sorted(safeNodes))
      _WeightedAtlasNode(
        node: node,
        area: area * math.max(1.0, node.weight) / total,
      ),
  ];

  for (final item in _squarify(weightedNodes, bounds)) {
    final node = item.node;
    var rect = _enforceMinimumSize(
      item.rect,
      minSize: options.minInteractiveTileSize,
      bounds: bounds,
    );

    rect = _deflate(rect, options.gap / 2);
    rect = _clampRect(rect, bounds);
    if (rect.width <= 0 || rect.height <= 0) continue;
    rects.add(
      AtlasLayoutRect(
        nodeId: node.id,
        rect: rect,
        depth: depth,
        isLeaf: node.isLeaf,
      ),
    );

    if (node.children.isNotEmpty &&
        (options.maxDepth == null || depth < options.maxDepth!) &&
        rect.width > options.groupHeaderHeight &&
        rect.height > options.groupHeaderHeight) {
      final inset = math.max(2.0, options.gap);
      final childBounds = Rect.fromLTWH(
        rect.left + inset,
        rect.top + options.groupHeaderHeight,
        math.max(0, rect.width - inset * 2),
        math.max(0, rect.height - options.groupHeaderHeight - inset),
      );
      _layoutNodes(
        nodes: _sorted(node.children),
        bounds: childBounds,
        depth: depth + 1,
        rects: rects,
        options: options,
      );
    }
  }
}

List<_LaidOutAtlasNode> _squarify(
  List<_WeightedAtlasNode> nodes,
  Rect bounds,
) {
  if (nodes.isEmpty) return const <_LaidOutAtlasNode>[];

  var remaining = bounds;
  var index = 0;
  final row = <_WeightedAtlasNode>[];
  final output = <_LaidOutAtlasNode>[];

  while (index < nodes.length) {
    final candidate = nodes[index];
    if (row.isEmpty) {
      row.add(candidate);
      index++;
      continue;
    }

    final side = math.min(remaining.width, remaining.height);
    final currentWorst = _worstAspectRatio(row, side);
    final nextWorst = _worstAspectRatio([...row, candidate], side);
    if (nextWorst <= currentWorst) {
      row.add(candidate);
      index++;
    } else {
      remaining = _layoutSquarifiedRow(
        row: row,
        remaining: remaining,
        output: output,
      );
      row.clear();
    }
  }

  if (row.isNotEmpty) {
    _layoutSquarifiedRow(
      row: row,
      remaining: remaining,
      output: output,
    );
  }

  return output;
}

Rect _layoutSquarifiedRow({
  required List<_WeightedAtlasNode> row,
  required Rect remaining,
  required List<_LaidOutAtlasNode> output,
}) {
  if (row.isEmpty || remaining.width <= 0 || remaining.height <= 0) {
    return remaining;
  }

  final rowArea = row.fold<double>(0, (sum, item) => sum + item.area);
  if (rowArea <= 0) return remaining;

  if (remaining.width >= remaining.height) {
    final rowWidth =
        (rowArea / remaining.height).clamp(0.0, remaining.width).toDouble();
    var top = remaining.top;
    for (var i = 0; i < row.length; i++) {
      final item = row[i];
      final isLast = i == row.length - 1;
      final height = isLast
          ? remaining.bottom - top
          : (item.area / math.max(rowWidth, 0.0001))
              .clamp(
                0.0,
                remaining.bottom - top,
              )
              .toDouble();
      output.add(
        _LaidOutAtlasNode(
          node: item.node,
          rect: Rect.fromLTWH(remaining.left, top, rowWidth, height),
        ),
      );
      top += height;
    }
    return Rect.fromLTRB(
      remaining.left + rowWidth,
      remaining.top,
      remaining.right,
      remaining.bottom,
    );
  }

  final rowHeight =
      (rowArea / remaining.width).clamp(0.0, remaining.height).toDouble();
  var left = remaining.left;
  for (var i = 0; i < row.length; i++) {
    final item = row[i];
    final isLast = i == row.length - 1;
    final width = isLast
        ? remaining.right - left
        : (item.area / math.max(rowHeight, 0.0001))
            .clamp(
              0.0,
              remaining.right - left,
            )
            .toDouble();
    output.add(
      _LaidOutAtlasNode(
        node: item.node,
        rect: Rect.fromLTWH(left, remaining.top, width, rowHeight),
      ),
    );
    left += width;
  }
  return Rect.fromLTRB(
    remaining.left,
    remaining.top + rowHeight,
    remaining.right,
    remaining.bottom,
  );
}

double _worstAspectRatio(List<_WeightedAtlasNode> row, double side) {
  if (row.isEmpty || side <= 0) return double.infinity;
  final areas = row.map((item) => item.area).where((area) => area > 0);
  if (areas.isEmpty) return double.infinity;
  final sum = areas.fold<double>(0, (total, area) => total + area);
  final minArea = areas.reduce(math.min);
  final maxArea = areas.reduce(math.max);
  final sideSquared = side * side;
  final sumSquared = sum * sum;
  if (minArea <= 0 || sumSquared <= 0) return double.infinity;
  return math.max(
    sideSquared * maxArea / sumSquared,
    sumSquared / (sideSquared * minArea),
  );
}

Rect _deflate(Rect rect, double delta) {
  return Rect.fromLTRB(
    rect.left + delta,
    rect.top + delta,
    rect.right - delta,
    rect.bottom - delta,
  );
}

Rect _enforceMinimumSize(
  Rect rect, {
  required Size minSize,
  required Rect bounds,
}) {
  if (rect.width <= 0 || rect.height <= 0) return Rect.zero;
  final width = math.min(bounds.width, math.max(minSize.width, rect.width));
  final height = math.min(bounds.height, math.max(minSize.height, rect.height));
  var left = rect.left;
  var top = rect.top;
  if (left + width > bounds.right) left = bounds.right - width;
  if (top + height > bounds.bottom) top = bounds.bottom - height;
  return Rect.fromLTWH(
    math.max(bounds.left, left),
    math.max(bounds.top, top),
    width,
    height,
  );
}

Rect _clampRect(Rect rect, Rect bounds) {
  if (rect.width <= 0 || rect.height <= 0) return Rect.zero;
  final left = rect.left.clamp(bounds.left, bounds.right).toDouble();
  final top = rect.top.clamp(bounds.top, bounds.bottom).toDouble();
  final right = rect.right.clamp(bounds.left, bounds.right).toDouble();
  final bottom = rect.bottom.clamp(bounds.top, bounds.bottom).toDouble();
  if (right <= left || bottom <= top) return Rect.zero;
  return Rect.fromLTRB(left, top, right, bottom);
}

List<AtlasNode> _sorted(List<AtlasNode> nodes) {
  return [...nodes]..sort((a, b) {
      final byWeight = b.weight.compareTo(a.weight);
      if (byWeight != 0) return byWeight;
      return a.id.compareTo(b.id);
    });
}

class _WeightedAtlasNode {
  const _WeightedAtlasNode({
    required this.node,
    required this.area,
  });

  final AtlasNode node;
  final double area;
}

class _AtlasLayoutOptions {
  const _AtlasLayoutOptions({
    required this.gap,
    required this.groupHeaderHeight,
    required this.minInteractiveTileSize,
    required this.maxDepth,
  });

  final double gap;
  final double groupHeaderHeight;
  final Size minInteractiveTileSize;
  final int? maxDepth;
}

class _LaidOutAtlasNode {
  const _LaidOutAtlasNode({
    required this.node,
    required this.rect,
  });

  final AtlasNode node;
  final Rect rect;
}
