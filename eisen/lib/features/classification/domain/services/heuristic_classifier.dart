import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';

class HeuristicClassification {
  const HeuristicClassification({
    required this.entryKind,
    required this.timeHorizon,
    required this.energyLevel,
    required this.priorityLevel,
    required this.extractedTags,
    required this.reasons,
    this.categoryId,
  });

  final String? categoryId;
  final EntryKind entryKind;
  final TimeHorizon timeHorizon;
  final EnergyLevel energyLevel;
  final PriorityLevel priorityLevel;
  final List<String> extractedTags;
  final List<String> reasons;

  TimeHorizon get fallbackHorizon => EntryKind.idea == entryKind
      ? TimeHorizon.someday
      : (entryKind == EntryKind.habit
          ? TimeHorizon.thisMonth
          : TimeHorizon.thisWeek);

  EnergyLevel get fallbackEnergy => EnergyLevel.medium;
  PriorityLevel get fallbackPriority => PriorityLevel.medium;

  int get signalCount {
    var total = reasons.length;
    if (categoryId != null) total += 1;
    if (extractedTags.isNotEmpty) total += 1;
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
    final kind = inferKind(
      normalizedInput,
      detectHabits: settings.detectHabits,
    );
    final categoryId = inferCategory(normalizedInput, categories);
    final horizon = inferHorizon(normalizedInput, inferredKind: kind);
    final energy = inferEnergy(normalizedInput);
    final priority = inferPriority(
      normalizedInput,
      inferredKind: kind,
      inferredHorizon: horizon,
      inferredEnergy: energy,
    );
    final tags = extractTags(normalizedInput);
    final reasons = <String>[
      if (categoryId != null) 'Coincidencia heurística con categoría.',
      ..._kindReasons(normalizedInput, kind),
      ..._horizonReasons(normalizedInput, horizon),
      ..._energyReasons(normalizedInput, energy),
      ..._priorityReasons(normalizedInput, priority),
    ];

    return HeuristicClassification(
      categoryId: categoryId,
      entryKind: kind,
      timeHorizon: horizon,
      energyLevel: energy,
      priorityLevel: priority,
      extractedTags: tags,
      reasons: reasons,
    );
  }

  EntryKind inferKind(String input, {bool detectHabits = true}) {
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

  String? inferCategory(String input, List<CategoryConfig> categories) {
    final tokens =
        _tokenPattern.allMatches(input).map((match) => match.group(0)!).toSet();

    String? bestCategoryId;
    double bestScore = 0;
    for (final category in categories.where((item) => !item.isHidden)) {
      var score = 0.0;
      final normalizedName = category.name.toLowerCase();
      if (input.contains(normalizedName)) {
        score += 0.75;
      }
      for (final keyword in category.keywords) {
        final normalizedKeyword = keyword.trim().toLowerCase();
        if (normalizedKeyword.isEmpty) continue;
        if (tokens.contains(normalizedKeyword)) {
          score += 0.4;
        } else if (input.contains(normalizedKeyword)) {
          score += 0.2;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategoryId = category.id;
      }
    }

    if (bestScore < 0.4) return null;
    return bestCategoryId;
  }

  TimeHorizon inferHorizon(String input, {EntryKind? inferredKind}) {
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
    if (inferredKind == EntryKind.habit) return TimeHorizon.thisMonth;
    if (inferredKind == EntryKind.idea) return TimeHorizon.someday;
    return TimeHorizon.thisWeek;
  }

  EnergyLevel inferEnergy(String input) {
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
  }) {
    if (input.contains('urgente') ||
        input.contains('asap') ||
        input.contains('hoy')) {
      return PriorityLevel.critical;
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

  List<String> extractTags(String input) {
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
}
