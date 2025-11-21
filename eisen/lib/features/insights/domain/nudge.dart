import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Tipo de insight que puede generar el motor de nudges.
enum NudgeType {
  lowQ2,
  excessiveReschedules,
  overload,
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
    this.metadata = const <String, Object?>{},
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

  /// Datos adicionales para enriquecer la experiencia (ej: métricas).
  final Map<String, Object?> metadata;

  /// Crea una copia con los cambios indicados sin mutar la instancia original.
  Nudge copyWith({
    String? id,
    NudgeType? type,
    String? title,
    String? message,
    NudgeSeverity? severity,
    DateTime? createdAt,
    Map<String, Object?>? metadata,
  }) {
    return Nudge(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
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
        metadata,
      ];
}
