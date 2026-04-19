// ignore_for_file: sort_constructors_first

import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';

@immutable
class TaskIsolateSnapshot {
  const TaskIsolateSnapshot({
    required this.id,
    required this.title,
    required this.quadrant,
    required this.priority,
    required this.minutes,
    this.due,
    this.tags = const <String>[],
    this.categories = const <String>[],
    this.notes,
    this.projectId,
    this.status = TaskStatus.pending,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.normalizedPriority,
    this.normalizedMinutes,
  });

  final String id;
  final String title;
  final Quadrant quadrant;
  final int priority;
  final int minutes;
  final DateTime? due;
  final List<String> tags;
  final List<String> categories;
  final String? notes;
  final String? projectId;
  final TaskStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final double? normalizedPriority;
  final double? normalizedMinutes;

  factory TaskIsolateSnapshot.fromTask(Task task) => TaskIsolateSnapshot(
        id: task.id,
        title: task.title,
        quadrant: task.quadrant,
        priority: task.priority,
        minutes: task.minutes,
        due: task.due,
        tags: task.tags,
        categories: task.categories,
        notes: task.notes,
        projectId: task.projectId,
        status: task.status,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
        completedAt: task.completedAt,
        normalizedPriority: task.normalizedPriority,
        normalizedMinutes: task.normalizedMinutes,
      );

  Task toDomain() => Task(
        id: id,
        title: title,
        quadrant: quadrant,
        priority: priority,
        minutes: minutes,
        due: due,
        tags: tags,
        categories: categories,
        notes: notes,
        projectId: projectId,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
        completedAt: completedAt,
        normalizedPriority: normalizedPriority,
        normalizedMinutes: normalizedMinutes,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'quadrant': quadrant.index,
        'priority': priority,
        'minutes': minutes,
        'due': due?.toIso8601String(),
        'tags': tags,
        'categories': categories,
        'notes': notes,
        'projectId': projectId,
        'status': status.index,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'normalizedPriority': normalizedPriority,
        'normalizedMinutes': normalizedMinutes,
      };

  factory TaskIsolateSnapshot.fromJson(Map<String, Object?> json) {
    DateTime? parseTs(Object? raw) {
      if (raw is String) return DateTime.tryParse(raw);
      if (raw is DateTime) return raw;
      return null;
    }

    final rawTags = json['tags'];
    final rawCategories = json['categories'];
    final tags =
        rawTags is List ? List<String>.from(rawTags) : const <String>[];
    final categories = rawCategories is List
        ? List<String>.from(rawCategories)
        : const <String>[];

    final quadrantIndex = json['quadrant'] as int? ?? 0;
    final safeQuadrantIndex = quadrantIndex < 0
        ? 0
        : (quadrantIndex >= Quadrant.values.length
            ? Quadrant.values.length - 1
            : quadrantIndex);
    final statusIndex = json['status'] as int? ?? TaskStatus.pending.index;
    final safeStatusIndex = statusIndex < 0
        ? 0
        : (statusIndex >= TaskStatus.values.length
            ? TaskStatus.values.length - 1
            : statusIndex);

    return TaskIsolateSnapshot(
      id: json['id'] as String,
      title: json['title'] as String,
      quadrant: Quadrant.values[safeQuadrantIndex],
      priority: json['priority'] as int,
      minutes: json['minutes'] as int,
      due: parseTs(json['due']),
      tags: tags,
      categories: categories,
      notes: json['notes'] as String?,
      projectId: json['projectId'] as String?,
      status: TaskStatus.values[safeStatusIndex],
      createdAt: parseTs(json['createdAt']),
      updatedAt: parseTs(json['updatedAt']),
      completedAt: parseTs(json['completedAt']),
      normalizedPriority: (json['normalizedPriority'] as num?)?.toDouble(),
      normalizedMinutes: (json['normalizedMinutes'] as num?)?.toDouble(),
    );
  }

  DateTime? get freshness => completedAt ?? updatedAt ?? createdAt;
  bool get isCompleted => completedAt != null;
}

@immutable
class MatrixRectDto {
  const MatrixRectDto({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  factory MatrixRectDto.fromRect(Rect rect) => MatrixRectDto(
        left: rect.left,
        top: rect.top,
        width: rect.width,
        height: rect.height,
      );

  Rect toRect() => Rect.fromLTWH(left, top, width, height);

  MatrixRectDto scale(double factor) => MatrixRectDto(
        left: left * factor,
        top: top * factor,
        width: width * factor,
        height: height * factor,
      );

  MatrixRectDto translate(double dx, double dy) => MatrixRectDto(
        left: left + dx,
        top: top + dy,
        width: width,
        height: height,
      );

  Map<String, Object> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
      };

  factory MatrixRectDto.fromJson(Map<String, Object?> json) => MatrixRectDto(
        left: (json['left'] as num).toDouble(),
        top: (json['top'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );
}

@immutable
class MatrixViewportSnapshot {
  const MatrixViewportSnapshot({
    required this.width,
    required this.height,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  });

  final double width;
  final double height;
  final double scale;
  final double offsetX;
  final double offsetY;

  bool get hasArea => width > 0 && height > 0;

  Map<String, Object> toJson() => {
        'width': width,
        'height': height,
        'scale': scale,
        'offsetX': offsetX,
        'offsetY': offsetY,
      };

  factory MatrixViewportSnapshot.fromJson(Map<String, Object?> json) =>
      MatrixViewportSnapshot(
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
        offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
      );
}
