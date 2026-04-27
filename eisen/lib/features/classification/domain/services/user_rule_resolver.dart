import 'package:eisen/features/classification/domain/entities/classification_rule.dart';
import 'package:eisen/features/classification/domain/entities/vocabulary_alias.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/rule_match_type.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

class UserRuleResolution {
  const UserRuleResolution({
    this.source,
    this.categoryId,
    this.entryKind,
    this.timeHorizon,
    this.energyLevel,
    this.priorityLevel,
    this.suggestedQuadrant,
    this.matchedRuleId,
    this.matchedAliasId,
    this.matchedKeywords = const <String>[],
    this.reasons = const <String>[],
  });

  final ClassificationSource? source;
  final String? categoryId;
  final EntryKind? entryKind;
  final TimeHorizon? timeHorizon;
  final EnergyLevel? energyLevel;
  final PriorityLevel? priorityLevel;
  final Quadrant? suggestedQuadrant;
  final String? matchedRuleId;
  final String? matchedAliasId;
  final List<String> matchedKeywords;
  final List<String> reasons;

  bool get hasRuleMatch => matchedRuleId != null;
  bool get hasAliasMatch => matchedAliasId != null;
}

class UserRuleResolver {
  const UserRuleResolver();

  UserRuleResolution resolve({
    required String normalizedInput,
    required List<ClassificationRule> rules,
    required List<VocabularyAlias> aliases,
  }) {
    final ruleResolution = _resolveRule(normalizedInput, rules);
    if (ruleResolution != null) return ruleResolution;

    final aliasResolution = _resolveAlias(normalizedInput, aliases);
    if (aliasResolution != null) return aliasResolution;

    return const UserRuleResolution();
  }

  UserRuleResolution? _resolveRule(
    String input,
    List<ClassificationRule> rules,
  ) {
    final activeRules = rules.where((item) => item.isEnabled).toList()
      ..sort((a, b) => b.priority.weight.compareTo(a.priority.weight));

    for (final rule in activeRules) {
      final matchedKeywords = _matchedKeywordsForRule(input, rule);
      if (matchedKeywords.isEmpty) continue;
      return UserRuleResolution(
        source: ClassificationSource.rule,
        categoryId: rule.targetCategoryId,
        entryKind: rule.targetKind,
        timeHorizon: rule.targetHorizon,
        energyLevel: rule.targetEnergy,
        priorityLevel: rule.targetPriority,
        suggestedQuadrant: rule.targetQuadrant,
        matchedRuleId: rule.id,
        matchedKeywords: <String>[
          ...matchedKeywords,
          ...rule.targetTags.where((item) => item.trim().isNotEmpty),
        ],
        reasons: <String>['Regla activa "${rule.name}" aplicada.'],
      );
    }

    return null;
  }

  UserRuleResolution? _resolveAlias(
    String input,
    List<VocabularyAlias> aliases,
  ) {
    VocabularyAlias? bestAlias;
    List<String> bestHits = const [];

    for (final alias in aliases.where((item) => item.isEnabled)) {
      final hits = alias.searchTerms
          .where((term) => term.isNotEmpty && input.contains(term))
          .toSet()
          .toList(growable: false);
      if (hits.isEmpty) continue;
      if (hits.length > bestHits.length) {
        bestAlias = alias;
        bestHits = hits;
        continue;
      }
      if (hits.length == bestHits.length &&
          bestAlias != null &&
          alias.normalizedTerm.length > bestAlias.normalizedTerm.length) {
        bestAlias = alias;
        bestHits = hits;
      }
    }

    if (bestAlias == null) return null;
    return UserRuleResolution(
      source: ClassificationSource.alias,
      categoryId: bestAlias.mappedCategoryId,
      entryKind: bestAlias.mappedKind,
      timeHorizon: bestAlias.timeHorizon,
      energyLevel: bestAlias.energyLevel,
      priorityLevel: bestAlias.priorityLevel,
      suggestedQuadrant: bestAlias.suggestedQuadrant,
      matchedAliasId: bestAlias.id,
      matchedKeywords: bestHits,
      reasons: <String>[
        'Alias reconocido: ${bestHits.join(', ')}.',
      ],
    );
  }

  List<String> _matchedKeywordsForRule(
    String input,
    ClassificationRule rule,
  ) {
    final hits = <String>[];
    for (final keyword in rule.keywords) {
      final pattern = keyword.trim().toLowerCase();
      if (pattern.isEmpty) continue;
      final matched = switch (rule.matchType) {
        RuleMatchType.contains => input.contains(pattern),
        RuleMatchType.startsWith => input.startsWith(pattern),
        RuleMatchType.equals => input == pattern,
        RuleMatchType.regex => RegExp(pattern).hasMatch(input),
      };
      if (matched) {
        hits.add(pattern);
      }
    }
    return hits;
  }
}
