import 'package:eisen/features/insights_adaptive/data/adaptive_policy_engine_impl.dart';
import 'package:eisen/features/insights_adaptive/domain/bandit_engine.dart';
import 'package:eisen/features/insights_adaptive/domain/bandit_models.dart';
import 'package:eisen/features/insights_adaptive/domain/cluster_models.dart';
import 'package:eisen/features/insights_adaptive/domain/clustering_service.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scoring_service.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBandit implements BanditEngine {
  @override
  Future<NudgeArm> selectArm(BanditContext context) async =>
      NudgeArm.reduceTodayLoad;

  @override
  Future<void> updateReward(NudgeArm arm, double reward) async {}
}

class _FakeCluster implements ProductivityClusteringService {
  _FakeCluster(this.cluster);
  final ProductivityCluster cluster;
  @override
  Future<UserProductivityProfile> computeWeeklyProfile(DateTime now) async =>
      UserProductivityProfile(cluster: cluster, computedAt: now);
}

class _FakeScoring implements ProductivityScoringService {
  @override
  Future<List<DailyProductivityScore>> computeDailyScores(
          {required DateTime from, required DateTime to}) async =>
      [
        DailyProductivityScore(
          day: from,
          overloadScore: 0.2,
          q2Ratio: 0.5,
          procrastinationScore: 0.5,
          focusConsistencyScore: 0.5,
        )
      ];

  @override
  Future<List<FocusWindowSuggestion>> computeFocusWindows(
          {DateTime? from, DateTime? to}) async =>
      [];

  @override
  Future<OverloadRisk> computeDailyOverloadRisk(DateTime date) async =>
      const OverloadRisk(0.2);

  @override
  Future<TaskCompletionPrediction> predictTaskCompletion(task) async =>
      const TaskCompletionPrediction(
          onTimeProbability: 0.5, reprogramProbability: 0.5);

  @override
  Future<ProcrastinationScore> predictTaskProcrastination(task) async =>
      const ProcrastinationScore(0.5);
}

void main() {
  test('AdaptivePolicyEngine biases arm based on cluster', () async {
    final engine = AdaptivePolicyEngineImpl(
      banditEngine: _FakeBandit(),
      clusteringService:
          _FakeCluster(ProductivityCluster.starterButNotFinisher),
      scoringService: _FakeScoring(),
    );
    final arm = await engine.selectBestNudgeArm(DateTime(2025, 1, 1));
    expect(arm, NudgeArm.splitBigTask);
  });
}
