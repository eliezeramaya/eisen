import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for Quadrant properties.
///
/// Ensures that the urgency and importance classifications remain correct
/// according to the Eisenhower Matrix definition:
///
/// - Q1: Urgent + Important (Do First)
/// - Q2: Not Urgent + Important (Schedule)
/// - Q3: Urgent + Not Important (Delegate)
/// - Q4: Not Urgent + Not Important (Eliminate)
void main() {
  group('Quadrant Properties - Eisenhower Matrix Definition', () {
    test('Q1 is both Urgent AND Important', () {
      expect(Quadrant.q1.isUrgent, true, reason: 'Q1 must be urgent');
      expect(Quadrant.q1.isImportant, true, reason: 'Q1 must be important');
    });

    test('Q2 is Important but NOT Urgent', () {
      expect(Quadrant.q2.isUrgent, false,
          reason: 'Q2 must NOT be urgent (Schedule tasks)');
      expect(Quadrant.q2.isImportant, true,
          reason: 'Q2 must be important (Schedule tasks)');
    });

    test('Q3 is Urgent but NOT Important', () {
      expect(Quadrant.q3.isUrgent, true,
          reason: 'Q3 must be urgent (Delegate tasks)');
      expect(Quadrant.q3.isImportant, false,
          reason: 'Q3 must NOT be important (Delegate tasks)');
    });

    test('Q4 is neither Urgent NOR Important', () {
      expect(Quadrant.q4.isUrgent, false,
          reason: 'Q4 must NOT be urgent (Eliminate tasks)');
      expect(Quadrant.q4.isImportant, false,
          reason: 'Q4 must NOT be important (Eliminate tasks)');
    });
  });

  group('Quadrant Properties - Urgency Classification', () {
    test('urgent quadrants are Q1 and Q3 only', () {
      final urgentQuadrants = Quadrant.values.where((q) => q.isUrgent).toSet();
      expect(urgentQuadrants, {Quadrant.q1, Quadrant.q3},
          reason: 'Only Q1 (Do First) and Q3 (Delegate) are urgent');
    });

    test('non-urgent quadrants are Q2 and Q4 only', () {
      final nonUrgentQuadrants =
          Quadrant.values.where((q) => !q.isUrgent).toSet();
      expect(nonUrgentQuadrants, {Quadrant.q2, Quadrant.q4},
          reason: 'Only Q2 (Schedule) and Q4 (Eliminate) are non-urgent');
    });
  });

  group('Quadrant Properties - Importance Classification', () {
    test('important quadrants are Q1 and Q2 only', () {
      final importantQuadrants =
          Quadrant.values.where((q) => q.isImportant).toSet();
      expect(importantQuadrants, {Quadrant.q1, Quadrant.q2},
          reason: 'Only Q1 (Do First) and Q2 (Schedule) are important');
    });

    test('non-important quadrants are Q3 and Q4 only', () {
      final nonImportantQuadrants =
          Quadrant.values.where((q) => !q.isImportant).toSet();
      expect(nonImportantQuadrants, {Quadrant.q3, Quadrant.q4},
          reason: 'Only Q3 (Delegate) and Q4 (Eliminate) are non-important');
    });
  });

  group('Quadrant Properties - Matrix Combinations', () {
    test('each quadrant has unique urgent/important combination', () {
      final combinations = <String>{};

      for (final q in Quadrant.values) {
        final combo = '${q.isUrgent ? "U" : "N"}${q.isImportant ? "I" : "N"}';
        expect(combinations.contains(combo), false,
            reason: 'Each quadrant should have unique urgent/important combo');
        combinations.add(combo);
      }

      expect(combinations, {'UI', 'NI', 'UN', 'NN'},
          reason: 'Should have all 4 combinations: UI, NI, UN, NN');
    });

    test('exactly 2 quadrants are urgent', () {
      final urgentCount = Quadrant.values.where((q) => q.isUrgent).length;
      expect(urgentCount, 2,
          reason: 'Exactly 2 quadrants (Q1, Q3) should be urgent');
    });

    test('exactly 2 quadrants are important', () {
      final importantCount = Quadrant.values.where((q) => q.isImportant).length;
      expect(importantCount, 2,
          reason: 'Exactly 2 quadrants (Q1, Q2) should be important');
    });
  });

  group('Quadrant Properties - Regression Tests', () {
    test('Q2 is important (not Q4) - regression for common mistake', () {
      // This test specifically catches the bug where Q4 was marked as important
      // instead of Q2. The Eisenhower Matrix defines Q2 as "Important but not urgent"
      expect(Quadrant.q2.isImportant, true,
          reason:
              'Q2 = Important + Not Urgent (Schedule). Common bug: Q4 marked as important instead.');
      expect(Quadrant.q4.isImportant, false,
          reason: 'Q4 = Not Important + Not Urgent (Eliminate)');
    });

    test('Q3 is urgent (not Q2) - regression check', () {
      // Ensure urgency classification is correct
      expect(Quadrant.q3.isUrgent, true,
          reason: 'Q3 = Urgent + Not Important (Delegate)');
      expect(Quadrant.q2.isUrgent, false,
          reason: 'Q2 = Not Urgent + Important (Schedule)');
    });
  });

  group('Quadrant Properties - Semantic Validation', () {
    test('Q1 semantics: Do First - Urgent AND Important', () {
      expect(Quadrant.q1.isUrgent && Quadrant.q1.isImportant, true,
          reason: 'Q1 tasks should be done first (urgent + important)');
    });

    test('Q2 semantics: Schedule - Important but can wait', () {
      expect(!Quadrant.q2.isUrgent && Quadrant.q2.isImportant, true,
          reason: 'Q2 tasks should be scheduled (important but not urgent)');
    });

    test('Q3 semantics: Delegate - Urgent but not core', () {
      expect(Quadrant.q3.isUrgent && !Quadrant.q3.isImportant, true,
          reason: 'Q3 tasks should be delegated (urgent but not important)');
    });

    test('Q4 semantics: Eliminate - Neither urgent nor important', () {
      expect(!Quadrant.q4.isUrgent && !Quadrant.q4.isImportant, true,
          reason:
              'Q4 tasks should be eliminated (neither urgent nor important)');
    });
  });
}
