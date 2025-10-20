import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/bandit_service.dart';

class TreemapRect {
  final Rect rect01; // normalized [0..1]
  final Task task;
  final List<Task> stackChildren;
  TreemapRect(this.rect01, this.task, {this.stackChildren = const []});
  bool get isStack => stackChildren.isNotEmpty;
}

double ema(double prev, double cur, {double alpha = 0.5}) => alpha * cur + (1 - alpha) * prev;

double minTileAreaPx(double devicePixelRatio) => 44.0 * 44.0;

class LayoutCache {
  final lastWeight = <String, double>{};
  final lastRect = <String, Rect>{};
  final lastRank = <String, int>{};
}

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
    return _layoutIntoRect(byQuadrant[zoom]!, full);
  }

  final qRects = <Quadrant, Rect>{
    Quadrant.q1: const Rect.fromLTWH(0, 0, 0.5, 0.5),
    Quadrant.q2: const Rect.fromLTWH(0.5, 0, 0.5, 0.5),
    Quadrant.q3: const Rect.fromLTWH(0, 0.5, 0.5, 0.5),
    Quadrant.q4: const Rect.fromLTWH(0.5, 0.5, 0.5, 0.5),
  };

  final out = <TreemapRect>[];
  for (final q in Quadrant.values) {
    out.addAll(_layoutIntoRect(byQuadrant[q]!, qRects[q]!));
  }
  return out;
}

List<TreemapRect> _layoutIntoRect(List<Task> tasks, Rect rect) {
  if (tasks.isEmpty) return const [];
  final values = tasks.map((t) => weight(t)).toList();
  final sum = values.fold<double>(0, (a, b) => a + (b.isFinite ? b : 0));
  if (sum <= 0) return tasks.map((t) => TreemapRect(rect, t)).toList();

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

  double worst(List<_Item> row, double w) {
    final s = row.fold<double>(0, (a, e) => a + e.area);
    final maxA = row.fold<double>(0, (a, e) => math.max(a, e.area));
    final minA = row.fold<double>(double.infinity, (a, e) => math.min(a, e.area));
    if (s == 0 || minA == 0) return double.infinity;
    final w2 = w * w;
    final s2 = s * s;
    return math.max((w2 * maxA) / s2, s2 / (w2 * minA));
  }

  void layoutRow(List<(_Item, Task)> row, Rect rect) {
    if (row.isEmpty) return;
    final sumA = row.fold<double>(0, (a, e) => a + e.$1.area);
    final horizontal = rect.width >= rect.height;
    if (horizontal) {
      final h = sumA / rect.width;
      var x = rect.left;
      for (final it in row) {
        final w = it.$1.area / h;
        final r = Rect.fromLTWH(x, rect.top, w, h);
        result.add(TreemapRect(r, it.$2));
        x += w;
      }
      cur = Rect.fromLTWH(rect.left, rect.top + h, rect.width, math.max(0, rect.height - h));
    } else {
      final w = sumA / rect.height;
      var y = rect.top;
      for (final it in row) {
        final h = it.$1.area / w;
        final r = Rect.fromLTWH(rect.left, y, w, h);
        result.add(TreemapRect(r, it.$2));
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

  // Normalize minor floating rounding to keep within rect
  final dx = rect.left;
  final dy = rect.top;
  return result
      .map((e) {
        final r = Rect.fromLTWH(
          (e.rect01.left).clamp(rect.left, rect.right),
          (e.rect01.top).clamp(rect.top, rect.bottom),
          math.min(e.rect01.width, rect.right - e.rect01.left),
          math.min(e.rect01.height, rect.bottom - e.rect01.top),
        );
        return TreemapRect(r, e.task);
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

/// Computes a visually stable squarified treemap.
/// - EMA smoothing of weights using [cache] if available
/// - Root-scale area basis (sqrt) for perceptual stability
/// - Stable ordering; applies bandit-based tie-break when areas ≈ within 5%
///
/// Note: Does not enforce minimum tile area; that decision is handled at
/// paint/hit-test time where actual pixels are known.
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
    return _layoutStableIntoRect(byQuadrant[zoom]!, full, cache, bandit, zoom, minTileArea01: minTileArea01);
  }

  final qRects = <Quadrant, Rect>{
    Quadrant.q1: const Rect.fromLTWH(0, 0, 0.5, 0.5),
    Quadrant.q2: const Rect.fromLTWH(0.5, 0, 0.5, 0.5),
    Quadrant.q3: const Rect.fromLTWH(0, 0.5, 0.5, 0.5),
    Quadrant.q4: const Rect.fromLTWH(0.5, 0.5, 0.5, 0.5),
  };

  final out = <TreemapRect>[];
  for (final q in Quadrant.values) {
    out.addAll(_layoutStableIntoRect(byQuadrant[q]!, qRects[q]!, cache, bandit, q, minTileArea01: minTileArea01));
  }
  return out;
}

List<TreemapRect> layoutQuadrantStable(
  List<Task> tasks,
  Rect rect,
  LayoutCache? cache,
  BanditService? bandit,
  Quadrant quadrant, {
  double? minTileArea01,
}) => _layoutStableIntoRect(tasks, rect, cache, bandit, quadrant, minTileArea01: minTileArea01);

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
  final ids = tasks.map((t) => t.id).toList(growable: false);
  final values = <double>[];
  for (final t in tasks) {
    final w = weight(t);
    final prev = cache?.lastWeight[t.id] ?? w;
    final smooth = ema(prev, w, alpha: 0.5);
    cache?.lastWeight[t.id] = smooth;
    values.add(math.sqrt(math.max(0.0, smooth)));
  }

  final sum = values.fold<double>(0, (a, b) => a + b);
  if (sum <= 0) return tasks.map((t) => TreemapRect(rect, t)).toList();
  final rawAreas = values.map((v) => (v / sum) * rect.width * rect.height).toList(growable: false);

  // Minimum-area stacking: group all items below threshold into a single stack tile
  final keep = <int>[];
  final small = <int>[];
  if (minTileArea01 != null && minTileArea01 > 0) {
    for (var i = 0; i < rawAreas.length; i++) {
      if (rawAreas[i] < minTileArea01) {
        small.add(i);
      } else {
        keep.add(i);
      }
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

  // Bandit tie ranks for near-equal areas
  final tieRanks = bandit?.tieBreakRanks(tasks, quadrant) ?? const <String, int>{};
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
    // Tie-break using previous rank (keep stability), then bandit rank, then id
    final pra = prevRanks[a.$2.id] ?? 1 << 20;
    final prb = prevRanks[b.$2.id] ?? 1 << 20;
    final dp = pra.compareTo(prb);
    if (dp != 0) return dp;

    // Bandit rank (lower better)
    final ra = tieRanks[a.$2.id] ?? 1 << 20;
    final rb = tieRanks[b.$2.id] ?? 1 << 20;
    final dr = ra.compareTo(rb);
    if (dr != 0) return dr;
    return a.$2.id.compareTo(b.$2.id);
  });

  // Proceed with squarified layout using same row-building logic
  var cur = rect;
  final result = <TreemapRect>[];
  var row = <(_Item, Task)>[];

  double worst(List<_Item> row, double w) {
    final s = row.fold<double>(0, (a, e) => a + e.area);
    final maxA = row.fold<double>(0, (a, e) => math.max(a, e.area));
    final minA = row.fold<double>(double.infinity, (a, e) => math.min(a, e.area));
    if (s == 0 || minA == 0) return double.infinity;
    final w2 = w * w;
    final s2 = s * s;
    return math.max((w2 * maxA) / s2, s2 / (w2 * minA));
  }

  void layoutRow(List<(_Item, Task)> row, Rect rect) {
    if (row.isEmpty) return;
    final sumA = row.fold<double>(0, (a, e) => a + e.$1.area);
    final horizontal = rect.width >= rect.height;
    if (horizontal) {
      final h = sumA / rect.width;
      var x = rect.left;
      for (final it in row) {
        final w = it.$1.area / h;
        final r = Rect.fromLTWH(x, rect.top, w, h);
        result.add(TreemapRect(r, it.$2, stackChildren: it.$1.stackChildren));
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
        result.add(TreemapRect(r, it.$2, stackChildren: it.$1.stackChildren));
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

  // Clamp to rect bounds
  final clamped = result
      .map((e) {
        final r = Rect.fromLTWH(
          (e.rect01.left).clamp(rect.left, rect.right),
          (e.rect01.top).clamp(rect.top, rect.bottom),
          math.min(e.rect01.width, rect.right - e.rect01.left),
          math.min(e.rect01.height, rect.bottom - e.rect01.top),
        );
        return TreemapRect(r, e.task);
      })
      .toList();

  // Update last ranks for stability on next passes
  if (cache != null) {
    for (var i = 0; i < tuples.length; i++) {
      cache.lastRank[tuples[i].$2.id] = i;
    }
  }
  return clamped;
}
