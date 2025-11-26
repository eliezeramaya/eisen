import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FocusPeriod { today, week, month }

extension FocusPeriodLabel on FocusPeriod {
  String get label => switch (this) {
        FocusPeriod.today => 'Today',
        FocusPeriod.week => 'This week',
        FocusPeriod.month => 'This month',
      };
}

class FocusWindowSegment {
  const FocusWindowSegment({
    required this.start,
    required this.end,
    required this.color,
  }) : assert(start <= end, 'Segment start must be before end');

  final double start;
  final double end;
  final Color color;
}

class FocusDashboardState {
  const FocusDashboardState({
    required this.focusScore,
    required this.focusLabel,
    required this.currentHourPosition,
    required this.windowSegments,
    required this.windowHandlePosition,
    required this.period,
    required this.selectedDate,
  });

  final int focusScore;
  final String focusLabel;
  final double currentHourPosition;
  final List<FocusWindowSegment> windowSegments;
  final double windowHandlePosition;
  final FocusPeriod period;
  final DateTime selectedDate;

  FocusDashboardState copyWith({
    int? focusScore,
    String? focusLabel,
    double? currentHourPosition,
    List<FocusWindowSegment>? windowSegments,
    double? windowHandlePosition,
    FocusPeriod? period,
    DateTime? selectedDate,
  }) {
    return FocusDashboardState(
      focusScore: focusScore ?? this.focusScore,
      focusLabel: focusLabel ?? this.focusLabel,
      currentHourPosition: currentHourPosition ?? this.currentHourPosition,
      windowSegments: windowSegments ?? this.windowSegments,
      windowHandlePosition: windowHandlePosition ?? this.windowHandlePosition,
      period: period ?? this.period,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class FocusDashboardController extends Notifier<FocusDashboardState> {
  @override
  FocusDashboardState build() {
    return FocusDashboardState(
      focusScore: 86,
      focusLabel: 'En flujo',
      currentHourPosition: 0.55,
      windowHandlePosition: 0.46,
      period: FocusPeriod.today,
      selectedDate: DateTime.now(),
      windowSegments: const [
        FocusWindowSegment(
          start: 0.0,
          end: 0.22,
          color: Color(0xFF2A2F3A),
        ),
        FocusWindowSegment(
          start: 0.22,
          end: 0.38,
          color: Color(0xFF66D08F),
        ),
        FocusWindowSegment(
          start: 0.38,
          end: 0.52,
          color: Color(0xFF4FA4F7),
        ),
        FocusWindowSegment(
          start: 0.52,
          end: 0.64,
          color: Color(0xFF66D08F),
        ),
        FocusWindowSegment(
          start: 0.64,
          end: 0.86,
          color: Color(0xFF2A2F3A),
        ),
        FocusWindowSegment(
          start: 0.86,
          end: 1.0,
          color: Color(0xFF8B2F3A),
        ),
      ],
    );
  }

  void setHandlePosition(double value) {
    final clamped = value.clamp(0.0, 1.0);
    state = state.copyWith(windowHandlePosition: clamped);
  }

  void setPeriod(FocusPeriod period) {
    if (period == state.period) return;
    final baseScore = switch (period) {
      FocusPeriod.today => 86,
      FocusPeriod.week => 82,
      FocusPeriod.month => 78,
    };
    state = state.copyWith(
      period: period,
      focusScore: baseScore,
      focusLabel: period == FocusPeriod.today ? 'En flujo' : 'Constante',
      selectedDate: DateTime.now(),
    );
  }
}

final focusDashboardControllerProvider =
    NotifierProvider<FocusDashboardController, FocusDashboardState>(
  FocusDashboardController.new,
);
