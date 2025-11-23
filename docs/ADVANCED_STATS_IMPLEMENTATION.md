# Estadísticas Avanzadas con Gráficas de Tendencias

## Resumen de Implementación

Este documento describe la implementación completa de la funcionalidad de **Estadísticas Avanzadas con Gráficas de Tendencias** en la aplicación Eisen.

## Características Implementadas

### 1. Modelos de Dominio (`trend_points.dart`)

- **DailyProductivityPoint**: Representa la productividad diaria con desglose por cuadrante
  - `date`: Fecha normalizada (UTC medianoche)
  - `completedCount`: Total de tareas completadas
  - `byQuadrant`: Map<Quadrant, int> con conteos por Q1-Q4
  - `getCount(quadrant)`: Helper para obtener conteo de un cuadrante específico

- **DailyFocusPoint**: Representa las sesiones de foco diarias
  - `date`: Fecha normalizada
  - `totalFocus`: Duration total de sesiones
  - `sessionsCount`: Número de sesiones completadas
  - `averageSessionDuration`: Propiedad computada

- **TrendAnalysis**: Análisis de tendencias entre períodos
  - `direction`: TrendDirection (increasing, decreasing, stable)
  - `percentageChange`: Cambio porcentual
  - `insight`: Mensaje generado automáticamente
  - `compare(current, previous)`: Factory para comparar períodos

- **TrendsData**: Contenedor de todos los datos de tendencias
  - `productivityPoints`: Lista de puntos diarios de productividad
  - `focusPoints`: Lista de puntos diarios de foco
  - `range`: TrendsTimeRange actual
  - `trendAnalysis`: Análisis de tendencia opcional
  - `mostActiveQuadrant`: Cuadrante más productivo
  - `averageDailyCompletions`: Promedio de tareas por día

### 2. Servicio de Agregación (`stats_trends_service.dart`)

**Métodos principales:**

- `getDailyProductivity(from, to)`: Agrega tareas completadas por día
  - Normaliza fechas a UTC medianoche
  - Agrupa por cuadrante (Q1-Q4)
  - Rellena gaps con días sin datos (valores en 0)

- `getDailyFocus(from, to)`: Agrega sesiones de foco por día
  - Suma duraciones (actualDuration ?? plannedDuration)
  - Cuenta número de sesiones
  - Rellena gaps para continuidad

- `analyzeTrend(current, previous)`: Compara dos períodos
  - Calcula porcentaje de cambio
  - Determina dirección (aumentando/disminuyendo/estable)
  - Genera insights automáticos en español

- `getMostActiveQuadrant(points)`: Encuentra el cuadrante con más tareas
- `getAverageDailyCompletions(points)`: Calcula promedio diario

**Características técnicas:**
- Usa `matrixControllerProvider` para acceso a tareas
- Usa `focusRepositoryProvider` para sesiones de foco
- Normalización consistente de fechas (UTC medianoche)
- Manejo de datos ausentes (gap filling)

### 3. Controller con Riverpod (`stats_trends_controller.dart`)

**Enum TrendsTimeRange:**
- `week`: 7 días
- `month`: 30 días
- `quarter`: 90 días
- Extension con `days`, `labelEs`, `labelEn`

**TrendsTimeRangeController:**
- `Notifier<TrendsTimeRange>` para manejar el rango seleccionado
- Método `set(range)` para cambiar el rango

**statsTrendsControllerProvider:**
- `FutureProvider<TrendsData>` que recalcula automáticamente
- Watch `trendsTimeRangeProvider` para reactividad
- Carga datos en paralelo con `Future.wait`
- Calcula automáticamente el período anterior para comparación
- Genera insights (tendencia, cuadrante activo, promedio)

### 4. Widgets de UI

#### EisenLineChart (`eisen_line_chart.dart`)

Widget de gráfico de líneas con design system Eisen:

**Props:**
- `data`: List<MapEntry<DateTime, Map<Quadrant, int>>>
- `height`: Altura del gráfico (default 200)
- `showGrid`: Mostrar cuadrícula de fondo
- `showDots`: Mostrar puntos en las líneas
- `animate`: Animar transiciones

**Características:**
- Múltiples series (una por cuadrante)
- Colores diferenciados por cuadrante:
  - Q1 (Urgente + Importante): Rojo
  - Q2 (Importante): Verde
  - Q3 (Urgente): Naranja
  - Q4 (Otras): Azul
- Área bajo la curva con transparencia
- Touch interactions con tooltips
- Grid horizontal con líneas punteadas
- Labels en ejes (fechas y valores)
- Estado vacío con mensaje

#### StatsTrendsSection (`stats_trends_section.dart`)

Sección completa de tendencias con:

**1. Header personalizado:**
- Ícono de trending_up
- Título "Tendencias de Productividad"

**2. Range selector:**
- ChoiceChips para 7d/30d/90d
- Estilo consistente con design system
- Cambio reactivo del rango

**3. Gráfico principal:**
- EisenLineChart con datos de productividad
- Leyenda con los 4 cuadrantes
- Card con borde outline

**4. Panel de Insights:**
- **Insight de Tendencia**: Dirección e ícono (↑↓→)
- **Cuadrante más activo**: Con mensaje contextual
- **Promedio diario**: Tareas completadas por día
- Cada insight en un _InsightCard con ícono y colores

**5. Estados:**
- **Loading**: Spinner + mensaje "Cargando tendencias..."
- **Error**: Ícono error + mensaje
- **Data**: Gráfico + insights

### 5. Integración en StatsPage

La sección de tendencias se agregó como **primera sección** en StatsPage, antes de WeeklySummarySection.

**Orden de secciones:**
1. **StatsTrendsSection** (NUEVO) ← Gráficas avanzadas
2. WeeklySummarySection
3. EisenhowerBalanceSection
4. WeeklyFocusTrendSection
5. NudgesSection

## Arquitectura

```
Domain Layer
├── trend_points.dart (Modelos)
├── stats_trends_service.dart (Lógica de agregación)
└── stats_trends_controller.dart (Riverpod state management)

Presentation Layer
├── widgets/
│   ├── eisen_line_chart.dart (Chart component)
│   └── stats_trends_section.dart (Section widget)
└── pages/
    └── stats_page.dart (Integración)
```

## Dependencias Agregadas

- **fl_chart: ^0.69.2** - Librería de gráficos para Flutter

## Consistencia con Design System

✅ Usa `EisenCard` para containers
✅ Usa constantes locales de spacing (_eisenSpacingXs, _eisenSpacingSm, etc.)
✅ Usa constantes locales de radius (_eisenRadiusSm, _eisenRadiusMd, _eisenRadiusLg)
✅ Colores desde `Theme.of(context).colorScheme`
✅ Tipografía desde `Theme.of(context).textTheme`
✅ Bordes con `outlined: true` en EisenCard
✅ Responsivo (chart width adaptable, dots solo para <14 días)

## Flujo de Datos

1. Usuario selecciona rango (7d/30d/90d) en ChoiceChip
2. `TrendsTimeRangeController.set(range)` actualiza el estado
3. `statsTrendsControllerProvider` se recomputa automáticamente (watch)
4. `StatsTrendsService` agrega datos de tareas y foco
5. Se calcula período anterior para comparación
6. Se generan insights automáticos
7. `StatsTrendsSection` recibe `AsyncValue<TrendsData>`
8. Se renderiza gráfico + insights

## Testing Pendiente

Para completar la implementación, se deben crear:

1. **Unit tests** para `StatsTrendsService`:
   - `getDailyProductivity` con diferentes rangos
   - `getDailyFocus` con sesiones variadas
   - `analyzeTrend` con escenarios de aumento/disminución/estabilidad
   - Gap filling (días sin datos)
   - Normalización de fechas

2. **Widget tests** para `EisenLineChart`:
   - Renderizado con múltiples series
   - Estado vacío
   - Touch interactions
   - Colores por cuadrante

3. **Widget tests** para `StatsTrendsSection`:
   - Cambio de rango
   - Estados: loading, error, data
   - Insights panel
   - Integración con FutureProvider

## Archivos Creados/Modificados

### Creados (5 archivos, ~1,300 líneas):
- `lib/features/stats/domain/trend_points.dart` (172 líneas)
- `lib/features/stats/domain/stats_trends_service.dart` (211 líneas)
- `lib/features/stats/domain/stats_trends_controller.dart` (137 líneas)
- `lib/core/design_system/widgets/eisen_line_chart.dart` (262 líneas)
- `lib/features/stats/presentation/widgets/stats_trends_section.dart` (520 líneas)

### Modificados (2 archivos):
- `pubspec.yaml` - Agregado fl_chart: ^0.69.2
- `lib/features/stats/presentation/pages/stats_page.dart` - Integrada StatsTrendsSection

## Próximos Pasos

1. ✅ Implementación completa del feature
2. ⏳ Crear tests unitarios (StatsTrendsService)
3. ⏳ Crear tests de widgets (EisenLineChart, StatsTrendsSection)
4. ⏳ Pruebas de integración end-to-end
5. ⏳ Optimización de rendimiento (si es necesario)
6. ⏳ Localización completa (inglés)

## Notas Técnicas

- **Normalización de fechas**: Todas las fechas se normalizan a UTC medianoche para agrupar correctamente
- **Gap filling**: Se crean puntos con valor 0 para días sin datos, asegurando continuidad en el gráfico
- **Comparación de períodos**: Se carga automáticamente el período anterior del mismo tamaño para análisis de tendencias
- **Performance**: Carga paralela de productividad y foco con `Future.wait`
- **Reactividad**: Uso de `watch` en trendsTimeRangeProvider para recálculo automático
- **Type safety**: Modelos inmutables con equality operators para caching confiable

---

**Fecha de implementación**: 2025-01-XX
**Implementado por**: GitHub Copilot (Claude Sonnet 4.5)
**Estado**: ✅ Implementación completa, tests pendientes
