import 'dart:math' as math;

/// Projects DateTime values to horizontal pixel positions in the Gantt view.
class TimelineProjector {
  const TimelineProjector({required this.viewStart, required this.pxPerDay});
  final DateTime viewStart;
  final double pxPerDay;

  /// Converts a DateTime to an x coordinate (pixels) relative to [viewStart].
  double dx(DateTime t) {
    final msPerDay = 86400000.0; // 24*60*60*1000
    final dtMs = t.millisecondsSinceEpoch - viewStart.millisecondsSinceEpoch;
    final days = dtMs / msPerDay;
    return days * pxPerDay;
  }

  /// Returns the DateTime represented at a given x coordinate.
  DateTime timeAt(double x) {
    final msPerDay = 86400000.0;
    final days = x / pxPerDay;
    final ms = (days * msPerDay).round();
    return DateTime.fromMillisecondsSinceEpoch(
        viewStart.millisecondsSinceEpoch + ms);
  }

  /// Width in pixels between two instants [a] and [b].
  double widthBetween(DateTime a, DateTime b) {
    final left = math.min(dx(a), dx(b));
    final right = math.max(dx(a), dx(b));
    return right - left;
  }
}
