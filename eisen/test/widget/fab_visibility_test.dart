import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/app/app.dart';

void main() {
  testWidgets('Single FAB present and no duplicate New task button', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EisenApp()));
    await tester.pump(const Duration(milliseconds: 200));

    // One FloatingActionButton (extended)
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // No visible duplicate "New task" button in the UI
    expect(find.text('New task'), findsNothing);
  });
}
