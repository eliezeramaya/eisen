import 'package:eisen/features/calendar_gantt/application/dependencies_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('addDependency avoids duplicates and removeDependency cleans up', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final matrix = container.read(matrixControllerProvider.notifier);
    final a = matrix.createTask(quadrant: Quadrant.q1, title: 'A');
    final b = matrix.createTask(quadrant: Quadrant.q2, title: 'B');

    final controller = container.read(dependenciesControllerProvider.notifier);
    controller.addDependency(prerequisiteId: a, dependentId: b);
    controller.addDependency(prerequisiteId: a, dependentId: b);

    final state = container.read(dependenciesControllerProvider);
    expect(state.length, 1);

    controller.removeDependency(prerequisiteId: a, dependentId: b);
    expect(container.read(dependenciesControllerProvider), isEmpty);
  });

  test('cycles are detected and rejected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final matrix = container.read(matrixControllerProvider.notifier);
    final a = matrix.createTask(quadrant: Quadrant.q1, title: 'A');
    final b = matrix.createTask(quadrant: Quadrant.q2, title: 'B');
    final c = matrix.createTask(quadrant: Quadrant.q3, title: 'C');

    final controller = container.read(dependenciesControllerProvider.notifier);
    controller.addDependency(prerequisiteId: a, dependentId: b);
    controller.addDependency(prerequisiteId: b, dependentId: c);
    container.refresh(dependenciesControllerProvider);

    final beforeCycle = container.read(dependenciesControllerProvider);
    final result = controller.addDependency(prerequisiteId: c, dependentId: a);

    expect(result.hasCycle, isTrue);
    expect(container.read(dependenciesControllerProvider).length,
        beforeCycle.length);
  });
}
