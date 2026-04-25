import 'dart:convert';

import 'package:eisen/features/classification/data/models/category_config_model.dart';
import 'package:eisen/features/classification/data/models/classification_correction_event_model.dart';
import 'package:eisen/features/classification/data/models/classification_rule_model.dart';
import 'package:eisen/features/classification/data/models/classification_settings_model.dart';
import 'package:eisen/features/classification/data/models/rule_suggestion_model.dart';
import 'package:eisen/features/classification/data/models/vocabulary_alias_model.dart';
import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/entities/vocabulary_alias.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClassificationLocalDatasource {
  static const _settingsKey = 'eisen.classification.settings.v1';
  static const _categoriesKey = 'eisen.classification.categories.v1';
  static const _rulesKey = 'eisen.classification.rules.v1';
  static const _aliasesKey = 'eisen.classification.aliases.v1';
  static const _correctionsKey = 'eisen.classification.corrections.v1';
  static const _suggestionsKey = 'eisen.classification.rule_suggestions.v1';

  Future<ClassificationSettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) {
      return ClassificationSettingsModel.fromEntity(
        ClassificationSettingsDefaults.value,
      );
    }
    final decoded = jsonDecode(raw);
    return ClassificationSettingsModel.fromJson(
      (decoded as Map).cast<String, Object?>(),
    );
  }

  Future<void> saveSettings(ClassificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final model = ClassificationSettingsModel.fromEntity(settings);
    await prefs.setString(_settingsKey, jsonEncode(model.toJson()));
  }

  Future<List<CategoryConfigModel>> loadCategories() async {
    final jsonList = await _loadList(_categoriesKey);
    if (jsonList.isEmpty) {
      return CategoryConfigDefaults.values
          .map(CategoryConfigModel.fromEntity)
          .toList();
    }
    return jsonList.map(CategoryConfigModel.fromJson).toList();
  }

  Future<void> saveCategories(List<CategoryConfig> categories) async {
    await _saveList(
      _categoriesKey,
      categories
          .map((item) => CategoryConfigModel.fromEntity(item).toJson())
          .toList(),
    );
  }

  Future<List<ClassificationRuleModel>> loadRules() async {
    final jsonList = await _loadList(_rulesKey);
    return jsonList.map(ClassificationRuleModel.fromJson).toList();
  }

  Future<void> saveRules(List<ClassificationRuleModel> rules) async {
    await _saveList(
      _rulesKey,
      rules.map((item) => item.toJson()).toList(),
    );
  }

  Future<List<VocabularyAliasModel>> loadAliases() async {
    final jsonList = await _loadList(_aliasesKey);
    if (jsonList.isEmpty) {
      return VocabularyAliasDefaults.values
          .map(VocabularyAliasModel.fromEntity)
          .toList();
    }
    return jsonList.map(VocabularyAliasModel.fromJson).toList();
  }

  Future<void> saveAliases(List<VocabularyAlias> aliases) async {
    await _saveList(
      _aliasesKey,
      aliases
          .map((item) => VocabularyAliasModel.fromEntity(item).toJson())
          .toList(),
    );
  }

  Future<List<ClassificationCorrectionEventModel>> loadCorrections() async {
    final jsonList = await _loadList(_correctionsKey);
    return jsonList.map(ClassificationCorrectionEventModel.fromJson).toList();
  }

  Future<void> saveCorrections(
    List<ClassificationCorrectionEventModel> corrections,
  ) async {
    await _saveList(
      _correctionsKey,
      corrections.map((item) => item.toJson()).toList(),
    );
  }

  Future<List<RuleSuggestionModel>> loadRuleSuggestions() async {
    final jsonList = await _loadList(_suggestionsKey);
    return jsonList.map(RuleSuggestionModel.fromJson).toList();
  }

  Future<void> saveRuleSuggestions(
    List<RuleSuggestionModel> suggestions,
  ) async {
    await _saveList(
      _suggestionsKey,
      suggestions.map((item) => item.toJson()).toList(),
    );
  }

  Future<List<Map<String, Object?>>> _loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return const <Map<String, Object?>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <Map<String, Object?>>[];
    return decoded
        .whereType<Map<Object?, Object?>>()
        .map((item) => item.cast<String, Object?>())
        .toList();
  }

  Future<void> _saveList(
    String key,
    List<Map<String, Object?>> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }
}
