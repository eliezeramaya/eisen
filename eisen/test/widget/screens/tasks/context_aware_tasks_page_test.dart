import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/tasks/context_aware/application/context_aware_tasks_controller.dart';
import 'package:eisen/features/tasks/context_aware/presentation/pages/context_aware_tasks_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renderiza contexto manual y tarea mas relevante',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final matrix = container.read(matrixControllerProvider.notifier);
    final officeTaskId =
        matrix.createTask(quadrant: Quadrant.q1, title: 'Preparar brief');
    matrix.updateTask(
      officeTaskId,
      (task) => task.copyWith(
        priority: 8,
        minutes: 40,
        notes: 'Trabajo con el equipo de oficina',
        locationTag: 'office',
        latitude: 19.4328,
        longitude: -99.1332,
        radiusMeters: 450,
      ),
    );

    final homeTaskId =
        matrix.createTask(quadrant: Quadrant.q2, title: 'Lavar ropa');
    matrix.updateTask(
      homeTaskId,
      (task) => task.copyWith(
        priority: 9,
        minutes: 25,
        locationTag: 'home',
        latitude: 19.4260,
        longitude: -99.1677,
        radiusMeters: 450,
      ),
    );

    final contextController =
        container.read(contextAwareTasksControllerProvider.notifier);
    contextController.setAutoMode(false);
    contextController.selectManualContext('office');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('es'),
          home: ContextAwareTasksPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.text('Preparar brief'), findsOneWidget);
    expect(find.text('Lavar ropa'), findsNothing);
  });
}
