import 'package:eisen/features/atlas/domain/atlas_insight.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

List<AtlasInsight> buildAtlasInsights({
  required List<Task> tasks,
  required DateTime now,
  int limit = 3,
}) {
  final activeTasks = tasks
      .where((task) => task.completedAt == null && !task.isArchived)
      .toList(growable: false);
  if (activeTasks.isEmpty || limit <= 0) return const <AtlasInsight>[];

  final insights = <AtlasInsight>[
    ..._dailyLoadInsight(activeTasks, now),
    ..._quadrantImbalanceInsight(activeTasks),
    ..._focusOpportunityInsight(activeTasks),
    ..._classificationReviewInsight(activeTasks),
    ..._stalePlanInsight(activeTasks),
  ];

  insights.sort((a, b) {
    final byPriority = b.priority.index.compareTo(a.priority.index);
    if (byPriority != 0) return byPriority;
    return a.kind.index.compareTo(b.kind.index);
  });

  return insights.take(limit).toList(growable: false);
}

Iterable<AtlasInsight> _dailyLoadInsight(List<Task> tasks, DateTime now) {
  final todayStart = DateTime(now.year, now.month, now.day);
  final tomorrowStart = todayStart.add(const Duration(days: 1));
  final dueNow = tasks.where((task) {
    final due = task.due;
    return due != null && due.isBefore(tomorrowStart);
  }).toList(growable: false);

  final minutes = dueNow.fold<int>(0, (sum, task) => sum + task.minutes);
  if (dueNow.length < 4 && minutes < 180) return const <AtlasInsight>[];

  final sorted = [...dueNow]..sort(_byUrgency);
  final hours = (minutes / 60).toStringAsFixed(minutes % 60 == 0 ? 0 : 1);
  return [
    AtlasInsight(
      id: 'atlas-daily-load',
      kind: AtlasInsightKind.overload,
      priority: AtlasInsightPriority.high,
      title: 'Día cargado',
      message:
          '${dueNow.length} tareas concentran ${hours}h. Prioriza las 2 más críticas.',
      primaryTaskId: sorted.first.id,
      taskIds: sorted.take(6).map((task) => task.id).toList(growable: false),
      actions: const [
        AtlasInsightAction(
          kind: AtlasInsightActionKind.openPrimaryTask,
          label: 'Ver crítica',
        ),
        AtlasInsightAction(
          kind: AtlasInsightActionKind.editPrimaryTask,
          label: 'Replanificar',
        ),
      ],
    ),
  ];
}

Iterable<AtlasInsight> _quadrantImbalanceInsight(List<Task> tasks) {
  if (tasks.length < 6) return const <AtlasInsight>[];

  final urgentCount = tasks
      .where((task) =>
          task.quadrant == Quadrant.q1 || task.quadrant == Quadrant.q3)
      .length;
  final share = urgentCount / tasks.length;
  if (share < 0.65) return const <AtlasInsight>[];

  return [
    AtlasInsight(
      id: 'atlas-urgent-imbalance',
      kind: AtlasInsightKind.quadrantImbalance,
      priority: AtlasInsightPriority.high,
      title: 'Atlas en modo urgencia',
      message:
          '${(share * 100).round()}% de tus tareas están en cuadrantes urgentes.',
      taskIds: tasks
          .where((task) =>
              task.quadrant == Quadrant.q1 || task.quadrant == Quadrant.q3)
          .take(6)
          .map((task) => task.id)
          .toList(growable: false),
      actions: const [
        AtlasInsightAction(
          kind: AtlasInsightActionKind.groupByQuadrant,
          label: 'Ver por cuadrante',
        ),
      ],
    ),
  ];
}

Iterable<AtlasInsight> _focusOpportunityInsight(List<Task> tasks) {
  final candidates = tasks
      .where((task) => task.quadrant == Quadrant.q2)
      .toList(growable: false);
  if (candidates.isEmpty) return const <AtlasInsight>[];

  candidates.sort((a, b) {
    final priority = b.priority.compareTo(a.priority);
    if (priority != 0) return priority;
    return b.minutes.compareTo(a.minutes);
  });
  final task = candidates.first;
  if (task.priority < 6 && task.minutes < 45) return const <AtlasInsight>[];

  return [
    AtlasInsight(
      id: 'atlas-q2-focus-opportunity',
      kind: AtlasInsightKind.focusOpportunity,
      priority: AtlasInsightPriority.medium,
      title: 'Oportunidad de foco',
      message:
          'Bloquea tiempo para "${task.title}" antes de que se vuelva urgente.',
      primaryTaskId: task.id,
      taskIds: [task.id],
      actions: const [
        AtlasInsightAction(
          kind: AtlasInsightActionKind.openPrimaryTask,
          label: 'Ver tarea',
        ),
        AtlasInsightAction(
          kind: AtlasInsightActionKind.editPrimaryTask,
          label: 'Planificar',
        ),
      ],
    ),
  ];
}

Iterable<AtlasInsight> _classificationReviewInsight(List<Task> tasks) {
  final lowConfidence = tasks
      .where((task) => task.classificationConfidence == ConfidenceLevel.low)
      .toList(growable: false);
  if (lowConfidence.length < 2) return const <AtlasInsight>[];

  return [
    AtlasInsight(
      id: 'atlas-low-confidence',
      kind: AtlasInsightKind.classificationReview,
      priority: AtlasInsightPriority.medium,
      title: 'Revisa clasificación',
      message: '${lowConfidence.length} tareas tienen confianza baja.',
      primaryTaskId: lowConfidence.first.id,
      taskIds:
          lowConfidence.take(6).map((task) => task.id).toList(growable: false),
      actions: const [
        AtlasInsightAction(
          kind: AtlasInsightActionKind.reclassifyPrimaryTask,
          label: 'Reclasificar',
        ),
        AtlasInsightAction(
          kind: AtlasInsightActionKind.filterLowConfidence,
          label: 'Filtrar bajas',
        ),
      ],
    ),
  ];
}

Iterable<AtlasInsight> _stalePlanInsight(List<Task> tasks) {
  final stale = tasks.where((task) {
    final needsBreakdown = task.minutes >= 120 && task.subtasks.isEmpty;
    return task.replanCount >= 2 || task.snoozeCount >= 2 || needsBreakdown;
  }).toList(growable: false);
  if (stale.isEmpty) return const <AtlasInsight>[];

  stale.sort((a, b) {
    final byReplans = b.replanCount.compareTo(a.replanCount);
    if (byReplans != 0) return byReplans;
    return b.minutes.compareTo(a.minutes);
  });

  return [
    AtlasInsight(
      id: 'atlas-stale-plan',
      kind: AtlasInsightKind.stalePlan,
      priority: AtlasInsightPriority.medium,
      title: 'Tareas que piden desglose',
      message:
          'Divide o replanifica "${stale.first.title}" para desbloquear avance.',
      primaryTaskId: stale.first.id,
      taskIds: stale.take(6).map((task) => task.id).toList(growable: false),
      actions: const [
        AtlasInsightAction(
          kind: AtlasInsightActionKind.editPrimaryTask,
          label: 'Editar',
        ),
        AtlasInsightAction(
          kind: AtlasInsightActionKind.openPrimaryTask,
          label: 'Ver detalle',
        ),
      ],
    ),
  ];
}

int _byUrgency(Task a, Task b) {
  final dueA = a.due;
  final dueB = b.due;
  if (dueA != null && dueB != null) {
    final byDue = dueA.compareTo(dueB);
    if (byDue != 0) return byDue;
  } else if (dueA != null) {
    return -1;
  } else if (dueB != null) {
    return 1;
  }
  return b.priority.compareTo(a.priority);
}
