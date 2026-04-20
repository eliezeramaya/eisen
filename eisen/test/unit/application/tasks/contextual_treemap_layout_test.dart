import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/tasks/context_aware/application/contextual_treemap_layout.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_aware_task_scoring.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active context is grouped first and blocked tasks lose visual weight',
      () {
    const officeContext = ContextState(
      currentLocationTag: 'office',
      latitude: 19.4328,
      longitude: -99.1332,
      isAutoMode: false,
      permissionState: ContextPermissionState.granted,
    );

    final activeTask = RankedContextTask(
      task: const Task(
        id: 'office_fast',
        title: 'Sync with design',
        quadrant: Quadrant.q1,
        priority: 8,
        minutes: 25,
        locationTag: 'office',
      ),
      score: 0.82,
      locationMatch: 1,
      proximityScore: 0.6,
      priorityWeight: 0.78,
      explanation: 'Office match',
    );

    final blockedTask = RankedContextTask(
      task: const Task(
        id: 'office_blocked',
        title: 'Review blockers',
        quadrant: Quadrant.q1,
        priority: 8,
        minutes: 25,
        locationTag: 'office',
        status: TaskStatus.blocked,
      ),
      score: 0.82,
      locationMatch: 1,
      proximityScore: 0.6,
      priorityWeight: 0.78,
      explanation: 'Office match',
    );

    final homeTask = RankedContextTask(
      task: const Task(
        id: 'home_reset',
        title: 'Reset kitchen',
        quadrant: Quadrant.q2,
        priority: 6,
        minutes: 35,
        locationTag: 'home',
      ),
      score: 0.52,
      locationMatch: 0.5,
      proximityScore: 0,
      priorityWeight: 0.64,
      explanation: 'Home task',
    );

    expect(
      computeContextualVisualWeight(blockedTask),
      lessThan(computeContextualVisualWeight(activeTask)),
    );

    final sections = buildContextTreemapSections(
      rankedTasks: [homeTask, blockedTask, activeTask],
      context: officeContext,
    );

    expect(sections, isNotEmpty);
    expect(sections.first.group, ContextTreemapGroup.office);
    expect(sections.first.isActive, isTrue);
    expect(sections.first.tasks.first.rankedTask.task.id, 'office_fast');
  });
}
