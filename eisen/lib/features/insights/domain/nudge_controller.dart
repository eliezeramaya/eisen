import 'dart:async';

import 'package:eisen/features/insights/data/nudge_tracking_repository.dart';
import 'package:eisen/features/insights/domain/nudge.dart';
import 'package:eisen/features/insights/domain/nudge_engine.dart';
import 'package:eisen/features/insights/domain/nudge_notification_service.dart';
import 'package:eisen/features/insights/domain/nudge_tracking.dart';
import 'package:eisen/features/settings/domain/notification_prefs_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dismissedKey = 'nudges_dismissed_ids';
const _minRecalcGap = Duration(hours: 1);

class NudgesState {
  const NudgesState({
    this.nudges = const [],
    this.lastCalculatedAt,
  });

  final List<Nudge> nudges;
  final DateTime? lastCalculatedAt;

  bool get hasActiveNudges => nudges.isNotEmpty;

  NudgesState copyWith({
    List<Nudge>? nudges,
    DateTime? lastCalculatedAt,
  }) =>
      NudgesState(
        nudges: nudges ?? this.nudges,
        lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
      );
}

class NudgeController extends AsyncNotifier<NudgesState> {
  Set<String>? _dismissedCache;

  @override
  FutureOr<NudgesState> build() {
    // Lazy-load to avoid blocking build; callers can trigger loadNudges().
    return const NudgesState();
  }

  Future<Set<String>> _loadDismissedIds() async {
    if (_dismissedCache != null) return _dismissedCache!;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_dismissedKey) ?? const <String>[];
    _dismissedCache = ids.toSet();
    return _dismissedCache!;
  }

  Future<void> _persistDismissed(Set<String> ids) async {
    _dismissedCache = ids;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_dismissedKey, ids.toList());
  }

  Future<void> loadNudges({bool force = false}) async {
    final notifPrefs = ref
        .read(notificationPrefsControllerProvider)
        .maybeWhen(data: (v) => v, orElse: () => null);
    if (notifPrefs != null && notifPrefs.nudgesEnabled == false) {
      state = const AsyncData(NudgesState(nudges: [], lastCalculatedAt: null));
      return;
    }

    final current = state.value ?? const NudgesState();
    final last = current.lastCalculatedAt;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _minRecalcGap &&
        current.nudges.isNotEmpty) {
      return;
    }
    final dismissed = await _loadDismissedIds();
    final engine = ref.read(nudgeEngineProvider);
    final now = DateTime.now();
    final nudges = await engine.calculateNudges(now);
    final filtered =
        nudges.where((n) => !dismissed.contains(n.id)).toList(growable: false);
    filtered.sort(_severityCompare);

    // Marcar nudges como vistos (tracking)
    await _trackNudgesAsSeen(filtered);

    // Enviar notificaciones si hay nudges nuevos de alta prioridad
    if (notifPrefs != null) {
      await _sendNotificationsIfNeeded(filtered, notifPrefs);
    }

    state = AsyncData(
      NudgesState(
        nudges: filtered,
        lastCalculatedAt: now,
      ),
    );
  }

  Future<void> _trackNudgesAsSeen(List<Nudge> nudges) async {
    if (nudges.isEmpty) return;

    final trackingRepo = ref.read(nudgeTrackingRepositoryProvider);
    final trackings = <NudgeTrackingData>[];

    for (final nudge in nudges) {
      final existing = await trackingRepo.getTracking(nudge.id);
      final updated = existing?.markAsSeen() ??
          NudgeTrackingData(nudgeId: nudge.id).markAsSeen();
      trackings.add(updated);
    }

    await trackingRepo.saveMultiple(trackings);
  }

  Future<void> refresh() => loadNudges(force: true);

  Future<void> dismissNudge(Nudge nudge) async {
    final current = state.value ?? const NudgesState();
    final nextList = current.nudges.where((it) => it.id != nudge.id).toList();
    state = AsyncData(
      current.copyWith(nudges: nextList, lastCalculatedAt: DateTime.now()),
    );
    final dismissed = await _loadDismissedIds();
    dismissed.add(nudge.id);
    await _persistDismissed(dismissed);

    // Registrar dismissal en tracking
    await _trackDismissal(nudge.id);
  }

  Future<void> _trackDismissal(String nudgeId) async {
    final trackingRepo = ref.read(nudgeTrackingRepositoryProvider);
    final existing = await trackingRepo.getTracking(nudgeId);
    final updated = existing?.markAsDismissed() ??
        NudgeTrackingData(nudgeId: nudgeId).markAsDismissed();
    await trackingRepo.saveTracking(updated);
  }

  /// Ejecuta la acción asociada a un nudge y navega a la ruta correspondiente.
  Future<void> executeAction(
      NudgeAction action, Nudge nudge, GoRouter router) async {
    if (action.route != null) {
      router.go(action.route!);
    }

    // Registrar acción en tracking
    await _trackAction(nudge.id);
  }

  Future<void> _trackAction(String nudgeId) async {
    final trackingRepo = ref.read(nudgeTrackingRepositoryProvider);
    final existing = await trackingRepo.getTracking(nudgeId);
    final updated = existing?.markAsActed() ??
        NudgeTrackingData(nudgeId: nudgeId).markAsActed();
    await trackingRepo.saveTracking(updated);
  }

  /// Envía notificaciones para nudges de alta prioridad que son nuevos
  Future<void> _sendNotificationsIfNeeded(
      List<Nudge> nudges, notificationPrefs) async {
    // Solo enviar notificaciones para nudges de severidad alta o mediumHigh
    final highPriorityNudges = nudges
        .where((n) =>
            n.severity == NudgeSeverity.high ||
            n.severity == NudgeSeverity.mediumHigh)
        .toList();

    if (highPriorityNudges.isEmpty) return;

    // Verificar cuáles son nuevos (no han sido notificados antes)
    final trackingRepo = ref.read(nudgeTrackingRepositoryProvider);
    final newNudges = <Nudge>[];

    for (final nudge in highPriorityNudges) {
      final tracking = await trackingRepo.getTracking(nudge.id);
      // Es nuevo si no tiene tracking o tiene menos de 2 vistas
      if (tracking == null || tracking.viewCount < 2) {
        newNudges.add(nudge);
      }
    }

    if (newNudges.isNotEmpty) {
      // Enviar notificaciones en batch (máximo 3)
      await NudgeNotificationService.sendBatchNudges(
        nudges: newNudges,
        prefs: notificationPrefs,
      );
    }
  }

  int _severityCompare(Nudge a, Nudge b) =>
      _score(b.severity).compareTo(_score(a.severity));

  int _score(NudgeSeverity s) {
    switch (s) {
      case NudgeSeverity.high:
        return 3;
      case NudgeSeverity.mediumHigh:
        return 2;
      case NudgeSeverity.medium:
        return 1;
      case NudgeSeverity.low:
        return 0;
    }
  }
}

final nudgeControllerProvider =
    AsyncNotifierProvider<NudgeController, NudgesState>(
  NudgeController.new,
);
