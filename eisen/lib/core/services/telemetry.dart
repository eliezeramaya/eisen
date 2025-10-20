import 'dart:developer' as dev;
import 'metrics.dart';

/// Minimal telemetry sink. In production, replace with analytics backend.
class Telemetry {
  static void tileTap(String taskId) => dev.log('tile_tap', name: 'telemetry', error: taskId);
  static void tileDragStart(String taskId) => dev.log('tile_drag_start', name: 'telemetry', error: taskId);
  static void tileDrop(String fromId, String toQuadrant) => dev.log('tile_drop', name: 'telemetry', error: '$fromId->$toQuadrant');
  static void zoomQuadrant(String q) => dev.log('zoom_quadrant', name: 'telemetry', error: q);
  static void stackOpen(String q, int count) => dev.log('stack_open', name: 'telemetry', error: '$q +$count');
  static void suggestedExpose(Iterable<String> ids) {
    Metrics.instance.topSpotExposures += ids.length;
    dev.log('bandit_suggest_expose', name: 'telemetry', error: ids.join(','));
  }
  static void topSpotClick(String taskId) {
    Metrics.instance.topSpotClicks += 1;
    dev.log('bandit_topspot_click', name: 'telemetry', error: taskId);
  }
  static void layoutTime(String? quadrant, double ms) {
    Metrics.instance.recordLayoutMs(quadrant, ms);
    dev.log('layout_time', name: 'telemetry', error: '${quadrant ?? "all"}: ${ms.toStringAsFixed(2)}ms');
  }
  static void top3ReorderDelta(int delta) {
    Metrics.instance.top3ReorderChanges += delta;
    dev.log('top3_reorder', name: 'telemetry', error: '$delta');
  }
  static void taskDone(String taskId, {required bool isQ2}) {
    if (isQ2) Metrics.instance.q2Done += 1;
    dev.log('task_done', name: 'telemetry', error: taskId);
  }
  static void taskSnooze(String taskId, Duration duration) {
    if (duration.inHours < 2) Metrics.instance.shortSnoozes += 1;
    dev.log('task_snooze', name: 'telemetry', error: '${taskId}:${duration.inMinutes}m');
  }
}
