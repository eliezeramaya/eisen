import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/classification/presentation/widgets/classification_preview_card.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'ClassificationPreviewCard shows compact fields and reacts to taps',
      (tester) async {
    var categoryTapped = false;
    var kindTapped = false;

    final metadata = ClassificationMetadata(
      inputText: 'Comprar leche hoy',
      normalizedText: 'comprar leche hoy',
      categoryId: 'errands',
      entryKind: EntryKind.shoppingItem,
      timeHorizon: TimeHorizon.today,
      energyLevel: EnergyLevel.low,
      priorityLevel: PriorityLevel.medium,
      confidenceScore: 0.86,
      confidenceLevel: ConfidenceLevel.high,
      source: ClassificationSource.heuristic,
      confidenceReason:
          'Clasificada como Compras porque contiene comprar, leche.',
      reasons: const <String>['Keywords detectadas: comprar, leche.'],
      suggestedQuadrant: Quadrant.q1,
      urgencyScore: 0.92,
      importanceScore: 0.76,
      quadrantReason: 'Alta urgencia y alta importancia',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ClassificationPreviewCard(
              metadata: metadata,
              categories: CategoryConfigDefaults.values,
              compact: true,
              onTapCategory: () => categoryTapped = true,
              onTapKind: () => kindTapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Categoría'), findsOneWidget);
    expect(find.text('Mandados'), findsOneWidget);
    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('Compra'), findsOneWidget);
    expect(find.text('Horizonte'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Energía'), findsOneWidget);
    expect(find.text('Baja'), findsOneWidget);
    expect(find.text('Confianza'), findsOneWidget);
    expect(find.text('Alta'), findsOneWidget);
    expect(find.text('Cuadrante sugerido'), findsOneWidget);
    expect(find.text('Crítico'), findsOneWidget);
    expect(find.text('Requiere atención inmediata'), findsOneWidget);

    await tester.tap(find.text('Mandados'));
    await tester.tap(find.text('Compra'));
    await tester.pump();

    expect(categoryTapped, isTrue);
    expect(kindTapped, isTrue);
  });
}
