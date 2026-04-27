import 'package:eisen/features/classification/domain/classification_result.dart';
import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/services/classification_engine.dart'
    as services;
import 'package:eisen/features/classification/domain/services/heuristic_classifier.dart';

class LocalClassificationEngine {
  const LocalClassificationEngine({
    HeuristicClassifier heuristicClassifier = const HeuristicClassifier(),
  }) : _heuristicClassifier = heuristicClassifier;

  final HeuristicClassifier _heuristicClassifier;

  ClassificationResult classify(
    String input, {
    List<CategoryConfig> categories = CategoryConfigDefaults.values,
    ClassificationSettings settings = ClassificationSettingsDefaults.value,
  }) {
    final normalizedInput = services.normalizeClassificationText(input);
    final afterUserRules = _applyUserRulesStub(normalizedInput);
    final afterAliases = _applyAliasesStub(afterUserRules);
    final heuristics = _heuristicClassifier.classify(
      normalizedInput: afterAliases,
      categories: categories,
      settings: settings,
    );
    return heuristics.result;
  }

  String _applyUserRulesStub(String input) {
    // TODO: resolve deterministic user rules before heuristics.
    return input;
  }

  String _applyAliasesStub(String input) {
    // TODO: expand personalized aliases before heuristics.
    return input;
  }
}
