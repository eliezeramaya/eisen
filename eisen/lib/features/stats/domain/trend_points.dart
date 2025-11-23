import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/foundation.dart';

/// Punto de datos agregado de productividad diaria.
///
/// Contiene métricas de tareas completadas por día,
/// desglosadas por cuadrante Eisenhower.
@immutable
class DailyProductivityPoint {
  const DailyProductivityPoint({
    required this.date,
    required this.completedCount,
    required this.byQuadrant,
  });

  /// Fecha del punto (normalizada a medianoche).
  final DateTime date;

  /// Total de tareas completadas en este día.
  final int completedCount;

  /// Desglose por cuadrante Eisenhower.
  final Map<Quadrant, int> byQuadrant;

  /// Obtiene el conteo para un cuadrante específico.
  int getCount(Quadrant quadrant) => byQuadrant[quadrant] ?? 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyProductivityPoint &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          completedCount == other.completedCount &&
          _mapEquals(byQuadrant, other.byQuadrant);

  @override
  int get hashCode => Object.hash(date, completedCount, byQuadrant);

  bool _mapEquals(Map<Quadrant, int> a, Map<Quadrant, int> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Punto de datos agregado de sesiones de foco diarias.
///
/// Contiene métricas de tiempo de foco y conteo de sesiones
/// completadas por día.
@immutable
class DailyFocusPoint {
  const DailyFocusPoint({
    required this.date,
    required this.totalFocus,
    required this.sessionsCount,
  });

  /// Fecha del punto (normalizada a medianoche).
  final DateTime date;

  /// Tiempo total de foco en este día.
  final Duration totalFocus;

  /// Número de sesiones completadas en este día.
  final int sessionsCount;

  /// Duración promedio por sesión.
  Duration get averageSessionDuration => sessionsCount > 0
      ? Duration(
          milliseconds: totalFocus.inMilliseconds ~/ sessionsCount,
        )
      : Duration.zero;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyFocusPoint &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          totalFocus == other.totalFocus &&
          sessionsCount == other.sessionsCount;

  @override
  int get hashCode => Object.hash(date, totalFocus, sessionsCount);
}

/// Tipo de tendencia detectada en los datos.
enum TrendDirection {
  /// Tendencia al alza.
  increasing,

  /// Tendencia a la baja.
  decreasing,

  /// Sin cambio significativo.
  stable,
}

/// Análisis de tendencia sobre un conjunto de puntos.
@immutable
class TrendAnalysis {
  const TrendAnalysis({
    required this.direction,
    required this.percentageChange,
    required this.insight,
  });

  /// Dirección de la tendencia.
  final TrendDirection direction;

  /// Cambio porcentual (puede ser negativo).
  final double percentageChange;

  /// Mensaje legible sobre la tendencia.
  final String insight;

  /// Calcula análisis de tendencia comparando dos períodos.
  ///
  /// [current] es el valor del período más reciente.
  /// [previous] es el valor del período anterior.
  static TrendAnalysis compare({
    required double current,
    required double previous,
  }) {
    if (previous == 0 && current == 0) {
      return const TrendAnalysis(
        direction: TrendDirection.stable,
        percentageChange: 0,
        insight: 'Sin cambios',
      );
    }

    if (previous == 0) {
      return TrendAnalysis(
        direction: TrendDirection.increasing,
        percentageChange: 100,
        insight: 'Inicio de actividad: ${current.toStringAsFixed(0)} tareas',
      );
    }

    final change = ((current - previous) / previous) * 100;
    final absChange = change.abs();

    if (absChange < 5) {
      return TrendAnalysis(
        direction: TrendDirection.stable,
        percentageChange: change,
        insight: 'Productividad estable',
      );
    }

    if (change > 0) {
      return TrendAnalysis(
        direction: TrendDirection.increasing,
        percentageChange: change,
        insight: 'Mejora del ${change.toStringAsFixed(0)}%',
      );
    }

    return TrendAnalysis(
      direction: TrendDirection.decreasing,
      percentageChange: change,
      insight: 'Descenso del ${absChange.toStringAsFixed(0)}%',
    );
  }
}
