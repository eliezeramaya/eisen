import 'package:eisen/core/a11y/semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accessibility compliance', () {
    group('WCAG AA contrast requirements', () {
      // Note: Quadrant colors are used with alpha blending (0.18-0.28) overlays
      // on glassBg, not directly on plain backgrounds. Tests verify the concept
      // works with reference colors.

      test('white on black meets AAA contrast (reference)', () {
        final passes = A11y.meetsContrastAA(Colors.white, Colors.black);
        expect(passes, isTrue,
            reason: 'White on black is 21:1 (maximum contrast)');
      });

      test('low contrast fails AA (reference)', () {
        // Very similar grays should fail
        final passes = A11y.meetsContrastAA(
          const Color(0xFFCCCCCC),
          const Color(0xFFDDDDDD),
        );
        expect(passes, isFalse,
            reason: 'Similar grays should fail AA contrast');
      });

      test('contrast validator works for typical text on light bg', () {
        // Dark gray text on white
        final passes = A11y.meetsContrastAA(
          const Color(0xFF1F2937),
          Colors.white,
        );
        expect(passes, isTrue, reason: 'Dark gray on white meets AA');
      });

      test('contrast validator works for typical text on dark bg', () {
        // Light text on dark blue
        final passes = A11y.meetsContrastAA(
          const Color(0xFFF3F4F6),
          const Color(0xFF1E293B),
        );
        expect(passes, isTrue, reason: 'Light gray on dark blue meets AA');
      });
    });

    group('Touch target enforcement', () {
      test('A11y.minTouch is 44x44', () {
        expect(A11y.minTouch.width, 44);
        expect(A11y.minTouch.height, 44);
      });

      testWidgets('touchTarget enforces minimum size', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: A11y.touchTarget(
                  child: Container(
                    width: 20, // Smaller than minimum
                    height: 20,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        );

        // Find all ConstrainedBox widgets and get the one from touchTarget
        final constrainedBoxes =
            tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));

        // Look for our touchTarget's ConstrainedBox (the one with 44x44 constraints)
        final touchTargetBox = constrainedBoxes.firstWhere(
          (box) =>
              box.constraints.minWidth == 44 && box.constraints.minHeight == 44,
        );

        expect(touchTargetBox.constraints.minWidth, 44);
        expect(touchTargetBox.constraints.minHeight, 44);
      });
    });

    group('Semantic labels', () {
      test('taskTileLabel includes all required information', () {
        final label = A11y.taskTileLabel(
          title: 'Test Task',
          priority: 7,
          minutes: 45,
          quadrant: 'Q1',
        );

        expect(label, contains('Task: Test Task'));
        expect(label, contains('Priority: 7'));
        expect(label, contains('Duration: 45 minutes'));
        expect(label, contains('Quadrant: Q1'));
      });

      test('taskTileLabel includes suggestion status', () {
        final label = A11y.taskTileLabel(
          title: 'Test',
          priority: 5,
          minutes: 30,
          quadrant: 'Q2',
          isSuggested: true,
        );

        expect(label, contains('Suggested task'));
      });

      test('taskTileLabel handles stack groups', () {
        final label = A11y.taskTileLabel(
          title: 'Ignored for stacks',
          priority: 5,
          minutes: 30,
          quadrant: 'Q3',
          stackSize: 5,
        );

        expect(label, contains('Group of 5 tasks'));
        expect(label, contains('Q3'));
        expect(label, isNot(contains('Ignored for stacks')),
            reason: 'Stack label should not include title');
      });
    });

    group('Focus ring', () {
      test('focusRing creates valid decoration', () {
        final decoration = A11y.focusRing();

        expect(decoration.border, isA<Border>());
        expect(decoration.borderRadius, isNotNull);
        expect(decoration.boxShadow, isNotEmpty);
      });

      test('focusRing accepts custom parameters', () {
        final decoration = A11y.focusRing(
          color: Colors.red,
          width: 3.0,
          radius: 8.0,
        );

        final border = decoration.border as Border;
        expect(border.top.color, Colors.red);
        expect(border.top.width, 3.0);
        expect(decoration.borderRadius, BorderRadius.circular(8.0));
      });
    });
  });
}
