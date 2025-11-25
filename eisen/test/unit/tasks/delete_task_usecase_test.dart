import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/delete_task_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeleteTaskUseCase.cleanupCache', () {
    final useCase = DeleteTaskUseCase();
    final cache = LayoutCache();

    setUp(() {
      cache.lastWeight.clear();
      cache.lastRect.clear();
      cache.lastRank.clear();
      cache.lastWeight['t1'] = 10;
      cache.lastRank['t1'] = 1;
    });

    test('removes cached entries for given task id', () {
      useCase.cleanupCache('t1', cache);

      expect(cache.lastWeight.containsKey('t1'), isFalse);
      expect(cache.lastRect.containsKey('t1'), isFalse);
      expect(cache.lastRank.containsKey('t1'), isFalse);
    });

    test('is idempotent for missing ids (no throw)', () {
      expect(() => useCase.cleanupCache('missing', cache), returnsNormally);
    });
  });
}
