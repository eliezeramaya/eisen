import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/focus/domain/focus_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trend_points.dart';

/// Servicio para calcular estadísticas de tendencias agregadas.
///
/// Procesa datos históricos de tareas y sesiones de foco para
/// generar puntos diarios que pueden visualizarse en gráficas.
class StatsTrendsService {
  StatsTrendsService(this.ref);

  final Ref ref;

  /// Obtiene todas las tareas disponibles.
  List<Task> _getAllTasks() => ref.read(matrixControllerProvider).tasks;

  /// Normaliza una fecha a medianoche (UTC).
  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  /// Calcula productividad diaria en el rango especificado.
  ///
  /// Agrupa tareas completadas por día y cuadrante.
  Future<List<DailyProductivityPoint>> getDailyProductivity({
    required DateTime from,
    required DateTime to,
  }) async {
    final tasks = _getAllTasks();
    final normalizedFrom = _normalizeDate(from);
    final normalizedTo = _normalizeDate(to);

    // Filtrar tareas completadas en el rango
    final completedTasks = tasks.where((task) {
      final completed = task.completedAt;
      if (completed == null) return false;

      final normalizedCompleted = _normalizeDate(completed);
      return !normalizedCompleted.isBefore(normalizedFrom) &&
          normalizedCompleted
              .isBefore(normalizedTo.add(const Duration(days: 1)));
    }).toList();

    // Agrupar por día
    final Map<DateTime, List<Task>> tasksByDay = {};
    for (final task in completedTasks) {
      final day = _normalizeDate(task.completedAt!);
      tasksByDay.putIfAbsent(day, () => []).add(task);
    }

    // Crear puntos para cada día en el rango (incluso días sin datos)
    final points = <DailyProductivityPoint>[];
    var currentDate = normalizedFrom;

    while (!currentDate.isAfter(normalizedTo)) {
      final dayTasks = tasksByDay[currentDate] ?? [];

      // Contar por cuadrante
      final byQuadrant = <Quadrant, int>{
        Quadrant.q1: 0,
        Quadrant.q2: 0,
        Quadrant.q3: 0,
        Quadrant.q4: 0,
      };

      for (final task in dayTasks) {
        byQuadrant[task.quadrant] = (byQuadrant[task.quadrant] ?? 0) + 1;
      }

      points.add(DailyProductivityPoint(
        date: currentDate,
        completedCount: dayTasks.length,
        byQuadrant: byQuadrant,
      ));

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return points;
  }

  /// Calcula métricas de foco diarias en el rango especificado.
  ///
  /// Agrupa sesiones de foco completadas por día.
  Future<List<DailyFocusPoint>> getDailyFocus({
    required DateTime from,
    required DateTime to,
  }) async {
    final repository = ref.read(focusRepositoryProvider);
    final normalizedFrom = _normalizeDate(from);
    final normalizedTo = _normalizeDate(to);

    // Get sessions in the date range
    final sessions = await repository.getSessions(
      from: normalizedFrom,
      to: normalizedTo.add(const Duration(days: 1)),
    );

    // Group sessions by day
    final Map<DateTime, List<dynamic>> sessionsByDay = {};
    for (final session in sessions) {
      final day = _normalizeDate(session.startedAt);
      sessionsByDay.putIfAbsent(day, () => []).add(session);
    }

    // Crear puntos para cada día
    final points = <DailyFocusPoint>[];
    var currentDate = normalizedFrom;

    while (!currentDate.isAfter(normalizedTo)) {
      final daySessions = sessionsByDay[currentDate] ?? [];

      // Calcular duración total
      var totalDuration = Duration.zero;
      for (final session in daySessions) {
        final duration = session.actualDuration ?? session.plannedDuration;
        totalDuration += duration;
      }

      points.add(DailyFocusPoint(
        date: currentDate,
        totalFocus: totalDuration,
        sessionsCount: daySessions.length,
      ));

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return points;
  }

  /// Calcula análisis de tendencia comparando dos períodos.
  ///
  /// [currentPeriodPoints] son los puntos del período actual.
  /// [previousPeriodPoints] son los puntos del período anterior.
  TrendAnalysis analyzeTrend({
    required List<DailyProductivityPoint> currentPeriodPoints,
    required List<DailyProductivityPoint> previousPeriodPoints,
  }) {
    final currentTotal = currentPeriodPoints.fold<int>(
      0,
      (sum, point) => sum + point.completedCount,
    );

    final previousTotal = previousPeriodPoints.fold<int>(
      0,
      (sum, point) => sum + point.completedCount,
    );

    return TrendAnalysis.compare(
      current: currentTotal.toDouble(),
      previous: previousTotal.toDouble(),
    );
  }

  /// Encuentra el cuadrante con mayor actividad.
  ///
  /// Retorna el cuadrante que tiene el mayor número de tareas
  /// completadas en el conjunto de puntos dado.
  Quadrant getMostActiveQuadrant(List<DailyProductivityPoint> points) {
    final totals = <Quadrant, int>{
      Quadrant.q1: 0,
      Quadrant.q2: 0,
      Quadrant.q3: 0,
      Quadrant.q4: 0,
    };

    for (final point in points) {
      for (final quadrant in Quadrant.values) {
        totals[quadrant] = (totals[quadrant] ?? 0) + point.getCount(quadrant);
      }
    }

    // Encontrar el máximo
    var maxQuadrant = Quadrant.q1;
    var maxCount = totals[Quadrant.q1] ?? 0;

    for (final entry in totals.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        maxQuadrant = entry.key;
      }
    }

    return maxQuadrant;
  }

  /// Calcula el promedio diario de tareas completadas.
  double getAverageDailyCompletions(List<DailyProductivityPoint> points) {
    if (points.isEmpty) return 0;

    final total = points.fold<int>(
      0,
      (sum, point) => sum + point.completedCount,
    );

    return total / points.length;
  }
}

/// Provider para el servicio de tendencias.
final statsTrendsServiceProvider = Provider<StatsTrendsService>((ref) {
  return StatsTrendsService(ref);
});
