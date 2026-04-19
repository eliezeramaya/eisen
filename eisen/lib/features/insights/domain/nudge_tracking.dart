import 'package:flutter/foundation.dart';

/// Datos de tracking para medir la interacción del usuario con un nudge.
///
/// Permite registrar cuándo se vio por primera vez, cuántas veces se ha
/// mostrado, si fue descartado, o si el usuario actuó sobre él.
@immutable
class NudgeTrackingData {
  const NudgeTrackingData({
    required this.nudgeId,
    this.firstSeenAt,
    this.lastSeenAt,
    this.dismissedAt,
    this.actedAt,
    this.viewCount = 0,
  });

  /// Crea desde Map (deserialización).
  factory NudgeTrackingData.fromJson(Map<String, dynamic> json) {
    return NudgeTrackingData(
      nudgeId: json['nudgeId'] as String,
      firstSeenAt: json['firstSeenAt'] != null
          ? DateTime.parse(json['firstSeenAt'] as String)
          : null,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.parse(json['lastSeenAt'] as String)
          : null,
      dismissedAt: json['dismissedAt'] != null
          ? DateTime.parse(json['dismissedAt'] as String)
          : null,
      actedAt: json['actedAt'] != null
          ? DateTime.parse(json['actedAt'] as String)
          : null,
      viewCount: json['viewCount'] as int? ?? 0,
    );
  }

  /// ID del nudge al que pertenece este tracking.
  final String nudgeId;

  /// Primera vez que se mostró este nudge al usuario.
  final DateTime? firstSeenAt;

  /// Última vez que se mostró este nudge.
  final DateTime? lastSeenAt;

  /// Momento en que el usuario descartó el nudge.
  final DateTime? dismissedAt;

  /// Momento en que el usuario ejecutó una acción desde el nudge.
  final DateTime? actedAt;

  /// Número de veces que se ha mostrado el nudge.
  final int viewCount;

  /// Si el nudge fue descartado.
  bool get wasDismissed => dismissedAt != null;

  /// Si el usuario actuó sobre el nudge.
  bool get wasActedOn => actedAt != null;

  /// Si el nudge ha sido visto al menos una vez.
  bool get hasBeenSeen => firstSeenAt != null;

  /// Crea una copia con los cambios indicados.
  NudgeTrackingData copyWith({
    String? nudgeId,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    DateTime? dismissedAt,
    DateTime? actedAt,
    int? viewCount,
  }) {
    return NudgeTrackingData(
      nudgeId: nudgeId ?? this.nudgeId,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      actedAt: actedAt ?? this.actedAt,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  /// Marca el nudge como visto ahora.
  NudgeTrackingData markAsSeen() {
    final now = DateTime.now();
    return copyWith(
      firstSeenAt: firstSeenAt ?? now,
      lastSeenAt: now,
      viewCount: viewCount + 1,
    );
  }

  /// Marca el nudge como descartado ahora.
  NudgeTrackingData markAsDismissed() {
    return copyWith(
      dismissedAt: DateTime.now(),
    );
  }

  /// Marca el nudge como actuado ahora.
  NudgeTrackingData markAsActed() {
    return copyWith(
      actedAt: DateTime.now(),
    );
  }

  /// Convierte a Map para persistencia.
  Map<String, dynamic> toJson() {
    return {
      'nudgeId': nudgeId,
      'firstSeenAt': firstSeenAt?.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'dismissedAt': dismissedAt?.toIso8601String(),
      'actedAt': actedAt?.toIso8601String(),
      'viewCount': viewCount,
    };
  }
}
