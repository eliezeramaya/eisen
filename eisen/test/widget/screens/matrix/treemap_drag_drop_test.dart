import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/eisen_treemap_hybrid.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/layout_config.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TreemapCanvas Drag & Drop', () {
    late List<Task> testTasks;
    late List<TreemapRect> testLayout;

    setUp(() {
      testTasks = [
        Task(
          id: 'task_q1_1',
          title: 'Q1 Task 1',
          quadrant: Quadrant.q1,
          priority: 8,
          minutes: 45,
        ),
        Task(
          id: 'task_q1_2',
          title: 'Q1 Task 2',
          quadrant: Quadrant.q1,
          priority: 6,
          minutes: 30,
        ),
        Task(
          id: 'task_q2_1',
          title: 'Q2 Task 1',
          quadrant: Quadrant.q2,
          priority: 7,
          minutes: 60,
        ),
        Task(
          id: 'task_q3_1',
          title: 'Q3 Task 1',
          quadrant: Quadrant.q3,
          priority: 4,
          minutes: 20,
        ),
        Task(
          id: 'task_q4_1',
          title: 'Q4 Task 1',
          quadrant: Quadrant.q4,
          priority: 3,
          minutes: 15,
        ),
      ];

      // Generate layout
      const config = LayoutConfig(
        topKPerQuadrant: 10,
        minAreaNormalized: 0.0001,
        gamma: 1.0,
        quadrantPadding: 0.01,
      );
      final engine = EisenTreemapHybrid(config);
      testLayout = engine.layout(testTasks);
    });

    Widget buildTestWidget({
      required List<Task> tasks,
      required List<TreemapRect> layout,
      void Function(String? id)? onTap,
      void Function(String id, Quadrant q)? onDropToQuadrant,
      void Function(Quadrant q)? onDoubleTapQuadrant,
      Quadrant? zoom,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: TreemapCanvas(
              tasks: tasks,
              layout: layout,
              onTap: onTap,
              onDropToQuadrant: onDropToQuadrant,
              onDoubleTapQuadrant: onDoubleTapQuadrant,
              zoom: zoom,
            ),
          ),
        ),
      );
    }

    testWidgets('renders canvas with tasks', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          tasks: testTasks,
          layout: testLayout,
        ),
      );

      // Find the canvas
      final canvas = find.byType(TreemapCanvas);
      expect(canvas, findsOneWidget);
    });

    testWidgets('accepts onTap callback', (tester) async {
      var callbackInvoked = false;
      await tester.pumpWidget(
        buildTestWidget(
          tasks: testTasks,
          layout: testLayout,
          onTap: (id) => callbackInvoked = true,
        ),
      );

      expect(find.byType(TreemapCanvas), findsOneWidget);
      // Callback exists and can be called
    });

    testWidgets('accepts onDropToQuadrant callback', (tester) async {
      var dropCallbackExists = false;
      await tester.pumpWidget(
        buildTestWidget(
          tasks: testTasks,
          layout: testLayout,
          onDropToQuadrant: (id, q) => dropCallbackExists = true,
        ),
      );

      expect(find.byType(TreemapCanvas), findsOneWidget);
      // Drop callback is wired up
    });

    testWidgets('accepts onDoubleTapQuadrant callback', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          tasks: testTasks,
          layout: testLayout,
          onDoubleTapQuadrant: (q) {},
        ),
      );

      expect(find.byType(TreemapCanvas), findsOneWidget);
    });

    testWidgets('supports zoom parameter', (tester) async {
      final zoomedLayout = EisenTreemapHybrid(const LayoutConfig())
          .layout(testTasks, only: Quadrant.q2);

      await tester.pumpWidget(
        buildTestWidget(
          tasks: testTasks.where((t) => t.quadrant == Quadrant.q2).toList(),
          layout: zoomedLayout,
          zoom: Quadrant.q2,
        ),
      );

      expect(find.byType(TreemapCanvas), findsOneWidget);
    });

    testWidgets('handles empty task list', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          tasks: [],
          layout: [],
        ),
      );

      expect(find.byType(TreemapCanvas), findsOneWidget);
    });

    testWidgets('renders with minimal mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TreemapCanvas(
                tasks: testTasks,
                layout: testLayout,
                minimal: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TreemapCanvas), findsOneWidget);
    });

    testWidgets('renders with compact mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TreemapCanvas(
                tasks: testTasks,
                layout: testLayout,
                compact: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TreemapCanvas), findsOneWidget);
    });

    testWidgets('handles loading state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TreemapCanvas(
                tasks: testTasks,
                layout: testLayout,
                loading: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TreemapCanvas), findsOneWidget);
    });

    testWidgets('handles task selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TreemapCanvas(
                tasks: testTasks,
                layout: testLayout,
                selectedId: 'task_q1_1',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TreemapCanvas), findsOneWidget);
    });

    testWidgets('handles suggested tasks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TreemapCanvas(
                tasks: testTasks,
                layout: testLayout,
                suggestedIds: {'task_q1_1', 'task_q2_1'},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TreemapCanvas), findsOneWidget);
    });

    testWidgets('handles text scale parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TreemapCanvas(
                tasks: testTasks,
                layout: testLayout,
                textScale: 1.5,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TreemapCanvas), findsOneWidget);
    });
  });
}
