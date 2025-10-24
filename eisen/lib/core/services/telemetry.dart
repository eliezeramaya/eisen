import 'dart:convert';
import 'dart:developer' as dev;
import 'package:crypto/crypto.dart';
import 'metrics.dart';

/// Privacy-focused telemetry sink with consent management and ID anonymization.
///
/// Features:
/// - Opt-in consent required (check enabled status before logging)
/// - Task IDs are hashed with salt for anonymization
/// - No PII (personally identifiable information) is collected
/// - Users can opt-out via settings at any time
///
/// In production:
/// - Replace dev.log with actual analytics backend (Firebase, PostHog, etc.)
/// - Store consent in shared_preferences
/// - Implement consent banner on first launch
class Telemetry {
  static String? _salt;
  static bool _enabled = false; // Default: disabled until user consents

  /// Check if telemetry is enabled (user has consented).
  static bool get enabled => _enabled;

  /// Enable or disable telemetry (should be persisted to storage).
  static void setEnabled(bool value) {
    _enabled = value;
    dev.log('telemetry_${value ? "enabled" : "disabled"}', name: 'telemetry');
  }

  /// Initialize salt for ID hashing. Call once on app start.
  /// In production, load from secure storage or generate and persist.
  static void initSalt(String salt) {
    _salt = salt;
  }

  /// Anonymize a task ID by hashing with salt.
  /// Returns hashed string that cannot be reversed to original ID.
  static String _anonymizeId(String taskId) {
    if (_salt == null) return 'hash_no_salt';
    final bytes = utf8.encode('$_salt:$taskId');
    final digest = sha256.convert(bytes);
    // Return first 12 chars of hash (sufficient for uniqueness, compact for logs)
    return digest.toString().substring(0, 12);
  }

  /// Check if telemetry is enabled before logging.
  static bool get _canLog => _enabled;
  static void tileTap(String taskId) {
    if (!_canLog) return;
    dev.log('tile_tap', name: 'telemetry', error: _anonymizeId(taskId));
  }

  static void tileDragStart(String taskId) {
    if (!_canLog) return;
    dev.log('tile_drag_start', name: 'telemetry', error: _anonymizeId(taskId));
  }

  static void tileDrop(String fromId, String toQuadrant) {
    if (!_canLog) return;
    dev.log('tile_drop', name: 'telemetry',
        error: '${_anonymizeId(fromId)}->$toQuadrant');
  }

  static void zoomQuadrant(String q) {
    if (!_canLog) return;
    dev.log('zoom_quadrant', name: 'telemetry', error: q);
  }

  static void stackOpen(String q, int count) {
    if (!_canLog) return;
    dev.log('stack_open', name: 'telemetry', error: '$q +$count');
  }

  static void suggestedExpose(Iterable<String> ids) {
    if (!_canLog) return;
    Metrics.instance.topSpotExposures += ids.length;
    final anonymized = ids.map(_anonymizeId).join(',');
    dev.log('bandit_suggest_expose', name: 'telemetry', error: anonymized);
  }

  static void topSpotClick(String taskId) {
    if (!_canLog) return;
    Metrics.instance.topSpotClicks += 1;
    dev.log('bandit_topspot_click', name: 'telemetry', error: _anonymizeId(taskId));
  }

  static void layoutTime(String? quadrant, double ms) {
    // Always record metrics locally (no privacy concern - no IDs)
    Metrics.instance.recordLayoutMs(quadrant, ms);
    if (!_canLog) return;
    dev.log('layout_time', name: 'telemetry', error: '${quadrant ?? "all"}: ${ms.toStringAsFixed(2)}ms');
  }

  static void top3ReorderDelta(int delta) {
    // Always record metrics locally
    Metrics.instance.top3ReorderChanges += delta;
    if (!_canLog) return;
    dev.log('top3_reorder', name: 'telemetry', error: '$delta');
  }

  static void taskDone(String taskId, {required bool isQ2}) {
    // Always record metrics locally
    if (isQ2) Metrics.instance.q2Done += 1;
    if (!_canLog) return;
    dev.log('task_done', name: 'telemetry', error: _anonymizeId(taskId));
  }

  static void taskSnooze(String taskId, Duration duration) {
    // Always record metrics locally
    if (duration.inHours < 2) Metrics.instance.shortSnoozes += 1;
    if (!_canLog) return;
    dev.log('task_snooze', name: 'telemetry', error: '${_anonymizeId(taskId)}:${duration.inMinutes}m');
  }
}
