import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_line_chart.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/stats/domain/stats_trends_controller.dart';
import 'package:eisen/features/stats/domain/trend_points.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Spacing constants from EisenTokens
const double _eisenSpacingXs = 4.0;
const double _eisenSpacingSm = 8.0;
const double _eisenSpacingMd = 12.0;
const double _eisenSpacingLg = 16.0;
const double _eisenSpacingXl = 24.0;

// Radius constants from EisenTokens
const double _eisenRadiusSm = 8.0;
const double _eisenRadiusMd = 12.0;
const double _eisenRadiusLg = 16.0;

/// Sección de estadísticas avanzadas con gráficas de tendencias.
///
/// Muestra:
/// - Gráfica de productividad por cuadrante (últimos 7/30/90 días)
/// - Mini-panel de insights automáticos
/// - Controles para cambiar el rango temporal
class StatsTrendsSection extends ConsumerWidget {
  const StatsTrendsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(statsTrendsControllerProvider);
    final currentRange = ref.watch(trendsTimeRangeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: _eisenSpacingSm),
            Text(
              'Tendencias de Productividad',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: _eisenSpacingXs),
        Text(
          'Insights avanzados sobre tu ritmo y equilibrio.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: _eisenSpacingMd),
        // Range selector chips
        _RangeSelector(currentRange: currentRange),
        const SizedBox(height: _eisenSpacingLg),
        // Chart area
        trendsAsync.when(
          data: (data) => _DataView(data: data),
          loading: () => const _LoadingView(),
          error: (error, stack) => _ErrorView(error: error),
        ),
      ],
    );
  }
}

/// Selector de rango temporal.
class _RangeSelector extends ConsumerWidget {
  const _RangeSelector({required this.currentRange});

  final TrendsTimeRange currentRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: _eisenSpacingSm,
      children: TrendsTimeRange.values.map((range) {
        final isSelected = range == currentRange;

        return ChoiceChip(
          label: Text(range.labelEs),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              ref.read(trendsTimeRangeProvider.notifier).set(range);
            }
          },
          selectedColor: colorScheme.primaryContainer,
          backgroundColor: colorScheme.surfaceContainerHigh,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: _eisenSpacingMd,
            vertical: _eisenSpacingXs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_eisenRadiusLg),
          ),
        );
      }).toList(),
    );
  }
}

/// Vista de datos con gráfico e insights.
class _DataView extends StatelessWidget {
  const _DataView({required this.data});

  final TrendsData data;

  @override
  Widget build(BuildContext context) {
    final chartData = data.productivityPoints.map((point) {
      return MapEntry(point.date, point.byQuadrant);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gráfico principal
        EisenCard(
          outlined: true,
          padding: const EdgeInsets.all(_eisenSpacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tareas completadas por día',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: _eisenSpacingLg),
              EisenLineChart(
                data: chartData,
                height: 200,
                showGrid: true,
                showDots: chartData.length <= 14,
              ),
              const SizedBox(height: _eisenSpacingMd),
              _ChartLegend(),
            ],
          ),
        ),
        const SizedBox(height: _eisenSpacingLg),
        // Panel de insights
        _InsightsPanel(data: data),
      ],
    );
  }
}

/// Leyenda del gráfico.
class _ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: _eisenSpacingMd,
      runSpacing: _eisenSpacingXs,
      children: [
        _LegendItem(
          color: Colors.red.shade600,
          label: 'Q1 (Urgente + Importante)',
        ),
        _LegendItem(
          color: Colors.green.shade600,
          label: 'Q2 (Importante)',
        ),
        _LegendItem(
          color: Colors.orange.shade600,
          label: 'Q3 (Urgente)',
        ),
        _LegendItem(
          color: Colors.blue.shade600,
          label: 'Q4 (Otras)',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Panel de insights automáticos.
class _InsightsPanel extends StatelessWidget {
  const _InsightsPanel({required this.data});

  final TrendsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final insights = <Widget>[];

    // Insight de tendencia
    if (data.trendAnalysis != null) {
      final analysis = data.trendAnalysis!;
      IconData icon;
      Color iconColor;

      switch (analysis.direction) {
        case TrendDirection.increasing:
          icon = Icons.trending_up;
          iconColor = Colors.green.shade600;
          break;
        case TrendDirection.decreasing:
          icon = Icons.trending_down;
          iconColor = Colors.red.shade600;
          break;
        case TrendDirection.stable:
          icon = Icons.trending_flat;
          iconColor = colorScheme.onSurface.withAlpha(128);
          break;
      }

      insights.add(
        _InsightCard(
          icon: icon,
          iconColor: iconColor,
          title: 'Tendencia',
          message: analysis.insight,
        ),
      );
    }

    // Insight de cuadrante más activo
    if (data.mostActiveQuadrant != null) {
      final quadrant = data.mostActiveQuadrant!;
      final quadrantLabel = _getQuadrantLabel(quadrant);
      final quadrantMessage = _getQuadrantMessage(quadrant);

      insights.add(
        _InsightCard(
          icon: Icons.filter_vintage,
          iconColor: _getQuadrantColor(quadrant),
          title: 'Cuadrante más activo',
          message: '$quadrantLabel - $quadrantMessage',
        ),
      );
    }

    // Insight de promedio diario
    if (data.averageDailyCompletions != null) {
      final avg = data.averageDailyCompletions!.toStringAsFixed(1);

      insights.add(
        _InsightCard(
          icon: Icons.speed,
          iconColor: colorScheme.primary,
          title: 'Promedio diario',
          message: '$avg tareas completadas por día',
        ),
      );
    }

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return EisenCard(
      outlined: true,
      padding: const EdgeInsets.all(_eisenSpacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: _eisenSpacingXs),
              Text(
                'Insights',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: _eisenSpacingMd),
          ...insights
              .expand(
                  (widget) => [widget, const SizedBox(height: _eisenSpacingSm)])
              .toList()
            ..removeLast(), // Remove last spacing
        ],
      ),
    );
  }

  String _getQuadrantLabel(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.q1:
        return 'Q1 (Urgente + Importante)';
      case Quadrant.q2:
        return 'Q2 (Importante)';
      case Quadrant.q3:
        return 'Q3 (Urgente)';
      case Quadrant.q4:
        return 'Q4 (Otras)';
    }
  }

  String _getQuadrantMessage(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.q1:
        return 'Crisis y emergencias atendidas';
      case Quadrant.q2:
        return '¡Excelente! Enfocado en lo importante';
      case Quadrant.q3:
        return 'Cuidado con las urgencias sin importancia';
      case Quadrant.q4:
        return 'Considera priorizar tareas más importantes';
    }
  }

  Color _getQuadrantColor(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.q1:
        return Colors.red.shade600;
      case Quadrant.q2:
        return Colors.green.shade600;
      case Quadrant.q3:
        return Colors.orange.shade600;
      case Quadrant.q4:
        return Colors.blue.shade600;
    }
  }
}

/// Card individual de insight.
class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(_eisenSpacingSm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_eisenRadiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(_eisenSpacingXs),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(_eisenRadiusSm),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: _eisenSpacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vista de carga.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return EisenCard(
      outlined: true,
      padding: const EdgeInsets.all(_eisenSpacingXl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: _eisenSpacingMd),
            Text(
              'Cargando tendencias...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(128),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista de error.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EisenCard(
      outlined: true,
      padding: const EdgeInsets.all(_eisenSpacingLg),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: colorScheme.error,
          ),
          const SizedBox(height: _eisenSpacingMd),
          Text(
            'Error al cargar tendencias',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: _eisenSpacingXs),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
