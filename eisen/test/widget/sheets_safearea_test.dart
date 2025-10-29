import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eisen/features/eisen_matrix/presentation/widgets/settings_sheet.dart';
import 'package:eisen/features/tasks/presentation/add_task_sheet.dart';

void main() {
  testWidgets('AddTaskSheet uses SafeArea and is scroll controlled', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: Scaffold(body: SizedBox.shrink()))));

    showModalBottomSheet(
      // Use the Scaffold context to avoid ambiguous SizedBox lookups
      context: tester.element(find.byType(Scaffold)),
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskSheet(),
    );

    await tester.pumpAndSettle();

    // SafeArea and scroll container present
    expect(find.byType(SafeArea), findsWidgets);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // Close the sheet
  Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('SettingsSheet uses SafeArea and scroll view', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: Scaffold(body: SizedBox.shrink()))));

    showModalBottomSheet(
      // Use the Scaffold context to avoid ambiguous SizedBox lookups
      context: tester.element(find.byType(Scaffold)),
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsSheet(
        onToggleTheme: () {},
        onToggleDensity: () {},
        compact: false,
        showAxisLegends: true,
        onToggleAxisLegends: () {},
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(SafeArea), findsWidgets);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

  Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pumpAndSettle();
  });
}

