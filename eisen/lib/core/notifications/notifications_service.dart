import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static Future<void> Function(String payload)? _onNudgeSelected;

  static void setOnNudgeSelected(
      Future<void> Function(String payload)? handler) {
    _onNudgeSelected = handler;
  }

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (resp) async {
        final payload = resp.payload;
        if (payload != null) {
          await _onNudgeSelected?.call(payload);
        }
      },
    );
    _initialized = true;
  }

  static Future<void> scheduleDaily({
    required int id,
    required String time, // Changed from Time to String for web compatibility
    required String title,
    required String body,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '[NotificationsService] scheduleDaily (debug only): id=$id time=$time title=$title');
        return;
      }
      await init();
      const details = NotificationDetails(
        android: AndroidNotificationDetails('daily', 'Daily',
            importance: Importance.defaultImportance),
        iOS: DarwinNotificationDetails(),
      );
      // Fallback in dev: show a one-off notification instead of exact daily schedule
      await _plugin.periodicallyShow(
          id, title, body, RepeatInterval.daily, details,
          androidAllowWhileIdle: true);
    } catch (e) {
      debugPrint('NotificationsService.scheduleDaily skipped: $e');
    }
  }

  static Future<void> cancel(int id) async {
    try {
      if (kDebugMode) {
        debugPrint('[NotificationsService] cancel (debug only): id=$id');
        return;
      }
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('NotificationsService.cancel skipped: $e');
    }
  }

  /// Show an immediate notification
  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '[NotificationsService] show (debug only): id=$id title=$title');
        return;
      }
      await init();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'focus',
          'Focus Sessions',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('NotificationsService.show skipped: $e');
    }
  }

  /// Show a nudge notification with specific channel and priority
  static Future<void> showNudge({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '[NotificationsService] showNudge (debug only): id=$id title=$title');
        return;
      }
      await init();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'nudges',
          'Nudges Inteligentes',
          channelDescription: 'Sugerencias personalizadas de productividad',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('NotificationsService.showNudge skipped: $e');
    }
  }

  /// Schedule a nudge notification after a specific duration
  static Future<void> scheduleNudge({
    required int id,
    required Duration delay,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '[NotificationsService] scheduleNudge (debug only): id=$id delay=$delay title=$title');
        return;
      }
      await init();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'nudges',
          'Nudges Inteligentes',
          channelDescription: 'Sugerencias personalizadas de productividad',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Use simple delayed notification
      await Future.delayed(delay, () async {
        await _plugin.show(id, title, body, details, payload: payload);
      });
    } catch (e) {
      debugPrint('NotificationsService.scheduleNudge skipped: $e');
    }
  }

  /// Cancel all nudge notifications (IDs 2000-2999)
  static Future<void> cancelAllNudges() async {
    try {
      if (kDebugMode) {
        debugPrint('[NotificationsService] cancelAllNudges (debug only)');
        return;
      }
      for (int id = 2000; id < 3000; id++) {
        await _plugin.cancel(id);
      }
    } catch (e) {
      debugPrint('NotificationsService.cancelAllNudges skipped: $e');
    }
  }
}
