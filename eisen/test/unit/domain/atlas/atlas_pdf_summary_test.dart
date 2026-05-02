import 'package:eisen/features/atlas/application/export/atlas_pdf_summary.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('atlasSummaryByQuadrant', () {
    test('counts tasks per quadrant correctly', () {
      final tasks = [
        _task('1', Quadrant.q1),
        _task('2', Quadrant.q1),
        _task('3', Quadrant.q2),
        _task('4', Quadrant.q3),
      ];
      final summary = atlasSummaryByQuadrant(tasks);
      expect(summary['Crítico'], 2);
      expect(summary['Crecimiento'], 1);
      expect(summary['De otros'], 1);
      expect(summary['Archivar'], 0);
    });

    test('returns zero for quadrants with no tasks', () {
      final summary = atlasSummaryByQuadrant([_task('1', Quadrant.q1)]);
      expect(summary['Archivar'], 0);
    });

    test('returns all zeroes for empty list', () {
      final summary = atlasSummaryByQuadrant([]);
      expect(summary.values.every((v) => v == 0), isTrue);
    });
  });

  group('atlasSummaryByCategory', () {
    test('counts tasks by category', () {
      final tasks = [
        _task('1', Quadrant.q1, category: 'Trabajo'),
        _task('2', Quadrant.q2, category: 'Trabajo'),
        _task('3', Quadrant.q3, category: 'Personal'),
      ];
      final summary = atlasSummaryByCategory(tasks);
      expect(summary['Trabajo'], 2);
      expect(summary['Personal'], 1);
    });

    test('groups null category as "Sin categoría"', () {
      final tasks = [_task('1', Quadrant.q1)];
      final summary = atlasSummaryByCategory(tasks);
      expect(summary['Sin categoría'], 1);
    });
  });

  group('atlasPdfInsights', () {
    test('returns empty list when no tasks', () {
      final insights = atlasPdfInsights(
        summaryByQuadrant: {'Crítico': 0, 'Crecimiento': 0},
        summaryByCategory: {},
        visibleTaskCount: 0,
      );
      expect(insights, isEmpty);
    });

    test('generates insight when q1 > q2', () {
      final insights = atlasPdfInsights(
        summaryByQuadrant: {
          'Crítico': 5,
          'Crecimiento': 2,
          'De otros': 1,
          'Archivar': 0,
        },
        summaryByCategory: {},
        visibleTaskCount: 8,
      );
      expect(
        insights.any((i) => i.contains('carga crítica')),
        isTrue,
      );
    });

    test('generates insight when category dominates > 60%', () {
      final insights = atlasPdfInsights(
        summaryByQuadrant: {'Crítico': 7, 'Crecimiento': 0},
        summaryByCategory: {'Trabajo': 8, 'Personal': 2},
        visibleTaskCount: 10,
      );
      expect(
        insights.any((i) => i.contains('Trabajo')),
        isTrue,
      );
    });

    test('no insight when category is below 60% threshold', () {
      final insights = atlasPdfInsights(
        summaryByQuadrant: {'Crítico': 5, 'Crecimiento': 5},
        summaryByCategory: {'A': 5, 'B': 5},
        visibleTaskCount: 10,
      );
      expect(
        insights.any((i) => i.contains('mayoría')),
        isFalse,
      );
    });
  });
}

Task _task(String id, Quadrant quadrant, {String? category}) {
  return Task(
    id: id,
    title: 'Task $id',
    quadrant: quadrant,
    priority: 5,
    minutes: 30,
    category: category,
  );
}
