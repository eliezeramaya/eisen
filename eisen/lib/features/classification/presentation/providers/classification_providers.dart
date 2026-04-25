import 'package:eisen/features/classification/data/datasources/classification_local_datasource.dart';
import 'package:eisen/features/classification/data/repositories/classification_repository_impl.dart';
import 'package:eisen/features/classification/domain/entities/rule_suggestion.dart';
import 'package:eisen/features/classification/domain/repositories/classification_repository.dart';
import 'package:eisen/features/classification/domain/services/classification_engine.dart';
import 'package:eisen/features/classification/domain/services/confidence_scorer.dart';
import 'package:eisen/features/classification/domain/services/heuristic_classifier.dart';
import 'package:eisen/features/classification/domain/services/suggestion_engine.dart';
import 'package:eisen/features/classification/domain/services/user_rule_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final classificationLocalDatasourceProvider =
    Provider<ClassificationLocalDatasource>(
  (ref) => ClassificationLocalDatasource(),
);

final userRuleResolverProvider = Provider<UserRuleResolver>(
  (ref) => const UserRuleResolver(),
);

final confidenceScorerProvider = Provider<ConfidenceScorer>(
  (ref) => const ConfidenceScorer(),
);

final suggestionEngineProvider = Provider<SuggestionEngine>(
  (ref) => const SuggestionEngine(),
);

final heuristicClassifierProvider = Provider<HeuristicClassifier>(
  (ref) => const HeuristicClassifier(),
);

final classificationEngineProvider = Provider<ClassificationEngine>((ref) {
  return DefaultClassificationEngine(
    ruleResolver: ref.read(userRuleResolverProvider),
    heuristicClassifier: ref.read(heuristicClassifierProvider),
    confidenceScorer: ref.read(confidenceScorerProvider),
  );
});

final classificationRepositoryProvider = Provider<ClassificationRepository>(
  (ref) {
    return ClassificationRepositoryImpl(
      localDatasource: ref.read(classificationLocalDatasourceProvider),
      classificationEngine: ref.read(classificationEngineProvider),
      suggestionEngine: ref.read(suggestionEngineProvider),
    );
  },
);

final classificationSuggestionsProvider =
    FutureProvider<List<RuleSuggestion>>((ref) {
  return ref.read(classificationRepositoryProvider).suggestRules();
});
