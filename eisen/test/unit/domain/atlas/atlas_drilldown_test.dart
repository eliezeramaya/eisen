import 'package:eisen/features/atlas/application/atlas_providers.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resuelve un path de drilldown contra el árbol actual', () {
    final leaf = _node('task:1', children: const []);
    final group = _node('group:a', children: [leaf]);
    final roots = [group, _node('group:b', children: const [])];

    final path = resolveAtlasDrilldownPath(
      roots: roots,
      requestedPath: [_node('group:a', children: const [])],
    );

    expect(path, hasLength(1));
    expect(path.single.id, 'group:a');
    expect(path.single.children.single.id, 'task:1');
  });

  test('descarta path obsoleto si cambian nodos o agrupación', () {
    final roots = [
      _node('group:b', children: [_node('task:2')])
    ];

    final path = resolveAtlasDrilldownPath(
      roots: roots,
      requestedPath: [
        _node('group:a', children: [_node('task:1')])
      ],
    );

    expect(path, isEmpty);
  });

  test('soporta niveles anidados', () {
    final task = _node('task:1');
    final nested = _node('group:a:project', children: [task]);
    final group = _node('group:a', children: [nested]);

    final path = resolveAtlasDrilldownPath(
      roots: [group],
      requestedPath: [
        _node('group:a'),
        _node('group:a:project'),
      ],
    );

    expect(path.map((node) => node.id), ['group:a', 'group:a:project']);
    expect(path.last.children.single.id, 'task:1');
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
