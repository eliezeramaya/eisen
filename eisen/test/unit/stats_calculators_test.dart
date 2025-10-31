import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/stats/domain/calculators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('streakDays counts consecutive', () {
    final now = DateTime(2025, 1, 8, 12);
    final t1 = Task(
        id: '1',
        title: 'a',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        completedAt: DateTime(2025, 1, 8, 10));
    final t2 = Task(
        id: '2',
        title: 'b',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        completedAt: DateTime(2025, 1, 7, 9));
    final t3 = Task(
        id: '3',
        title: 'c',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        completedAt: DateTime(2025, 1, 5, 9));
    expect(streakDays([t1, t2, t3], now), 2);
  });

  test('weeklyQ2Share computes ratio', () {
    final start = DateTime(2025, 1, 1);
    final end = DateTime(2025, 1, 8);
    final t1 = Task(
        id: '1',
        title: 'a',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        completedAt: DateTime(2025, 1, 2));
    final t2 = Task(
        id: '2',
        title: 'b',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
        completedAt: DateTime(2025, 1, 3));
    final tasks = [t1, t2];
    final v = weeklyQ2Share(tasks, start, end);
    expect(v, closeTo(0.5, 1e-9));
  });

  test('lead time median in hours', () {
    final start = DateTime(2025, 1, 1);
    final end = DateTime(2025, 1, 8);
    final a = Task(
        id: 'a',
        title: 'a',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        createdAt: DateTime(2025, 1, 1),
        completedAt: DateTime(2025, 1, 2));
    final b = Task(
        id: 'b',
        title: 'b',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        createdAt: DateTime(2025, 1, 1, 12),
        completedAt: DateTime(2025, 1, 3, 12));
    final v = weeklyLeadTimeMedianHours([a, b], start, end);
    expect(v, closeTo(36.0, 1e-9));
  });
}
