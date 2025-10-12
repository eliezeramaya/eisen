import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'entities.dart';

class TreemapRect {
  final Rect rect01; // normalized [0..1]
  final Task task;
  TreemapRect(this.rect01, this.task);
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
  _Item({required this.area});
}

