import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:eisen/features/atlas/domain/atlas_semantic_zoom.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_canvas.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_empty_state.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AtlasCanvas monta InteractiveViewer y controles de zoom',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 420,
            child: AtlasCanvas(
              nodes: [_groupNode()],
              focusedTaskIds: const {},
              selectedTaskId: null,
              emptyStateKind: AtlasEmptyStateKind.noTasks,
              zoomState: AtlasZoomState.initial(),
              onZoomChanged: (scale, offset) {},
              onZoomIn: () {},
              onZoomOut: () {},
              onZoomReset: () {},
              onTaskSelected: (_) {},
              onTaskLongPress: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AtlasCanvas oculta controles de zoom en exportMode',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 420,
            child: AtlasCanvas(
              nodes: [_groupNode()],
              focusedTaskIds: const {},
              selectedTaskId: null,
              emptyStateKind: AtlasEmptyStateKind.noTasks,
              zoomState: AtlasZoomState.initial(),
              onZoomChanged: (scale, offset) {},
              onZoomIn: () {},
              onZoomOut: () {},
              onZoomReset: () {},
              onTaskSelected: (_) {},
              onTaskLongPress: (_) {},
              exportMode: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.remove), findsNothing);
    expect(find.byIcon(Icons.center_focus_strong), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

AtlasNode _groupNode() {
  final task = Task(
    id: '1',
    title: 'Tarea visible al acercar',
    quadrant: Quadrant.q2,
    priority: 5,
    minutes: 30,
  );
  return AtlasNode(
    id: 'group:test',
    label: 'Grupo',
    weight: 10,
    type: AtlasNodeType.group,
    children: [
      AtlasNode(
        id: 'task:1',
        label: task.title,
        weight: 10,
        task: task,
        type: AtlasNodeType.task,
        children: const [],
      ),
    ],
  );
}
