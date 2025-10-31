import 'package:eisen/core/services/telemetry.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';

/// Use case for computing top-3 reorder delta for telemetry.
///
/// Tracks how much the top 3 largest tiles per quadrant change between
/// layout computations (used for measuring layout stability).
class ComputeReorderDeltaUseCase {
  ComputeReorderDeltaUseCase(this._cache);
  final LayoutCache _cache;

  /// Computes the symmetric difference in top-3 tiles vs previous layout.
  ///
  /// Parameters:
  /// - [layout]: Current layout
  /// - [allTasks]: Map of all tasks by ID for quadrant lookup
  ///
  /// Emits telemetry event if delta > 0.
  void execute(List<TreemapRect> layout, Map<String, Task> allTasks) {
    final prevByQ = <Quadrant, List<String>>{
      for (final q in Quadrant.values) q: []
    };
    final currByQ = <Quadrant, List<String>>{
      for (final q in Quadrant.values) q: []
    };

    // Build previous top-3 from cache ranks
    for (final q in Quadrant.values) {
      final ids = _cache.lastRank.keys.where((id) {
        final t = allTasks[id];
        return t != null && t.quadrant == q;
      }).toList();

      ids.sort((a, b) => (_cache.lastRank[a] ?? (1 << 30))
          .compareTo(_cache.lastRank[b] ?? (1 << 30)));

      prevByQ[q] = ids.take(3).toList();
    }

    // Build current top-3 from layout (sorted by area)
    for (final q in Quadrant.values) {
      final items = layout
          .where((e) => e.task.quadrant == q && e.stackChildren.isEmpty)
          .toList();

      if (items.isEmpty) continue;

      items.sort((a, b) => (b.rect01.width * b.rect01.height)
          .compareTo(a.rect01.width * a.rect01.height));

      currByQ[q] = items.map((e) => e.task.id).take(3).toList();
    }

    // Compute symmetric difference
    int delta = 0;
    for (final q in Quadrant.values) {
      final prev = prevByQ[q]!.toSet();
      final curr = currByQ[q]!.toSet();
      final symmetric = {
        ...prev.difference(curr),
        ...curr.difference(prev),
      };
      delta += symmetric.length;
    }

    if (delta > 0) {
      Telemetry.top3ReorderDelta(delta);
    }
  }
}
