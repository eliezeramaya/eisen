import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/app/app.dart';

void main() {
  testWidgets('Axis labels use onSurfaceVariant for contrast', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EisenApp()));
    await tester.pump(const Duration(milliseconds: 200));

    // Find axis labels in English locale
    final urgent = find.text('Urgent');
    final notUrgent = find.text('Not urgent');

    expect(urgent, findsOneWidget);
    expect(notUrgent, findsOneWidget);

    final BuildContext ctx = tester.element(urgent);
    final onSurfaceVariant = Theme.of(ctx).colorScheme.onSurfaceVariant;

    final urgentText = tester.widget<Text>(urgent);
    final notUrgentText = tester.widget<Text>(notUrgent);

    expect(urgentText.style?.color, onSurfaceVariant);
    expect(notUrgentText.style?.color, onSurfaceVariant);
  });
}
