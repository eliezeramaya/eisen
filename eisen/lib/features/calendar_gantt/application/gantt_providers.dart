import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_lanes.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_projection.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart' show Task;

/// Build CalendarSpan list from matrix tasks.
///
/// Rule of thumb mapping (placeholder for Stage 1):
/// - Only include tasks with a due date.
/// - Span end = end of due day (exclusive)
/// - Span start = end - estimatedDays, where estimatedDays = ceil(minutes / 360)
///   clamped to [1, 14]. Assumes ~6h effective work per day.
final calendarSpansProvider = Provider<List<CalendarSpan>>((ref) {
  final List<Task> tasks = ref.watch(matrixTasksProvider);
  final out = <CalendarSpan>[];
  for (final t in tasks) {
    final due = t.due;
    if (due == null) continue;
    final end = DateTime(due.year, due.month, due.day).add(const Duration(days: 1)); // exclusive end
    final estDays = (t.minutes / 360.0).ceil().clamp(1, 14);
    final start = end.subtract(Duration(days: estDays));
    out.add(CalendarSpan(
      id: t.id,
      title: t.title,
      start: start,
      end: end,
      kind: GanttKind.dev, // default; can be refined by tags/categories later
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
    return TimelineProjector(viewStart: viewStart, pxPerDay: UiTokens.pxPerDayDefault);
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

final projectorProvider = NotifierProvider<ProjectorController, TimelineProjector>(ProjectorController.new);

/// Lanes assignment provider; stable greedy packing.
final lanesProvider = Provider<List<CalendarSpan>>((ref) {
  final spans = ref.watch(calendarSpansProvider);
  return assignLanes(spans);
});
