import 'package:eisen/features/classification/data/models/classification_rule_model.dart';
import 'package:eisen/features/classification/domain/entities/rule_suggestion.dart';
import 'package:eisen/features/classification/domain/enums/suggestion_status.dart';

class RuleSuggestionModel extends RuleSuggestion {
  const RuleSuggestionModel({
    required super.id,
    required super.detectedPattern,
    required super.suggestedRule,
    required super.confidence,
    super.status,
    required super.createdAt,
    super.updatedAt,
  });

  factory RuleSuggestionModel.fromEntity(RuleSuggestion entity) {
    return RuleSuggestionModel(
      id: entity.id,
      detectedPattern: entity.detectedPattern,
      suggestedRule: entity.suggestedRule,
      confidence: entity.confidence,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory RuleSuggestionModel.fromJson(Map<String, Object?> json) {
    return RuleSuggestionModel(
      id: json['id'] as String,
      detectedPattern: json['detectedPattern'] as String? ??
          json['pattern'] as String? ??
          '',
      suggestedRule: ClassificationRuleModel.fromJson(
        (json['suggestedRule'] as Map).cast<String, Object?>(),
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      status: _statusFromName(json['status'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'detectedPattern': detectedPattern,
        'suggestedRule':
            ClassificationRuleModel.fromEntity(suggestedRule).toJson(),
        'confidence': confidence,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

SuggestionStatus _statusFromName(String? name) {
  for (final status in SuggestionStatus.values) {
    if (status.name == name) return status;
  }
  return SuggestionStatus.pending;
}
