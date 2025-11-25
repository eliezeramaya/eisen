import 'package:eisen/features/insights_adaptive/data/adaptive_policy_engine_impl.dart';
import 'package:eisen/features/insights_adaptive/data/bandit_state_repository.dart';
import 'package:eisen/features/insights_adaptive/data/productivity_clustering_service_impl.dart';
import 'package:eisen/features/insights_adaptive/data/thompson_bandit_engine.dart';
import 'package:eisen/features/insights_adaptive/domain/adaptive_policy_engine.dart';
import 'package:eisen/features/insights_adaptive/domain/bandit_engine.dart';
import 'package:eisen/features/insights_adaptive/domain/clustering_service.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scoring_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final banditEngineProvider = Provider<BanditEngine>((ref) {
  final repo = ref.watch(banditStateRepositoryProvider);
  return ThompsonBanditEngine(repo);
});

final productivityClusteringProvider =
    Provider<ProductivityClusteringService>((ref) {
  return ref.watch(productivityClusteringServiceProvider);
});

final adaptivePolicyEngineProvider = Provider<AdaptivePolicyEngine>((ref) {
  final bandit = ref.watch(banditEngineProvider);
  final clustering = ref.watch(productivityClusteringProvider);
  final scoring = ref.watch(productivityScoringServiceProvider);
  return AdaptivePolicyEngineImpl(
    banditEngine: bandit,
    clusteringService: clustering,
    scoringService: scoring,
  );
});
