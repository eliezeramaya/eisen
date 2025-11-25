import 'dart:math' as math;

import 'package:eisen/features/insights_adaptive/data/bandit_state_repository.dart';
import 'package:eisen/features/insights_adaptive/domain/bandit_engine.dart';
import 'package:eisen/features/insights_adaptive/domain/bandit_models.dart';

/// Bandit Thompson Sampling simplificado para seleccionar nudges.
class ThompsonBanditEngine implements BanditEngine {
  ThompsonBanditEngine(this._repo, {math.Random? random})
      : _rand = random ?? math.Random.secure();

  final BanditStateRepository _repo;
  final math.Random _rand;

  @override
  Future<NudgeArm> selectArm(BanditContext context) async {
    final state = await _repo.loadState();
    double sampleFor(NudgeArm arm) {
      final stats = state.arms[arm] ?? const NudgeArmStats(successes: 1, failures: 1);
      // Beta(alpha, beta) ~ Gamma(alpha,1)/[Gamma(alpha,1)+Gamma(beta,1)]
      double gamma(int k) {
        double sum = 0;
        for (int i = 0; i < k; i++) {
          sum -= math.log(_rand.nextDouble().clamp(1e-6, 1.0));
        }
        return sum;
      }

      final alpha = stats.successes + 1;
      final beta = stats.failures + 1;
      final g1 = gamma(alpha);
      final g2 = gamma(beta);
      final base = g1 / (g1 + g2);

      // Contextual ligero: penalizar si overload alto para brazos que agregan carga
      final overloadBias = context.recentOverloadScore / 100.0;
      final procrastBias = context.recentProcrastinationScore / 100.0;
      double adjusted = base;
      switch (arm) {
        case NudgeArm.focusBlock:
          adjusted += (context.recentQ2Ratio / 100.0) * 0.05;
          break;
        case NudgeArm.reduceTodayLoad:
          adjusted += overloadBias * 0.08;
          break;
        case NudgeArm.splitBigTask:
          adjusted += procrastBias * 0.06;
          break;
        case NudgeArm.dailyShutdown:
          adjusted += overloadBias * 0.03;
          break;
      }
      return adjusted;
    }

    final samples = <NudgeArm, double>{
      for (final arm in NudgeArm.values) arm: sampleFor(arm),
    };

    return samples.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  @override
  Future<void> updateReward(NudgeArm arm, double reward) async {
    final state = await _repo.loadState();
    final current = state.arms[arm] ?? const NudgeArmStats(successes: 1, failures: 1);
    final isSuccess = reward > 0.5;
    final updated = current.copyWith(
      successes: current.successes + (isSuccess ? 1 : 0),
      failures: current.failures + (isSuccess ? 0 : 1),
    );
    await _repo.saveState(state.copyWithArm(arm, updated));
  }
}
