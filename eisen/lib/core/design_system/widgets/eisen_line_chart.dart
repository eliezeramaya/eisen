import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Widget de gráfico de líneas siguiendo el design system Eisen.
///
/// Soporta múltiples series de datos (una por cuadrante) y
/// aplica los tokens de color y espaciado de Eisen.
class EisenLineChart extends StatelessWidget {
  const EisenLineChart({
    super.key,
    required this.data,
    this.height = 200,
    this.showGrid = true,
    this.showDots = true,
    this.animate = true,
  });

  /// Datos a visualizar: fecha → valor por cuadrante.
  final List<MapEntry<DateTime, Map<Quadrant, int>>> data;

  /// Altura del gráfico.
  final double height;

  /// Si mostrar la cuadrícula de fondo.
  final bool showGrid;

  /// Si mostrar puntos en las líneas.
  final bool showDots;

  /// Si animar el gráfico.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No hay datos para mostrar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colores por cuadrante (consistentes con el resto de la app)
    final colors = {
      Quadrant.q1: _getQuadrantColor(Quadrant.q1, colorScheme),
      Quadrant.q2: _getQuadrantColor(Quadrant.q2, colorScheme),
      Quadrant.q3: _getQuadrantColor(Quadrant.q3, colorScheme),
      Quadrant.q4: _getQuadrantColor(Quadrant.q4, colorScheme),
    };

    // Preparar spots para cada cuadrante
    final spotsByQuadrant = <Quadrant, List<FlSpot>>{};

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      final x = i.toDouble();

      for (final quadrant in Quadrant.values) {
        final value = entry.value[quadrant] ?? 0;
        spotsByQuadrant.putIfAbsent(quadrant, () => []).add(
              FlSpot(x, value.toDouble()),
            );
      }
    }

    // Crear líneas
    final lines = <LineChartBarData>[];

    for (final quadrant in Quadrant.values) {
      final spots = spotsByQuadrant[quadrant] ?? [];
      if (spots.isEmpty) continue;

      // Solo mostrar cuadrantes con datos
      if (spots.every((spot) => spot.y == 0)) continue;

      lines.add(
        LineChartBarData(
          spots: spots,
          color: colors[quadrant],
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: showDots,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: colors[quadrant]!,
                strokeWidth: 1.5,
                strokeColor: colorScheme.surface,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: colors[quadrant]!.withAlpha(20),
          ),
        ),
      );
    }

    // Calcular valor máximo para el eje Y
    final maxY = data
        .expand((e) => e.value.values)
        .fold<int>(0, (max, val) => val > max ? val : max)
        .toDouble();

    final adjustedMaxY = (maxY > 0 ? maxY * 1.1 : 10.0).toDouble();

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(
          right: EisenSpacing.md,
          top: EisenSpacing.sm,
        ),
        child: LineChart(
          LineChartData(
            lineBarsData: lines,
            minY: 0,
            maxY: adjustedMaxY,
            gridData: FlGridData(
              show: showGrid,
              drawVerticalLine: false,
              horizontalInterval: adjustedMaxY / 4,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: colorScheme.outlineVariant.withAlpha(50),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: (adjustedMaxY / 4).toDouble(),
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == adjustedMaxY) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      value.toInt().toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(128),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: (data.length / 4).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox.shrink();
                    }

                    final date = data[index].key;
                    final label = '${date.day}/${date.month}';

                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => colorScheme.surfaceContainerHigh,
                tooltipBorderRadius: BorderRadius.circular(EisenRadius.sm),
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: EisenSpacing.sm,
                  vertical: EisenSpacing.xs,
                ),
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    final quadrant = Quadrant.values[spots.indexOf(spot)];
                    final quadrantLabel = _getQuadrantLabel(quadrant);

                    return LineTooltipItem(
                      '$quadrantLabel: ${spot.y.toInt()}',
                      theme.textTheme.bodySmall!.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
          duration: animate ? const Duration(milliseconds: 250) : Duration.zero,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  /// Obtiene el color para un cuadrante.
  Color _getQuadrantColor(Quadrant quadrant, ColorScheme colorScheme) {
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

  /// Obtiene la etiqueta para un cuadrante.
  String _getQuadrantLabel(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.q1:
        return 'Q1';
      case Quadrant.q2:
        return 'Q2';
      case Quadrant.q3:
        return 'Q3';
      case Quadrant.q4:
        return 'Q4';
    }
  }
}
