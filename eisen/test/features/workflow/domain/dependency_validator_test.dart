import 'package:eisen/features/calendar_gantt/domain/task_dependency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DependencyValidator', () {
    group('validateDependency', () {
      test('allows valid dependency with no cycle', () {
        final existingDeps = <String, List<String>>{
          'a': ['b'],
          'b': ['c'],
        };

        final result = DependencyValidator.validateDependency(
          prerequisiteId: 'c',
          dependentId: 'd',
          existingDependencies: existingDeps,
        );

        expect(result.hasCycle, false);
        expect(result.cycle, isEmpty);
      });

      test('detects simple cycle (A→B→A)', () {
        final existingDeps = <String, List<String>>{
          'a': ['b'],
        };

        final result = DependencyValidator.validateDependency(
          prerequisiteId: 'b',
          dependentId: 'a',
          existingDependencies: existingDeps,
        );

        expect(result.hasCycle, true);
        expect(result.cycle, isNotEmpty);
        expect(result.cycle.first, result.cycle.last);
      });

      test('detects complex cycle (A→B→C→D→A)', () {
        final existingDeps = <String, List<String>>{
          'a': ['b'],
          'b': ['c'],
          'c': ['d'],
        };

        final result = DependencyValidator.validateDependency(
          prerequisiteId: 'd',
          dependentId: 'a',
          existingDependencies: existingDeps,
        );

        expect(result.hasCycle, true);
        expect(result.cycle, isNotEmpty);
      });

      test('detects self-dependency (A→A)', () {
        final existingDeps = <String, List<String>>{};

        final result = DependencyValidator.validateDependency(
          prerequisiteId: 'a',
          dependentId: 'a',
          existingDependencies: existingDeps,
        );

        expect(result.hasCycle, true);
        expect(result.cycle.first, result.cycle.last);
      });

      test('detects cycle in branch (A→B, A→C, C→D, D→B)', () {
        final existingDeps = <String, List<String>>{
          'a': ['b', 'c'],
          'c': ['d'],
          'd': ['b'],
        };

        final result = DependencyValidator.validateDependency(
          prerequisiteId: 'b',
          dependentId: 'a',
          existingDependencies: existingDeps,
        );

        expect(result.hasCycle, true);
      });

      test('allows parallel dependencies without cycle', () {
        final existingDeps = <String, List<String>>{
          'a': ['c'],
          'b': ['c'],
        };

        final result = DependencyValidator.validateDependency(
          prerequisiteId: 'c',
          dependentId: 'd',
          existingDependencies: existingDeps,
        );

        expect(result.hasCycle, false);
      });

      test('detects cycle with multiple paths', () {
        final existingDeps = <String, List<String>>{
          'a': ['b', 'c'],
          'b': ['d'],
          'c': ['d'],
        };

        final result = DependencyValidator.validateDependency(
          prerequisiteId: 'd',
          dependentId: 'a',
          existingDependencies: existingDeps,
        );

        expect(result.hasCycle, true);
      });

      test('allows diamond dependency pattern (A→B, A→C, B→D, C→D)', () {
        final existingDeps = <String, List<String>>{
          'a': ['b', 'c'],
          'b': ['d'],
          'c': ['d'],
        };

        final result = DependencyValidator.validateDependency(
          prerequisiteId: 'd',
          dependentId: 'e',
          existingDependencies: existingDeps,
        );

        expect(result.hasCycle, false);
      });
    });

    group('validateAllDependencies', () {
      test('validates graph with no cycles', () {
        final dependencies = <String, List<String>>{
          'a': ['b'],
          'b': ['c'],
          'c': ['d'],
        };

        final result = DependencyValidator.validateAllDependencies(
          dependencies,
        );

        expect(result.hasCycle, false);
      });

      test('detects cycle in full graph', () {
        final dependencies = <String, List<String>>{
          'a': ['b'],
          'b': ['c'],
          'c': ['a'],
        };

        final result = DependencyValidator.validateAllDependencies(
          dependencies,
        );

        expect(result.hasCycle, true);
        expect(result.cycle, contains('a'));
        expect(result.cycle, contains('b'));
        expect(result.cycle, contains('c'));
      });

      test('validates empty dependency list', () {
        final result = DependencyValidator.validateAllDependencies(
          <String, List<String>>{},
        );

        expect(result.hasCycle, false);
        expect(result.cycle, isEmpty);
      });

      test('detects cycle in complex graph', () {
        final dependencies = <String, List<String>>{
          'a': ['b', 'd'],
          'b': ['c'],
          'c': ['a'], // c→a creates the cycle
          'd': ['e'],
        };

        final result = DependencyValidator.validateAllDependencies(
          dependencies,
        );

        expect(result.hasCycle, true);
      });
    });

    group('buildDependencyGraph', () {
      test('builds graph from tasks', () {
        final tasks = [
          {
            'id': 'a',
            'deps': ['b', 'd']
          },
          {
            'id': 'b',
            'deps': ['c']
          },
          {'id': 'c', 'deps': <String>[]},
          {'id': 'd', 'deps': <String>[]},
        ];

        final graph = DependencyValidator.buildDependencyGraph(
          tasks,
          (task) => task['id'] as String,
          (task) => task['deps'] as List<String>,
        );

        expect(graph['b'], contains('a'));
        expect(graph['d'], contains('a'));
        expect(graph['c'], contains('b'));
        expect(graph['a'], isEmpty);
      });

      test('handles empty dependencies', () {
        final graph = DependencyValidator.buildDependencyGraph(
          [],
          (task) => '',
          (task) => <String>[],
        );

        expect(graph, isEmpty);
      });

      test('merges multiple dependencies for same prerequisite', () {
        final tasks = [
          {'id': 'a', 'deps': <String>[]},
          {
            'id': 'b',
            'deps': ['a']
          },
          {
            'id': 'c',
            'deps': ['a']
          },
          {
            'id': 'd',
            'deps': ['a']
          },
        ];

        final graph = DependencyValidator.buildDependencyGraph(
          tasks,
          (task) => task['id'] as String,
          (task) => task['deps'] as List<String>,
        );

        expect(graph['a'], hasLength(3));
        expect(graph['a'], containsAll(['b', 'c', 'd']));
      });
    });

    group('topologicalSort', () {
      test('returns sorted order for valid graph', () {
        final graph = <String, List<String>>{
          'a': ['b'],
          'b': ['c'],
          'c': [],
        };

        final sorted = DependencyValidator.topologicalSort(graph);

        expect(sorted, isNotNull);
        expect(sorted!, hasLength(3));
        expect(sorted.indexOf('a'), lessThan(sorted.indexOf('b')));
        expect(sorted.indexOf('b'), lessThan(sorted.indexOf('c')));
      });

      test('returns null for graph with cycle', () {
        final graph = <String, List<String>>{
          'a': ['b'],
          'b': ['c'],
          'c': ['a'],
        };

        final sorted = DependencyValidator.topologicalSort(graph);

        expect(sorted, isNull);
      });

      test('handles parallel dependencies', () {
        final graph = <String, List<String>>{
          'a': ['c'],
          'b': ['c'],
          'c': [],
        };

        final sorted = DependencyValidator.topologicalSort(graph);

        expect(sorted, isNotNull);
        expect(sorted!, hasLength(3));
        expect(sorted.indexOf('c'), greaterThan(sorted.indexOf('a')));
        expect(sorted.indexOf('c'), greaterThan(sorted.indexOf('b')));
      });

      test('handles empty dependencies', () {
        final sorted = DependencyValidator.topologicalSort({});

        expect(sorted, isNotNull);
        expect(sorted!, isEmpty);
      });

      test('preserves task order for diamond pattern', () {
        final graph = <String, List<String>>{
          'a': ['b', 'c'],
          'b': ['d'],
          'c': ['d'],
          'd': [],
        };

        final sorted = DependencyValidator.topologicalSort(graph);

        expect(sorted, isNotNull);
        expect(sorted!, hasLength(4));
        expect(sorted.indexOf('a'), equals(0));
        expect(sorted.indexOf('d'), equals(3));
      });
    });
  });
}
