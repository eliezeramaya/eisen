import 'package:eisen/core/storage/local_storage_keys.dart';
import 'package:eisen/features/atlas/domain/task_view_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskViewModePrefs {
  const TaskViewModePrefs();

  Future<TaskViewMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    return taskViewModeFromName(
      prefs.getString(LocalStorageKeys.taskViewMode),
    );
  }

  Future<void> save(TaskViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LocalStorageKeys.taskViewMode, mode.name);
  }
}
