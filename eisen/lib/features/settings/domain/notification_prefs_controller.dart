import 'dart:async';

import 'package:eisen/core/notifications/notifications_service.dart';
import 'package:eisen/features/settings/data/notification_prefs_repository.dart';
import 'package:eisen/features/settings/domain/notification_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPrefsController
    extends AsyncNotifier<NotificationPrefs> {
  late final NotificationPrefsRepository _repo;

  @override
  FutureOr<NotificationPrefs> build() async {
    _repo = ref.read(notificationPrefsRepositoryProvider);
    final prefs = await _repo.load();
    return prefs;
  }

  Future<void> _save(NotificationPrefs prefs) async {
    state = AsyncData(prefs);
    await _repo.save(prefs);
    await _applyToSystem(prefs);
  }

  Future<void> toggleNotifications(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(notificationsEnabled: value));
  }

  Future<void> toggleDailyReminder(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(dailyReminderEnabled: value));
  }

  Future<void> setDailyReminderTime(TimeOfDay? time) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(dailyReminderTime: time));
  }

  Future<void> toggleQuietHours(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(quietHoursEnabled: value));
  }

  Future<void> setQuietHours(TimeOfDay start, TimeOfDay end) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(quietStart: start, quietEnd: end));
  }

  Future<void> toggleNudges(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(nudgesEnabled: value));
  }

  Future<void> toggleEndOfDaySummary(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(endOfDaySummary: value));
  }

  Future<void> setEndOfDayTime(TimeOfDay? time) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(endOfDayTime: time));
  }

  Future<void> setNotificationTone(String tone) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(notificationTone: tone));
  }

  Future<void> setPomodoroAlert(String mode) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(pomodoroAlert: mode));
  }

  Future<void> _applyToSystem(NotificationPrefs prefs) async {
    // Hook for local notifications; best-effort in debug to avoid platform noise.
    if (prefs.dailyReminderEnabled &&
        prefs.dailyReminderTime != null &&
        prefs.notificationsEnabled) {
      final t = prefs.dailyReminderTime!;
      await NotificationsService.scheduleDaily(
        id: 1001,
        time:
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        title: 'Enfócate hoy',
        body: 'Planifica tu día y protege tu bloque de foco.',
      );
    } else {
      await NotificationsService.cancel(1001);
    }

    if (prefs.endOfDaySummary &&
        prefs.endOfDayTime != null &&
        prefs.notificationsEnabled) {
      final t = prefs.endOfDayTime!;
      await NotificationsService.scheduleDaily(
        id: 1002,
        time:
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        title: 'Resumen del día',
        body: 'Revisa pendientes y celebra avances.',
      );
    } else {
      await NotificationsService.cancel(1002);
    }
  }
}

final notificationPrefsControllerProvider = AsyncNotifierProvider<
    NotificationPrefsController, NotificationPrefs>(NotificationPrefsController.new);
