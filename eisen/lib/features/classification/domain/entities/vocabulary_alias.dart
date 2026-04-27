import 'package:eisen/features/classification/domain/enums/alias_type.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/foundation.dart';

@immutable
class VocabularyAlias {
  const VocabularyAlias({
    required this.id,
    required this.term,
    required this.normalizedTerm,
    this.type = AliasType.generic,
    this.mappedCategoryId,
    this.mappedKind,
    this.aliases = const <String>[],
    this.timeHorizon,
    this.energyLevel,
    this.priorityLevel,
    this.suggestedQuadrant,
    this.enabled = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String term;
  final String normalizedTerm;
  final AliasType type;
  final List<String> aliases;
  final String? mappedCategoryId;
  final EntryKind? mappedKind;
  final TimeHorizon? timeHorizon;
  final EnergyLevel? energyLevel;
  final PriorityLevel? priorityLevel;
  final Quadrant? suggestedQuadrant;
  final bool enabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get canonicalValue => term;
  String? get categoryId => mappedCategoryId;
  EntryKind? get entryKind => mappedKind;
  bool get isEnabled => enabled;
  List<String> get searchTerms => <String>{
        normalizedTerm.toLowerCase(),
        term.toLowerCase(),
        ...aliases.map((item) => item.toLowerCase()),
      }.toList();

  VocabularyAlias copyWith({
    String? id,
    String? term,
    String? normalizedTerm,
    AliasType? type,
    List<String>? aliases,
    String? mappedCategoryId,
    EntryKind? mappedKind,
    TimeHorizon? timeHorizon,
    EnergyLevel? energyLevel,
    PriorityLevel? priorityLevel,
    Quadrant? suggestedQuadrant,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VocabularyAlias(
      id: id ?? this.id,
      term: term ?? this.term,
      normalizedTerm: normalizedTerm ?? this.normalizedTerm,
      type: type ?? this.type,
      aliases: aliases ?? this.aliases,
      mappedCategoryId: mappedCategoryId ?? this.mappedCategoryId,
      mappedKind: mappedKind ?? this.mappedKind,
      timeHorizon: timeHorizon ?? this.timeHorizon,
      energyLevel: energyLevel ?? this.energyLevel,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      suggestedQuadrant: suggestedQuadrant ?? this.suggestedQuadrant,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VocabularyAliasDefaults {
  const VocabularyAliasDefaults._();

  static const values = <VocabularyAlias>[
    VocabularyAlias(
      id: 'alias-errands-shopping',
      term: 'compras',
      normalizedTerm: 'compras',
      type: AliasType.category,
      aliases: <String>['comprar', 'super', 'leche', 'mercado'],
      mappedCategoryId: 'errands',
      mappedKind: EntryKind.shoppingItem,
      timeHorizon: TimeHorizon.today,
      energyLevel: EnergyLevel.low,
      priorityLevel: PriorityLevel.medium,
    ),
    VocabularyAlias(
      id: 'alias-work-client',
      term: 'cliente',
      normalizedTerm: 'cliente',
      type: AliasType.client,
      aliases: <String>['cliente', 'renders', 'entrega', 'feedback'],
      mappedCategoryId: 'work',
      mappedKind: EntryKind.task,
      timeHorizon: TimeHorizon.thisWeek,
      energyLevel: EnergyLevel.high,
      priorityLevel: PriorityLevel.high,
    ),
    VocabularyAlias(
      id: 'alias-ideas-creative',
      term: 'idea',
      normalizedTerm: 'idea',
      type: AliasType.category,
      aliases: <String>['idea', 'concepto', 'home', 'landing'],
      mappedCategoryId: 'ideas',
      mappedKind: EntryKind.idea,
      timeHorizon: TimeHorizon.someday,
      energyLevel: EnergyLevel.medium,
      priorityLevel: PriorityLevel.low,
    ),
    VocabularyAlias(
      id: 'alias-health-running',
      term: 'correr',
      normalizedTerm: 'correr',
      type: AliasType.category,
      aliases: <String>['correr', 'running', 'entrenar'],
      mappedCategoryId: 'health',
      mappedKind: EntryKind.habit,
      timeHorizon: TimeHorizon.thisMonth,
      energyLevel: EnergyLevel.medium,
      priorityLevel: PriorityLevel.medium,
    ),
    VocabularyAlias(
      id: 'alias-finance-payments',
      term: 'pagar',
      normalizedTerm: 'pagar',
      type: AliasType.category,
      aliases: <String>['pagar', 'tarjeta', 'factura', 'transferencia'],
      mappedCategoryId: 'finance',
      mappedKind: EntryKind.reminder,
      timeHorizon: TimeHorizon.thisWeek,
      energyLevel: EnergyLevel.low,
      priorityLevel: PriorityLevel.high,
    ),
  ];
}
