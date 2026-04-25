import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/classification/domain/entities/classification_rule.dart';
import 'package:eisen/features/classification/domain/entities/rule_suggestion.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/rule_match_type.dart';
import 'package:eisen/features/classification/domain/enums/rule_priority.dart';

class SuggestionEngine {
  const SuggestionEngine();

  List<RuleSuggestion> suggestRules(
    List<ClassificationCorrectionEvent> corrections, {
    List<ClassificationRule> existingRules = const <ClassificationRule>[],
  }) {
    final grouped = <String, List<_SuggestionCandidate>>{};
    for (final correction in corrections) {
      final correctedCategoryId = correction.correctedCategoryId;
      if (correctedCategoryId == null ||
          correctedCategoryId == correction.originalCategoryId) {
        continue;
      }

      final token = (correction.detectedKeyword ??
              _extractRelevantToken(
                correction.rawText,
              ))
          ?.trim()
          .toLowerCase();
      if (token == null || token.isEmpty) continue;

      final key =
          '$token::$correctedCategoryId::${correction.correctedKind?.name ?? 'none'}';
      grouped.putIfAbsent(key, () => <_SuggestionCandidate>[]).add(
            _SuggestionCandidate(
              token: token,
              correctedCategoryId: correctedCategoryId,
              correctedKind: correction.correctedKind,
              correction: correction,
            ),
          );
    }

    final suggestions = <RuleSuggestion>[];
    final sortedGroups = grouped.values.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final group in sortedGroups) {
      if (group.length < 3) continue;
      final first = group.first;
      if (_equivalentRuleExists(existingRules, first)) continue;

      final latest = group.map((item) => item.correction).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final reference = latest.first;

      final confidence = (0.45 + (group.length * 0.08)).clamp(0.0, 0.96);
      suggestions.add(
        RuleSuggestion(
          id: 'suggested-${first.correctedCategoryId}-${first.token}',
          detectedPattern: first.token,
          suggestedRule: ClassificationRule(
            id: 'rule-suggested-${first.correctedCategoryId}-${first.token}',
            name: 'Sugerencia para "${first.token}"',
            description:
                'Generada por ${group.length} correcciones repetidas del mismo término.',
            keywords: <String>[first.token],
            matchType: RuleMatchType.contains,
            targetCategoryId: first.correctedCategoryId,
            targetKind: first.correctedKind,
            targetHorizon: reference.correctedClassification?.timeHorizon,
            targetEnergy: reference.correctedClassification?.energyLevel,
            targetPriority: reference.correctedClassification?.priorityLevel,
            targetTags: <String>[first.token],
            priority: RulePriority.high,
            scoreBoost: 0.24,
          ),
          confidence: confidence.toDouble(),
          createdAt: reference.createdAt,
        ),
      );
      if (suggestions.length == 6) break;
    }

    return suggestions;
  }

  bool _equivalentRuleExists(
    List<ClassificationRule> existingRules,
    _SuggestionCandidate candidate,
  ) {
    for (final rule in existingRules.where((item) => item.isEnabled)) {
      final sameKeyword = rule.keywords.any(
        (keyword) => keyword.trim().toLowerCase() == candidate.token,
      );
      if (!sameKeyword) continue;
      if (rule.targetCategoryId != candidate.correctedCategoryId) continue;
      if (rule.targetKind != candidate.correctedKind) continue;
      return true;
    }
    return false;
  }

  String? _extractRelevantToken(String input) {
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
            'esta',
            'semana',
          }.contains(item),
        )
        .toList();
    if (tokens.isEmpty) return null;
    return tokens.first;
  }
}

class _SuggestionCandidate {
  const _SuggestionCandidate({
    required this.token,
    required this.correctedCategoryId,
    required this.correctedKind,
    required this.correction,
  });

  final String token;
  final String correctedCategoryId;
  final EntryKind? correctedKind;
  final ClassificationCorrectionEvent correction;
}
