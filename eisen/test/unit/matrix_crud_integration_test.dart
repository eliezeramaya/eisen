import 'package:eisen/core/services/storage_prefs.dart';
import 'package:eisen/features/eisen_matrix/data/local_repo.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('MatrixController full CRUD persists to repository', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(matrixControllerProvider.notifier);

    // Create
    final id = controller.createTask(
      quadrant: Quadrant.q1,
      title: 'Nueva tarea',
    );
    expect(controller.state.tasks.length, 1);
    expect(controller.state.selectedId, id);

    // Update
    controller.updateTask(id, (t) {
      return t.copyWith(
        title: 'Actualizada',
        quadrant: Quadrant.q3,
        priority: 9,
        minutes: 45,
      );
    });
    final updated = controller.state.tasks.firstWhere((t) => t.id == id);
    expect(updated.title, 'Actualizada');
    expect(updated.quadrant, Quadrant.q3);
    expect(updated.priority, 9);
    expect(updated.updatedAt, isNotNull);

    // Persist and verify repository round-trip
    await controller.persist();
    final repo = LocalPrefsMatrixRepository(StoragePrefs());
    final saved = await repo.load();
    expect(saved.length, 1);
    expect(saved.first.title, 'Actualizada');
    expect(saved.first.quadrant, Quadrant.q3);

    // Delete and persist empty state
    controller.deleteTask(id);
    expect(controller.state.tasks, isEmpty);
    await controller.persist();
    final afterDelete = await repo.load();
    expect(afterDelete, isEmpty);
  });
}
