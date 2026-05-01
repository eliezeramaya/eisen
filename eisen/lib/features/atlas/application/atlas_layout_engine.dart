import 'dart:math' as math;

import 'package:eisen/features/atlas/domain/atlas_layout_rect.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:flutter/widgets.dart';

List<AtlasLayoutRect> computeAtlasLayout({
  required List<AtlasNode> nodes,
  required Size size,
  required EdgeInsets padding,
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
  _layoutNodes(
    nodes: _sorted(nodes),
    bounds: rootRect,
    depth: 0,
    rects: rects,
  );
  return rects;
}

const double _gap = 4;
const double _minExtent = 2;
const double _groupHeaderHeight = 24;

void _layoutNodes({
  required List<AtlasNode> nodes,
  required Rect bounds,
  required int depth,
  required List<AtlasLayoutRect> rects,
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
    var rect = item.rect;
    if (rect.width < _minExtent || rect.height < _minExtent) {
      rect = Rect.fromLTWH(
        rect.left,
        rect.top,
        math.max(_minExtent, rect.width),
        math.max(_minExtent, rect.height),
      );
    }

    rect = _deflate(rect, _gap / 2);
    if (rect.width <= 0 || rect.height <= 0) continue;
    rects.add(
      AtlasLayoutRect(
        nodeId: node.id,
        rect: rect,
        depth: depth,
        isLeaf: node.isLeaf,
      ),
    );

    if (node.children.isNotEmpty && rect.width > 16 && rect.height > 16) {
      final childBounds = Rect.fromLTWH(
        rect.left + 4,
        rect.top + _groupHeaderHeight,
        math.max(0, rect.width - 8),
        math.max(0, rect.height - _groupHeaderHeight - 4),
      );
      _layoutNodes(
        nodes: _sorted(node.children),
        bounds: childBounds,
        depth: depth + 1,
        rects: rects,
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

    final side = remaining.width >= remaining.height
        ? remaining.width
        : remaining.height;
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

class _LaidOutAtlasNode {
  const _LaidOutAtlasNode({
    required this.node,
    required this.rect,
  });

  final AtlasNode node;
  final Rect rect;
}
