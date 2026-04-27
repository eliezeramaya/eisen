import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:flutter/foundation.dart';

@immutable
class ClassificationVocabularyProfile {
  const ClassificationVocabularyProfile({
    required this.id,
    required this.categoryLabel,
    required this.preferredCategoryIds,
    required this.keywords,
    required this.baseKind,
    required this.baseHorizon,
    required this.baseEnergy,
    required this.basePriority,
    required this.baseConfidence,
    required this.autoTags,
  });

  final String id;
  final String categoryLabel;
  final List<String> preferredCategoryIds;
  final List<String> keywords;
  final EntryKind baseKind;
  final TimeHorizon baseHorizon;
  final EnergyLevel baseEnergy;
  final PriorityLevel basePriority;
  final ConfidenceLevel baseConfidence;
  final List<String> autoTags;
}

@immutable
class ClassificationVocabularyMatch {
  const ClassificationVocabularyMatch({
    required this.profile,
    required this.matchedKeywords,
  });

  final ClassificationVocabularyProfile profile;
  final List<String> matchedKeywords;

  bool get isStrong => matchedKeywords.length >= 2;
}

class ClassificationVocabulary {
  const ClassificationVocabulary._();

  static const shopping = ClassificationVocabularyProfile(
    id: 'shopping',
    categoryLabel: 'Compras',
    preferredCategoryIds: <String>['errands'],
    keywords: <String>[
      'comprar',
      'super',
      'despensa',
      'leche',
      'papel',
      'farmacia',
      'mercado',
    ],
    baseKind: EntryKind.shoppingItem,
    baseHorizon: TimeHorizon.thisWeek,
    baseEnergy: EnergyLevel.low,
    basePriority: PriorityLevel.medium,
    baseConfidence: ConfidenceLevel.high,
    autoTags: <String>['compras'],
  );

  static const workArchitecture = ClassificationVocabularyProfile(
    id: 'work-architecture',
    categoryLabel: 'Trabajo',
    preferredCategoryIds: <String>['work'],
    keywords: <String>[
      'cliente',
      'obra',
      'render',
      'plano',
      'junta',
      'propuesta',
      'entrega',
      'presupuesto',
      'cotizacion',
    ],
    baseKind: EntryKind.task,
    baseHorizon: TimeHorizon.thisWeek,
    baseEnergy: EnergyLevel.high,
    basePriority: PriorityLevel.medium,
    baseConfidence: ConfidenceLevel.medium,
    autoTags: <String>['trabajo', 'cliente'],
  );

  static const ideas = ClassificationVocabularyProfile(
    id: 'ideas',
    categoryLabel: 'Ideas',
    preferredCategoryIds: <String>['ideas'],
    keywords: <String>[
      'idea',
      'concepto',
      'explorar',
      'probar',
      'investigar',
      'imaginar',
      'experimentar',
    ],
    baseKind: EntryKind.idea,
    baseHorizon: TimeHorizon.someday,
    baseEnergy: EnergyLevel.medium,
    basePriority: PriorityLevel.low,
    baseConfidence: ConfidenceLevel.medium,
    autoTags: <String>['idea'],
  );

  static const health = ClassificationVocabularyProfile(
    id: 'health',
    categoryLabel: 'Salud',
    preferredCategoryIds: <String>['health'],
    keywords: <String>[
      'gym',
      'correr',
      'proteina',
      'rutina',
      'ejercicio',
      'entrenar',
      'caminar',
    ],
    baseKind: EntryKind.habit,
    baseHorizon: TimeHorizon.thisMonth,
    baseEnergy: EnergyLevel.medium,
    basePriority: PriorityLevel.medium,
    baseConfidence: ConfidenceLevel.medium,
    autoTags: <String>['salud'],
  );

  static const finance = ClassificationVocabularyProfile(
    id: 'finance',
    categoryLabel: 'Finanzas',
    preferredCategoryIds: <String>['finance'],
    keywords: <String>[
      'pagar',
      'tarjeta',
      'banco',
      'transferencia',
      'factura',
      'impuesto',
    ],
    baseKind: EntryKind.task,
    baseHorizon: TimeHorizon.thisWeek,
    baseEnergy: EnergyLevel.low,
    basePriority: PriorityLevel.medium,
    baseConfidence: ConfidenceLevel.medium,
    autoTags: <String>['finanzas'],
  );

  static const values = <ClassificationVocabularyProfile>[
    shopping,
    workArchitecture,
    ideas,
    health,
    finance,
  ];

  static ClassificationVocabularyMatch? bestMatch(
    String normalizedInput,
    Set<String> tokens,
  ) {
    ClassificationVocabularyMatch? best;
    for (final profile in values) {
      final hits = <String>{
        for (final keyword in profile.keywords)
          if (tokens.contains(keyword) || normalizedInput.contains(keyword))
            keyword,
      }.toList(growable: false);
      if (hits.isEmpty) {
        continue;
      }
      final candidate = ClassificationVocabularyMatch(
        profile: profile,
        matchedKeywords: [...hits],
      );
      if (best == null ||
          candidate.matchedKeywords.length > best.matchedKeywords.length) {
        best = candidate;
      }
    }
    return best;
  }
}
