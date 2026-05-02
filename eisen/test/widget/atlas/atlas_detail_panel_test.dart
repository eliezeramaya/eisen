import 'package:eisen/features/atlas/presentation/widgets/atlas_detail_panel.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('respeta QuadrantLabelStyle recibido y monta scrollable',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 260,
            child: AtlasDetailPanel(
              task: _task(),
              labelStyle: QuadrantLabelStyle.action,
              onComplete: () {},
              onEdit: () {},
              onReclassify: () {},
              onArchive: () {},
              onRestore: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Haz ahora'), findsOneWidget);
    expect(find.text('Crítico'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Task _task() {
  return const Task(
    id: '1',
    title: 'Tarea con un título suficientemente largo para probar scroll',
    quadrant: Quadrant.q1,
    priority: 9,
    minutes: 45,
  );
}
