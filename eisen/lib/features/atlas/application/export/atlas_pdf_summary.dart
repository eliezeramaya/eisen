import 'package:eisen/features/eisen_matrix/domain/entities.dart';

/// Returns task count grouped by quadrant label.
/// Uses professional labels: Crítico, Crecimiento, De otros, Archivar.
Map<String, int> atlasSummaryByQuadrant(List<Task> tasks) {
  final result = <String, int>{
    'Crítico': 0,
    'Crecimiento': 0,
    'De otros': 0,
    'Archivar': 0,
  };
  for (final task in tasks) {
    final label = switch (task.quadrant) {
      Quadrant.q1 => 'Crítico',
      Quadrant.q2 => 'Crecimiento',
      Quadrant.q3 => 'De otros',
      Quadrant.q4 => 'Archivar',
    };
    result[label] = (result[label] ?? 0) + 1;
  }
  return result;
}

/// Returns task count grouped by category name.
Map<String, int> atlasSummaryByCategory(List<Task> tasks) {
  final result = <String, int>{};
  for (final task in tasks) {
    final label = task.category ?? 'Sin categoría';
    result[label] = (result[label] ?? 0) + 1;
  }
  return result;
}

/// Generates simple rule-based insight strings for PDF reports.
List<String> atlasPdfInsights({
  required Map<String, int> summaryByQuadrant,
  required Map<String, int> summaryByCategory,
  required int visibleTaskCount,
}) {
  if (visibleTaskCount == 0) return const [];

  final insights = <String>[];

  final q1 = summaryByQuadrant['Crítico'] ?? 0;
  final q2 = summaryByQuadrant['Crecimiento'] ?? 0;
  final q3 = summaryByQuadrant['De otros'] ?? 0;

  if (q1 > q2) {
    insights.add('Tu carga crítica supera tu trabajo de crecimiento.');
  }

  if (q2 < visibleTaskCount ~/ 5 && visibleTaskCount >= 5) {
    insights.add('Crecimiento tiene poca presencia en este Atlas.');
  }

  if (q3 > visibleTaskCount ~/ 3 && visibleTaskCount >= 6) {
    insights.add('Hay muchas tareas urgentes de otros.');
  }

  if (summaryByCategory.isNotEmpty) {
    final sorted = summaryByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    if (top.value / visibleTaskCount > 0.6) {
      insights.add(
        'La mayoría de tus tareas visibles están en "${top.key}".',
      );
    }
  }

  return insights;
}
