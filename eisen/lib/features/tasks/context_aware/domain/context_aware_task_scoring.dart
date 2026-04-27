import 'dart:math' as math;

import 'package:eisen/features/eisen_matrix/domain/entities.dart';

import 'context_state.dart';

class RankedContextTask {
  const RankedContextTask({
    required this.task,
    required this.score,
    required this.locationMatch,
    required this.proximityScore,
    required this.priorityWeight,
    required this.explanation,
    this.distanceMeters,
  });

  final Task task;
  final double score;
  final double locationMatch;
  final double proximityScore;
  final double priorityWeight;
  final double? distanceMeters;
  final String explanation;

  bool get isHighRelevance => score >= 0.72;
  bool get isMediumRelevance => score >= 0.48;
}

List<RankedContextTask> rankContextAwareTasks({
  required Iterable<Task> tasks,
  required ContextState context,
}) {
  final ranked = tasks
      .where((task) => !task.isCompleted)
      .map((task) => scoreContextAwareTask(task: task, context: context))
      .toList(growable: false);

  ranked.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;

    final byPriority = b.task.priority.compareTo(a.task.priority);
    if (byPriority != 0) return byPriority;

    final byMinutes = a.task.minutes.compareTo(b.task.minutes);
    if (byMinutes != 0) return byMinutes;

    return a.task.title.compareTo(b.task.title);
  });

  return ranked;
}

RankedContextTask scoreContextAwareTask({
  required Task task,
  required ContextState context,
}) {
  final locationMatch = _locationMatch(task, context);
  final proximity = _proximitySignal(task, context);
  final priorityWeight = _priorityWeight(task);

  final score =
      (locationMatch * 0.5) + (proximity.score * 0.3) + (priorityWeight * 0.2);

  return RankedContextTask(
    task: task,
    score: score.clamp(0.0, 1.0),
    locationMatch: locationMatch,
    proximityScore: proximity.score,
    priorityWeight: priorityWeight,
    distanceMeters: proximity.distanceMeters,
    explanation: _buildExplanation(
      task: task,
      context: context,
      locationMatch: locationMatch,
      proximity: proximity,
      priorityWeight: priorityWeight,
    ),
  );
}

double _locationMatch(Task task, ContextState context) {
  if (task.locationTag != null &&
      task.locationTag == context.currentLocationTag) {
    return 1.0;
  }

  return _inferLocationFromMetadata(task, context.currentLocationTag);
}

double _inferLocationFromMetadata(Task task, String contextTag) {
  if (contextTag == unknownContextPreset.tag) {
    return 0.0;
  }

  final haystack = <String>[
    if (task.category != null) task.category!,
    ...task.categories,
    ...task.tags,
    task.description,
  ].join(' ').toLowerCase();

  final keywords = switch (contextTag) {
    'home' => const ['casa', 'home', 'personal', 'salud', 'hogar', 'yoga'],
    'office' => const [
        'oficina',
        'office',
        'trabajo',
        'backend',
        'cliente',
        'reuniones',
        'estrategia',
      ],
    'errands' => const ['recados', 'compra', 'compras', 'llamada', 'gestión'],
    'study' => const [
        'study',
        'estudio',
        'aprendiz',
        'learn',
        'curso',
        'leer',
        'research',
        'doc',
      ],
    'wellness' => const [
        'wellness',
        'salud',
        'health',
        'yoga',
        'medita',
        'cardio',
        'descanso',
      ],
    _ => const <String>[],
  };

  if (keywords.any(haystack.contains)) {
    return 0.62;
  }

  return 0.0;
}

_ProximitySignal _proximitySignal(Task task, ContextState context) {
  if (!task.hasCoordinates || !context.hasCoordinates) {
    return const _ProximitySignal(score: 0.0, distanceMeters: null);
  }

  final distanceMeters = _haversineMeters(
    context.latitude!,
    context.longitude!,
    task.latitude!,
    task.longitude!,
  );
  final radiusMeters = (task.radiusMeters ?? 1200).clamp(250.0, 5000.0);
  final score = math.max(0.0, 1.0 - (distanceMeters / (radiusMeters * 1.5)));

  return _ProximitySignal(score: score, distanceMeters: distanceMeters);
}

double _priorityWeight(Task task) {
  final priorityNorm = ((task.priority.clamp(1, 10) - 1) / 9).clamp(0.0, 1.0);
  final minutesNorm =
      ((task.minutes.clamp(10, 180) - 10) / 170).clamp(0.0, 1.0);
  final quickWinBonus = 1.0 - minutesNorm;
  return (priorityNorm * 0.78) + (quickWinBonus * 0.22);
}

String _buildExplanation({
  required Task task,
  required ContextState context,
  required double locationMatch,
  required _ProximitySignal proximity,
  required double priorityWeight,
}) {
  if (locationMatch >= 0.95 && proximity.distanceMeters != null) {
    return 'Coincide con ${context.currentLocationTag} y esta cerca (${_compactDistance(proximity.distanceMeters!)})';
  }

  if (locationMatch >= 0.95) {
    return 'Coincide con tu contexto actual';
  }

  if (proximity.score > 0.0 && proximity.distanceMeters != null) {
    return 'Ubicacion asociada a ${_compactDistance(proximity.distanceMeters!)}';
  }

  if (priorityWeight >= 0.65) {
    return 'Sube por prioridad ${task.priority}/10 y tiempo accionable';
  }

  return 'Sin senal contextual fuerte, ordenada por prioridad base';
}

double _haversineMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.pow(math.sin(dLon / 2), 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusMeters * c;
}

double _degToRad(double value) => value * (math.pi / 180.0);

String _compactDistance(double distanceMeters) {
  if (distanceMeters >= 1000) {
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
  return '${distanceMeters.round()} m';
}

class _ProximitySignal {
  const _ProximitySignal({
    required this.score,
    required this.distanceMeters,
  });

  final double score;
  final double? distanceMeters;
}
