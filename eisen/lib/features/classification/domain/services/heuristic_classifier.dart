import 'package:eisen/features/classification/domain/classification_result.dart';
import 'package:eisen/features/classification/domain/classification_vocabulary.dart';
import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';

class HeuristicClassification {
  const HeuristicClassification({
    required this.result,
    required this.entryKind,
    required this.timeHorizon,
    required this.energyLevel,
    required this.priorityLevel,
    required this.extractedTags,
    required this.matchedKeywords,
    required this.confidenceLevel,
    required this.confidenceReason,
    required this.reasons,
    this.categoryId,
    this.categoryLabel,
  });

  final ClassificationResult result;
  final String? categoryId;
  final String? categoryLabel;
  final EntryKind entryKind;
  final TimeHorizon timeHorizon;
  final EnergyLevel energyLevel;
  final PriorityLevel priorityLevel;
  final List<String> extractedTags;
  final List<String> matchedKeywords;
  final ConfidenceLevel confidenceLevel;
  final String confidenceReason;
  final List<String> reasons;

  TimeHorizon get fallbackHorizon => EntryKind.idea == entryKind
      ? TimeHorizon.someday
      : (entryKind == EntryKind.habit
          ? TimeHorizon.thisMonth
          : TimeHorizon.thisWeek);

  EnergyLevel get fallbackEnergy => entryKind == EntryKind.shoppingItem
      ? EnergyLevel.low
      : EnergyLevel.medium;
  PriorityLevel get fallbackPriority =>
      entryKind == EntryKind.idea ? PriorityLevel.low : PriorityLevel.medium;

  int get signalCount {
    var total = reasons.length;
    if (categoryId != null) total += 1;
    if (extractedTags.isNotEmpty) total += 1;
    total += matchedKeywords.length;
    return total;
  }
}

class HeuristicClassifier {
  const HeuristicClassifier();

  static final RegExp _tokenPattern = RegExp(r'[a-z0-9]+');

  HeuristicClassification classify({
    required String normalizedInput,
    required List<CategoryConfig> categories,
    required ClassificationSettings settings,
  }) {
    final tokens = _tokenPattern
        .allMatches(normalizedInput)
        .map((match) => match.group(0)!)
        .toSet();
    final vocabularyMatch = ClassificationVocabulary.bestMatch(
      normalizedInput,
      tokens,
    );
    final categoryResolution = _inferCategory(
      normalizedInput,
      categories,
      vocabularyMatch: vocabularyMatch,
      tokens: tokens,
    );
    final kind = inferKind(
      normalizedInput,
      detectHabits: settings.detectHabits,
      vocabularyMatch: vocabularyMatch,
    );
    final horizon = inferHorizon(
      normalizedInput,
      inferredKind: kind,
      vocabularyMatch: vocabularyMatch,
    );
    final energy = inferEnergy(
      normalizedInput,
      inferredKind: kind,
      vocabularyMatch: vocabularyMatch,
    );
    final priority = inferPriority(
      normalizedInput,
      inferredKind: kind,
      inferredHorizon: horizon,
      inferredEnergy: energy,
      vocabularyMatch: vocabularyMatch,
    );
    final confidence = inferConfidence(
      normalizedInput,
      vocabularyMatch: vocabularyMatch,
      kind: kind,
      horizon: horizon,
      priority: priority,
      categoryId: categoryResolution.id,
    );
    final matchedKeywords =
        vocabularyMatch?.matchedKeywords ?? const <String>[];
    final tags = extractTags(
      normalizedInput,
      vocabularyMatch: vocabularyMatch,
      matchedKeywords: matchedKeywords,
    );
    final confidenceReason = _confidenceReason(
      confidence,
      vocabularyMatch: vocabularyMatch,
      matchedKeywords: matchedKeywords,
    );
    final reasons = <String>[
      if (categoryResolution.id != null)
        'Coincidencia heurística con categoría ${categoryResolution.label ?? categoryResolution.id}.',
      if (matchedKeywords.isNotEmpty)
        'Keywords detectadas: ${matchedKeywords.join(', ')}.',
      ..._kindReasons(normalizedInput, kind),
      ..._horizonReasons(normalizedInput, horizon),
      ..._energyReasons(normalizedInput, energy),
      ..._priorityReasons(normalizedInput, priority),
    ];
    final result = ClassificationResult(
      kind: kind,
      category: categoryResolution.label,
      horizon: horizon,
      energy: energy,
      priority: priority,
      confidence: confidence,
      autoTags: tags,
      matchedKeywords: matchedKeywords,
      confidenceReason: confidenceReason,
    );

    return HeuristicClassification(
      result: result,
      categoryId: categoryResolution.id,
      categoryLabel: categoryResolution.label,
      entryKind: kind,
      timeHorizon: horizon,
      energyLevel: energy,
      priorityLevel: priority,
      extractedTags: tags,
      matchedKeywords: matchedKeywords,
      confidenceLevel: confidence,
      confidenceReason: confidenceReason,
      reasons: reasons,
    );
  }

  EntryKind inferKind(
    String input, {
    bool detectHabits = true,
    ClassificationVocabularyMatch? vocabularyMatch,
  }) {
    final profile = vocabularyMatch?.profile;
    if (profile == ClassificationVocabulary.shopping) {
      return EntryKind.shoppingItem;
    }
    if (profile == ClassificationVocabulary.finance) {
      return _hasDateCue(input) || input.contains('pagar')
          ? EntryKind.reminder
          : EntryKind.task;
    }
    if (profile == ClassificationVocabulary.health) {
      return detectHabits &&
              (input.contains('rutina') ||
                  input.contains('cada ') ||
                  input.contains('correr') ||
                  input.contains('entrenar') ||
                  input.contains('caminar'))
          ? EntryKind.habit
          : EntryKind.task;
    }
    if (profile == ClassificationVocabulary.ideas) {
      return EntryKind.idea;
    }
    if (input.contains('idea') ||
        input.contains('concepto') ||
        input.contains('boceto')) {
      return EntryKind.idea;
    }
    if (input.contains('proyecto') ||
        input.contains('lanzamiento') ||
        input.contains('roadmap') ||
        input.contains('plan ')) {
      return EntryKind.project;
    }
    if (input.contains('recordar') ||
        input.contains('pagar') ||
        input.contains('viernes') ||
        input.contains('manana') ||
        input.contains('mañana')) {
      return EntryKind.reminder;
    }
    if (detectHabits &&
        (input.contains('quiero empezar') ||
            input.contains('cada ') ||
            input.contains('rutina') ||
            input.contains('habito') ||
            input.contains('hábito'))) {
      return EntryKind.habit;
    }
    return EntryKind.task;
  }

  _CategoryInference _inferCategory(
    String input,
    List<CategoryConfig> categories, {
    ClassificationVocabularyMatch? vocabularyMatch,
    Set<String>? tokens,
  }) {
    final tokenSet = tokens ??
        _tokenPattern.allMatches(input).map((match) => match.group(0)!).toSet();
    final vocabularyCategoryId = _resolveVocabularyCategoryId(
      vocabularyMatch,
      categories,
    );
    if (vocabularyCategoryId != null) {
      return _CategoryInference(
        id: vocabularyCategoryId,
        label: vocabularyMatch?.profile.categoryLabel,
      );
    }

    String? bestCategoryId;
    String? bestCategoryLabel;
    double bestScore = 0;
    for (final category in categories.where((item) => !item.isHidden)) {
      var score = 0.0;
      final normalizedName = category.name.toLowerCase();
      if (input.contains(normalizedName)) {
        score += 0.75;
      }
      for (final alias in category.aliases) {
        final normalizedAlias = alias.trim().toLowerCase();
        if (normalizedAlias.isEmpty) continue;
        if (tokenSet.contains(normalizedAlias)) {
          score += 0.45;
        } else if (input.contains(normalizedAlias)) {
          score += 0.25;
        }
      }
      for (final keyword in category.keywords) {
        final normalizedKeyword = keyword.trim().toLowerCase();
        if (normalizedKeyword.isEmpty) continue;
        if (tokenSet.contains(normalizedKeyword)) {
          score += 0.4;
        } else if (input.contains(normalizedKeyword)) {
          score += 0.2;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategoryId = category.id;
        bestCategoryLabel = category.name;
      }
    }

    if (bestScore < 0.4) {
      return const _CategoryInference();
    }
    return _CategoryInference(id: bestCategoryId, label: bestCategoryLabel);
  }

  TimeHorizon inferHorizon(
    String input, {
    EntryKind? inferredKind,
    ClassificationVocabularyMatch? vocabularyMatch,
  }) {
    if (input.contains('hoy') || input.contains('ahora')) {
      return TimeHorizon.today;
    }
    if (input.contains('manana') ||
        input.contains('mañana') ||
        input.contains('viernes') ||
        input.contains('esta semana')) {
      return TimeHorizon.thisWeek;
    }
    if (input.contains('este mes') ||
        input.contains('proximo mes') ||
        input.contains('proximo')) {
      return TimeHorizon.thisMonth;
    }
    if (vocabularyMatch?.profile == ClassificationVocabulary.ideas) {
      return TimeHorizon.someday;
    }
    if (vocabularyMatch?.profile == ClassificationVocabulary.health &&
        inferredKind == EntryKind.habit) {
      return TimeHorizon.thisMonth;
    }
    if (inferredKind == EntryKind.habit) return TimeHorizon.thisMonth;
    if (inferredKind == EntryKind.idea) return TimeHorizon.someday;
    return TimeHorizon.thisWeek;
  }

  EnergyLevel inferEnergy(
    String input, {
    EntryKind? inferredKind,
    ClassificationVocabularyMatch? vocabularyMatch,
  }) {
    if (vocabularyMatch?.profile == ClassificationVocabulary.shopping ||
        vocabularyMatch?.profile == ClassificationVocabulary.finance) {
      return EnergyLevel.low;
    }
    if (vocabularyMatch?.profile == ClassificationVocabulary.workArchitecture) {
      return EnergyLevel.high;
    }
    if (vocabularyMatch?.profile == ClassificationVocabulary.health) {
      if (input.contains('caminar')) {
        return EnergyLevel.medium;
      }
      return EnergyLevel.high;
    }
    if (inferredKind == EntryKind.shoppingItem) {
      return EnergyLevel.low;
    }
    if (input.contains('terminar') ||
        input.contains('disenar') ||
        input.contains('diseñar') ||
        input.contains('cliente') ||
        input.contains('presentacion') ||
        input.contains('renders')) {
      return EnergyLevel.high;
    }
    if (input.contains('comprar') ||
        input.contains('pagar') ||
        input.contains('mandado') ||
        input.contains('llamar')) {
      return EnergyLevel.low;
    }
    return EnergyLevel.medium;
  }

  PriorityLevel inferPriority(
    String input, {
    EntryKind? inferredKind,
    TimeHorizon? inferredHorizon,
    EnergyLevel? inferredEnergy,
    ClassificationVocabularyMatch? vocabularyMatch,
  }) {
    if (input.contains('urgente') ||
        input.contains('asap') ||
        input.contains('hoy')) {
      return PriorityLevel.critical;
    }
    if (vocabularyMatch?.profile == ClassificationVocabulary.workArchitecture &&
        (input.contains('cliente') ||
            input.contains('entrega') ||
            input.contains('cotizacion') ||
            input.contains('presupuesto'))) {
      return PriorityLevel.high;
    }
    if (vocabularyMatch?.profile == ClassificationVocabulary.finance &&
        _hasDateCue(input)) {
      return PriorityLevel.high;
    }
    if (inferredKind == EntryKind.shoppingItem && _hasDateCue(input)) {
      return PriorityLevel.high;
    }
    if (inferredHorizon == TimeHorizon.today ||
        input.contains('viernes') ||
        input.contains('cliente') ||
        inferredEnergy == EnergyLevel.high) {
      return PriorityLevel.high;
    }
    if (inferredKind == EntryKind.idea) return PriorityLevel.low;
    return PriorityLevel.medium;
  }

  ConfidenceLevel inferConfidence(
    String input, {
    required ClassificationVocabularyMatch? vocabularyMatch,
    required EntryKind kind,
    required TimeHorizon horizon,
    required PriorityLevel priority,
    required String? categoryId,
  }) {
    final matchCount = vocabularyMatch?.matchedKeywords.length ?? 0;
    if (vocabularyMatch?.profile == ClassificationVocabulary.shopping &&
        matchCount >= 1) {
      return ConfidenceLevel.high;
    }
    if (vocabularyMatch?.profile == ClassificationVocabulary.workArchitecture) {
      return matchCount >= 2 ? ConfidenceLevel.high : ConfidenceLevel.medium;
    }
    if (vocabularyMatch?.profile == ClassificationVocabulary.finance) {
      if (matchCount >= 2 || _hasDateCue(input)) {
        return ConfidenceLevel.high;
      }
      return ConfidenceLevel.medium;
    }
    if (vocabularyMatch != null) {
      return vocabularyMatch.isStrong
          ? vocabularyMatch.profile.baseConfidence
          : ConfidenceLevel.medium;
    }
    if (categoryId != null &&
        (kind == EntryKind.idea || horizon == TimeHorizon.today)) {
      return ConfidenceLevel.medium;
    }
    if (priority == PriorityLevel.critical) {
      return ConfidenceLevel.medium;
    }
    return ConfidenceLevel.low;
  }

  List<String> extractTags(
    String input, {
    ClassificationVocabularyMatch? vocabularyMatch,
    List<String> matchedKeywords = const <String>[],
  }) {
    final stopWords = <String>{
      'para',
      'quiero',
      'empezar',
      'terminar',
      'esta',
      'este',
      'hoy',
      'ahora',
      'manana',
      'viernes',
      'tarea',
    };

    final tags = <String>{};
    if (vocabularyMatch != null) {
      tags.addAll(vocabularyMatch.profile.autoTags);
    }
    for (final keyword in matchedKeywords) {
      if (keyword.length >= 4) {
        tags.add(keyword);
      }
      if (tags.length >= 3) {
        return tags.take(3).toList(growable: false);
      }
    }
    for (final match in _tokenPattern.allMatches(input)) {
      final token = match.group(0)!;
      if (token.length < 4 || stopWords.contains(token)) continue;
      tags.add(token);
      if (tags.length == 3) break;
    }
    return tags.toList(growable: false);
  }

  List<String> _kindReasons(String input, EntryKind kind) {
    switch (kind) {
      case EntryKind.shoppingItem:
        return const ['El texto parece una compra concreta.'];
      case EntryKind.idea:
        return const ['El texto se parece a una idea abierta.'];
      case EntryKind.habit:
        return const ['El texto describe un hábito o rutina.'];
      case EntryKind.project:
        return const ['El texto apunta a una iniciativa más grande.'];
      case EntryKind.reminder:
        return const ['El texto parece un recordatorio puntual.'];
      case EntryKind.task:
        return input.isEmpty ? const [] : const ['Se interpreta como tarea.'];
    }
  }

  List<String> _horizonReasons(String input, TimeHorizon horizon) {
    switch (horizon) {
      case TimeHorizon.today:
        return const ['Se detectó una referencia inmediata.'];
      case TimeHorizon.thisWeek:
        return input.contains('viernes') ||
                input.contains('manana') ||
                input.contains('mañana')
            ? const ['Se detectó una referencia de esta semana.']
            : const [];
      case TimeHorizon.thisMonth:
        return const ['El horizonte sugerido es mensual.'];
      case TimeHorizon.someday:
        return const ['La entrada parece exploratoria o sin fecha.'];
    }
  }

  List<String> _energyReasons(String input, EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.high:
        return const ['La acción parece cognitivamente exigente.'];
      case EnergyLevel.low:
        return const ['La acción parece rápida o ligera.'];
      case EnergyLevel.medium:
        return input.isEmpty ? const [] : const [];
    }
  }

  List<String> _priorityReasons(String input, PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.critical:
        return const ['Hay señales de urgencia explícita.'];
      case PriorityLevel.high:
        return const ['Hay señales de prioridad alta.'];
      case PriorityLevel.medium:
        return const [];
      case PriorityLevel.low:
        return const ['La entrada puede esperar.'];
    }
  }

  String _confidenceReason(
    ConfidenceLevel confidence, {
    required ClassificationVocabularyMatch? vocabularyMatch,
    required List<String> matchedKeywords,
  }) {
    if (vocabularyMatch != null && matchedKeywords.isNotEmpty) {
      return 'Clasificada como ${vocabularyMatch.profile.categoryLabel} porque contiene ${matchedKeywords.join(', ')}.';
    }
    return switch (confidence) {
      ConfidenceLevel.high => 'La entrada tiene señales claras y consistentes.',
      ConfidenceLevel.medium =>
        'La entrada tiene señales útiles pero todavía generales.',
      ConfidenceLevel.low =>
        'La entrada tiene pocas señales y conviene revisarla.',
    };
  }

  String? _resolveVocabularyCategoryId(
    ClassificationVocabularyMatch? vocabularyMatch,
    List<CategoryConfig> categories,
  ) {
    if (vocabularyMatch == null) {
      return null;
    }
    for (final preferredId in vocabularyMatch.profile.preferredCategoryIds) {
      for (final category in categories) {
        if (category.id == preferredId) {
          return category.id;
        }
      }
    }
    for (final category in categories) {
      if (category.name.toLowerCase() ==
          vocabularyMatch.profile.categoryLabel.toLowerCase()) {
        return category.id;
      }
      if (category.aliases.any(
        (alias) =>
            alias.trim().toLowerCase() ==
            vocabularyMatch.profile.categoryLabel.toLowerCase(),
      )) {
        return category.id;
      }
    }
    return null;
  }

  bool _hasDateCue(String input) {
    return input.contains('hoy') ||
        input.contains('ahora') ||
        input.contains('manana') ||
        input.contains('mañana') ||
        input.contains('viernes') ||
        input.contains('lunes') ||
        input.contains('martes') ||
        input.contains('miercoles') ||
        input.contains('miércoles') ||
        input.contains('jueves') ||
        input.contains('sabado') ||
        input.contains('sábado') ||
        input.contains('domingo') ||
        input.contains('esta semana');
  }
}

class _CategoryInference {
  const _CategoryInference({
    this.id,
    this.label,
  });

  final String? id;
  final String? label;
}
