import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'project_category.dart';

/// Time filter type for completed tasks.
///
/// Determines the time range for filtering:
/// - [all]: No time filtering (all history)
/// - [year]: Full calendar year
/// - [month]: Full calendar month
/// - [week]: Monday to Sunday of the week
/// - [day]: Single day (00:00 to 23:59)
enum TimeFilterType {
  all,
  year,
  month,
  week,
  day;

  /// Human-readable display name
  String get displayName => switch (this) {
        TimeFilterType.all => 'Todo',
        TimeFilterType.year => 'Año',
        TimeFilterType.month => 'Mes',
        TimeFilterType.week => 'Semana',
        TimeFilterType.day => 'Día',
      };

  /// Icon for UI display
  IconData get icon => switch (this) {
        TimeFilterType.all => Icons.all_inclusive,
        TimeFilterType.year => Icons.calendar_today,
        TimeFilterType.month => Icons.calendar_month,
        TimeFilterType.week => Icons.date_range,
        TimeFilterType.day => Icons.today,
      };
}

/// Filter configuration for completed tasks.
///
/// Immutable filter state that combines:
/// - Time range filtering ([timeType] + [referenceDate])
/// - Optional project/category filtering ([project])
///
/// Uses [Equatable] for efficient comparison in Riverpod state.
class CompletedTasksFilter extends Equatable {
  const CompletedTasksFilter({
    required this.timeType,
    required this.referenceDate,
    this.project,
  });

  final TimeFilterType timeType;
  final DateTime referenceDate;
  final ProjectCategory? project;

  /// Compute the date range for this filter.
  ///
  /// Returns [DateTimeRange] with inclusive start and exclusive end:
  /// - [all]: Last 3 years to now + 1 day
  /// - [year]: Jan 1 00:00 to Jan 1 00:00 next year
  /// - [month]: First day 00:00 to first day 00:00 next month
  /// - [week]: Monday 00:00 to next Monday 00:00
  /// - [day]: Day 00:00 to next day 00:00
  DateTimeRange getDateRange() {
    final date = referenceDate;

    return switch (timeType) {
      TimeFilterType.all => DateTimeRange(
          start: DateTime(date.year - 3, 1, 1),
          end: DateTime(date.year, date.month, date.day)
              .add(const Duration(days: 1)),
        ),
      TimeFilterType.year => DateTimeRange(
          start: DateTime(date.year, 1, 1),
          end: DateTime(date.year + 1, 1, 1),
        ),
      TimeFilterType.month => DateTimeRange(
          start: DateTime(date.year, date.month, 1),
          end: DateTime(date.year, date.month + 1, 1),
        ),
      TimeFilterType.week => _getWeekRange(date),
      TimeFilterType.day => DateTimeRange(
          start: DateTime(date.year, date.month, date.day),
          end: DateTime(date.year, date.month, date.day + 1),
        ),
    };
  }

  /// Calculate Monday-to-Monday week range
  DateTimeRange _getWeekRange(DateTime date) {
    // Find Monday of the week containing date
    final weekday = date.weekday; // 1=Monday, 7=Sunday
    final daysFromMonday = weekday - 1;
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromMonday));
    final nextMonday = monday.add(const Duration(days: 7));

    return DateTimeRange(start: monday, end: nextMonday);
  }

  /// Human-readable description of the current filter
  String get description {
    final range = getDateRange();
    final projectName = project?.displayName ?? 'Todos los proyectos';

    return switch (timeType) {
      TimeFilterType.all => projectName,
      TimeFilterType.year => '${range.start.year} - $projectName',
      TimeFilterType.month =>
        '${_monthName(range.start.month)} ${range.start.year} - $projectName',
      TimeFilterType.week =>
        'Semana del ${range.start.day}/${range.start.month} - $projectName',
      TimeFilterType.day =>
        '${range.start.day}/${range.start.month}/${range.start.year} - $projectName',
    };
  }

  String _monthName(int month) => [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre'
      ][month - 1];

  @override
  List<Object?> get props => [timeType, referenceDate, project];

  CompletedTasksFilter copyWith({
    TimeFilterType? timeType,
    DateTime? referenceDate,
    ProjectCategory? project,
    bool clearProject = false,
  }) {
    return CompletedTasksFilter(
      timeType: timeType ?? this.timeType,
      referenceDate: referenceDate ?? this.referenceDate,
      project: clearProject ? null : (project ?? this.project),
    );
  }
}
