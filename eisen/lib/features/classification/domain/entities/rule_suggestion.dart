import 'package:eisen/features/classification/domain/entities/classification_rule.dart';
import 'package:eisen/features/classification/domain/enums/rule_match_type.dart';
import 'package:eisen/features/classification/domain/enums/suggestion_status.dart';
import 'package:flutter/foundation.dart';

@immutable
class RuleSuggestion {
  const RuleSuggestion({
    required this.id,
    required this.detectedPattern,
    required this.suggestedRule,
    required this.confidence,
    this.status = SuggestionStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String detectedPattern;
  final ClassificationRule suggestedRule;
  final double confidence;
  final SuggestionStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get name => suggestedRule.name;
  String get description => suggestedRule.description ?? '';
  String get pattern => suggestedRule.pattern;
  String? get categoryId => suggestedRule.categoryId;
  RuleMatchType get matchType => suggestedRule.matchType;
  bool get isPending => status == SuggestionStatus.pending;

  RuleSuggestion copyWith({
    String? id,
    String? detectedPattern,
    ClassificationRule? suggestedRule,
    double? confidence,
    SuggestionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RuleSuggestion(
      id: id ?? this.id,
      detectedPattern: detectedPattern ?? this.detectedPattern,
      suggestedRule: suggestedRule ?? this.suggestedRule,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
