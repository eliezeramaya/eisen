import 'package:flutter/foundation.dart';

/// Tipos de eventos de usuario instrumentados para analítica local/ML.
enum UserEventType {
  taskCreated,
  taskCompleted,
  taskRescheduled,
  focusSessionStarted,
  focusSessionEnded,
  appOpened,
  appClosed,
  nudgeShown,
  nudgeActionExecuted,
}

/// Evento estructurado con metadatos opcionales serializables.
@immutable
class UserEvent {
  const UserEvent({
    required this.type,
    required this.timestamp,
    this.metadata = const {},
  });

  final UserEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  UserEvent copyWith({
    UserEventType? type,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return UserEvent(
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory UserEvent.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    final parsedType = UserEventType.values.firstWhere(
      (t) => t.name == rawType,
      orElse: () => UserEventType.appOpened,
    );
    final ts = json['timestamp'] as String?;
    return UserEvent(
      type: parsedType,
      timestamp: ts != null ? DateTime.parse(ts) : DateTime.now(),
      metadata:
          (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
