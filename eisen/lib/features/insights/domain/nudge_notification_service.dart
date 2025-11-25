import 'package:eisen/core/notifications/notifications_service.dart';
import 'package:eisen/features/insights/domain/nudge.dart';
import 'package:eisen/features/settings/domain/notification_prefs.dart';
import 'package:flutter/material.dart';

/// Service for sending nudge notifications intelligently.
///
/// Features:
/// - Respects notification preferences (enabled, quiet hours)
/// - Sends immediate or delayed notifications
/// - Maps nudge severity to notification priority
/// - Handles notification content formatting
class NudgeNotificationService {
  /// Send a nudge notification immediately if conditions are met
  static Future<void> sendNudge({
    required Nudge nudge,
    required NotificationPrefs prefs,
  }) async {
    // Respetar preferencias globales y de nudges
    if (!prefs.notificationsEnabled || !prefs.nudgesEnabled) {
      return;
    }

    // No enviar durante horas silenciosas
    if (_isInQuietHours(prefs)) {
      return;
    }

    // Generate notification ID from nudge type
    final notificationId = _getNudgeNotificationId(nudge.type);

    // Format title and body
    final title = _formatTitle(nudge);
    final body = _formatBody(nudge);

    // Send notification
    await NotificationsService.showNudge(
      id: notificationId,
      title: title,
      body: body,
      payload: nudge.type.name, // payload estable para deep-links
    );
  }

  /// Schedule a nudge notification for later
  static Future<void> scheduleNudge({
    required Nudge nudge,
    required NotificationPrefs prefs,
    required Duration delay,
  }) async {
    // Check if notifications are enabled
    if (!prefs.notificationsEnabled || !prefs.nudgesEnabled) {
      return;
    }

    // Generate notification ID from nudge type
    final notificationId = _getNudgeNotificationId(nudge.type);

    // Format title and body
    final title = _formatTitle(nudge);
    final body = _formatBody(nudge);

    // Schedule notification
    await NotificationsService.scheduleNudge(
      id: notificationId,
      delay: delay,
      title: title,
      body: body,
      payload: nudge.type.name,
    );
  }

  /// Send multiple nudges as a batch (max 3 per session)
  static Future<void> sendBatchNudges({
    required List<Nudge> nudges,
    required NotificationPrefs prefs,
  }) async {
    // Check if notifications are enabled
    if (!prefs.notificationsEnabled || !prefs.nudgesEnabled) {
      return;
    }

    // Check quiet hours
    if (_isInQuietHours(prefs)) {
      return;
    }

    // Limit to top 3 nudges by severity
    final topNudges = _prioritizeNudges(nudges).take(3).toList();

    // Send with delays to avoid spamming (UX: pocos pero importantes)
    for (int i = 0; i < topNudges.length; i++) {
      final nudge = topNudges[i];
      final delay = Duration(seconds: i * 5); // 5 seconds between notifications

      if (i == 0) {
        // Send first one immediately
        await sendNudge(nudge: nudge, prefs: prefs);
      } else {
        // Schedule rest with delays
        await scheduleNudge(nudge: nudge, prefs: prefs, delay: delay);
      }
    }
  }

  /// Cancel all pending nudge notifications
  static Future<void> cancelAllNudges() async {
    await NotificationsService.cancelAllNudges();
  }

  // Helper methods

  static bool _isInQuietHours(NotificationPrefs prefs) {
    if (!prefs.quietHoursEnabled ||
        prefs.quietStart == null ||
        prefs.quietEnd == null) {
      return false;
    }

    final now = TimeOfDay.now();
    final start = prefs.quietStart!;
    final end = prefs.quietEnd!;

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    // Handle overnight quiet hours (e.g., 22:00 - 08:00)
    if (startMinutes > endMinutes) {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }

    // Normal quiet hours (e.g., 14:00 - 16:00)
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  static int _getNudgeNotificationId(NudgeType type) {
    // Use range 2000-2099 for nudge notifications
    switch (type) {
      case NudgeType.lowQ2:
        return 2001;
      case NudgeType.excessiveReschedules:
        return 2002;
      case NudgeType.overload:
        return 2003;
      case NudgeType.procrastination:
        return 2004;
      case NudgeType.quadrantImbalance:
        return 2005;
      case NudgeType.noProject:
        return 2006;
      case NudgeType.dailyOverload:
        return 2007;
      case NudgeType.noFocusSessions:
        return 2008;
      case NudgeType.lateNightWork:
        return 2009;
    }
  }

  static String _formatTitle(Nudge nudge) {
    switch (nudge.severity) {
      case NudgeSeverity.high:
        return '🚨 ${_getTitleByType(nudge.type)}';
      case NudgeSeverity.mediumHigh:
        return '⚠️ ${_getTitleByType(nudge.type)}';
      case NudgeSeverity.medium:
        return '💡 ${_getTitleByType(nudge.type)}';
      case NudgeSeverity.low:
        return '✨ ${_getTitleByType(nudge.type)}';
    }
  }

  static String _getTitleByType(NudgeType type) {
    switch (type) {
      case NudgeType.lowQ2:
        return 'Poco Tiempo en Q2';
      case NudgeType.excessiveReschedules:
        return 'Muchas Tareas Retrasadas';
      case NudgeType.overload:
        return 'Sobrecarga de Urgencias';
      case NudgeType.procrastination:
        return 'Tareas Estancadas';
      case NudgeType.quadrantImbalance:
        return 'Desbalance de Cuadrantes';
      case NudgeType.noProject:
        return 'Organización Pendiente';
      case NudgeType.dailyOverload:
        return 'Demasiadas Urgencias Hoy';
      case NudgeType.noFocusSessions:
        return 'Sin Sesiones de Foco';
      case NudgeType.lateNightWork:
        return 'Trabajo Nocturno';
    }
  }

  static String _formatBody(Nudge nudge) {
    // Use the nudge message directly
    return nudge.message;
  }

  static List<Nudge> _prioritizeNudges(List<Nudge> nudges) {
    // Sort by severity (high first) and then by metadata values
    final sorted = List<Nudge>.from(nudges);
    sorted.sort((a, b) {
      // Compare severity
      final severityCompare =
          _severityValue(b.severity).compareTo(_severityValue(a.severity));
      if (severityCompare != 0) return severityCompare;

      // If same severity, prioritize by metadata values
      final aValue =
          a.metadata.values.whereType<num>().fold(0.0, (a, b) => a + b);
      final bValue =
          b.metadata.values.whereType<num>().fold(0.0, (a, b) => a + b);
      return bValue.compareTo(aValue);
    });
    return sorted;
  }

  static int _severityValue(NudgeSeverity severity) {
    switch (severity) {
      case NudgeSeverity.high:
        return 4;
      case NudgeSeverity.mediumHigh:
        return 3;
      case NudgeSeverity.medium:
        return 2;
      case NudgeSeverity.low:
        return 1;
    }
  }
}
