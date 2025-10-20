import 'dart:developer' as dev;

/// Minimal telemetry sink. In production, replace with analytics backend.
class Telemetry {
  static void tileTap(String taskId) => dev.log('tile_tap', name: 'telemetry', error: taskId);
  static void tileDragStart(String taskId) => dev.log('tile_drag_start', name: 'telemetry', error: taskId);
  static void tileDrop(String fromId, String toQuadrant) => dev.log('tile_drop', name: 'telemetry', error: '$fromId->$toQuadrant');
  static void zoomQuadrant(String q) => dev.log('zoom_quadrant', name: 'telemetry', error: q);
  static void stackOpen(String q, int count) => dev.log('stack_open', name: 'telemetry', error: '$q +$count');
}

