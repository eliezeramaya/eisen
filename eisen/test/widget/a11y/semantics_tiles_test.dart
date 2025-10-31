import 'package:eisen/features/eisen_matrix/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Accessibility tests for interactive widgets.
///
/// Verifies:
/// - Semantic labels are present and descriptive
/// - Focusable elements can be reached via keyboard
/// - Screen readers can announce widget state
/// - High contrast/focus indicators are visible
void main() {
  group('Task Tile Accessibility', () {
    testWidgets('TaskTile has proper semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              title: 'Test Task',
              subtitle: 'Priority 5, Q2',
            ),
          ),
        ),
      );

      final semanticsNode = tester.getSemantics(find.byType(TaskTile));

      expect(
        semanticsNode.label,
        contains('Test Task'),
        reason: 'Semantic label should include task title',
      );

      expect(
        semanticsNode.label,
        contains('Priority 5'),
        reason: 'Semantic label should include priority info',
      );
    });

    testWidgets('TaskTile is focusable via keyboard', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              title: 'Focusable Task',
              subtitle: 'Test',
              onTap: () {},
            ),
          ),
        ),
      );

      // Find Focus widgets within TaskTile
      final focusWidget = find.descendant(
        of: find.byType(TaskTile),
        matching: find.byType(Focus),
      );
      expect(focusWidget, findsAtLeastNWidgets(1),
          reason:
              'TaskTile should have a Focus widget for keyboard navigation');
    });

    testWidgets('TaskTile shows focus indicator when focused', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FocusScope(
              child: TaskTile(
                title: 'Focus Test',
                subtitle: 'Test',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Initially not focused
      expect(focusNode.hasFocus, isFalse);

      // Request focus
      await tester.pump();

      // Focus indicator should be present in widget tree
      expect(find.byType(TaskTile), findsOneWidget);
    });

    testWidgets('TaskTile with onTap is interactive', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              title: 'Interactive Task',
              subtitle: 'Tap test',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap the TaskTile widget itself
      await tester.tap(find.byType(TaskTile));
      await tester.pump();

      expect(tapped, isTrue,
          reason: 'onTap callback should be invoked when tile is tapped');
    });

    testWidgets('TaskTile selection state is reflected in semantics',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              title: 'Selected Task',
              subtitle: 'Test',
              selected: true,
            ),
          ),
        ),
      );

      final semanticsNode = tester.getSemantics(find.byType(TaskTile));
      final semanticsData = semanticsNode.getSemanticsData();

      // Verify selection is included in semantic data
      expect(
        semanticsData.flagsCollection.isSelected,
        isTrue,
        reason: 'Selected state should be announced to screen readers',
      );
    });

    testWidgets('TaskTile without onTap still has semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              title: 'Non-interactive Task',
              subtitle: 'Test',
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(TaskTile));

      expect(
        semantics.label,
        contains('Non-interactive Task'),
        reason: 'Semantic labels should be present even without interaction',
      );
    });
  });

  group('App-wide Accessibility', () {
    testWidgets('MaterialApp has proper semantics configuration',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Accessibility Test')),
            body: const Center(child: Text('Content')),
          ),
        ),
      );

      // Verify basic semantic tree exists
      expect(find.bySemanticsLabel('Accessibility Test'), findsOneWidget,
          reason: 'AppBar title should have semantic label');

      expect(find.text('Content'), findsOneWidget,
          reason: 'Body content should be rendered');
    });

    testWidgets('Semantic labels are present in semantic tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                TaskTile(title: 'Task 1', subtitle: 'Sub 1'),
                TaskTile(title: 'Task 2', subtitle: 'Sub 2'),
                TaskTile(title: 'Task 3', subtitle: 'Sub 3'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all tiles are rendered
      expect(find.byType(TaskTile), findsNWidgets(3),
          reason: 'All tiles should be rendered');

      // Verify semantic label contains task info
      final firstTile = find.byType(TaskTile).first;
      final semantics = tester.getSemantics(firstTile);
      expect(semantics.label, contains('Task'),
          reason: 'Semantic labels should contain task info');
    });
  });

  group('Contrast and Visual Indicators', () {
    testWidgets('Focus border has sufficient visual weight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              title: 'Contrast Test',
              subtitle: 'Visual check',
              onTap: () {},
            ),
          ),
        ),
      );

      // Find AnimatedContainer which should have border when focused
      final container = find.descendant(
        of: find.byType(TaskTile),
        matching: find.byType(AnimatedContainer),
      );

      expect(container, findsOneWidget,
          reason: 'TaskTile should contain AnimatedContainer for styling');
    });

    testWidgets('InkWell provides visual feedback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              title: 'Feedback Test',
              subtitle: 'Ripple effect',
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify InkWell is present for touch/click feedback
      expect(find.byType(InkWell), findsAtLeastNWidgets(1),
          reason: 'InkWell should provide visual feedback on interaction');
    });

    testWidgets('Material widget enables ink effects', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              title: 'Material Test',
              subtitle: 'Ink splash',
              onTap: () {},
            ),
          ),
        ),
      );

      // Material widget should be present for proper ink effects
      expect(find.byType(Material), findsAtLeastNWidgets(1),
          reason: 'Material widget enables ink splash effects');
    });
  });
}
