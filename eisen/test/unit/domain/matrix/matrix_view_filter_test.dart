import 'package:eisen/features/eisen_matrix/domain/focus_space.dart';
import 'package:eisen/features/eisen_matrix/domain/matrix_view_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MatrixViewFilter.getDateRange', () {
    test('returns Monday-based week range', () {
      final reference = DateTime(2024, 1, 17); // Wednesday
      final filter = MatrixViewFilter(
        focusSpace: FocusSpace.general,
        timeFilter: MatrixTimeFilterType.week,
        referenceDate: reference,
      );

      final range = filter.getDateRange();

      expect(range.start, DateTime(2024, 1, 15));
      expect(range.end, DateTime(2024, 1, 22));
    });

    test('returns wide range for "all"', () {
      final reference = DateTime(2025, 6, 10);
      final filter = MatrixViewFilter(
        focusSpace: FocusSpace.general,
        timeFilter: MatrixTimeFilterType.all,
        referenceDate: reference,
      );

      final range = filter.getDateRange();

      expect(range.start, DateTime(2015, 1, 1));
      expect(range.end, DateTime(2036, 1, 1));
    });
  });

  group('MatrixViewFilter.copyWith', () {
    test('can toggle onlyCompleted while preserving other fields', () {
      final reference = DateTime(2024, 5, 2);
      final original = MatrixViewFilter(
        focusSpace: FocusSpace.general,
        timeFilter: MatrixTimeFilterType.today,
        referenceDate: reference,
      );

      final updated = original.copyWith(onlyCompleted: true);

      expect(updated.onlyCompleted, isTrue);
      expect(updated.focusSpace, original.focusSpace);
      expect(updated.timeFilter, original.timeFilter);
      expect(updated.referenceDate, original.referenceDate);
    });
  });
}
