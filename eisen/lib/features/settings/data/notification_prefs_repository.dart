import 'dart:convert';

import 'package:eisen/features/settings/domain/notification_prefs.dart';
import 'package:eisen/features/settings/domain/notification_tone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class NotificationPrefsRepository {
  Future<NotificationPrefs> load();
  Future<void> save(NotificationPrefs prefs);
}

class NotificationPrefsLocalRepository implements NotificationPrefsRepository {
  static const _key = 'settings.notifications.v1';

  @override
  Future<NotificationPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      // Defaults
      return NotificationPrefs(
        notificationsEnabled: true,
        dailyReminderEnabled: false,
        dailyReminderTime: null,
        quietHoursEnabled: false,
        quietStart: null,
        quietEnd: null,
        nudgesEnabled: true,
        endOfDaySummary: false,
        endOfDayTime: null,
        notificationTone: NotificationTone.defaultTone,
        pomodoroAlert: 'sound',
      );
    }
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, Object?>) {
        return NotificationPrefs.fromJson(map);
      }
    } catch (_) {
      // Ignore malformed payloads and fallback to defaults.
    }
    return NotificationPrefs(
      notificationsEnabled: true,
      dailyReminderEnabled: false,
      dailyReminderTime: null,
      quietHoursEnabled: false,
      quietStart: null,
      quietEnd: null,
      nudgesEnabled: true,
      endOfDaySummary: false,
      endOfDayTime: null,
      notificationTone: NotificationTone.defaultTone,
      pomodoroAlert: 'sound',
    );
  }

  @override
  Future<void> save(NotificationPrefs prefs) async {
    final prefsStore = await SharedPreferences.getInstance();
    await prefsStore.setString(_key, jsonEncode(prefs.toJson()));
  }
}

final notificationPrefsRepositoryProvider =
    Provider<NotificationPrefsRepository>(
        (ref) => NotificationPrefsLocalRepository());
