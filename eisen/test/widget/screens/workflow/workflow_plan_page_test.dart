import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/application/dependencies_controller.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_providers.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_interaction_layer.dart';
import 'package:eisen/features/calendar_gantt/presentation/pages/workflow_plan_page.dart';
import 'package:eisen/features/calendar_gantt/presentation/widgets/dependency_arrows.dart';
import 'package:eisen/features/calendar_gantt/presentation/widgets/manage_dependencies_sheet.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders dependency arrows on top of the Gantt', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final matrix = container.read(matrixControllerProvider.notifier);
    final projector = container.read(projectorProvider.notifier);
    final baseDate = DateTime(2024, 1, 1);
    projector.setViewStart(baseDate);

    final a = matrix.createTask(quadrant: Quadrant.q1, title: 'Alpha');
    matrix.updateTask(
        a,
        (t) => t.copyWith(
            minutes: 180, due: baseDate.add(const Duration(days: 5))));

    final b = matrix.createTask(quadrant: Quadrant.q2, title: 'Beta');
    matrix.updateTask(
        b,
        (t) => t.copyWith(
            minutes: 240, due: baseDate.add(const Duration(days: 8))));

    final deps = container.read(dependenciesControllerProvider.notifier);
    deps.addDependency(prerequisiteId: a, dependentId: b);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: WorkflowPlanPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final arrowsLayer = find.byType(DependencyArrowsLayer);
    expect(arrowsLayer, findsOneWidget);
    final widget = tester.widget<DependencyArrowsLayer>(arrowsLayer);
    expect(widget.arrows.length, 1);
  });

  testWidgets('tapping a span opens the dependencies sheet', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final matrix = container.read(matrixControllerProvider.notifier);
    final projector = container.read(projectorProvider.notifier);
    final baseDate = DateTime(2024, 2, 1);
    projector.setViewStart(baseDate);

    final a = matrix.createTask(quadrant: Quadrant.q1, title: 'Alpha');
    matrix.updateTask(
        a,
        (t) => t.copyWith(
            minutes: 180, due: baseDate.add(const Duration(days: 4))));

    final b = matrix.createTask(quadrant: Quadrant.q2, title: 'Beta');
    matrix.updateTask(
        b,
        (t) => t.copyWith(
            minutes: 120, due: baseDate.add(const Duration(days: 9))));

    final deps = container.read(dependenciesControllerProvider.notifier);
    deps.addDependency(prerequisiteId: a, dependentId: b);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: WorkflowPlanPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Rect spanRect(String taskId) {
      final spans = container.read(lanesProvider);
      final span = spans.firstWhere((s) => s.id == taskId);
      final projectorState = container.read(projectorProvider);
      final left = projectorState.dx(span.start);
      final right = projectorState.dx(span.end);
      final y = span.lane * UiTokens.laneHeight + UiTokens.laneGap / 2;
      return Rect.fromLTWH(
        left,
        y,
        right - left,
        UiTokens.laneHeight - UiTokens.laneGap,
      );
    }

    final rect = spanRect(a);
    final interaction = find.byType(GanttInteractionLayer);
    final origin = tester.getTopLeft(interaction);

    await tester.tapAt(origin + rect.center);
    await tester.pumpAndSettle();

    expect(find.byType(ManageDependenciesSheet), findsOneWidget);
  });
}
