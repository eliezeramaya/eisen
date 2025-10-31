import 'package:eisen/core/services/telemetry.dart';
import 'package:eisen/features/eisen_matrix/domain/bandit_service.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';

/// Use case for computing suggested "top spots" using bandit algorithm.
///
/// For each quadrant, finds the largest tiles (within 95% of max area)
/// and uses bandit tie-breaking to select the top candidate.
class SuggestTopSpotsUseCase {
  SuggestTopSpotsUseCase(this._bandit);
  final BanditService _bandit;

  /// Computes suggested task IDs from the given [layout].
  ///
  /// Returns a set of task IDs (one per quadrant max) that should be
  /// highlighted as "top spots" for user attention.
  Set<String> execute(List<TreemapRect> layout) {
    final byQ = <Quadrant, List<TreemapRect>>{
      for (final q in Quadrant.values) q: []
    };

    for (final tr in layout) {
      if (tr.stackChildren.isNotEmpty) continue; // Skip stacked tiles
      byQ[tr.task.quadrant]!.add(tr);
    }

    final suggested = <String>{};

    for (final q in Quadrant.values) {
      final list = byQ[q]!;
      if (list.isEmpty) continue;

      // Find max area
      final areas = list.map((e) => e.rect01.width * e.rect01.height).toList();
      final maxA = areas.reduce((a, b) => a > b ? a : b);

      // Candidates: tiles within 95% of max area
      final candidates = <Task>[];
      for (var i = 0; i < list.length; i++) {
        if (areas[i] >= maxA * 0.95) {
          candidates.add(list[i].task);
        }
      }

      if (candidates.isEmpty) continue;

      // Use bandit to pick winner among candidates
      final top = _bandit.pickTopSpot(candidates, q);
      if (top != null) {
        suggested.add(top);
      }
    }

    if (suggested.isNotEmpty) {
      Telemetry.suggestedExpose(suggested);
    }

    return suggested;
  }
}
