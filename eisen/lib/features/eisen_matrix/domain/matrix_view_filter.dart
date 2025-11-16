import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'focus_space.dart';

/// Time filter for the active Eisenhower matrix view.
///
/// - [today]: Single day (referenceDate)
/// - [week]: Monday–Monday week containing [referenceDate]
/// - [month]: Calendar month of [referenceDate]
/// - [year]: Calendar year of [referenceDate]
/// - [all]: No time filtering
enum MatrixTimeFilterType {
  today,
  week,
  month,
  year,
  all;

  String get displayName => switch (this) {
        MatrixTimeFilterType.today => 'Hoy',
        MatrixTimeFilterType.week => 'Esta semana',
        MatrixTimeFilterType.month => 'Este mes',
        MatrixTimeFilterType.year => 'Este año',
        MatrixTimeFilterType.all => 'Todo',
      };
}

/// Filter configuration for the active Eisenhower matrix view.
///
/// Combines:
/// - Focus space (category context)
/// - Time filter
/// - Reference date for relative ranges
/// - Optional completed-only toggle
class MatrixViewFilter extends Equatable {
  const MatrixViewFilter({
    required this.focusSpace,
    required this.timeFilter,
    required this.referenceDate,
    this.onlyCompleted = false,
  });

  final FocusSpace focusSpace;
  final MatrixTimeFilterType timeFilter;
  final DateTime referenceDate;
  final bool onlyCompleted;

  MatrixViewFilter copyWith({
    FocusSpace? focusSpace,
    MatrixTimeFilterType? timeFilter,
    DateTime? referenceDate,
    bool? onlyCompleted,
  }) {
    return MatrixViewFilter(
      focusSpace: focusSpace ?? this.focusSpace,
      timeFilter: timeFilter ?? this.timeFilter,
      referenceDate: referenceDate ?? this.referenceDate,
      onlyCompleted: onlyCompleted ?? this.onlyCompleted,
    );
  }

  /// Compute the date range for this filter.
  ///
  /// Returns [DateTimeRange] with inclusive start and exclusive end:
  /// - [today]: Day 00:00 to next day 00:00
  /// - [week]: Monday 00:00 to next Monday 00:00
  /// - [month]: First day 00:00 to first day 00:00 next month
  /// - [year]: Jan 1 00:00 to Jan 1 00:00 next year
  /// - [all]: Very wide range; callers may choose to ignore it for filtering
  DateTimeRange getDateRange() {
    final date = referenceDate;

    return switch (timeFilter) {
      MatrixTimeFilterType.all => DateTimeRange(
          start: DateTime(date.year - 10, 1, 1),
          end: DateTime(date.year + 10, 12, 31).add(const Duration(days: 1)),
        ),
      MatrixTimeFilterType.year => DateTimeRange(
          start: DateTime(date.year, 1, 1),
          end: DateTime(date.year + 1, 1, 1),
        ),
      MatrixTimeFilterType.month => DateTimeRange(
          start: DateTime(date.year, date.month, 1),
          end: DateTime(date.year, date.month + 1, 1),
        ),
      MatrixTimeFilterType.week => _getWeekRange(date),
      MatrixTimeFilterType.today => DateTimeRange(
          start: DateTime(date.year, date.month, date.day),
          end: DateTime(date.year, date.month, date.day + 1),
        ),
    };
  }

  DateTimeRange _getWeekRange(DateTime date) {
    // Monday-based week
    final weekday = date.weekday; // 1=Monday, 7=Sunday
    final daysFromMonday = weekday - 1;
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromMonday));
    final nextMonday = monday.add(const Duration(days: 7));
    return DateTimeRange(start: monday, end: nextMonday);
  }

  @override
  List<Object?> get props => [
        focusSpace,
        timeFilter,
        referenceDate,
        onlyCompleted,
      ];
}

