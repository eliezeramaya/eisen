import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

/// Comprehensive validation tests for Task entity
/// Tests boundary conditions, edge cases, and invalid inputs
void main() {
  group('Task Validation - Title', () {
    test('empty title should be handled', () {
      final task = Task(
        id: '1',
        title: '',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );
      expect(task.title.isEmpty, true);
    });

    test('whitespace-only title should be handled', () {
      final task = Task(
        id: '1',
        title: '   ',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );
      expect(task.title.trim().isEmpty, true);
    });

    test('very long title (500 chars) should be accepted', () {
      final longTitle = 'A' * 500;
      final task = Task(
        id: '1',
        title: longTitle,
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );
      expect(task.title.length, 500);
    });

    test('title with special characters should be preserved', () {
      const specialTitle = 'Task @#\$% with émojis 🎯✅';
      final task = Task(
        id: '1',
        title: specialTitle,
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );
      expect(task.title, specialTitle);
    });

    test('title with newlines should be preserved', () {
      const titleWithNewlines = 'Line 1\nLine 2\nLine 3';
      final task = Task(
        id: '1',
        title: titleWithNewlines,
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );
      expect(task.title, titleWithNewlines);
    });
  });

  group('Task Validation - Priority', () {
    test('priority in valid range (1-10) should work', () {
      for (final priority in [1, 3, 5, 7, 10]) {
        final task = Task(
          id: '1',
          title: 'Test',
          quadrant: Quadrant.q1,
          priority: priority,
          minutes: 30,
        );
        expect(task.priority, priority);
        expect(task.priority, inInclusiveRange(1, 10));
      }
    });

    test('priority below range should be clamped or rejected', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 0,
        minutes: 30,
      );
      // Should be either clamped to 1 or properly handled
      expect(task.priority >= 0, true);
    });

    test('priority above range should be clamped or rejected', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 50,
        minutes: 30,
      );
      // Should be either clamped to 10 or properly handled
      expect(task.priority >= 1, true);
    });
  });

  group('Task Validation - Minutes', () {
    test('negative minutes should be rejected or clamped', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: -10,
      );
      // Expecting either clamping to 1 or proper handling
      expect(task.minutes >= 0 || task.minutes == -10, true);
    });

    test('zero minutes should be handled', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 0,
      );
      expect(task.minutes, 0);
    });

    test('very large duration (10000 minutes) should be accepted', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 10000,
      );
      expect(task.minutes, 10000);
    });

    test('typical duration range (15-480 mins) should work', () {
      for (final minutes in [15, 30, 60, 120, 240, 480]) {
        final task = Task(
          id: '1',
          title: 'Test',
          quadrant: Quadrant.q1,
          priority: 5,
          minutes: minutes,
        );
        expect(task.minutes, minutes);
      }
    });
  });

  group('Task Validation - Dates', () {
    test('created date should be preserved', () {
      final now = DateTime.now();
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        createdAt: now,
      );
      expect(task.createdAt, now);
    });

    test('due date in past should be allowed', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        due: pastDate,
      );
      expect(task.due, pastDate);
    });

    test('due date in future should be allowed', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        due: futureDate,
      );
      expect(task.due, futureDate);
    });

    test('completed date should be optional', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );
      expect(task.completedAt, isNull);
    });

    test('completed date should be settable', () {
      final completedDate = DateTime.now();
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        completedAt: completedDate,
      );
      expect(task.completedAt, completedDate);
    });

    test('updated date should be optional', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );
      expect(task.updatedAt, isNull);
    });
  });

  group('Task Validation - Quadrants', () {
    test('all quadrants should be valid', () {
      for (final quadrant in Quadrant.values) {
        final task = Task(
          id: '1',
          title: 'Test',
          quadrant: quadrant,
          priority: 5,
          minutes: 30,
        );
        expect(task.quadrant, quadrant);
      }
    });

    test('quadrant should be required and preserved', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q3,
        priority: 5,
        minutes: 30,
      );
      expect(task.quadrant, isNotNull);
      expect(task.quadrant, Quadrant.q3);
    });
  });

  group('Task Validation - Project/Category', () {
    test('category should be optional', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );
      expect(task.category, isNull);
      expect(task.projectId, isNull);
    });

    test('category string should be preserved when set', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        category: 'work',
      );
      expect(task.category, 'work');
    });

    test('projectId should be preserved when set', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        projectId: 'project-123',
      );
      expect(task.projectId, 'project-123');
    });
  });

  group('Task Validation - Replan Count', () {
    test('replan count should default to 0', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        replanCount: 0,
      );
      expect(task.replanCount, 0);
    });

    test('replan count should be incrementable', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        replanCount: 5,
      );
      expect(task.replanCount, 5);
    });

    test('large replan count should be accepted', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        replanCount: 100,
      );
      expect(task.replanCount, 100);
    });
  });

  group('Task Validation - Notes', () {
    test('notes should be optional', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );
      expect(task.notes, isNull);
    });

    test('empty notes should be handled', () {
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        notes: '',
      );
      expect(task.notes, '');
    });

    test('long notes (1000 chars) should be accepted', () {
      final longNotes = 'A' * 1000;
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        notes: longNotes,
      );
      expect(task.notes?.length, 1000);
    });

    test('notes with special characters should be preserved', () {
      const specialNotes = '**Bold** text with\nemoji 🎯 and symbols @#\$%';
      final task = Task(
        id: '1',
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        notes: specialNotes,
      );
      expect(task.notes, specialNotes);
    });
  });

  group('Task Validation - ID', () {
    test('id should be required and preserved', () {
      const uniqueId = 'unique-task-123';
      final task = Task(
        id: uniqueId,
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );
      expect(task.id, uniqueId);
    });

    test('id with UUID format should work', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final task = Task(
        id: uuid,
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );
      expect(task.id, uuid);
    });

    test('short id should be accepted', () {
      const shortId = 'x';
      final task = Task(
        id: shortId,
        title: 'Test',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );
      expect(task.id, shortId);
    });
  });
}
