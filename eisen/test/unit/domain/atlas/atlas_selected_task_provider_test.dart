import 'package:eisen/features/atlas/application/atlas_providers.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _tasksOverrideProvider = NotifierProvider<_TasksOverride, List<Task>>(
  _TasksOverride.new,
);

class _TasksOverride extends Notifier<List<Task>> {
  @override
  List<Task> build() => const <Task>[];

  void update(List<Task> tasks) {
    state = tasks;
  }
}

void main() {
  test('selectedTaskId resuelve la tarea actual', () {
    final task = _task('a', title: 'Original');
    final container = _container([task]);

    container.read(atlasSelectedTaskIdProvider.notifier).select('a');

    expect(container.read(atlasSelectedTaskProvider)?.title, 'Original');
  });

  test('si la tarea desaparece devuelve null', () {
    final container = _container([_task('a')]);
    container.read(atlasSelectedTaskIdProvider.notifier).select('a');

    container.read(_tasksOverrideProvider.notifier).update(const <Task>[]);

    expect(container.read(atlasSelectedTaskProvider), isNull);
  });

  test('si la tarea se actualiza devuelve datos frescos', () {
    final container = _container([_task('a', title: 'Original')]);
    container.read(atlasSelectedTaskIdProvider.notifier).select('a');

    container.read(_tasksOverrideProvider.notifier).update([
      _task('a', title: 'Actualizada'),
    ]);

    expect(container.read(atlasSelectedTaskProvider)?.title, 'Actualizada');
  });
}

ProviderContainer _container(List<Task> tasks) {
  final container = ProviderContainer(
    overrides: [
      _tasksOverrideProvider.overrideWith(() => _SeededTasksOverride(tasks)),
      atlasTasksProvider.overrideWith(
        (ref) => ref.watch(_tasksOverrideProvider),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _SeededTasksOverride extends _TasksOverride {
  _SeededTasksOverride(this.tasks);

  final List<Task> tasks;

  @override
  List<Task> build() => tasks;
}

Task _task(String id, {String title = 'Tarea'}) {
  return Task(
    id: id,
    title: title,
    quadrant: Quadrant.q2,
    priority: 5,
    minutes: 30,
  );
}
