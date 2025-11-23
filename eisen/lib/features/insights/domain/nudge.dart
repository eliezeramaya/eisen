import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Tipo de insight que puede generar el motor de nudges.
enum NudgeType {
  // Reglas existentes
  lowQ2,
  excessiveReschedules,
  overload,

  // Nuevas reglas P2
  procrastination, // Tareas grandes sin avance
  quadrantImbalance, // Desbalance extremo entre cuadrantes
  noProject, // Muchas tareas sin proyecto asignado
  dailyOverload, // Sobrecarga recurrente (similar a overload pero histórico)
  noFocusSessions, // Días sin sesiones de foco
  lateNightWork, // Trabajo nocturno recurrente (después de medianoche)
}

/// Categoría temática del nudge para agrupar y filtrar.
enum NudgeCategory {
  balance, // Balance entre cuadrantes
  focus, // Sesiones de foco y concentración
  health, // Salud y bienestar (late night work)
  organization, // Organización y proyectos
  productivity, // Productividad general
}

/// Tipo de acción que puede ejecutar el usuario desde un nudge.
enum NudgeActionType {
  openFocus, // Abrir página de Focus/Pomodoro
  openTaskSplit, // Abrir editor de tarea para dividirla
  openGantt, // Abrir vista Gantt/Calendar
  openMatrix, // Abrir Matriz con filtro específico
  openSettings, // Abrir Settings en sección específica
  openStats, // Abrir Stats
  none, // Sin acción específica (solo informativo)
}

/// Acción accionable que puede ejecutar el usuario desde un nudge.
@immutable
class NudgeAction extends Equatable {
  const NudgeAction({
    required this.type,
    required this.label,
    this.route,
    this.params = const <String, Object?>{},
  });

  /// Tipo de acción a ejecutar.
  final NudgeActionType type;

  /// Etiqueta del botón mostrado en UI.
  final String label;

  /// Ruta opcional de navegación (para uso con GoRouter).
  final String? route;

  /// Parámetros adicionales para la acción (ej: taskId, filter, etc).
  final Map<String, Object?> params;

  @override
  List<Object?> get props => [type, label, route, params];
}

/// Severidad relativa para priorizar la visibilidad de los nudges.
enum NudgeSeverity {
  low,
  medium,
  mediumHigh,
  high,
}

/// Modelo inmutable que representa un nudge (insight accionable).
///
/// Los nudges se identifican por [id] para poder persistir descartes
/// y evitar duplicados. [metadata] permite almacenar datos de contexto
/// (por ejemplo, porcentajes o contadores) sin acoplar la UI.
@immutable
class Nudge extends Equatable {
  const Nudge({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.category = NudgeCategory.productivity,
    this.metadata = const <String, Object?>{},
    this.actions = const <NudgeAction>[],
  });

  /// Identificador estable usado para deduplicar y persistir descartes.
  final String id;

  /// Categoría del nudge que indica su origen o regla aplicada.
  final NudgeType type;

  /// Título corto mostrado en UI.
  final String title;

  /// Mensaje descriptivo o recomendación.
  final String message;

  /// Severidad para ordenar y priorizar en la capa de presentación.
  final NudgeSeverity severity;

  /// Momento en que se calculó o generó el nudge.
  final DateTime createdAt;

  /// Categoría temática para agrupar nudges.
  final NudgeCategory category;

  /// Datos adicionales para enriquecer la experiencia (ej: métricas).
  final Map<String, Object?> metadata;

  /// Lista de acciones que el usuario puede ejecutar desde este nudge.
  final List<NudgeAction> actions;

  /// Crea una copia con los cambios indicados sin mutar la instancia original.
  Nudge copyWith({
    String? id,
    NudgeType? type,
    String? title,
    String? message,
    NudgeSeverity? severity,
    DateTime? createdAt,
    NudgeCategory? category,
    Map<String, Object?>? metadata,
    List<NudgeAction>? actions,
  }) {
    return Nudge(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
      actions: actions ?? this.actions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        message,
        severity,
        createdAt,
        category,
        metadata,
        actions,
      ];
}
