import 'package:flutter/material.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:eisen/features/eisen_matrix/domain/bandit_service.dart';
import 'package:eisen/core/services/telemetry.dart';
import 'package:eisen/core/constants/layout_constants.dart';

/// Use case for computing the treemap layout with incremental updates.
///
/// Features:
/// - Memoization: Reuses previous layout if inputs haven't changed
/// - Incremental: Only recomputes dirty quadrants when possible
/// - Viewport-aware: Calculates minimum tile area based on screen size
/// - Stable: Uses EMA smoothing and bandit tie-breaking
class ComputeLayoutUseCase {
  final LayoutCache _cache;
  final BanditService _bandit;
  
  // Memoization state
  int _lastHash = 0;
  List<TreemapRect> _lastLayout = const [];
  Set<Quadrant> _dirtyQuadrants = {};
  Quadrant? _lastZoom;
  Size? _lastViewport;

  ComputeLayoutUseCase({
    required LayoutCache cache,
    required BanditService bandit,
  })  : _cache = cache,
        _bandit = bandit;

  /// Computes the treemap layout for given [tasks].
  ///
  /// Parameters:
  /// - [tasks]: Tasks to layout
  /// - [zoom]: If set, layout only this quadrant in full [0..1] rect
  /// - [viewport]: Screen size for calculating minimum tile area
  /// - [only]: Mark only this quadrant as dirty and recompute it
  ///
  /// Returns cached layout if inputs haven't changed.
  List<TreemapRect> execute({
    required List<Task> tasks,
    Quadrant? zoom,
    Size? viewport,
    Quadrant? only,
    bool compactDensity = false,
  }) {
    // DEBUG: surface runtime info to logs to help diagnose empty-layout issues
    if (kDebugMode) {
      try {
        debugPrint('ComputeLayoutUseCase.execute: tasks=${tasks.length} zoom=${zoom?.name} viewport=${viewport?.width}x${viewport?.height}');
      } catch (_) {}
    }
    // Compute hash to detect changes
    int hash = Object.hashAllUnordered(tasks.map((t) => t.id)) ^ 
               tasks.length ^ 
               (zoom?.index ?? -1);
    
    // Calculate minimum area from viewport
    double? minArea01;
    if (viewport != null && viewport.width > 0 && viewport.height > 0) {
      // Adjust minimum interactive tile area depending on density mode
      final baseMinPx = LayoutConstants.minTileAreaPx; // centralized constant
      final densityFactor = compactDensity ? 0.7 : 1.0; // smaller threshold in compact mode
      final minPx = baseMinPx * densityFactor;
      final totalPx = viewport.width * viewport.height;
      minArea01 = (minPx / totalPx).clamp(0.0, 1.0);
      hash ^= viewport.width.round();
      hash ^= (viewport.height.round() << 16);
    }

    final viewportChanged = _lastViewport == null || 
                           viewport == null || 
                           _lastViewport != viewport;
    final zoomChanged = _lastZoom != zoom;

    // Add explicit quadrant to dirty set if requested
    if (only != null) {
      _dirtyQuadrants.add(only);
    }

    // Return cached if nothing changed
    if (_dirtyQuadrants.isEmpty && 
        !zoomChanged && 
        !viewportChanged && 
        _lastHash == hash) {
      return _lastLayout;
    }

    // Full recompute for zoomed view
    if (zoom != null) {
      return _computeZoomedLayout(tasks, zoom, minArea01, hash, viewport);
    }

    // Full recompute if many quadrants dirty or major state change
    if (_lastLayout.isEmpty || 
        viewportChanged || 
        zoomChanged || 
        _dirtyQuadrants.length >= 4) {
      return _computeFullLayout(tasks, minArea01, hash, viewport);
    }

    // Incremental update: recompute only dirty quadrants
    return _computeIncrementalLayout(tasks, minArea01, hash, viewport);
  }

  List<TreemapRect> _computeZoomedLayout(
    List<Task> tasks,
    Quadrant zoom,
    double? minArea01,
    int hash,
    Size? viewport,
  ) {
    const rect = Rect.fromLTWH(0, 0, 1, 1);
    final tasksInQ = tasks.where((t) => t.quadrant == zoom).toList();
    
    final sw = Stopwatch()..start();
    final layout = layoutQuadrantStable(
      tasksInQ,
      rect,
      _cache,
      _bandit,
      zoom,
      minTileArea01: minArea01,
    );
    if (kDebugMode) {
      try {
        debugPrint('ComputeLayoutUseCase._computeZoomedLayout: quadrant=${zoom.name} tasksInQ=${tasksInQ.length} minArea01=$minArea01 layout=${layout.length}');
      } catch (_) {}
    }
    sw.stop();
    
    Telemetry.layoutTime(zoom.name, sw.elapsedMicroseconds / 1000.0);
    
    _lastLayout = layout;
    _lastHash = hash;
    _lastZoom = zoom;
    _lastViewport = viewport;
    _dirtyQuadrants.clear();
    
    return layout;
  }

  List<TreemapRect> _computeFullLayout(
    List<Task> tasks,
    double? minArea01,
    int hash,
    Size? viewport,
  ) {
    final sw = Stopwatch()..start();
    final layout = computeStableLayout(
      tasks,
      zoom: null,
      cache: _cache,
      bandit: _bandit,
      minTileArea01: minArea01,
    );
    if (kDebugMode) {
      try {
        debugPrint('ComputeLayoutUseCase._computeFullLayout: tasks=${tasks.length} minArea01=$minArea01 layout=${layout.length}');
      } catch (_) {}
    }
    sw.stop();
    
    Telemetry.layoutTime(null, sw.elapsedMicroseconds / 1000.0);
    
    _lastLayout = layout;
    _lastHash = hash;
    _lastZoom = null;
    _lastViewport = viewport;
    _dirtyQuadrants.clear();
    
    return layout;
  }

  List<TreemapRect> _computeIncrementalLayout(
    List<Task> tasks,
    double? minArea01,
    int hash,
    Size? viewport,
  ) {
    // Keep tiles from clean quadrants
    final keepQuadrants = {
      Quadrant.q1,
      Quadrant.q2,
      Quadrant.q3,
      Quadrant.q4,
    }..removeAll(_dirtyQuadrants);

    final prevByQ = <Quadrant, List<TreemapRect>>{
      for (final q in Quadrant.values) q: []
    };
    for (final tr in _lastLayout) {
      prevByQ[tr.task.quadrant]!.add(tr);
    }

    final qRects = <Quadrant, Rect>{
      Quadrant.q1: const Rect.fromLTWH(0, 0, 0.5, 0.5),
      Quadrant.q2: const Rect.fromLTWH(0.5, 0, 0.5, 0.5),
      Quadrant.q3: const Rect.fromLTWH(0, 0.5, 0.5, 0.5),
      Quadrant.q4: const Rect.fromLTWH(0.5, 0.5, 0.5, 0.5),
    };

    final tasksByQ = <Quadrant, List<Task>>{
      for (final q in Quadrant.values) q: []
    };
    for (final t in tasks) {
      tasksByQ[t.quadrant]!.add(t);
    }

    final merged = <TreemapRect>[];
    final existingIds = tasks.map((t) => t.id).toSet();

    // Keep clean quadrants
    for (final q in keepQuadrants) {
      final kept = prevByQ[q]!
          .where((tr) => existingIds.contains(tr.task.id))
          .toList();
      merged.addAll(kept);
    }

    // Recompute dirty quadrants
    for (final q in _dirtyQuadrants) {
      final sw = Stopwatch()..start();
      final part = layoutQuadrantStable(
        tasksByQ[q]!,
        qRects[q]!,
        _cache,
        _bandit,
        q,
        minTileArea01: minArea01,
      );
      sw.stop();
      
      Telemetry.layoutTime(q.name, sw.elapsedMicroseconds / 1000.0);
      merged.addAll(part);
    }

    _lastLayout = merged;
    _lastHash = hash;
    _lastZoom = null;
    _lastViewport = viewport;
    _dirtyQuadrants.clear();

    return merged;
  }

  /// Mark a quadrant (or all if null) as dirty for recomputation.
  void invalidate([Quadrant? q]) {
    if (q == null) {
      _dirtyQuadrants = {Quadrant.q1, Quadrant.q2, Quadrant.q3, Quadrant.q4};
    } else {
      _dirtyQuadrants.add(q);
    }
  }

  /// Mark specific quadrants as dirty (called after task mutations).
  void markDirty(Set<Quadrant> quadrants) {
    _dirtyQuadrants.addAll(quadrants);
  }
}
