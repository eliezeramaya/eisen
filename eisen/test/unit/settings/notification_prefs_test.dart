import 'dart:convert';

import 'package:eisen/features/settings/data/notification_prefs_repository.dart';
import 'package:eisen/features/settings/domain/notification_prefs.dart';
import 'package:eisen/features/settings/domain/notification_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationPrefsLocalRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns defaults when empty', () async {
      final repo = NotificationPrefsLocalRepository();
      final prefs = await repo.load();

      expect(prefs.notificationsEnabled, isTrue);
      expect(prefs.dailyReminderEnabled, isFalse);
      expect(prefs.nudgesEnabled, isTrue);
      expect(prefs.pomodoroAlert, 'sound');
    });

    test('save then load preserves values', () async {
      final repo = NotificationPrefsLocalRepository();
      final original = NotificationPrefs(
        notificationsEnabled: false,
        dailyReminderEnabled: true,
        dailyReminderTime: const TimeOfDay(hour: 8, minute: 30),
        quietHoursEnabled: true,
        quietStart: const TimeOfDay(hour: 22, minute: 0),
        quietEnd: const TimeOfDay(hour: 7, minute: 0),
        nudgesEnabled: false,
        endOfDaySummary: true,
        endOfDayTime: const TimeOfDay(hour: 21, minute: 15),
        notificationTone: NotificationTone.bellShort,
        pomodoroAlert: 'visual',
      );

      await repo.save(original);
      final loaded = await repo.load();

      expect(loaded.notificationsEnabled, isFalse);
      expect(loaded.dailyReminderEnabled, isTrue);
      expect(loaded.dailyReminderTime?.hour, 8);
      expect(loaded.quietHoursEnabled, isTrue);
      expect(loaded.quietStart?.hour, 22);
      expect(loaded.notificationTone.id, 'bell_short');
      expect(loaded.pomodoroAlert, 'visual');
    });

    test('tolerates corrupt payload and falls back to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'settings.notifications.v1': '{not-json',
      });
      final repo = NotificationPrefsLocalRepository();
      final prefs = await repo.load();

      expect(prefs.notificationsEnabled, isTrue);
      expect(prefs.nudgesEnabled, isTrue);
    });

    test('missing new fields uses defaults (pomodoroAlert)', () async {
      final legacy = {
        'notificationsEnabled': true,
        'dailyReminderEnabled': false,
        'nudgesEnabled': true,
      };
      SharedPreferences.setMockInitialValues(
        {'settings.notifications.v1': jsonEncode(legacy)},
      );
      final repo = NotificationPrefsLocalRepository();
      final prefs = await repo.load();
      expect(prefs.pomodoroAlert, 'sound');
    });
  });
}
