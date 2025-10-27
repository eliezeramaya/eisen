import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
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
        debugPrint('[NotificationsService] scheduleDaily (debug only): id=$id time=$time title=$title');
        return;
      }
      await init();
      const details = NotificationDetails(
        android: AndroidNotificationDetails('daily', 'Daily', importance: Importance.defaultImportance),
        iOS: DarwinNotificationDetails(),
      );
      // Fallback in dev: show a one-off notification instead of exact daily schedule
      await _plugin.periodicallyShow(id, title, body, RepeatInterval.daily, details,
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
}
