import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stats_trends_service.dart';
import 'trend_points.dart';

/// Rango de tiempo para visualización de tendencias.
enum TrendsTimeRange {
  /// Últimos 7 días.
  week,

  /// Últimos 30 días.
  month,

  /// Últimos 90 días.
  quarter,
}

extension TrendsTimeRangeX on TrendsTimeRange {
  /// Número de días del rango.
  int get days {
    return switch (this) {
      TrendsTimeRange.week => 7,
      TrendsTimeRange.month => 30,
      TrendsTimeRange.quarter => 90,
    };
  }

  /// Etiqueta de visualización en español.
  String get labelEs {
    return switch (this) {
      TrendsTimeRange.week => '7 días',
      TrendsTimeRange.month => '30 días',
      TrendsTimeRange.quarter => '90 días',
    };
  }

  /// Etiqueta de visualización en inglés.
  String get labelEn {
    return switch (this) {
      TrendsTimeRange.week => '7 days',
      TrendsTimeRange.month => '30 days',
      TrendsTimeRange.quarter => '90 days',
    };
  }
}

/// Estado de datos de tendencias.
class TrendsData {
  const TrendsData({
    required this.productivityPoints,
    required this.focusPoints,
    required this.range,
    this.trendAnalysis,
    this.mostActiveQuadrant,
    this.averageDailyCompletions,
  });

  final List<DailyProductivityPoint> productivityPoints;
  final List<DailyFocusPoint> focusPoints;
  final TrendsTimeRange range;
  final TrendAnalysis? trendAnalysis;
  final Quadrant? mostActiveQuadrant;
  final double? averageDailyCompletions;
}

/// Controller para el rango de tiempo seleccionado.
class TrendsTimeRangeController extends Notifier<TrendsTimeRange> {
  @override
  TrendsTimeRange build() => TrendsTimeRange.week;

  void set(TrendsTimeRange value) {
    state = value;
  }
}

/// Provider para el rango de tiempo actual.
final trendsTimeRangeProvider =
    NotifierProvider<TrendsTimeRangeController, TrendsTimeRange>(
  TrendsTimeRangeController.new,
);

/// Provider para calcular los datos de tendencias.
final statsTrendsControllerProvider = FutureProvider<TrendsData>((ref) async {
  final service = ref.read(statsTrendsServiceProvider);
  final range = ref.watch(trendsTimeRangeProvider);

  final now = DateTime.now();
  final to = DateTime(now.year, now.month, now.day);
  final from = to.subtract(Duration(days: range.days));

  // Cargar datos en paralelo
  final results = await Future.wait([
    service.getDailyProductivity(from: from, to: to),
    service.getDailyFocus(from: from, to: to),
  ]);

  final productivityPoints = results[0] as List<DailyProductivityPoint>;
  final focusPoints = results[1] as List<DailyFocusPoint>;

  // Calcular análisis de tendencia comparando con período anterior
  TrendAnalysis? analysis;
  if (productivityPoints.length > 1) {
    final previousFrom = from.subtract(Duration(days: range.days));
    final previousTo = from;

    final previousPoints = await service.getDailyProductivity(
      from: previousFrom,
      to: previousTo,
    );

    analysis = service.analyzeTrend(
      currentPeriodPoints: productivityPoints,
      previousPeriodPoints: previousPoints,
    );
  }

  // Calcular estadísticas adicionales
  final mostActive = productivityPoints.isNotEmpty
      ? service.getMostActiveQuadrant(productivityPoints)
      : null;

  final avgDaily = productivityPoints.isNotEmpty
      ? service.getAverageDailyCompletions(productivityPoints)
      : null;

  return TrendsData(
    productivityPoints: productivityPoints,
    focusPoints: focusPoints,
    range: range,
    trendAnalysis: analysis,
    mostActiveQuadrant: mostActive,
    averageDailyCompletions: avgDaily,
  );
});
