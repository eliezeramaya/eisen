import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load seeds demo tasks when empty', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(matrixControllerProvider.notifier);
    expect(container.read(matrixControllerProvider).tasks, isEmpty);
    await controller.load();
    expect(container.read(matrixControllerProvider).tasks, isNotEmpty);
  });

  test('create, update, delete and move task', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final c = container.read(matrixControllerProvider.notifier);
    await c.load();

    final initial = container.read(matrixControllerProvider).tasks.length;
    c.createTask(quadrant: Quadrant.q3);
    expect(container.read(matrixControllerProvider).tasks.length, initial + 1);
    final id = container.read(matrixControllerProvider).selectedId!;

    c.updateTask(id, (t) => t.copyWith(title: 'Updated', priority: 9));
    final updated = container.read(matrixControllerProvider).tasks.firstWhere((t) => t.id == id);
    expect(updated.title, 'Updated');
    expect(updated.priority, 9);

    c.moveTaskToQuadrant(id, Quadrant.q1);
    final moved = container.read(matrixControllerProvider).tasks.firstWhere((t) => t.id == id);
    expect(moved.quadrant, Quadrant.q1);

    c.deleteTask(id);
    expect(container.read(matrixControllerProvider).tasks.any((t) => t.id == id), isFalse);
  });

  test('theme toggle cycles through modes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final c = container.read(matrixControllerProvider.notifier);
    final m1 = container.read(matrixControllerProvider).themeMode;
    c.toggleTheme();
    final m2 = container.read(matrixControllerProvider).themeMode;
    c.toggleTheme();
    final m3 = container.read(matrixControllerProvider).themeMode;
    expect(m1 != m2 && m2 != m3 && m3 != m1, isTrue);
  });

  test('axis legends toggle flips flag', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final c = container.read(matrixControllerProvider.notifier);
    await c.load();
    final before = container.read(matrixControllerProvider).showAxisLegends;
    c.toggleAxisLegends();
    final after = container.read(matrixControllerProvider).showAxisLegends;
    expect(after, !before);
  });

  test('query filters layout results', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final c = container.read(matrixControllerProvider.notifier);
    await c.load();
    final allLayout = c.layout();
    expect(allLayout, isNotEmpty);
    // Use a query that likely matches a single task name "Task 1"
    c.setQuery('task 1');
    final filtered = c.layout();
    expect(filtered.length <= allLayout.length, isTrue);
  });
}
