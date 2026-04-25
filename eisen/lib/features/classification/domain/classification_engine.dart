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
    final heuristics = _heuristicClassifier.classify(
      normalizedInput: services.normalizeClassificationText(input),
      categories: categories,
      settings: settings,
    );
    return heuristics.result;
  }
}
