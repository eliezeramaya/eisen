import 'package:eisen/features/atlas/application/atlas_layout_engine.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no crashea con lista vacía', () {
    final rects = computeAtlasLayout(
      nodes: const [],
      size: const Size(300, 200),
      padding: EdgeInsets.zero,
    );

    expect(rects, isEmpty);
  });

  test('genera rects dentro del canvas y sin dimensiones negativas', () {
    final rects = computeAtlasLayout(
      nodes: [_node('a', 10), _node('b', 5)],
      size: const Size(300, 200),
      padding: const EdgeInsets.all(8),
    );

    expect(rects, hasLength(2));
    for (final item in rects) {
      expect(item.rect.left, greaterThanOrEqualTo(0));
      expect(item.rect.top, greaterThanOrEqualTo(0));
      expect(item.rect.right, lessThanOrEqualTo(300));
      expect(item.rect.bottom, lessThanOrEqualTo(200));
      expect(item.rect.width, greaterThanOrEqualTo(0));
      expect(item.rect.height, greaterThanOrEqualTo(0));
    }
  });

  test('respeta orden por peso', () {
    final rects = computeAtlasLayout(
      nodes: [_node('small', 1), _node('large', 10)],
      size: const Size(300, 200),
      padding: EdgeInsets.zero,
    );

    expect(rects.first.nodeId, 'large');
    expect(_area(rects.first.rect), greaterThan(_area(rects.last.rect)));
  });

  test('squarified treemap genera bloques proporcionados para pesos iguales',
      () {
    final rects = computeAtlasLayout(
      nodes: [
        _node('a', 1),
        _node('b', 1),
        _node('c', 1),
        _node('d', 1),
      ],
      size: const Size(400, 400),
      padding: EdgeInsets.zero,
    );

    expect(rects, hasLength(4));
    final worstAspect = rects
        .map((item) => _aspectRatio(item.rect))
        .reduce((a, b) => a > b ? a : b);
    expect(worstAspect, lessThan(1.15));
  });

  test('ubica hijos de grupo dentro del rect del grupo', () {
    final childA = _node('child-a', 1);
    final childB = _node('child-b', 1);
    final group = AtlasNode(
      id: 'group',
      label: 'Grupo',
      weight: 2,
      children: [childA, childB],
      type: AtlasNodeType.group,
    );

    final rects = computeAtlasLayout(
      nodes: [group],
      size: const Size(360, 240),
      padding: EdgeInsets.zero,
    );

    final groupRect = rects.firstWhere((item) => item.nodeId == 'group').rect;
    final childRects = rects.where((item) => item.depth == 1);
    expect(childRects, hasLength(2));
    for (final child in childRects) {
      expect(groupRect.contains(child.rect.topLeft), isTrue);
      expect(groupRect.contains(child.rect.bottomRight), isTrue);
    }
  });
}

AtlasNode _node(String id, double weight) {
  return AtlasNode(
    id: id,
    label: id,
    weight: weight,
    children: const [],
    type: AtlasNodeType.task,
  );
}

double _area(Rect rect) => rect.width * rect.height;

double _aspectRatio(Rect rect) {
  final shortSide = rect.shortestSide;
  if (shortSide <= 0) return double.infinity;
  return rect.longestSide / shortSide;
}
