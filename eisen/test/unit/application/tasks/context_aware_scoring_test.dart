import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_aware_task_scoring.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prioriza tareas cercanas y alineadas con el contexto activo', () {
    const officeContext = ContextState(
      currentLocationTag: 'office',
      latitude: 19.4328,
      longitude: -99.1332,
      isAutoMode: true,
      permissionState: ContextPermissionState.granted,
    );

    final officeTask = Task(
      id: 'office',
      title: 'Preparar demo para cliente',
      quadrant: Quadrant.q1,
      priority: 8,
      minutes: 45,
      locationTag: 'office',
      latitude: 19.4329,
      longitude: -99.1334,
      radiusMeters: 500,
    );

    final homeTask = Task(
      id: 'home',
      title: 'Ordenar estudio',
      quadrant: Quadrant.q2,
      priority: 10,
      minutes: 30,
      locationTag: 'home',
      latitude: 19.4260,
      longitude: -99.1677,
      radiusMeters: 500,
    );

    final ranked = rankContextAwareTasks(
      tasks: [homeTask, officeTask],
      context: officeContext,
    );

    expect(ranked.first.task.id, 'office');
    expect(ranked.first.locationMatch, greaterThan(ranked.last.locationMatch));
    expect(ranked.first.proximityScore, greaterThan(0.6));
    expect(ranked.first.score, greaterThan(ranked.last.score));
  });
}
