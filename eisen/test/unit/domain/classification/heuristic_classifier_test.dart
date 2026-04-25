import 'package:eisen/features/classification/domain/classification_engine.dart';
import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/classification/domain/services/classification_engine.dart';
import 'package:eisen/features/classification/domain/services/heuristic_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeuristicClassifier', () {
    const classifier = HeuristicClassifier();
    const settings = ClassificationSettingsDefaults.value;
    const categories = CategoryConfigDefaults.values;

    test('clasifica compras como shoppingItem con confianza alta', () {
      final result = classifier.classify(
        normalizedInput:
            normalizeClassificationText('Comprar leche en el super hoy'),
        categories: categories,
        settings: settings,
      );

      expect(result.entryKind, EntryKind.shoppingItem);
      expect(result.categoryId, 'errands');
      expect(result.confidenceLevel, ConfidenceLevel.high);
      expect(result.energyLevel, EnergyLevel.low);
      expect(result.result.category, 'Compras');
    });

    test('eleva prioridad de trabajo cuando hay cliente o entrega', () {
      final result = classifier.classify(
        normalizedInput: normalizeClassificationText(
          'Enviar propuesta al cliente y preparar entrega',
        ),
        categories: categories,
        settings: settings,
      );

      expect(result.entryKind, EntryKind.task);
      expect(result.categoryId, 'work');
      expect(result.priorityLevel, PriorityLevel.high);
      expect(result.confidenceLevel,
          anyOf(ConfidenceLevel.medium, ConfidenceLevel.high));
      expect(result.matchedKeywords, contains('cliente'));
    });

    test('manda ideas a someday con prioridad baja', () {
      final result = classifier.classify(
        normalizedInput:
            normalizeClassificationText('Idea para explorar un concepto nuevo'),
        categories: categories,
        settings: settings,
      );

      expect(result.entryKind, EntryKind.idea);
      expect(result.categoryId, 'ideas');
      expect(result.timeHorizon, TimeHorizon.someday);
      expect(result.priorityLevel, PriorityLevel.low);
      expect(result.confidenceLevel, ConfidenceLevel.medium);
    });

    test('detecta salud como habito o tarea con energia media o alta', () {
      final result = classifier.classify(
        normalizedInput:
            normalizeClassificationText('Empezar rutina para correr en el gym'),
        categories: categories,
        settings: settings,
      );

      expect(result.categoryId, 'health');
      expect(result.entryKind, EntryKind.habit);
      expect(result.energyLevel, anyOf(EnergyLevel.medium, EnergyLevel.high));
      expect(result.confidenceLevel, ConfidenceLevel.medium);
    });

    test('detecta finanzas y sube prioridad cuando hay fecha', () {
      final result = classifier.classify(
        normalizedInput: normalizeClassificationText(
          'Pagar factura del banco el viernes',
        ),
        categories: categories,
        settings: settings,
      );

      expect(result.categoryId, 'finance');
      expect(result.entryKind, EntryKind.reminder);
      expect(result.priorityLevel, PriorityLevel.high);
      expect(result.confidenceLevel, ConfidenceLevel.high);
    });
  });

  test('LocalClassificationEngine expone ClassificationResult simple', () {
    const engine = LocalClassificationEngine();
    final result = engine.classify('Comprar papel y leche en la farmacia');

    expect(result.kind, EntryKind.shoppingItem);
    expect(result.category, 'Compras');
    expect(result.confidence, ConfidenceLevel.high);
    expect(result.autoTags, contains('compras'));
  });
}
