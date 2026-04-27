import 'package:equatable/equatable.dart';

import 'matrix_view_filter.dart';

/// A saved combination of focus space + time filter + completion state.
///
/// Example name: "Trabajo – Semana completadas".
class SavedMatrixView extends Equatable {
  const SavedMatrixView({
    required this.id,
    required this.name,
    required this.focusSpaceId,
    required this.timeFilter,
    required this.referenceDate,
    required this.onlyCompleted,
  });

  final String id;
  final String name;
  final String focusSpaceId;
  final MatrixTimeFilterType timeFilter;
  final DateTime referenceDate;
  final bool onlyCompleted;

  SavedMatrixView copyWith({
    String? id,
    String? name,
    String? focusSpaceId,
    MatrixTimeFilterType? timeFilter,
    DateTime? referenceDate,
    bool? onlyCompleted,
  }) {
    return SavedMatrixView(
      id: id ?? this.id,
      name: name ?? this.name,
      focusSpaceId: focusSpaceId ?? this.focusSpaceId,
      timeFilter: timeFilter ?? this.timeFilter,
      referenceDate: referenceDate ?? this.referenceDate,
      onlyCompleted: onlyCompleted ?? this.onlyCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        focusSpaceId,
        timeFilter,
        referenceDate,
        onlyCompleted,
      ];
}
