import 'dart:async';

import 'package:eisen/core/storage/local_storage_keys.dart';
import 'package:eisen/features/atlas/application/atlas_providers.dart';
import 'package:eisen/features/atlas/application/task_view_mode_prefs.dart';
import 'package:eisen/features/atlas/domain/task_view_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('TaskViewModePrefs guarda y carga el modo seleccionado', () async {
    const prefs = TaskViewModePrefs();

    await prefs.save(TaskViewMode.atlas);

    expect(await prefs.load(), TaskViewMode.atlas);
  });

  test('TaskViewModePrefs vuelve a matrix con valor inválido', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocalStorageKeys.taskViewMode: 'unknown',
    });

    expect(await const TaskViewModePrefs().load(), TaskViewMode.matrix);
  });

  test('taskViewModeProvider carga atlas persistido', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocalStorageKeys.taskViewMode: TaskViewMode.atlas.name,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final loaded = Completer<TaskViewMode>();
    container.listen<TaskViewMode>(
      taskViewModeProvider,
      (_, next) {
        if (next == TaskViewMode.atlas && !loaded.isCompleted) {
          loaded.complete(next);
        }
      },
      fireImmediately: true,
    );

    expect(container.read(taskViewModeProvider), TaskViewMode.matrix);
    expect(
      await loaded.future.timeout(const Duration(seconds: 1)),
      TaskViewMode.atlas,
    );
  });

  test('taskViewModeProvider persiste cambios de usuario', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(taskViewModeProvider.notifier).update(TaskViewMode.atlas);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(LocalStorageKeys.taskViewMode),
      TaskViewMode.atlas.name,
    );
  });
}
