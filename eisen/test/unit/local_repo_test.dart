import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eisen/core/services/storage_prefs.dart';
import 'package:eisen/features/eisen_matrix/data/local_repo.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('LocalPrefsMatrixRepository saves and loads tasks', () async {
    final repo = LocalPrefsMatrixRepository(StoragePrefs());

    // Initially empty
    var loaded = await repo.load();
    expect(loaded, isEmpty);

    final tasks = [
      const Task(id: '1', title: 'A', quadrant: Quadrant.q2, priority: 5, minutes: 30),
      const Task(id: '2', title: 'B', quadrant: Quadrant.q1, priority: 7, minutes: 45),
    ];

    await repo.save(tasks);

    loaded = await repo.load();
    expect(loaded.length, 2);
    expect(loaded[0].id, '1');
    expect(loaded[1].quadrant, Quadrant.q1);
  });
}