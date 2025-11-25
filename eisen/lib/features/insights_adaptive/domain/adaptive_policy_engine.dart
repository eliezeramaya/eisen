import 'package:eisen/features/insights_adaptive/domain/bandit_models.dart';
import 'package:eisen/features/insights_adaptive/domain/cluster_models.dart';

abstract class AdaptivePolicyEngine {
  Future<NudgeArm> selectBestNudgeArm(DateTime now);
  Future<void> registerNudgeOutcome(NudgeArm arm, bool actionExecuted);
  Future<UserProductivityProfile> getCurrentProfile();
}
