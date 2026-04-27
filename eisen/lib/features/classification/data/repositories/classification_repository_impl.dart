import 'package:eisen/features/classification/data/datasources/classification_local_datasource.dart';
import 'package:eisen/features/classification/data/models/classification_correction_event_model.dart';
import 'package:eisen/features/classification/data/models/classification_rule_model.dart';
import 'package:eisen/features/classification/data/models/rule_suggestion_model.dart';
import 'package:eisen/features/classification/data/models/vocabulary_alias_model.dart';
import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/entities/classification_rule.dart';
import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/entities/rule_suggestion.dart';
import 'package:eisen/features/classification/domain/entities/vocabulary_alias.dart';
import 'package:eisen/features/classification/domain/enums/alias_type.dart';
import 'package:eisen/features/classification/domain/enums/suggestion_status.dart';
import 'package:eisen/features/classification/domain/repositories/classification_repository.dart';
import 'package:eisen/features/classification/domain/services/classification_engine.dart';
import 'package:eisen/features/classification/domain/services/suggestion_engine.dart';

class ClassificationRepositoryImpl implements ClassificationRepository {
  ClassificationRepositoryImpl({
    required ClassificationLocalDatasource localDatasource,
    required ClassificationEngine classificationEngine,
    required SuggestionEngine suggestionEngine,
  })  : _localDatasource = localDatasource,
        _classificationEngine = classificationEngine,
        _suggestionEngine = suggestionEngine;

  final ClassificationLocalDatasource _localDatasource;
  final ClassificationEngine _classificationEngine;
  final SuggestionEngine _suggestionEngine;

  @override
  Future<ClassificationSettings> loadSettings() {
    return _localDatasource.loadSettings();
  }

  @override
  Future<void> saveSettings(ClassificationSettings settings) {
    return _localDatasource.saveSettings(
      settings.copyWith(updatedAt: DateTime.now()),
    );
  }

  @override
  Future<List<CategoryConfig>> loadCategories() {
    return _localDatasource.loadCategories();
  }

  @override
  Future<void> saveCategories(List<CategoryConfig> categories) {
    final now = DateTime.now();
    return _localDatasource.saveCategories(
      categories
          .map(
            (category) => category.copyWith(
              createdAt: category.createdAt ?? now,
              updatedAt: now,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<List<ClassificationRule>> loadRules() async {
    return _localDatasource.loadRules();
  }

  @override
  Future<void> saveRules(List<ClassificationRule> rules) {
    final now = DateTime.now();
    return _localDatasource.saveRules(
      rules
          .map(
            (rule) => ClassificationRuleModel.fromEntity(
              rule.copyWith(
                isUserCreated: rule.isUserCreated ||
                    !rule.id.startsWith('rule-suggested-'),
                createdAt: rule.createdAt ?? now,
                updatedAt: now,
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<List<VocabularyAlias>> loadAliases() {
    return _localDatasource.loadAliases();
  }

  @override
  Future<void> saveAliases(List<VocabularyAlias> aliases) {
    final now = DateTime.now();
    return _localDatasource.saveAliases(
      aliases
          .map(
            (alias) => alias.copyWith(
              createdAt: alias.createdAt ?? now,
              updatedAt: now,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<List<ClassificationCorrectionEvent>> loadCorrections() {
    return _localDatasource.loadCorrections();
  }

  @override
  Future<ClassificationMetadata> classifyEntry(String input) async {
    final bundle = await _loadBundle();
    return _classificationEngine.classify(
      input: input,
      settings: bundle.settings,
      categories: bundle.categories,
      rules: bundle.rules,
      aliases: bundle.aliases,
    );
  }

  @override
  Future<ClassificationMetadata> previewClassification({
    required String input,
    ClassificationSettings? settings,
    List<CategoryConfig>? categories,
    List<ClassificationRule>? rules,
    List<VocabularyAlias>? aliases,
  }) async {
    final bundle = await _loadBundle();
    return _classificationEngine.classify(
      input: input,
      settings: settings ?? bundle.settings,
      categories: categories ?? bundle.categories,
      rules: rules ?? bundle.rules,
      aliases: aliases ?? bundle.aliases,
    );
  }

  @override
  Future<void> recordCorrection(ClassificationCorrectionEvent event) async {
    final corrections = await _localDatasource.loadCorrections();
    corrections.add(ClassificationCorrectionEventModel.fromEntity(event));
    await _localDatasource.saveCorrections(corrections);

    final settings = await loadSettings();
    if (!settings.learnFromCorrections || !settings.useVocabularyAliases) {
      return;
    }

    await _learnAliasFromCorrection(event);
  }

  @override
  Future<List<RuleSuggestion>> suggestRules() async {
    final settings = await loadSettings();
    if (!settings.suggestRules) return const <RuleSuggestion>[];
    final corrections = await loadCorrections();
    final existingRules = await loadRules();
    final persisted = await _localDatasource.loadRuleSuggestions();
    final generated = _suggestionEngine.suggestRules(
      corrections,
      existingRules: existingRules,
    );
    final merged = _mergeSuggestions(
      generated: generated,
      persisted: persisted,
    );
    await _localDatasource.saveRuleSuggestions(
      merged.map(RuleSuggestionModel.fromEntity).toList(growable: false),
    );
    return merged.where((item) => item.isPending).toList(growable: false);
  }

  @override
  Future<void> updateRuleSuggestionStatus(
    String suggestionId,
    SuggestionStatus status,
  ) async {
    final suggestions = await _localDatasource.loadRuleSuggestions();
    final now = DateTime.now();
    final updated = [
      for (final suggestion in suggestions)
        if (suggestion.id == suggestionId)
          suggestion.copyWith(status: status, updatedAt: now)
        else
          suggestion,
    ];
    await _localDatasource.saveRuleSuggestions(
      updated.map(RuleSuggestionModel.fromEntity).toList(growable: false),
    );
  }

  Future<void> _learnAliasFromCorrection(
    ClassificationCorrectionEvent event,
  ) async {
    final corrected = event.correctedClassification;
    final correctedCategoryId = event.correctedCategoryId;
    final correctedQuadrant =
        event.correctedQuadrant ?? corrected?.suggestedQuadrant;
    final token =
        event.detectedKeyword ?? _extractLearnableToken(event.rawText);
    if ((correctedCategoryId == null && correctedQuadrant == null) ||
        token == null) {
      return;
    }

    final aliases = await _localDatasource.loadAliases();
    final exists = aliases.any(
      (item) =>
          item.mappedCategoryId == correctedCategoryId &&
          item.suggestedQuadrant == correctedQuadrant &&
          item.searchTerms.contains(token),
    );
    if (exists) return;

    final idPart = correctedCategoryId ?? correctedQuadrant!.name;
    aliases.add(
      VocabularyAliasModel(
        id: 'learned-$idPart-$token',
        term: token,
        normalizedTerm: token,
        type: AliasType.category,
        aliases: <String>[token],
        mappedCategoryId: correctedCategoryId,
        mappedKind: event.correctedKind ?? corrected?.entryKind,
        timeHorizon: corrected?.timeHorizon,
        energyLevel: corrected?.energyLevel,
        priorityLevel: corrected?.priorityLevel,
        suggestedQuadrant: correctedQuadrant,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await _localDatasource.saveAliases(aliases);
  }

  String? _extractLearnableToken(String input) {
    final tokens = input
        .toLowerCase()
        .split(RegExp(r'[^a-zA-Záéíóúñ0-9]+'))
        .where((item) => item.length >= 4)
        .where(
          (item) => !const {
            'para',
            'quiero',
            'empezar',
            'terminar',
            'viernes',
          }.contains(item),
        )
        .toList();
    if (tokens.isEmpty) return null;
    return tokens.first;
  }

  Future<_ClassificationBundle> _loadBundle() async {
    final settings = await loadSettings();
    final categories = await loadCategories();
    final rules = await loadRules();
    final aliases = await loadAliases();
    return _ClassificationBundle(
      settings: settings,
      categories: categories,
      rules: rules,
      aliases: aliases,
    );
  }

  List<RuleSuggestion> _mergeSuggestions({
    required List<RuleSuggestion> generated,
    required List<RuleSuggestion> persisted,
  }) {
    final persistedById = {
      for (final suggestion in persisted) suggestion.id: suggestion,
    };
    final merged = <RuleSuggestion>[];
    for (final suggestion in generated) {
      final existing = persistedById.remove(suggestion.id);
      merged.add(
        existing?.copyWith(
              detectedPattern: suggestion.detectedPattern,
              suggestedRule: suggestion.suggestedRule,
              confidence: suggestion.confidence,
              updatedAt: DateTime.now(),
            ) ??
            suggestion.copyWith(updatedAt: DateTime.now()),
      );
    }

    for (final suggestion in persistedById.values) {
      if (suggestion.status != SuggestionStatus.pending) {
        merged.add(suggestion);
      }
    }

    return merged;
  }
}

class _ClassificationBundle {
  const _ClassificationBundle({
    required this.settings,
    required this.categories,
    required this.rules,
    required this.aliases,
  });

  final ClassificationSettings settings;
  final List<CategoryConfig> categories;
  final List<ClassificationRule> rules;
  final List<VocabularyAlias> aliases;
}
