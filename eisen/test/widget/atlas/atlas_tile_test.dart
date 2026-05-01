import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_tile.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AtlasTile oculta texto cuando el tile es pequeño',
      (tester) async {
    final task = Task(
      id: '1',
      title: 'Tarea muy importante',
      quadrant: Quadrant.q1,
      priority: 8,
      minutes: 30,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 30,
            height: 20,
            child: AtlasTile(
              node: AtlasNode(
                id: 'task:1',
                label: task.title,
                weight: 10,
                children: const [],
                task: task,
                type: AtlasNodeType.task,
              ),
              size: const Size(30, 20),
              isSelected: false,
              isFocused: false,
              onTap: null,
              onLongPress: null,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tarea muy importante'), findsNothing);
  });
}
