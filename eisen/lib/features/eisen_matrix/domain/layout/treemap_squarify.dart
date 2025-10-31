import 'dart:math' as math;
import 'dart:ui';

/// Simple squarify shelf algorithm.
/// Accepts absolute weights and a container [Rect] in normalized [0..1] units.
/// Returns a list of rects whose areas are proportional to [weights].
List<Rect> squarify(List<double> weights, Rect container) {
  if (weights.isEmpty || container.width <= 0 || container.height <= 0) {
    return const [];
  }
  final sum = weights.fold<double>(0, (a, b) => a + math.max(0.0001, b));
  if (sum <= 0) return const [];
  final areas = [
    for (final w in weights)
      (math.max(0.0001, w) / sum) * container.width * container.height
  ];

  final items = areas
      .asMap()
      .entries
      .map((e) => _Item(index: e.key, area: e.value))
      .toList()
    ..sort((a, b) => b.area.compareTo(a.area));

  var cur = container;
  final result = List<Rect>.filled(items.length, Rect.zero, growable: false);
  var row = <_Item>[];

  double worst(List<_Item> row, double shortSide) {
    final s = row.fold<double>(0, (a, e) => a + e.area);
    final maxA = row.fold<double>(0, (a, e) => math.max(a, e.area));
    final minA =
        row.fold<double>(double.infinity, (a, e) => math.min(a, e.area));
    if (s == 0 || minA == 0) return double.infinity;
    final s2 = s * s;
    final short2 = shortSide * shortSide;
    return math.max((short2 * maxA) / s2, s2 / (short2 * minA));
  }

  void layoutRow(List<_Item> row, Rect rect) {
    if (row.isEmpty) return;
    final sumA = row.fold<double>(0, (a, e) => a + e.area);
    final horizontal = rect.width >= rect.height;
    if (horizontal) {
      final h = sumA / rect.width;
      var x = rect.left;
      for (final it in row) {
        final w = it.area / h;
        final r = Rect.fromLTWH(x, rect.top, w, h);
        result[it.index] = _snap(r);
        x += w;
      }
      cur = Rect.fromLTWH(
          rect.left, rect.top + h, rect.width, math.max(0, rect.height - h));
    } else {
      final w = sumA / rect.height;
      var y = rect.top;
      for (final it in row) {
        final h = it.area / w;
        final r = Rect.fromLTWH(rect.left, y, w, h);
        result[it.index] = _snap(r);
        y += h;
      }
      cur = Rect.fromLTWH(
          rect.left + w, rect.top, math.max(0, rect.width - w), rect.height);
    }
  }

  for (final it in items) {
    if (row.isEmpty) {
      row = [it];
      continue;
    }
    final shortSide = math.min(cur.width, cur.height);
    final candidate = [...row, it];
    if (worst(candidate, shortSide) <= worst(row, shortSide)) {
      row.add(it);
    } else {
      layoutRow(row, cur);
      row = [it];
    }
  }
  layoutRow(row, cur);
  return result;
}

Rect _snap(Rect r) =>
    r; // Keep normalized precision; painter handles pixel snapping

class _Item {
  _Item({required this.index, required this.area});
  final int index;
  final double area;
}
