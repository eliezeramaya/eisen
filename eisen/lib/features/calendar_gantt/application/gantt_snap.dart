import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';

/// Maps UI prefs string to TimeScale. Defaults to days.
TimeScale timeScaleFromPrefs(String value) {
  switch (value) {
    case 'weeks':
      return TimeScale.weeks;
    case 'months':
      return TimeScale.months;
    case 'days':
      return TimeScale.days;
  }
  return TimeScale.days;
}

/// Floors a DateTime to the beginning of the unit for the given scale.
DateTime snapFloor(DateTime t, TimeScale scale) {
  switch (scale) {
    case TimeScale.weeks:
      final wd = t.weekday; // Mon=1..Sun=7
      final delta = wd - DateTime.monday;
      final d0 = DateTime(t.year, t.month, t.day).subtract(Duration(days: delta));
      return DateTime(d0.year, d0.month, d0.day);
    case TimeScale.months:
      return DateTime(t.year, t.month, 1);
    case TimeScale.days:
      return DateTime(t.year, t.month, t.day);
  }
}

/// Step size in days for right-edge resizing when aligning to scale boundaries.
int stepDaysForScale(TimeScale scale) {
  switch (scale) {
    case TimeScale.weeks:
      return 7;
    case TimeScale.months:
      // Variable length in months; as a simplification return 30.
      return 30;
    case TimeScale.days:
      return 1;
  }
}
