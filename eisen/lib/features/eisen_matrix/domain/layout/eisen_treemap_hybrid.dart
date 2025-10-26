import 'dart:math' as math;
import 'dart:ui';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/layout_config.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/treemap_squarify.dart';
import 'package:eisen/features/eisen_matrix/domain/weight.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart' show TreemapRect;

class EisenTreemapHybrid {
  final LayoutConfig cfg;
  const EisenTreemapHybrid(this.cfg);

  /// Returns TreemapRects across all quadrants. If [only] is provided, lays out
  /// only that quadrant in the full [0..1] area.
  List<TreemapRect> layout(List<Task> tasks, {Quadrant? only, double? minArea01}) {
    final out = <TreemapRect>[];

    final byQ = <Quadrant, List<Task>>{for (final q in Quadrant.values) q: []};
    for (final t in tasks) {
      byQ[t.quadrant]!.add(t);
    }

    final quadBoxes = <Quadrant, Rect>{
      Quadrant.q1: const Rect.fromLTWH(0, 0, 0.5, 0.5),
      Quadrant.q2: const Rect.fromLTWH(0.5, 0, 0.5, 0.5),
      Quadrant.q3: const Rect.fromLTWH(0, 0.5, 0.5, 0.5),
      Quadrant.q4: const Rect.fromLTWH(0.5, 0.5, 0.5, 0.5),
    };
    if (only != null) {
      quadBoxes[only] = const Rect.fromLTWH(0, 0, 1, 1);
      for (final q in Quadrant.values) {
        if (q != only) quadBoxes[q] = Rect.zero;
      }
    }

    for (final q in Quadrant.values) {
      final qb = quadBoxes[q]!;
      if (qb == Rect.zero) continue;

      final list = byQ[q]!;
      if (list.isEmpty) continue;

      final pad = cfg.quadrantPadding;
      final padded = Rect.fromLTWH(
        qb.left + pad,
        qb.top + pad,
        math.max(0, qb.width - 2 * pad),
        math.max(0, qb.height - 2 * pad),
      );

      // Compute weights (smoothed)
      final weights = list
          .map((t) => _smooth(importanceWeight(t), cfg.gamma))
          .toList(growable: false);
      final idx = List.generate(list.length, (i) => i)..sort((a, b) => weights[b].compareTo(weights[a]));

      final k = math.min(cfg.topKPerQuadrant, idx.length);
      final topIdx = idx.sublist(0, k);
      final restIdx = idx.length > k ? idx.sublist(k) : <int>[];

      // Prepare squarify weights (include cluster as sumRest if any)
      final topWeights = [for (final i in topIdx) weights[i]];
      final sumTop = topWeights.fold<double>(0, (a, b) => a + b);
      final sumRest = restIdx.fold<double>(0, (a, i) => a + weights[i]);
      final sequence = [...topWeights];
      final hasCluster = sumRest > 0.0 && restIdx.isNotEmpty;
      if (hasCluster) sequence.add(sumRest);

      final rects = squarify(sequence, padded);
      assert(() {
        // ignore: avoid_print
        print('[hybrid] q=${q.name} list=${list.length} top=${topIdx.length} rest=${restIdx.length} seq=${sequence.length} rects=${rects.length}');
        return true;
      }());
      final outMin = minArea01 ?? cfg.minAreaNormalized;

      for (var i = 0; i < topIdx.length && i < rects.length; i++) {
        final r = rects[i];
        if (r.width * r.height < outMin) continue;
        out.add(TreemapRect(r, list[topIdx[i]]));
      }

      if (hasCluster && rects.length == sequence.length) {
        final r = rects.last;
        if (r.width * r.height >= outMin) {
          final stack = [for (final i in restIdx) list[i]];
          // Synthetic tile: use first of rest as representative (visual only)
          final rep = list[restIdx.first];
          out.add(TreemapRect(r, rep, stackChildren: stack));
        }
      }
    }

    return out;
  }

  double _smooth(double w, double gamma) {
    final x = w <= 0 ? 0.0001 : w;
    if (gamma == 1.0) return x;
    return math.pow(x, gamma).toDouble();
  }
}
