import 'dart:async';

import 'package:eisen/core/haptics/haptics_service.dart';
import 'package:eisen/core/notifications/notifications_service.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/focus/data/focus_repository.dart';
import 'package:eisen/features/focus/data/focus_repository_stub.dart';
import 'package:eisen/features/focus/domain/focus_session.dart';
import 'package:eisen/features/focus/domain/focus_state.dart';
import 'package:eisen/features/settings/domain/notification_prefs_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository provider
final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  return FocusRepositoryStub();
});

/// Focus controller managing timer state
class FocusController extends AsyncNotifier<FocusState> {
  Timer? _timer;
  DateTime? _startedAt;

  @override
  FutureOr<FocusState> build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return FocusState.idle();
  }

  /// Start a new focus session
  Future<void> start({
    required FocusSessionType type,
    required Duration duration,
    Task? linkedTask,
  }) async {
    _timer?.cancel();

    _startedAt = DateTime.now();
    state = AsyncValue.data(
      FocusState(
        status: FocusStatus.running,
        type: type,
        phase: FocusPhase.focus,
        remaining: duration,
        total: duration,
        linkedTask: linkedTask,
        pomodoroCount: 0,
      ),
    );

    // Haptic feedback on session start
    final haptics = ref.read(hapticsServiceProvider);
    await haptics.medium();

    // TODO: Re-enable analytics
    // unawaited(_logEvent(
    //   UserEvent(
    //     type: UserEventType.focusSessionStarted,
    //     timestamp: _startedAt!,
    //     metadata: {
    //       'sessionType': type.name,
    //       'plannedMinutes': duration.inMinutes,
    //       'linkedTaskId': linkedTask?.id,
    //     },
    //   ),
    // ));

    _startTimer();
  }

  /// Pause the current session
  void pause() {
    final currentState = state.value;
    if (currentState == null || !currentState.isRunning) return;

    _timer?.cancel();
    state = AsyncValue.data(
      currentState.copyWith(status: FocusStatus.paused),
    );
  }

  /// Resume a paused session
  void resume() {
    final currentState = state.value;
    if (currentState == null || currentState.status != FocusStatus.paused) {
      return;
    }

    state = AsyncValue.data(
      currentState.copyWith(status: FocusStatus.running),
    );
    _startTimer();
  }

  /// Stop and save partial session
  Future<void> stop() async {
    final currentState = state.value;
    if (currentState == null || currentState.status == FocusStatus.idle) {
      return;
    }

    _timer?.cancel();

    // Save partial session if any time was spent
    if (_startedAt != null && currentState.remaining != currentState.total) {
      final actualDuration = DateTime.now().difference(_startedAt!);
      final session = FocusSession(
        type: currentState.type,
        plannedDuration: currentState.total,
        actualDuration: actualDuration,
        startedAt: _startedAt!,
        endedAt: DateTime.now(),
        linkedTask: currentState.linkedTask,
      );

      final repo = ref.read(focusRepositoryProvider);
      await repo.saveSession(session);

      // TODO: Re-enable analytics
      // unawaited(_logEvent(
      //   UserEvent(
      //     type: UserEventType.focusSessionEnded,
      //     timestamp: session.endedAt ?? DateTime.now(),
      //     metadata: {
      //       'sessionType': session.type.name,
      //       'plannedMinutes': session.plannedDuration.inMinutes,
      //       'actualMinutes': session.actualDuration?.inMinutes,
      //       'linkedTaskId': session.linkedTask?.id,
      //     },
      //   ),
      // ));
    }

    state = AsyncValue.data(FocusState.idle());
    _startedAt = null;
  }

  /// Internal timer tick
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _tick() {
    final currentState = state.value;
    if (currentState == null || !currentState.isRunning) {
      _timer?.cancel();
      return;
    }

    final newRemaining = currentState.remaining - const Duration(seconds: 1);

    if (newRemaining.inSeconds <= 0) {
      _timer?.cancel();
      _onPhaseComplete();
    } else {
      state = AsyncValue.data(
        currentState.copyWith(remaining: newRemaining),
      );
    }
  }

  /// Handle phase completion
  Future<void> _onPhaseComplete() async {
    final currentState = state.value;
    if (currentState == null) return;

    // Save completed session
    if (_startedAt != null) {
      final session = FocusSession(
        type: currentState.type,
        plannedDuration: currentState.total,
        actualDuration: currentState.total, // Completed fully
        startedAt: _startedAt!,
        endedAt: DateTime.now(),
        linkedTask: currentState.linkedTask,
      );

      final repo = ref.read(focusRepositoryProvider);
      await repo.saveSession(session);

      // TODO: Re-enable analytics
      // unawaited(_logEvent(
      //   UserEvent(
      //     type: UserEventType.focusSessionEnded,
      //     timestamp: session.endedAt ?? DateTime.now(),
      //     metadata: {
      //       'sessionType': session.type.name,
      //       'plannedMinutes': session.plannedDuration.inMinutes,
      //       'actualMinutes': session.actualDuration?.inMinutes,
      //       'linkedTaskId': session.linkedTask?.id,
      //       'completed': true,
      //     },
      //   ),
      // ));
    }

    // Trigger notification and haptic feedback
    await _scheduleNotification(currentState);

    // Haptic feedback on phase completion
    final haptics = ref.read(hapticsServiceProvider);
    await haptics.heavy();

    // For Pomodoro type, handle break transitions
    if (currentState.type == FocusSessionType.pomodoro) {
      _handlePomodoroTransition(currentState);
    } else {
      // For Deep Work and Sprint, just complete
      state = AsyncValue.data(
        currentState.copyWith(status: FocusStatus.completed),
      );
    }
  }

  /// Handle Pomodoro phase transitions (focus → break → focus)
  void _handlePomodoroTransition(FocusState currentState) {
    if (currentState.phase == FocusPhase.focus) {
      // After focus, start break
      final newCount = currentState.pomodoroCount + 1;
      final isLongBreak = newCount % 4 == 0;

      final breakDuration = isLongBreak
          ? const Duration(minutes: 15) // Long break
          : const Duration(minutes: 5); // Short break

      state = AsyncValue.data(
        FocusState(
          status: FocusStatus.completed,
          type: currentState.type,
          phase: isLongBreak ? FocusPhase.longBreak : FocusPhase.shortBreak,
          remaining: breakDuration,
          total: breakDuration,
          linkedTask: currentState.linkedTask,
          pomodoroCount: newCount,
        ),
      );
    } else {
      // After break, session is complete
      state = AsyncValue.data(
        currentState.copyWith(status: FocusStatus.completed),
      );
    }
  }

  /// Schedule notification respecting quiet hours
  Future<void> _scheduleNotification(FocusState currentState) async {
    // Check notification preferences
    final notificationPrefs =
        await ref.read(notificationPrefsControllerProvider.future);

    if (!notificationPrefs.notificationsEnabled) return;

    // Check quiet hours
    if (notificationPrefs.quietHoursEnabled &&
        notificationPrefs.quietStart != null &&
        notificationPrefs.quietEnd != null) {
      final now = TimeOfDay.now();
      if (_isInQuietHours(
        now,
        notificationPrefs.quietStart!,
        notificationPrefs.quietEnd!,
      )) {
        debugPrint('Skipping notification: quiet hours active');
        return;
      }
    }

    // Trigger notification based on pomodoroAlert preference
    final alertType = notificationPrefs.pomodoroAlert;

    if (alertType == 'sound' || alertType == 'visual') {
      final isBreakPhase = currentState.isBreak;
      final title =
          isBreakPhase ? 'Break Complete!' : 'Focus Session Complete!';
      final body = isBreakPhase
          ? 'Time to get back to work. You can do this! 💪'
          : 'Great work! Time for a well-deserved break. 🎉';

      if (!kDebugMode) {
        await NotificationsService.show(
          id: 1003, // Unique ID for Pomodoro notifications
          title: title,
          body: body,
        );
      } else {
        debugPrint('Notification: $title - $body');
      }
    }
  }

  /// Check if current time is within quiet hours
  bool _isInQuietHours(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Same day: e.g., 22:00 to 08:00 next day
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Crosses midnight: e.g., 22:00 to 08:00
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  /// Start a break session (for manual break start)
  Future<void> startBreak(Duration duration) async {
    _timer?.cancel();

    _startedAt = DateTime.now();
    final currentState = state.value ?? FocusState.idle();

    state = AsyncValue.data(
      FocusState(
        status: FocusStatus.running,
        type: currentState.type,
        phase: FocusPhase.shortBreak,
        remaining: duration,
        total: duration,
        linkedTask: null,
        pomodoroCount: currentState.pomodoroCount,
      ),
    );

    _startTimer();
  }
}

/// Provider for focus controller
final focusControllerProvider =
    AsyncNotifierProvider<FocusController, FocusState>(
  FocusController.new,
);

// TODO: Re-implement analytics logging with proper architecture
// extension _FocusAnalytics on FocusController {
//   Future<void> _logEvent(UserEvent event) {
//     return ref.read(analyticsServiceProvider).logEvent(event);
//   }
// }
