import 'package:eisen/features/insights_adaptive/domain/bandit_models.dart';

/// Contexto opcional para bandits contextuales.
class BanditContext {
  final DateTime now;
  final int recentProcrastinationScore; // 0..100
  final int recentOverloadScore; // 0..100
  final int recentQ2Ratio; // 0..100

  const BanditContext({
    required this.now,
    required this.recentProcrastinationScore,
    required this.recentOverloadScore,
    required this.recentQ2Ratio,
  });
}

abstract class BanditEngine {
  Future<NudgeArm> selectArm(BanditContext context);
  Future<void> updateReward(NudgeArm arm, double reward);
}
