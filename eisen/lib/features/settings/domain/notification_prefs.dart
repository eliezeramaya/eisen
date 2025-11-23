import 'package:flutter/material.dart';

import 'notification_tone.dart';

class NotificationPrefs {
  const NotificationPrefs({
    required this.notificationsEnabled,
    required this.dailyReminderEnabled,
    this.dailyReminderTime,
    required this.quietHoursEnabled,
    this.quietStart,
    this.quietEnd,
    required this.nudgesEnabled,
    required this.endOfDaySummary,
    this.endOfDayTime,
    this.notificationTone = NotificationTone.defaultTone,
    this.pomodoroAlert = 'sound',
  });

  final bool notificationsEnabled;
  final bool dailyReminderEnabled;
  final TimeOfDay? dailyReminderTime;
  final bool quietHoursEnabled;
  final TimeOfDay? quietStart;
  final TimeOfDay? quietEnd;
  final bool nudgesEnabled;
  final bool endOfDaySummary;
  final TimeOfDay? endOfDayTime;
  final NotificationTone notificationTone;
  final String pomodoroAlert;

  NotificationPrefs copyWith({
    bool? notificationsEnabled,
    bool? dailyReminderEnabled,
    TimeOfDay? dailyReminderTime,
    bool? quietHoursEnabled,
    TimeOfDay? quietStart,
    TimeOfDay? quietEnd,
    bool? nudgesEnabled,
    bool? endOfDaySummary,
    TimeOfDay? endOfDayTime,
    NotificationTone? notificationTone,
    String? pomodoroAlert,
  }) {
    return NotificationPrefs(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStart: quietStart ?? this.quietStart,
      quietEnd: quietEnd ?? this.quietEnd,
      nudgesEnabled: nudgesEnabled ?? this.nudgesEnabled,
      endOfDaySummary: endOfDaySummary ?? this.endOfDaySummary,
      endOfDayTime: endOfDayTime ?? this.endOfDayTime,
      notificationTone: notificationTone ?? this.notificationTone,
      pomodoroAlert: pomodoroAlert ?? this.pomodoroAlert,
    );
  }

  Map<String, Object?> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'dailyReminderEnabled': dailyReminderEnabled,
        'dailyReminderTime': _encodeTime(dailyReminderTime),
        'quietHoursEnabled': quietHoursEnabled,
        'quietStart': _encodeTime(quietStart),
        'quietEnd': _encodeTime(quietEnd),
        'nudgesEnabled': nudgesEnabled,
        'endOfDaySummary': endOfDaySummary,
        'endOfDayTime': _encodeTime(endOfDayTime),
        'notificationTone': notificationTone.id,
        'pomodoroAlert': pomodoroAlert,
      };

  static NotificationPrefs fromJson(Map<String, Object?> json) {
    return NotificationPrefs(
      notificationsEnabled: (json['notificationsEnabled'] as bool?) ?? true,
      dailyReminderEnabled: (json['dailyReminderEnabled'] as bool?) ?? false,
      dailyReminderTime: _decodeTime(json['dailyReminderTime'] as String?),
      quietHoursEnabled: (json['quietHoursEnabled'] as bool?) ?? false,
      quietStart: _decodeTime(json['quietStart'] as String?),
      quietEnd: _decodeTime(json['quietEnd'] as String?),
      nudgesEnabled: (json['nudgesEnabled'] as bool?) ?? true,
      endOfDaySummary: (json['endOfDaySummary'] as bool?) ?? false,
      endOfDayTime: _decodeTime(json['endOfDayTime'] as String?),
      notificationTone: NotificationToneX.fromId(
          (json['notificationTone'] as String?) ?? 'default'),
      pomodoroAlert: (json['pomodoroAlert'] as String?) ?? 'sound',
    );
  }

  static String? _encodeTime(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay? _decodeTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }
}
