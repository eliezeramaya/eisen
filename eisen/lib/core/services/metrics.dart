import 'dart:math' as math;

/// Simple in-memory metrics aggregator for the current app session.
class Metrics {
  Metrics._();
  static final instance = Metrics._();

  final _layoutTimes = <String, List<double>>{}; // key: quadrant name or 'all'
  int top3ReorderChanges = 0;
  int topSpotExposures = 0;
  int topSpotClicks = 0;
  int q2Done = 0;
  int shortSnoozes = 0;

  void recordLayoutMs(String? quadrant, double ms) {
    final k = quadrant ?? 'all';
    final list = _layoutTimes.putIfAbsent(k, () => <double>[]);
    list.add(ms);
    // keep tail small
    if (list.length > 200) list.removeRange(0, list.length - 200);
  }

  double p50LayoutMs(String key) {
    final list = _layoutTimes[key];
    if (list == null || list.isEmpty) return 0;
    final sorted = [...list]..sort();
    return sorted[(sorted.length * 0.5).floor()];
  }

  Map<String, Object> snapshot() {
    final keys = _layoutTimes.keys.toList();
    final p50 = {for (final k in keys) 'p50_${k}': p50LayoutMs(k)};
    return {
      'top3ReorderChanges': top3ReorderChanges,
      'topSpotExposures': topSpotExposures,
      'topSpotClicks': topSpotClicks,
      'q2Done': q2Done,
      'shortSnoozes': shortSnoozes,
      ...p50,
    };
  }
}

