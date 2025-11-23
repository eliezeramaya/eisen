import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_lanes.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_projection.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart'
    show Task, Quadrant;
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Map Quadrant to GanttKind for visual styling
GanttKind _kindFromQuadrant(Quadrant q) {
  switch (q) {
    case Quadrant.q1:
      return GanttKind.dev; // Urgent & Important -> Development/Execution
    case Quadrant.q2:
      return GanttKind.design; // Important not urgent -> Design/Planning
    case Quadrant.q3:
      return GanttKind.sync; // Urgent not important -> Sync/Coordination
    case Quadrant.q4:
      return GanttKind.qa; // Not urgent/important -> QA/Review
  }
}

/// Build CalendarSpan list from matrix tasks.
///
/// Enhanced mapping logic:
/// - Only include tasks with a due date
/// - Span end = end of due day (exclusive)
/// - Span start calculated from minutes:
///   - Short tasks (<60 min): 1 day span
///   - Medium tasks (60-360 min): 2-3 days
///   - Long tasks (>360 min): Multiple days (6h/day assumption)
/// - Visual kind determined by quadrant
/// - Filter out completed tasks (they belong in completed_tasks view)
final calendarSpansProvider = Provider<List<CalendarSpan>>((ref) {
  final List<Task> tasks = ref.watch(matrixTasksProvider);
  final out = <CalendarSpan>[];

  for (final t in tasks) {
    // Skip completed tasks
    if (t.completedAt != null) continue;

    final due = t.due;
    if (due == null) continue;

    // End date is exclusive (end of due day)
    final end =
        DateTime(due.year, due.month, due.day).add(const Duration(days: 1));

    // Calculate start date based on estimated work
    // Assume 6 hours of effective work per day (360 minutes)
    final int estDays;
    if (t.minutes < 60) {
      estDays = 1; // Short task: same day
    } else if (t.minutes < 180) {
      estDays = 2; // ~1-3 hours: 2 days
    } else if (t.minutes < 360) {
      estDays = 3; // ~3-6 hours: 3 days
    } else {
      // Long task: estimate multi-day span
      estDays = (t.minutes / 360.0).ceil().clamp(1, 30);
    }

    final start = end.subtract(Duration(days: estDays));

    // Determine visual kind from quadrant
    final kind = _kindFromQuadrant(t.quadrant);

    out.add(CalendarSpan(
      id: t.id,
      title: t.title,
      start: start,
      end: end,
      kind: kind,
      lane: -1,
    ));
  }

  return out;
});

/// Projector with adjustable px-per-day; viewStart defaults to 2 weeks before now.
class ProjectorController extends Notifier<TimelineProjector> {
  @override
  TimelineProjector build() {
    final now = DateTime.now();
    final viewStart = now.subtract(const Duration(days: 14));
    return TimelineProjector(
        viewStart: viewStart, pxPerDay: UiTokens.pxPerDayDefault);
  }

  void setPxPerDay(double v) {
    final min = UiTokens.pxPerDayMin;
    final max = UiTokens.pxPerDayMax;
    final clamped = v.clamp(min, max).toDouble();
    if ((clamped - state.pxPerDay).abs() < 0.001) return;
    state = TimelineProjector(viewStart: state.viewStart, pxPerDay: clamped);
  }

  void setViewStart(DateTime vs) {
    if (vs == state.viewStart) return;
    state = TimelineProjector(viewStart: vs, pxPerDay: state.pxPerDay);
  }
}

final projectorProvider =
    NotifierProvider<ProjectorController, TimelineProjector>(
        ProjectorController.new);

/// Lanes assignment provider; stable greedy packing.
final lanesProvider = Provider<List<CalendarSpan>>((ref) {
  final spans = ref.watch(calendarSpansProvider);
  return assignLanes(spans);
});
