import 'dart:ui';

import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_tile.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AtlasTile pequeño monta sin excepciones', (tester) async {
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
              minReadableSize: const Size(72, 44),
              compactMode: true,
              enableHover: false,
              isSelected: false,
              isFocused: false,
              onTap: null,
              onLongPress: null,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('AtlasTile exportMode neutraliza hover visual', (tester) async {
    final task = Task(
      id: '1',
      title: 'Tarea hover',
      quadrant: Quadrant.q1,
      priority: 8,
      minutes: 30,
    );
    final node = AtlasNode(
      id: 'task:1',
      label: task.title,
      weight: 10,
      children: const [],
      task: task,
      type: AtlasNodeType.task,
    );

    Widget buildTile({required bool exportMode}) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 96,
            child: AtlasTile(
              node: node,
              size: const Size(180, 96),
              minReadableSize: const Size(72, 44),
              compactMode: false,
              enableHover: true,
              exportMode: exportMode,
              isSelected: false,
              isFocused: false,
              onTap: null,
              onLongPress: null,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTile(exportMode: false));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(20, 20));
    await tester.pumpAndSettle();

    final hoveredScale = tester.widget<AnimatedScale>(
      find.byType(AnimatedScale),
    );
    expect(hoveredScale.scale, greaterThan(1));

    await tester.pumpWidget(buildTile(exportMode: true));
    await tester.pumpAndSettle();

    final exportScale = tester.widget<AnimatedScale>(
      find.byType(AnimatedScale),
    );
    expect(exportScale.scale, 1);
  });
}
