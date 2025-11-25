import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/stats/domain/trend_points.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrendAnalysis.compare', () {
    test('returns stable when both periods are zero', () {
      final analysis = TrendAnalysis.compare(current: 0, previous: 0);
      expect(analysis.direction, TrendDirection.stable);
      expect(analysis.percentageChange, 0);
    });

    test('treats small changes as stable', () {
      final analysis = TrendAnalysis.compare(current: 102, previous: 100);
      expect(analysis.direction, TrendDirection.stable);
      expect(analysis.percentageChange, closeTo(2, 1e-9));
    });

    test('detects growth when coming from zero', () {
      final analysis = TrendAnalysis.compare(current: 5, previous: 0);
      expect(analysis.direction, TrendDirection.increasing);
      expect(analysis.percentageChange, 100);
    });

    test('detects meaningful decrease', () {
      final analysis = TrendAnalysis.compare(current: 60, previous: 100);
      expect(analysis.direction, TrendDirection.decreasing);
      expect(analysis.percentageChange, closeTo(-40, 1e-9));
    });
  });

  test('DailyFocusPoint computes average safely', () {
    final point = DailyFocusPoint(
      date: DateTime(2025, 1, 1),
      totalFocus: const Duration(minutes: 90),
      sessionsCount: 3,
    );
    expect(point.averageSessionDuration, const Duration(minutes: 30));

    final empty = DailyFocusPoint(
      date: DateTime(2025, 1, 2),
      totalFocus: Duration.zero,
      sessionsCount: 0,
    );
    expect(empty.averageSessionDuration, Duration.zero);
  });

  test('DailyProductivityPoint getCount defaults to zero', () {
    final point = DailyProductivityPoint(
      date: DateTime(2025, 1, 1),
      completedCount: 2,
      byQuadrant: {Quadrant.q1: 1, Quadrant.q2: 1},
    );
    expect(point.getCount(Quadrant.q3), 0);
    expect(point.getCount(Quadrant.q1), 1);
  });
}
