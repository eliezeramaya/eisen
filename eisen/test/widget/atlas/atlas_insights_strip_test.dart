import 'package:eisen/features/atlas/domain/atlas_insight.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_insights_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AtlasInsightsStrip muestra insights y permite seleccionarlos',
      (tester) async {
    AtlasInsight? selected;
    AtlasInsightAction? selectedAction;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AtlasInsightsStrip(
            compact: true,
            insights: const [
              AtlasInsight(
                id: 'load',
                kind: AtlasInsightKind.overload,
                priority: AtlasInsightPriority.high,
                title: 'Día cargado',
                message: 'Prioriza las tareas críticas.',
                primaryTaskId: 'task-1',
                taskIds: ['task-1'],
                actions: [
                  AtlasInsightAction(
                    kind: AtlasInsightActionKind.openPrimaryTask,
                    label: 'Ver crítica',
                  ),
                ],
              ),
            ],
            onInsightSelected: (insight) => selected = insight,
            onActionSelected: (_, action) => selectedAction = action,
          ),
        ),
      ),
    );

    expect(find.text('Día cargado'), findsOneWidget);

    await tester.tap(find.text('Día cargado'));
    expect(selected?.id, 'load');

    await tester.tap(find.text('Ver crítica'));
    expect(selectedAction?.kind, AtlasInsightActionKind.openPrimaryTask);
    expect(tester.takeException(), isNull);
  });
}
