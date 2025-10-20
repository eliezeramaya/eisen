import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';

/// Use case for deleting a task and cleaning up its layout cache.
///
/// Removes task data from layout cache to prevent memory leaks.
class DeleteTaskUseCase {
  /// Removes cached layout data for the given task [id].
  ///
  /// Cleans up:
  /// - Cached weights
  /// - Cached rectangles
  /// - Cached ranks
  void cleanupCache(String id, LayoutCache cache) {
    cache.lastWeight.remove(id);
    cache.lastRect.remove(id);
    cache.lastRank.remove(id);
  }
}
