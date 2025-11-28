import 'package:eisen/features/eisen_matrix/presentation/pages/matrix_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Bottom bar Entry button opens AddTaskSheet', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: MatrixPage())));
    await tester.pump(const Duration(milliseconds: 300));

    final entryEs = find.text('Entrada');
    final entryEn = find.text('Entry');
    expect(
        entryEs.evaluate().isNotEmpty || entryEn.evaluate().isNotEmpty, isTrue,
        reason: 'Expected Entry/Entrada button in bottom bar');

    // Try robust target selection: FilledButton with label, else IconButton tooltip, else semantics
    Finder target;
    final filledButton = find.byType(FilledButton);
    if (filledButton.evaluate().isNotEmpty) {
      target = filledButton.first;
    } else {
      final iconTooltipEs = find.byTooltip('Entrada');
      final iconTooltipEn = find.byTooltip('Entry');
      if (iconTooltipEs.evaluate().isNotEmpty) {
        target = iconTooltipEs;
      } else if (iconTooltipEn.evaluate().isNotEmpty) {
        target = iconTooltipEn;
      } else {
        final entrySemEs = find.bySemanticsLabel('Entrada');
        final entrySemEn = find.bySemanticsLabel('Entry');
        target = entrySemEs.evaluate().isNotEmpty
            ? entrySemEs.first
            : (entrySemEn.evaluate().isNotEmpty
                ? entrySemEn.first
                : (entryEs.evaluate().isNotEmpty
                    ? entryEs.first
                    : entryEn.first));
      }
    }
    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 600));

    // AddTaskSheet shows Spanish labels by design ('Título' / 'Guardar')
    expect(find.text('Título'), findsOneWidget,
        reason: 'AddTaskSheet should appear with title field');
    expect(find.text('Guardar'), findsOneWidget,
        reason: 'AddTaskSheet should include Save button');
  });
}
