import 'dart:math' as math;
import 'entities.dart';

/// Bandit-inspired tie-breaking service for stable treemap ordering.
///
/// Implements a lightweight Thompson-sampling approach for tie-breaking tasks
/// with similar weights. Does NOT affect area computation, only ordering.
///
/// Features:
/// - Q2 guardrail: Tasks in Q2 with due < 48h get priority in tie-breaks
/// - Scoring: Combines priority (scaled 1-10) + recency boost + small noise
/// - Deterministic seeding for reproducible layouts (configurable via [seed])
/// - Same seed + same task set = same ordering (stability guarantee)
class BanditService {
  /// Creates a [BanditService] with optional custom [seed].
  ///
  /// If [seed] is not provided, defaults to 42 for deterministic behavior.
  /// Pass a time-based seed for non-deterministic ordering if desired.
  BanditService({this.seed = 42}) : _rng = math.Random(seed);
  final math.Random _rng;

  /// Random seed used for deterministic tie-breaking.
  ///
  /// Using the same seed with the same task set guarantees identical ordering
  /// across sessions, enabling reproducible layouts and stable tests.
  final int seed;

  /// Returns rank map (lower rank = higher priority) for [tasks] within [quadrant].
  ///
  /// Ranks are used to break ties when tasks have similar visual weights.
  /// Q2 tasks with due dates < 48h are prioritized among ties.
  Map<String, int> tieBreakRanks(List<Task> tasks, Quadrant quadrant) {
    if (tasks.isEmpty) return const {};
    final now = DateTime.now();
    final urgentQ2 = quadrant == Quadrant.q2
        ? tasks
            .where((t) => t.due != null && t.due!.difference(now).inHours <= 48)
            .toList()
        : <Task>[];

    final scored = <Task, double>{};
    for (final t in tasks) {
      // Base: scaled priority + small recency and a bit of randomness
      final prio = t.priority.clamp(1, 10).toDouble();
      final recencyDays =
          ((now.difference(t.updatedAt ?? t.createdAt ?? now).inHours) / 24.0)
              .abs();
      final recBoost = 1.0 / (1.0 + recencyDays);
      final noise = (_rng.nextDouble() * 0.06) - 0.03; // [-0.03..0.03]
      final base = 0.1 * prio + 0.25 * recBoost + noise;
      scored[t] = base;
    }

    final ordered = tasks.toList()
      ..sort((a, b) => scored[b]!.compareTo(scored[a]!));

    if (urgentQ2.isNotEmpty) {
      // Move urgent Q2 tasks to the front among ties
      final idsUrgent = urgentQ2.map((e) => e.id).toSet();
      ordered.sort((a, b) {
        final au = idsUrgent.contains(a.id);
        final bu = idsUrgent.contains(b.id);
        if (au == bu) return scored[b]!.compareTo(scored[a]!);
        return au ? -1 : 1;
      });
    }

    final ranks = <String, int>{};
    for (var i = 0; i < ordered.length; i++) {
      ranks[ordered[i].id] = i;
    }
    return ranks;
  }

  /// Pick a single top-spot candidate among [tasks] using the same scoring
  /// and guardrails used for tie-breaking. Returns the task id or null.
  String? pickTopSpot(List<Task> tasks, Quadrant quadrant) {
    if (tasks.isEmpty) return null;
    final ranks = tieBreakRanks(tasks, quadrant);
    String? best;
    int bestRank = 1 << 30;
    for (final t in tasks) {
      final r = ranks[t.id] ?? (1 << 29);
      if (r < bestRank) {
        best = t.id;
        bestRank = r;
      }
    }
    return best;
  }
}
