import 'package:eisen/features/atlas/application/atlas_node_builder.dart';
import 'package:eisen/features/atlas/domain/atlas_grouping.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agrupa por categoría y suma pesos de hijos', () {
    final nodes = buildAtlasNodes(
      tasks: [
        _task('1', category: 'Trabajo', priority: 10),
        _task('2', category: 'Trabajo', priority: 4),
        _task('3', category: 'Casa', priority: 2),
      ],
      grouping: AtlasGrouping.category,
    );

    final trabajo = nodes.firstWhere((node) => node.label == 'Trabajo');
    expect(trabajo.children, hasLength(2));
    expect(
      trabajo.weight,
      closeTo(
        trabajo.children.fold<double>(0, (sum, child) => sum + child.weight),
        0.001,
      ),
    );
  });

  test('usa fallback Sin categoría', () {
    final nodes = buildAtlasNodes(
      tasks: [_task('1')],
      grouping: AtlasGrouping.category,
    );

    expect(nodes.single.label, 'Sin categoría');
  });

  test('agrupa por cuadrante con labels amigables', () {
    final nodes = buildAtlasNodes(
      tasks: [
        _task('1', quadrant: Quadrant.q1),
        _task('2', quadrant: Quadrant.q2),
        _task('3', quadrant: Quadrant.q3),
        _task('4', quadrant: Quadrant.q4),
      ],
      grouping: AtlasGrouping.quadrant,
    );

    expect(
        nodes.map((node) => node.label),
        containsAll([
          'Crítico',
          'Crecimiento',
          'De otros',
          'Archivar',
        ]));
  });

  test('agrupa por horizonte, energía y tipo sin crashear', () {
    final tasks = [
      _task(
        '1',
        horizon: TimeHorizon.today,
        energy: EnergyLevel.high,
        kind: EntryKind.idea,
      ),
    ];

    expect(
      buildAtlasNodes(tasks: tasks, grouping: AtlasGrouping.horizon)
          .single
          .label,
      'Hoy',
    );
    expect(
      buildAtlasNodes(tasks: tasks, grouping: AtlasGrouping.energy)
          .single
          .label,
      'Alta energía',
    );
    expect(
      buildAtlasNodes(tasks: tasks, grouping: AtlasGrouping.kind).single.label,
      'Idea',
    );
  });
}

Task _task(
  String id, {
  String? category,
  Quadrant quadrant = Quadrant.q2,
  int priority = 5,
  TimeHorizon? horizon,
  EnergyLevel? energy,
  EntryKind kind = EntryKind.task,
}) {
  return Task(
    id: id,
    title: 'Task $id',
    quadrant: quadrant,
    priority: priority,
    minutes: 30,
    category: category,
    horizon: horizon,
    energy: energy,
    kind: kind,
  );
}
