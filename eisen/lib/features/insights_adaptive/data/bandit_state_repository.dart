import 'dart:convert';

import 'package:eisen/features/insights_adaptive/domain/bandit_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BanditStateRepository {
  Future<BanditState> loadState();
  Future<void> saveState(BanditState state);
}

class LocalBanditStateRepository implements BanditStateRepository {
  LocalBanditStateRepository({SharedPreferences? prefs}) : _prefs = prefs;

  static const _key = 'adaptive.bandit.state.v1';
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<BanditState> loadState() async {
    final prefs = await _sp;
    final raw = prefs.getString(_key);
    if (raw == null) return BanditState.initial();
    try {
      final map = (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          NudgeArm.values.firstWhere(
            (e) => e.name == k,
            orElse: () => NudgeArm.focusBlock,
          ),
          NudgeArmStats(
            successes: (v['s'] as int?) ?? 1,
            failures: (v['f'] as int?) ?? 1,
          ),
        ),
      );
      return BanditState(arms: map);
    } catch (_) {
      return BanditState.initial();
    }
  }

  @override
  Future<void> saveState(BanditState state) async {
    final prefs = await _sp;
    final map = state.arms.map(
      (k, v) => MapEntry(k.name, {'s': v.successes, 'f': v.failures}),
    );
    await prefs.setString(_key, jsonEncode(map));
  }
}

final banditStateRepositoryProvider = Provider<BanditStateRepository>(
  (ref) => LocalBanditStateRepository(),
);
