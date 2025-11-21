import 'dart:async';

import 'package:eisen/features/insights/domain/nudge.dart';
import 'package:eisen/features/insights/domain/nudge_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final filtered = nudges
        .where((n) => !dismissed.contains(n.id))
        .toList(growable: false);
    filtered.sort(_severityCompare);
    state = AsyncData(
      NudgesState(
        nudges: filtered,
        lastCalculatedAt: now,
      ),
    );
  }

  Future<void> refresh() => loadNudges(force: true);

  Future<void> dismissNudge(Nudge nudge) async {
    final current = state.value ?? const NudgesState();
    final nextList =
        current.nudges.where((it) => it.id != nudge.id).toList();
    state = AsyncData(
      current.copyWith(nudges: nextList, lastCalculatedAt: DateTime.now()),
    );
    final dismissed = await _loadDismissedIds();
    dismissed.add(nudge.id);
    await _persistDismissed(dismissed);
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
