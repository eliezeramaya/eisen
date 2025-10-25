import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/bandit_service.dart';

/// A tile in the computed treemap layout.
///
/// - [rect01]: Normalized rectangle in [0..1] range (relative to quadrant or full canvas)
/// - [task]: The task represented by this tile
/// - [stackChildren]: Tasks grouped into this tile if below minimum area threshold
class TreemapRect {
  final Rect rect01; // normalized [0..1]
  final Task task;
  final List<Task> stackChildren;
  TreemapRect(this.rect01, this.task, {this.stackChildren = const []});
  bool get isStack => stackChildren.isNotEmpty;
}

// --- Debug flags and checks ---

/// Toggle debug overlays / asserts when developing treemap issues.
/// Set to `false` by default for test and production runs. Enable when
/// actively debugging layout correctness to exercise internal asserts.
const bool debugTreemap = bool.fromEnvironment('EISEN_DEBUG_TREEMAP', defaultValue: false);

void _checkFinite(String where, double v) {
  assert(v.isFinite, 'Non-finite at $where: $v');
  assert(!v.isNaN, 'NaN at $where');
}

void _checkRect(String where, Rect r) {
  assert(r.width > 0 && r.height > 0, 'Invalid rect at $where: $r');
}

void _checkAreaSum(String where, List<Rect> rects, Rect quad) {
  final sum = rects.fold<double>(0, (a, r) => a + r.width * r.height);
  final total = quad.width * quad.height;
  assert((sum - total).abs() / total < 0.01, 'Area drift at $where: sum=$sum total=$total');
}

/// Global EMA alpha for weight smoothing. Adjust to tune hysteresis.
const double kTreemapEmaAlpha = 0.5;

double ema(double prev, double cur, {double? alpha}) {
  final a = alpha ?? kTreemapEmaAlpha;
  return a * cur + (1 - a) * prev;
}

double minTileAreaPx(double devicePixelRatio) => 44.0 * 44.0;

// Normalize/quantize rects to half-pixel grid to avoid hairline gaps
Rect _snapToPixel(Rect r) {
  double snap(double v) => (v * 2.0).roundToDouble() / 2.0; // 0.5 steps
  final l = snap(r.left);
  final t = snap(r.top);
  final rgt = snap(r.right);
  final b = snap(r.bottom);
  return Rect.fromLTWH(l, t, math.max(0.0, rgt - l), math.max(0.0, b - t));
}

/// Persistent cache for stable treemap layouts.
///
/// Stores previous weights, rects, and ranks to apply EMA smoothing
/// and minimize layout churn between frames.
class LayoutCache {
  final lastWeight = <String, double>{};
  final lastRect = <String, Rect>{};
  final lastRank = <String, int>{};
}

/// Computes a basic squarified treemap layout for tasks.
///
/// If [zoom] is provided, only tasks from that quadrant are laid out in [0..1] rect.
/// Otherwise, each quadrant gets a 0.5 × 0.5 subregion and tasks are distributed.
///
/// This is the original non-stable layout without EMA or bandit tie-breaking.
List<TreemapRect> computeSquarifiedLayout(List<Task> tasks, {Quadrant? zoom}) {
  final byQuadrant = <Quadrant, List<Task>>{
    Quadrant.q1: [],
    Quadrant.q2: [],
    Quadrant.q3: [],
    Quadrant.q4: [],
  };
  for (final t in tasks) {
    byQuadrant[t.quadrant]!.add(t);
  }

  final full = const Rect.fromLTWH(0, 0, 1, 1);

  if (zoom != null) {
    final out = _layoutIntoRect(byQuadrant[zoom]!, full);
    if (debugTreemap) {
      _checkAreaSum('computeSquarifiedLayout(zoom)', out.map((e) => e.rect01).toList(), full);
      for (final r in out) {
        _checkRect('computeSquarifiedLayout(zoom)', r.rect01);
      }
    }
    return out;
  }

  final qRects = <Quadrant, Rect>{
    Quadrant.q1: const Rect.fromLTWH(0, 0, 0.5, 0.5),
    Quadrant.q2: const Rect.fromLTWH(0.5, 0, 0.5, 0.5),
    Quadrant.q3: const Rect.fromLTWH(0, 0.5, 0.5, 0.5),
    Quadrant.q4: const Rect.fromLTWH(0.5, 0.5, 0.5, 0.5),
  };

  final out = <TreemapRect>[];
  for (final q in Quadrant.values) {
    final part = _layoutIntoRect(byQuadrant[q]!, qRects[q]!);
    if (debugTreemap) {
      _checkAreaSum('computeSquarifiedLayout($q)', part.map((e) => e.rect01).toList(), qRects[q]!);
      for (final r in part) {
        _checkRect('computeSquarifiedLayout($q)', r.rect01);
      }
    }
    out.addAll(part);
  }
  return out;
}

List<TreemapRect> _layoutIntoRect(List<Task> tasks, Rect rect) {
  if (tasks.isEmpty) return const [];
  // Defensive: clamp weights to finite positive range
  var values = tasks.map((t) {
    final w = weight(t);
    if (!w.isFinite || w <= 0) return 1.0; // fallback
    return w.clamp(0.0001, 1e9);
  }).toList();
  var sum = values.fold<double>(0, (a, b) => a + b);
  if (sum <= 0) {
    values = List.filled(tasks.length, 1.0);
    sum = values.length.toDouble();
  }

  final areas = values.map((v) => (v / sum) * rect.width * rect.height).toList();
  // sort by descending area keeping items paired
  final items = <(_Item, Task)>[];
  for (var i = 0; i < areas.length; i++) {
    items.add((_Item(area: areas[i]), tasks[i]));
  }
  items.sort((a, b) => b.$1.area.compareTo(a.$1.area));

  var cur = rect;
  final result = <TreemapRect>[];
  var row = <(_Item, Task)>[];

  // worst aspect ratio metric using short-side of the candidate shelf
  double worst(List<_Item> row, double shortSide) {
    final s = row.fold<double>(0, (a, e) => a + e.area);
    final maxA = row.fold<double>(0, (a, e) => math.max(a, e.area));
    final minA = row.fold<double>(double.infinity, (a, e) => math.min(a, e.area));
    if (s == 0 || minA == 0) return double.infinity;
    final s2 = s * s;
    final short2 = shortSide * shortSide;
    return math.max((short2 * maxA) / s2, s2 / (short2 * minA));
  }

  void layoutRow(List<(_Item, Task)> row, Rect rect) {
    if (row.isEmpty) return;
    final sumA = row.fold<double>(0, (a, e) => a + e.$1.area);
    // Use short-side shelf logic: decide orientation based on rect short side
    final shortSide = math.min(rect.width, rect.height);
    var horizontal = rect.width >= rect.height; // default
    // prefer laying out along the long side but measure worst using short side
    final worstRatio = worst(row.map((e) => e.$1).toList(), shortSide);
    if (worstRatio > 20.0) horizontal = !horizontal;
    if (horizontal) {
      // horizontal shelves: height determined by sumA / width
      final h = sumA / rect.width;
      var x = rect.left;
      for (final it in row) {
        final w = it.$1.area / h;
        final r = Rect.fromLTWH(x, rect.top, w, h);
        result.add(TreemapRect(_snapToPixel(r), it.$2));
        x += w;
      }
      cur = Rect.fromLTWH(rect.left, rect.top + h, rect.width, math.max(0, rect.height - h));
    } else {
      final w = sumA / rect.height;
      var y = rect.top;
      for (final it in row) {
        final h = it.$1.area / w;
        final r = Rect.fromLTWH(rect.left, y, w, h);
        result.add(TreemapRect(_snapToPixel(r), it.$2));
        y += h;
      }
      cur = Rect.fromLTWH(rect.left + w, rect.top, math.max(0, rect.width - w), rect.height);
    }
  }

  for (final it in items) {
    if (row.isEmpty) {
      row = [it];
      continue;
    }
    final shortSide = math.min(cur.width, cur.height);
    final candidate = [...row.map((e) => e.$1), it.$1];
    if (worst(candidate, shortSide) <= worst(row.map((e) => e.$1).toList(), shortSide)) {
      row.add(it);
    } else {
      layoutRow(row, cur);
      row = [it];
    }
  }
  layoutRow(row, cur);

  // Normalize minor floating rounding to keep within rect and snap to pixel grid
  return result
      .map((e) {
        final clamped = Rect.fromLTWH(
          (e.rect01.left).clamp(rect.left, rect.right),
          (e.rect01.top).clamp(rect.top, rect.bottom),
          math.min(e.rect01.width, rect.right - e.rect01.left),
          math.min(e.rect01.height, rect.bottom - e.rect01.top),
        );
        return TreemapRect(_snapToPixel(clamped), e.task);
      })
      .toList();
}

class _Item {
  final double area;
  final List<Task> stackChildren;
  _Item({required this.area, this.stackChildren = const []});
  bool get isStack => stackChildren.isNotEmpty;
}

// ---- Stable layout with smoothing, root-scale, and bandit tie-breaker ----

/// Computes a visually stable squarified treemap with smoothing and stacking.
///
/// Features:
/// - EMA smoothing of weights using [cache] to reduce layout churn
/// - Root-scale area basis (sqrt) for perceptual stability
/// - Stable ordering with bandit-based tie-break when areas ≈ within 5%
/// - [minTileArea01]: Tiles below this area are stacked into a single '+N' tile
///
/// If [zoom] is set, only that quadrant is laid out in the full [0..1] rect.
/// Otherwise all four quadrants are laid out in their respective 0.5 × 0.5 subregions.
List<TreemapRect> computeStableLayout(
  List<Task> tasks, {
  Quadrant? zoom,
  LayoutCache? cache,
  BanditService? bandit,
  double? minTileArea01,
}) {
  final byQuadrant = <Quadrant, List<Task>>{
    Quadrant.q1: [],
    Quadrant.q2: [],
    Quadrant.q3: [],
    Quadrant.q4: [],
  };
  for (final t in tasks) {
    byQuadrant[t.quadrant]!.add(t);
  }

  final full = const Rect.fromLTWH(0, 0, 1, 1);
  if (zoom != null) {
    final out = _layoutStableIntoRect(byQuadrant[zoom]!, full, cache, bandit, zoom, minTileArea01: minTileArea01);
    if (debugTreemap) {
      _checkAreaSum('computeStableLayout(zoom)', out.map((e) => e.rect01).toList(), full);
      for (final r in out) {
        _checkRect('computeStableLayout(zoom)', r.rect01);
      }
    }
    return out;
  }

  final qRects = <Quadrant, Rect>{
    Quadrant.q1: const Rect.fromLTWH(0, 0, 0.5, 0.5),
    Quadrant.q2: const Rect.fromLTWH(0.5, 0, 0.5, 0.5),
    Quadrant.q3: const Rect.fromLTWH(0, 0.5, 0.5, 0.5),
    Quadrant.q4: const Rect.fromLTWH(0.5, 0.5, 0.5, 0.5),
  };

  final out = <TreemapRect>[];
  for (final q in Quadrant.values) {
    final part = _layoutStableIntoRect(byQuadrant[q]!, qRects[q]!, cache, bandit, q, minTileArea01: minTileArea01);
    if (debugTreemap) {
      _checkAreaSum('computeStableLayout($q)', part.map((e) => e.rect01).toList(), qRects[q]!);
      for (final r in part) {
        _checkRect('computeStableLayout($q)', r.rect01);
      }
    }
    out.addAll(part);
  }
  return out;
}

/// Lays out a single quadrant with stable layout logic.
///
/// Used internally by [computeStableLayout]. Can be called directly to lay out
/// a specific quadrant's tasks into a given normalized [rect].
List<TreemapRect> layoutQuadrantStable(
  List<Task> tasks,
  Rect rect,
  LayoutCache? cache,
  BanditService? bandit,
  Quadrant quadrant, {
  double? minTileArea01,
}) => _layoutStableIntoRect(tasks, rect, cache, bandit, quadrant, minTileArea01: minTileArea01);

/// Computes a penalty cost for reordering stability.
///
/// [tau]: Hyperparameter controlling penalty sensitivity (default 0.02).
/// Returns tau × |newRank - prevRank|.
double reorderPenalty(int prevRank, int newRank, {double tau = 0.02}) => tau * (newRank - prevRank).abs();

List<TreemapRect> _layoutStableIntoRect(
  List<Task> tasks,
  Rect rect,
  LayoutCache? cache,
  BanditService? bandit,
  Quadrant quadrant,
  {double? minTileArea01}
) {
  if (tasks.isEmpty) return const [];

  // Smoothed, root-scaled areas
  final values = <double>[];
  for (final t in tasks) {
    final w = weight(t);
    _checkFinite('weight(${t.id})', w);
    final prev = cache?.lastWeight[t.id] ?? w;
    final smooth = ema(prev, w);
    cache?.lastWeight[t.id] = smooth;
    // clamp and root-scale
    final v = math.sqrt(math.max(0.0, smooth.clamp(0.0001, 1e12)));
    values.add(v);
  }

  var sum = values.fold<double>(0, (a, b) => a + b);
  if (sum <= 0) {
    for (var i = 0; i < values.length; i++) {
      values[i] = 1.0;
    }
    sum = values.length.toDouble();
  }
  final rawAreas = values.map((v) => (v / sum) * rect.width * rect.height).toList(growable: false);

  // Minimum-area stacking: group all items below threshold into a single stack tile
  final keep = <int>[];
  final small = <int>[];
  if (minTileArea01 != null && minTileArea01 > 0) {
    for (var i = 0; i < rawAreas.length; i++) {
      // rawAreas are already normalized to the full [0..1] canvas (include rect size).
      // Compare directly against minTileArea01 (minPx / totalPx). If the tile's normalized
      // area is below that threshold, it would render under 44x44 px on the given viewport.
      if (rawAreas[i] < minTileArea01) {
        small.add(i);
      } else {
        keep.add(i);
      }
    }
    if (kDebugMode) {
      try {
        debugPrint('layoutQuadrant[$quadrant]: tasks=${tasks.length} minArea01=$minTileArea01 keep=${keep.length} small=${small.length}');
      } catch (_) {}
    }
  } else {
    for (var i = 0; i < rawAreas.length; i++) {
      keep.add(i);
    }
  }

  // Build sortable list with stable ordering and tie-breaks
  final tuples = <(_Item, Task)>[];
  for (final i in keep) {
    tuples.add((_Item(area: rawAreas[i]), tasks[i]));
  }
  if (small.isNotEmpty) {
    final sumSmall = small.fold<double>(0, (a, i) => a + rawAreas[i]);
    final children = [for (final i in small) tasks[i]];
    final stackTask = Task(
      id: 'stack_${quadrant.name}',
      title: '+${children.length}',
      quadrant: quadrant,
      priority: 1,
      minutes: 5,
      category: '__stack__',
    );
    tuples.add((_Item(area: sumSmall, stackChildren: children), stackTask));
  }

  // Previous ranks to minimize reorder churn
  final prevRanks = cache?.lastRank ?? const <String, int>{};

  tuples.sort((a, b) {
    final da = b.$1.area.compareTo(a.$1.area);
    if (da != 0) {
      final aa = a.$1.area;
      final bb = b.$1.area;
      final nearEqual = (aa > 0 && ( (aa - bb).abs() / aa ) <= 0.05);
      if (!nearEqual) return da; // regular area sort
    }
    // Tie-break using previous rank (keep stability), then id
    final pra = prevRanks[a.$2.id] ?? 1 << 20;
    final prb = prevRanks[b.$2.id] ?? 1 << 20;
    final dp = pra.compareTo(prb);
    if (dp != 0) return dp;
    return a.$2.id.compareTo(b.$2.id);
  });

  // Proceed with squarified layout using same row-building logic
  var cur = rect;
  final result = <TreemapRect>[];
  var row = <(_Item, Task)>[];

  double worst(List<_Item> row, double shortSide) {
    final s = row.fold<double>(0, (a, e) => a + e.area);
    final maxA = row.fold<double>(0, (a, e) => math.max(a, e.area));
    final minA = row.fold<double>(double.infinity, (a, e) => math.min(a, e.area));
    if (s == 0 || minA == 0) return double.infinity;
    final s2 = s * s;
    final short2 = shortSide * shortSide;
    return math.max((short2 * maxA) / s2, s2 / (short2 * minA));
  }

  void layoutRow(List<(_Item, Task)> row, Rect rect) {
    if (row.isEmpty) return;
    final sumA = row.fold<double>(0, (a, e) => a + e.$1.area);
    final shortSide = math.min(rect.width, rect.height);
    var horizontal = rect.width >= rect.height;
    final worstRatio = worst(row.map((e) => e.$1).toList(), shortSide);
    if (worstRatio > 20.0) horizontal = !horizontal;
    if (horizontal) {
      final h = sumA / rect.width;
      var x = rect.left;
      for (final it in row) {
        final w = it.$1.area / h;
        final r = Rect.fromLTWH(x, rect.top, w, h);
        result.add(TreemapRect(_snapToPixel(r), it.$2, stackChildren: it.$1.stackChildren));
        cache?.lastRect[it.$2.id] = r;
        x += w;
      }
      cur = Rect.fromLTWH(rect.left, rect.top + h, rect.width, math.max(0, rect.height - h));
    } else {
      final w = sumA / rect.height;
      var y = rect.top;
      for (final it in row) {
        final h = it.$1.area / w;
        final r = Rect.fromLTWH(rect.left, y, w, h);
        result.add(TreemapRect(_snapToPixel(r), it.$2, stackChildren: it.$1.stackChildren));
        cache?.lastRect[it.$2.id] = r;
        y += h;
      }
      cur = Rect.fromLTWH(rect.left + w, rect.top, math.max(0, rect.width - w), rect.height);
    }
  }

  for (final it in tuples) {
    if (row.isEmpty) {
      row = [it];
      continue;
    }
    final w = math.min(cur.width, cur.height);
    final candidate = [...row.map((e) => e.$1), it.$1];
    if (worst(candidate, w) <= worst(row.map((e) => e.$1).toList(), w)) {
      row.add(it);
    } else {
      layoutRow(row, cur);
      row = [it];
    }
  }
  layoutRow(row, cur);

  // Clamp to rect bounds and snap
  final clamped = result
      .map((e) {
        final r = Rect.fromLTWH(
          (e.rect01.left).clamp(rect.left, rect.right),
          (e.rect01.top).clamp(rect.top, rect.bottom),
          math.min(e.rect01.width, rect.right - e.rect01.left),
          math.min(e.rect01.height, rect.bottom - e.rect01.top),
        );
        return TreemapRect(_snapToPixel(r), e.task, stackChildren: e.stackChildren);
      })
      .toList();

  // Update last ranks for stability on next passes
  if (cache != null) {
    for (var i = 0; i < tuples.length; i++) {
      cache.lastRank[tuples[i].$2.id] = i;
    }
  }
  if (debugTreemap) {
    _checkAreaSum('_layoutStableIntoRect($quadrant)', clamped.map((e) => e.rect01).toList(), rect);
    for (final r in clamped) {
      _checkRect('_layoutStableIntoRect($quadrant)', r.rect01);
    }
  }
  return clamped;
}
