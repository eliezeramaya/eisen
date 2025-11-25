import 'package:flutter/foundation.dart';

/// Brazos disponibles para el bandit de nudges.
enum NudgeArm {
  focusBlock, // Nudge A: “Bloques de foco”
  reduceTodayLoad, // Nudge B: “Reduce carga de hoy”
  splitBigTask, // Nudge C: “Divide tarea grande”
  dailyShutdown, // Nudge D: “Configura ritual de cierre”
}

@immutable
class NudgeArmStats {
  const NudgeArmStats({
    this.successes = 0,
    this.failures = 0,
  });

  final int successes;
  final int failures;

  NudgeArmStats copyWith({int? successes, int? failures}) {
    return NudgeArmStats(
      successes: successes ?? this.successes,
      failures: failures ?? this.failures,
    );
  }
}

@immutable
class BanditState {
  const BanditState({required this.arms});

  final Map<NudgeArm, NudgeArmStats> arms;

  BanditState.initial()
      : arms = {
          for (final arm in NudgeArm.values)
            arm: const NudgeArmStats(successes: 1, failures: 1),
        };

  BanditState copyWithArm(NudgeArm arm, NudgeArmStats stats) {
    final newArms = Map<NudgeArm, NudgeArmStats>.from(arms);
    newArms[arm] = stats;
    return BanditState(arms: newArms);
  }
}
