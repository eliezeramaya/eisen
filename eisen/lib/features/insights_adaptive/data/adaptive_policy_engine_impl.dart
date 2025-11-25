import 'package:eisen/features/insights_adaptive/domain/adaptive_policy_engine.dart';
import 'package:eisen/features/insights_adaptive/domain/bandit_engine.dart';
import 'package:eisen/features/insights_adaptive/domain/bandit_models.dart';
import 'package:eisen/features/insights_adaptive/domain/cluster_models.dart';
import 'package:eisen/features/insights_adaptive/domain/clustering_service.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scoring_service.dart';

class AdaptivePolicyEngineImpl implements AdaptivePolicyEngine {
  AdaptivePolicyEngineImpl({
    required this.banditEngine,
    required this.clusteringService,
    required this.scoringService,
  });

  final BanditEngine banditEngine;
  final ProductivityClusteringService clusteringService;
  final ProductivityScoringService scoringService;

  @override
  Future<NudgeArm> selectBestNudgeArm(DateTime now) async {
    final profile = await clusteringService.computeWeeklyProfile(now);
    final scores =
        await scoringService.computeDailyScores(from: now, to: now);
    final latest = scores.isNotEmpty ? scores.last : null;
    final ctx = BanditContext(
      now: now,
      recentProcrastinationScore:
          ((latest?.procrastinationScore ?? 0) * 100).toInt(),
      recentOverloadScore: ((latest?.overloadScore ?? 0) * 100).toInt(),
      recentQ2Ratio: ((latest?.q2Ratio ?? 0) * 100).toInt(),
    );

    final arm = await banditEngine.selectArm(ctx);
    return _biasArmWithProfile(profile.cluster, arm);
  }

  NudgeArm _biasArmWithProfile(ProductivityCluster cluster, NudgeArm arm) {
    switch (cluster) {
      case ProductivityCluster.nightSprinter:
        return NudgeArm.dailyShutdown;
      case ProductivityCluster.morningStrong:
        return NudgeArm.focusBlock;
      case ProductivityCluster.starterButNotFinisher:
        return NudgeArm.splitBigTask;
      case ProductivityCluster.unknown:
        return arm;
    }
  }

  @override
  Future<void> registerNudgeOutcome(NudgeArm arm, bool actionExecuted) {
    return banditEngine.updateReward(arm, actionExecuted ? 1.0 : 0.0);
  }

  @override
  Future<UserProductivityProfile> getCurrentProfile() {
    return clusteringService.computeWeeklyProfile(DateTime.now());
  }
}
