import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/entities/classification_rule.dart';
import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/entities/vocabulary_alias.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/services/confidence_scorer.dart';
import 'package:eisen/features/classification/domain/services/heuristic_classifier.dart';
import 'package:eisen/features/classification/domain/services/user_rule_resolver.dart';

abstract class ClassificationEngine {
  ClassificationMetadata classify({
    required String input,
    required ClassificationSettings settings,
    required List<CategoryConfig> categories,
    required List<ClassificationRule> rules,
    required List<VocabularyAlias> aliases,
    DateTime? now,
  });
}

class DefaultClassificationEngine implements ClassificationEngine {
  const DefaultClassificationEngine({
    required UserRuleResolver ruleResolver,
    required HeuristicClassifier heuristicClassifier,
    required ConfidenceScorer confidenceScorer,
  })  : _ruleResolver = ruleResolver,
        _heuristicClassifier = heuristicClassifier,
        _confidenceScorer = confidenceScorer;

  final UserRuleResolver _ruleResolver;
  final HeuristicClassifier _heuristicClassifier;
  final ConfidenceScorer _confidenceScorer;

  @override
  ClassificationMetadata classify({
    required String input,
    required ClassificationSettings settings,
    required List<CategoryConfig> categories,
    required List<ClassificationRule> rules,
    required List<VocabularyAlias> aliases,
    DateTime? now,
  }) {
    final normalized = normalizeClassificationText(input);
    final timestamp = now ?? DateTime.now();
    final resolution = _ruleResolver.resolve(
      normalizedInput: normalized,
      rules: rules,
      aliases: settings.useVocabularyAliases ? aliases : const [],
    );
    final heuristics = _heuristicClassifier.classify(
      normalizedInput: normalized,
      categories: categories,
      settings: settings,
    );

    final resolvedKind = _resolveKind(
      resolution: resolution,
      heuristics: heuristics,
      settings: settings,
    );
    final resolvedHorizon = resolution.timeHorizon ?? heuristics.timeHorizon;
    final resolvedEnergy = resolution.energyLevel ?? heuristics.energyLevel;
    final resolvedPriority =
        resolution.priorityLevel ?? heuristics.priorityLevel;
    final resolvedCategoryId = resolution.categoryId ??
        heuristics.categoryId ??
        settings.defaultCategoryId;

    final source = _resolveSource(
      resolution: resolution,
      heuristics: heuristics,
      categoryId: resolvedCategoryId,
    );

    final matchedKeywords = <String>{
      ...resolution.matchedKeywords,
      ...heuristics.extractedTags,
    }.toList(growable: false);

    final reasons = <String>[
      ...resolution.reasons,
      ...heuristics.reasons,
      if (resolvedCategoryId == settings.defaultCategoryId &&
          settings.defaultCategoryId != null &&
          resolution.categoryId == null &&
          heuristics.categoryId == null)
        'Se aplicó la categoría por defecto.',
    ];

    final score = _confidenceScorer.score(
      ClassificationConfidenceInput(
        source: source,
        heuristicSignalCount: heuristics.signalCount,
        matchedKeywordCount: matchedKeywords.length,
        hasCategory: resolvedCategoryId != null,
        hasKind: resolvedKind != EntryKind.task || resolution.entryKind != null,
        hasHorizon: resolution.timeHorizon != null ||
            heuristics.timeHorizon != heuristics.fallbackHorizon,
        hasEnergy: resolution.energyLevel != null ||
            heuristics.energyLevel != heuristics.fallbackEnergy,
        hasPriority: resolution.priorityLevel != null ||
            heuristics.priorityLevel != heuristics.fallbackPriority,
      ),
    );
    final level = _confidenceScorer.levelFor(score, settings);

    return ClassificationMetadata(
      inputText: input,
      normalizedText: normalized,
      categoryId: resolvedCategoryId,
      entryKind: resolvedKind,
      timeHorizon: resolvedHorizon,
      energyLevel: resolvedEnergy,
      priorityLevel: resolvedPriority,
      confidenceScore: score,
      confidenceLevel: level,
      classifierVersion: settings.classifierVersion,
      source: source,
      matchedRuleId: resolution.matchedRuleId,
      matchedAliasId: resolution.matchedAliasId,
      matchedKeywords: matchedKeywords,
      signals: <String>[
        ...resolution.reasons,
        ...heuristics.reasons,
      ],
      appliedRuleIds: resolution.matchedRuleId == null
          ? const <String>[]
          : <String>[resolution.matchedRuleId!],
      suggestedCategoryId: heuristics.categoryId,
      confidenceReason: _confidenceScorer.reasonFor(
        source: source,
        level: level,
        heuristicSignalCount: heuristics.signalCount,
      ),
      reasons: reasons,
      isAutoClassified: true,
      classifiedAt: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  EntryKind _resolveKind({
    required UserRuleResolution resolution,
    required HeuristicClassification heuristics,
    required ClassificationSettings settings,
  }) {
    final heuristicKind = settings.detectHabits
        ? heuristics.entryKind
        : (heuristics.entryKind == EntryKind.habit
            ? EntryKind.task
            : heuristics.entryKind);
    final resolved = resolution.entryKind ?? heuristicKind;
    if (!settings.detectHabits && resolved == EntryKind.habit) {
      return EntryKind.task;
    }
    return resolved;
  }

  ClassificationSource _resolveSource({
    required UserRuleResolution resolution,
    required HeuristicClassification heuristics,
    required String? categoryId,
  }) {
    if (resolution.source != null) {
      return resolution.source!;
    }
    if (heuristics.signalCount >= 2 || categoryId != null) {
      return ClassificationSource.heuristic;
    }
    return ClassificationSource.fallback;
  }
}

String normalizeClassificationText(String rawText) {
  final collapsed = rawText.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
  const replacements = <String, String>{
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };

  final buffer = StringBuffer();
  for (final rune in collapsed.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(replacements[char] ?? char);
  }
  return buffer.toString();
}
