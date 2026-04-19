// ignore_for_file: sort_constructors_first

import 'dart:async';

import 'package:eisen/core/workers/worker_models.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/foundation.dart';

enum TaskSortMode { priorityThenDue, dueThenPriority, updatedAt, createdAt }

class TaskSortRequest {
  const TaskSortRequest({
    required this.tasks,
    this.mode = TaskSortMode.priorityThenDue,
    this.query,
    this.onlyQuadrant,
    this.statuses = const <TaskStatus>{},
    this.projectIds = const <String>{},
    this.updatedAfter,
    this.limit,
    this.includeCompleted = false,
  });

  final List<TaskIsolateSnapshot> tasks;
  final TaskSortMode mode;
  final String? query;
  final Quadrant? onlyQuadrant;
  final Set<TaskStatus> statuses;
  final Set<String> projectIds;
  final DateTime? updatedAfter;
  final int? limit;
  final bool includeCompleted;

  Map<String, Object?> toJson() => {
        'tasks': tasks.map((t) => t.toJson()).toList(growable: false),
        'mode': mode.index,
        'query': query,
        'onlyQuadrant': onlyQuadrant?.index,
        'statuses': statuses.map((s) => s.index).toList(growable: false),
        'projectIds': projectIds.toList(growable: false),
        'updatedAfter': updatedAfter?.toIso8601String(),
        'limit': limit,
        'includeCompleted': includeCompleted,
      };

  factory TaskSortRequest.fromJson(Map<String, Object?> json) {
    final tasksJson = json['tasks'];
    final rawStatuses = json['statuses'];
    final rawProjects = json['projectIds'];
    final statusSet = <TaskStatus>{};
    if (rawStatuses is List) {
      for (final value in rawStatuses) {
        if (value is int && value >= 0 && value < TaskStatus.values.length) {
          statusSet.add(TaskStatus.values[value]);
        }
      }
    }

    final projectSet = <String>{};
    if (rawProjects is List) {
      projectSet.addAll(rawProjects.whereType<String>());
    }

    final updatedAfterRaw = json['updatedAfter'];
    DateTime? updatedAfter;
    if (updatedAfterRaw is String) {
      updatedAfter = DateTime.tryParse(updatedAfterRaw);
    } else if (updatedAfterRaw is DateTime) {
      updatedAfter = updatedAfterRaw;
    }

    final quadrantIndex = json['onlyQuadrant'] as int?;
    Quadrant? onlyQuadrant;
    if (quadrantIndex != null &&
        quadrantIndex >= 0 &&
        quadrantIndex < Quadrant.values.length) {
      onlyQuadrant = Quadrant.values[quadrantIndex];
    }

    final modeIndex = json['mode'] as int? ?? 0;
    final safeModeIndex = modeIndex < 0
        ? 0
        : (modeIndex >= TaskSortMode.values.length
            ? TaskSortMode.values.length - 1
            : modeIndex);

    return TaskSortRequest(
      tasks: tasksJson is List
          ? tasksJson
              .whereType<Map<String, Object?>>()
              .map(TaskIsolateSnapshot.fromJson)
              .toList(growable: false)
          : const <TaskIsolateSnapshot>[],
      mode: TaskSortMode.values[safeModeIndex],
      query: json['query'] as String?,
      onlyQuadrant: onlyQuadrant,
      statuses: statusSet,
      projectIds: projectSet,
      updatedAfter: updatedAfter,
      limit: json['limit'] as int?,
      includeCompleted: json['includeCompleted'] as bool? ?? false,
    );
  }
}

class TaskSortResponse {
  const TaskSortResponse({
    required this.orderedIds,
    required this.sorted,
    required this.total,
    required this.elapsedMs,
  });

  final List<String> orderedIds;
  final List<TaskIsolateSnapshot> sorted;
  final int total;
  final double elapsedMs;

  Map<String, Object?> toJson() => {
        'orderedIds': orderedIds,
        'sorted': sorted.map((t) => t.toJson()).toList(growable: false),
        'total': total,
        'elapsedMs': elapsedMs,
      };

  factory TaskSortResponse.fromJson(Map<String, Object?> json) =>
      TaskSortResponse(
        orderedIds:
            (json['orderedIds'] as List?)?.cast<String>() ?? const <String>[],
        sorted: (json['sorted'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, Object?>>()
            .map(TaskIsolateSnapshot.fromJson)
            .toList(growable: false),
        total: json['total'] as int? ?? 0,
        elapsedMs: (json['elapsedMs'] as num?)?.toDouble() ?? 0,
      );
}

/// Top-level worker entry for `compute`.
Future<TaskSortResponse> taskSortWorker(
  Map<String, Object?> message,
) async {
  final request = TaskSortRequest.fromJson(message);
  final sw = Stopwatch()..start();
  final normalizedQuery = request.query?.trim().toLowerCase();

  final filtered = request.tasks.where((task) {
    if (!request.includeCompleted && task.isCompleted) return false;
    if (request.onlyQuadrant != null && task.quadrant != request.onlyQuadrant) {
      return false;
    }
    if (request.statuses.isNotEmpty &&
        !request.statuses.contains(task.status)) {
      return false;
    }
    if (request.projectIds.isNotEmpty &&
        (task.projectId == null ||
            !request.projectIds.contains(task.projectId))) {
      return false;
    }
    if (request.updatedAfter != null &&
        (task.freshness == null ||
            task.freshness!.isBefore(request.updatedAfter!))) {
      return false;
    }
    if (normalizedQuery != null &&
        normalizedQuery.isNotEmpty &&
        !_matchesQuery(task, normalizedQuery)) {
      return false;
    }
    return true;
  }).toList(growable: false);

  final sortable = filtered
      .map(
        (snapshot) => _SortableTask(
          snapshot: snapshot,
          task: snapshot.toDomain(),
        ),
      )
      .toList(growable: false);

  sortable.sort(
    (a, b) => _compareTasks(a.task, b.task, request.mode),
  );

  final sortedSnapshots =
      sortable.map((pair) => pair.snapshot).toList(growable: false);
  final limited = request.limit == null
      ? sortedSnapshots
      : sortedSnapshots.take(request.limit!).toList(growable: false);

  sw.stop();

  final response = TaskSortResponse(
    orderedIds: limited.map((t) => t.id).toList(growable: false),
    sorted: limited,
    total: filtered.length,
    elapsedMs: sw.elapsedMicroseconds / 1000.0,
  );

  if (kDebugMode) {
    debugPrint(
        '[TaskSortWorker] tasks=${request.tasks.length} filtered=${filtered.length} mode=${request.mode.name} elapsed=${response.elapsedMs.toStringAsFixed(2)}ms');
  }
  return response;
}

bool _matchesQuery(TaskIsolateSnapshot task, String query) {
  final lowerTitle = task.title.toLowerCase();
  if (lowerTitle.contains(query)) return true;
  if (task.notes != null && task.notes!.toLowerCase().contains(query)) {
    return true;
  }
  for (final tag in task.tags) {
    if (tag.toLowerCase().contains(query)) return true;
  }
  for (final cat in task.categories) {
    if (cat.toLowerCase().contains(query)) return true;
  }
  return false;
}

int _compareTasks(Task a, Task b, TaskSortMode mode) {
  // Keep active tasks ahead of completed ones.
  final completedA = a.completedAt != null;
  final completedB = b.completedAt != null;
  if (completedA != completedB) {
    return completedA ? 1 : -1;
  }

  switch (mode) {
    case TaskSortMode.priorityThenDue:
      final prio = b.priority.compareTo(a.priority);
      if (prio != 0) return prio;
      final due = _dueCompare(a.due, b.due);
      if (due != 0) return due;
      final weightCmp = weight(b).compareTo(weight(a));
      if (weightCmp != 0) return weightCmp;
      final minutesCmp = b.minutes.compareTo(a.minutes);
      if (minutesCmp != 0) return minutesCmp;
      break;
    case TaskSortMode.dueThenPriority:
      final due = _dueCompare(a.due, b.due);
      if (due != 0) return due;
      final prio = b.priority.compareTo(a.priority);
      if (prio != 0) return prio;
      break;
    case TaskSortMode.updatedAt:
      final upd =
          _dateDesc(a.updatedAt ?? a.createdAt, b.updatedAt ?? b.createdAt);
      if (upd != 0) return upd;
      break;
    case TaskSortMode.createdAt:
      final cr = _dateDesc(a.createdAt, b.createdAt);
      if (cr != 0) return cr;
      break;
  }
  return a.title.compareTo(b.title);
}

int _dueCompare(DateTime? a, DateTime? b) {
  final future = DateTime.utc(9999, 1, 1);
  final da = a ?? future;
  final db = b ?? future;
  return da.compareTo(db);
}

int _dateDesc(DateTime? a, DateTime? b) {
  final base = DateTime.fromMillisecondsSinceEpoch(0);
  final da = a ?? base;
  final db = b ?? base;
  return db.compareTo(da);
}

class _SortableTask {
  const _SortableTask({required this.snapshot, required this.task});
  final TaskIsolateSnapshot snapshot;
  final Task task;
}
