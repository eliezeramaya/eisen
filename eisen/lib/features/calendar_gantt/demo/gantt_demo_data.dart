import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';

CalendarSpan span(String title, String startIso, String endIso, GanttKind kind) {
  final start = DateTime.parse(startIso);
  final end = DateTime.parse(endIso);
  return CalendarSpan(
    id: '${title}_${startIso}_${endIso}',
    title: title,
    start: start,
    end: end,
    kind: kind,
    lane: -1,
  );
}

List<CalendarSpan> demoSpans() => [
  span('Research', '2025-02-15', '2025-02-19', GanttKind.research),
  span('Business Analysis', '2025-02-25', '2025-03-21', GanttKind.analysis),
  span('Wireframes, proto', '2025-02-27', '2025-03-10', GanttKind.design),
  span('UI design', '2025-03-10', '2025-03-25', GanttKind.design),
  span('Development', '2025-03-01', '2025-04-15', GanttKind.dev),
  span('Sync', '2025-03-08', '2025-03-10', GanttKind.sync),
  span('WF Testing', '2025-03-12', '2025-03-16', GanttKind.qa),
  span('Feedback', '2025-04-20', '2025-04-22', GanttKind.feedback),
];
