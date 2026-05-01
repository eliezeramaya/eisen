import 'package:eisen/features/atlas/domain/atlas_layout_rect.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa CustomPainter cuando supera el umbral de nodos', () {
    final nodes = [
      for (var index = 0; index <= atlasCustomPainterNodeThreshold; index++)
        _node('task:$index'),
    ];

    expect(shouldUseAtlasCustomPainter(nodes), isTrue);
  });

  test('mantiene widgets para datasets debajo del umbral', () {
    final nodes = [
      for (var index = 0; index < atlasCustomPainterNodeThreshold; index++)
        _node('task:$index'),
    ];

    expect(shouldUseAtlasCustomPainter(nodes), isFalse);
  });

  test('hit testing prioriza el rect superior', () {
    final group = _node('group:a', children: [_node('task:1')]);
    final task = group.children.single;
    final rects = [
      const AtlasLayoutRect(
        nodeId: 'group:a',
        rect: Rect.fromLTWH(0, 0, 200, 200),
        depth: 0,
        isLeaf: false,
      ),
      const AtlasLayoutRect(
        nodeId: 'task:1',
        rect: Rect.fromLTWH(20, 20, 80, 80),
        depth: 1,
        isLeaf: true,
      ),
    ];

    final hit = findAtlasNodeAt(
      rects: rects,
      nodeById: {
        group.id: group,
        task.id: task,
      },
      position: const Offset(30, 30),
    );

    expect(hit?.id, 'task:1');
  });
}

AtlasNode _node(String id, {List<AtlasNode> children = const []}) {
  return AtlasNode(
    id: id,
    label: id,
    weight: 1,
    children: children,
    type: children.isEmpty ? AtlasNodeType.task : AtlasNodeType.group,
  );
}
