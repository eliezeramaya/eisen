import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eisen/features/eisen_matrix/presentation/pages/matrix_page.dart';

void main() {
  testWidgets('Bottom bar Entry button opens AddTaskSheet', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: MatrixPage())));
    await tester.pumpAndSettle();

    final entryEs = find.text('Entrada');
    final entryEn = find.text('Entry');
    expect(entryEs.evaluate().isNotEmpty || entryEn.evaluate().isNotEmpty, isTrue,
        reason: 'Expected Entry/Entrada button in bottom bar');

    final target = entryEs.evaluate().isNotEmpty ? entryEs : entryEn;
    await tester.tap(target);
    await tester.pumpAndSettle();

    // AddTaskSheet shows Spanish labels by design ('Título' / 'Guardar')
    expect(find.text('Título'), findsOneWidget,
        reason: 'AddTaskSheet should appear with title field');
    expect(find.text('Guardar'), findsOneWidget,
        reason: 'AddTaskSheet should include Save button');
  });
}

