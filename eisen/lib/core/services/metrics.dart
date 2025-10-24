/// Simple in-memory metrics aggregator for the current app session.
/// 
/// Tracks layout performance, user interactions, and web vitals (LCP).
class Metrics {
  Metrics._();
  static final instance = Metrics._();

  final _layoutTimes = <String, List<double>>{}; // key: quadrant name or 'all'
  int top3ReorderChanges = 0;
  int topSpotExposures = 0;
  int topSpotClicks = 0;
  int q2Done = 0;
  int shortSnoozes = 0;
  
  /// Largest Contentful Paint (LCP) in milliseconds (web only).
  /// 
  /// Measured via Performance API on web platform. Null if not yet recorded
  /// or not running on web. See web/index.html for measurement script.
  double? lcpMs;

  void recordLayoutMs(String? quadrant, double ms) {
    final k = quadrant ?? 'all';
    final list = _layoutTimes.putIfAbsent(k, () => <double>[]);
    list.add(ms);
    // keep tail small
    if (list.length > 200) list.removeRange(0, list.length - 200);
  }
  
  /// Record Largest Contentful Paint metric (typically called from web).
  void recordLCP(double ms) {
    lcpMs = ms;
  }

  double p50LayoutMs(String key) {
    final list = _layoutTimes[key];
    if (list == null || list.isEmpty) return 0;
    final sorted = [...list]..sort();
    return sorted[(sorted.length * 0.5).floor()];
  }

  Map<String, Object> snapshot() {
    final keys = _layoutTimes.keys.toList();
    final p50 = {for (final k in keys) 'p50_$k': p50LayoutMs(k)};
    return {
      'top3ReorderChanges': top3ReorderChanges,
      'topSpotExposures': topSpotExposures,
      'topSpotClicks': topSpotClicks,
      'q2Done': q2Done,
      'shortSnoozes': shortSnoozes,
      if (lcpMs != null) 'lcpMs': lcpMs!,
      ...p50,
    };
  }
}

