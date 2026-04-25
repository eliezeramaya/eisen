import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/entities/classification_rule.dart';
import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/entities/rule_suggestion.dart';
import 'package:eisen/features/classification/domain/entities/vocabulary_alias.dart';
import 'package:eisen/features/classification/domain/enums/suggestion_status.dart';

abstract class ClassificationRepository {
  Future<ClassificationSettings> loadSettings();
  Future<void> saveSettings(ClassificationSettings settings);

  Future<List<CategoryConfig>> loadCategories();
  Future<void> saveCategories(List<CategoryConfig> categories);

  Future<List<ClassificationRule>> loadRules();
  Future<void> saveRules(List<ClassificationRule> rules);

  Future<List<VocabularyAlias>> loadAliases();
  Future<void> saveAliases(List<VocabularyAlias> aliases);

  Future<List<ClassificationCorrectionEvent>> loadCorrections();

  Future<ClassificationMetadata> classifyEntry(String input);

  Future<ClassificationMetadata> previewClassification({
    required String input,
    ClassificationSettings? settings,
    List<CategoryConfig>? categories,
    List<ClassificationRule>? rules,
    List<VocabularyAlias>? aliases,
  });

  Future<void> recordCorrection(ClassificationCorrectionEvent event);

  Future<List<RuleSuggestion>> suggestRules();
  Future<void> updateRuleSuggestionStatus(
    String suggestionId,
    SuggestionStatus status,
  );
}
