import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_canvas.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_empty_state.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_painter.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_tile.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AtlasCanvas usa CustomPaint para datasets grandes',
      (tester) async {
    final nodes = [
      for (var index = 0; index <= atlasCustomPainterNodeThreshold; index++)
        _taskNode(index),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: AtlasCanvas(
              nodes: nodes,
              focusedTaskIds: const {},
              selectedTaskId: null,
              emptyStateKind: AtlasEmptyStateKind.noTasks,
              onTaskSelected: (_) {},
              onTaskLongPress: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AtlasPainterCanvas), findsOneWidget);
    expect(find.byType(AtlasTile), findsNothing);
  });
}

AtlasNode _taskNode(int index) {
  final task = Task(
    id: '$index',
    title: 'Task $index',
    quadrant: Quadrant.q2,
    priority: 5,
    minutes: 30,
  );
  return AtlasNode(
    id: 'task:${task.id}',
    label: task.title,
    weight: 1,
    children: const [],
    task: task,
    type: AtlasNodeType.task,
  );
}
