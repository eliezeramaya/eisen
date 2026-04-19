# ML Strategy – Implementación Actual

**Módulos**: `features/insights_ml/`, `features/insights_adaptive/`  
**Estado**: ✅ Capas 0, 1 y 2 implementadas | 🚧 Capa 3 pendiente  
**Última actualización**: Abril 2026

---

## Resumen de Capas

| Capa | Nombre | Estado | Módulo principal |
|------|--------|--------|-----------------|
| 0 | Instrumentación | ✅ Completo | `core/analytics/` |
| 1 | Scoring heurístico (IA Clásica) | ✅ Completo | `features/insights_ml/` |
| 2 | Bandits adaptativos (IA Adaptativa) | ✅ Completo | `features/insights_adaptive/` |
| 3 | IA Generativa / LLM | 🚧 Pendiente | `BackendMLApi` (placeholder) |

---

## Capa 0 – Instrumentación

**Módulo**: `core/analytics/`

Registra eventos de comportamiento del usuario de forma anónima (privacy-first). Alimenta a las capas superiores con datos de entrenamiento.

**Eventos clave** (`UserEventType`):
- `focusSessionEnded` — sesión de foco completada (con `actualMinutes`, `plannedMinutes`)
- Eventos de creación, completado y reprogramación de tareas

**`UserBehaviorService`**: Agrega eventos en snapshots diarios (`UserBehaviorSnapshot`) con métricas como:
- `tasksCreated`, `tasksCompleted`, `tasksRescheduled`
- `tasksCompletedQ1/Q2`, `focusSessionsCount`, `totalFocusDuration`

---

## Capa 1 – Scoring Heurístico (insights_ml)

**Módulo**: `features/insights_ml/`

```
insights_ml/
├── domain/
│   ├── productivity_scores.dart          # Modelos de salida
│   └── productivity_scoring_service.dart # Servicio + implementación heurística
├── data/
│   └── backend_ml_api.dart              # Placeholder para ML remoto futuro
└── presentation/
    └── widgets/
        └── stats_ml_section.dart         # UI en pantalla Stats
```

### Modelos de salida

| Modelo | Descripción |
|--------|-------------|
| `DailyProductivityScore` | Score diario con overload, Q2 ratio, procrastinación, foco |
| `FocusWindowSuggestion` | Franja horaria óptima de foco con confianza |
| `TaskCompletionPrediction` | Probabilidad de completar a tiempo vs reprogramar |
| `OverloadRisk` | Riesgo de sobrecarga para un día (0–1) |
| `ProcrastinationScore` | Probabilidad de procrastinar una tarea (0–1) |

### HeuristicProductivityScoringService

Implementación actual de `ProductivityScoringService`. Usa heurísticas sobre snapshots; diseñado para ser sustituido por modelo ML remoto sin cambiar la UI.

#### `computeDailyScores(from, to)`
- Lee snapshots del rango de fechas.
- Calcula por día:
  - **overloadScore**: `(tasksCreated/avgCreated × 0.6) + (1−completionRatio × 0.4)` / 2
  - **q2Ratio**: `tasksCompletedQ2 / totalCompleted`
  - **procrastinationScore**: `tasksRescheduled / tasksCreated`
  - **focusConsistency**: `focusMinutesHoy / avgFocusMinutes`

#### `computeFocusWindows()`
- Lee eventos `focusSessionEnded` de los últimos 30 días.
- Agrupa por hora del día; score por hora = `(avgDuration/90 × 0.6) + (count/5 × 0.4)`
- Retorna top-3 franjas horarias con su nivel de confianza.

#### `predictTaskCompletion(task)`
- Base: 0.7
- Ajustes: −0.1 por cada `replanCount`, +0.05 para Q2, −0.15 para Q4, −0.1 si >240min, −0.1 si vencida, etc.

#### `computeDailyOverloadRisk(date)`
- Compara tareas planificadas del día vs promedio de los últimos 7 días.

#### `predictTaskProcrastination(task)`
- Score basado en `replanCount`, duración, cuadrante, y palabras vagas en el título ("revisar", "ver", "checar"…).

### BackendMLApi (Placeholder)

**Archivo**: `insights_ml/data/backend_ml_api.dart`

Contrato vacío que documenta la interfaz que deberá implementar un servicio remoto (XGBoost/LightGBM) para reemplazar la heurística sin romper la UI:

```dart
class BackendMLApi {
  Future<TaskCompletionPrediction> fetchTaskPrediction(Task task)
}
```

Lanza `UnimplementedError` hasta que se conecte al backend real.

### UI: StatsMlSection

**Archivo**: `insights_ml/presentation/widgets/stats_ml_section.dart`

Muestra en la pantalla de Stats:
- **Riesgo de sobrecarga**: barra visual basada en `overloadRisk`.
- **Mejores franjas de foco**: chips con las horas recomendadas y botón CTA para crear bloque fijo.

---

## Capa 2 – Bandits Adaptativos (insights_adaptive)

**Módulo**: `features/insights_adaptive/`

```
insights_adaptive/
├── domain/
│   ├── bandit_engine.dart            # Interfaz abstracta del bandit
│   ├── bandit_models.dart            # NudgeArm, NudgeArmStats, BanditState
│   ├── cluster_models.dart           # ProductivityCluster, UserProductivityProfile
│   ├── clustering_service.dart       # Interfaz de clustering
│   ├── adaptive_policy_engine.dart   # Interfaz: selectBestNudgeArm, etc.
│   └── adaptive_providers.dart       # Riverpod providers
├── data/
│   ├── thompson_bandit_engine.dart           # Implementación Thompson Sampling
│   ├── bandit_state_repository.dart          # Persistencia local (SharedPreferences)
│   ├── productivity_clustering_service_impl.dart  # Clustering heurístico
│   └── adaptive_policy_engine_impl.dart      # Motor de política combinado
└── presentation/
    └── widgets/
        └── stats_adaptive_pattern_card.dart  # UI en Stats
```

### Nudge Arms (Brazos del Bandit)

| Arm | Descripción |
|-----|-------------|
| `focusBlock` | "Bloquea tiempo de foco en Q2" |
| `reduceTodayLoad` | "Reduce la carga de hoy" |
| `splitBigTask` | "Divide una tarea grande" |
| `dailyShutdown` | "Configura ritual de cierre" |

### ThompsonBanditEngine

Implementa Thompson Sampling sobre distribuciones Beta:

1. Por cada brazo, muestrea de `Beta(successes+1, failures+1)`.
2. Aplica sesgo contextual ligero según scores de productividad:
   - Alta sobrecarga → favorece `reduceTodayLoad`
   - Alta procrastinación → favorece `splitBigTask`
   - Alta ratio Q2 → favorece `focusBlock`
3. Selecciona el brazo con mayor muestra.

**Persistencia**: Estado del bandit guardado en `SharedPreferences` (`adaptive.bandit.state.v1`) como JSON.

### ProductivityClusteringServiceImpl

Clasifica al usuario en uno de 4 arquetipos según comportamiento de la última semana:

| Cluster | Señales detectadas |
|---------|--------------------|
| `nightSprinter` | Alta actividad en Q1 tardía, baja replanificación |
| `morningStrong` | Sesiones de foco tempranas frecuentes, alto completion ratio |
| `starterButNotFinisher` | Bajo completion ratio, alta replanificación |
| `unknown` | Sin patrón claro (datos insuficientes) |

### AdaptivePolicyEngineImpl

Combina clustering + scoring + bandit para seleccionar el mejor nudge:

1. Obtiene perfil semanal del usuario (`clusteringService`).
2. Obtiene scores de hoy (`scoringService`).
3. Pide al bandit que seleccione un brazo con contexto.
4. Si el perfil es conocido, sesga el resultado:
   - `nightSprinter` → siempre `dailyShutdown`
   - `morningStrong` → siempre `focusBlock`
   - `starterButNotFinisher` → siempre `splitBigTask`

### UI: StatsAdaptivePatternCard

**Archivo**: `insights_adaptive/presentation/widgets/stats_adaptive_pattern_card.dart`

Muestra en Stats:
- Nombre del patrón predominante de la semana.
- Descripción personalizada según cluster.
- CTA contextual (botón de acción recomendada) que navega a la pantalla correspondiente.

---

## Capa 3 – IA Generativa (Pendiente)

**Estado**: 🚧 No implementada

El contrato está documentado en `BackendMLApi`. La integración futura contempla:
- Daily Planner AI (sugerir plan del día).
- Task Breakdown Assistant (dividir tareas complejas con LLM).
- Explicaciones en lenguaje natural (usar outputs de Capa 1/2 + LLM para generar textos personalizados).

---

## Flujo de Datos General

```
UserBehavior Events (Capa 0)
        ↓
DailySnapshots (UserBehaviorService)
        ↓
HeuristicProductivityScoringService (Capa 1)
  → DailyProductivityScore
  → FocusWindowSuggestion
  → OverloadRisk
        ↓
AdaptivePolicyEngineImpl (Capa 2)
  + ProductivityClusteringService
  + ThompsonBanditEngine
        ↓
NudgeArm seleccionado
        ↓
StatsAdaptivePatternCard / StatsMlSection (UI)
```

---

## Providers Riverpod

| Provider | Capa | Descripción |
|----------|------|-------------|
| `productivityScoringServiceProvider` | 1 | `HeuristicProductivityScoringService` |
| `banditStateRepositoryProvider` | 2 | `LocalBanditStateRepository` |
| `banditEngineProvider` | 2 | `ThompsonBanditEngine` |
| `productivityClusteringProvider` | 2 | `ProductivityClusteringServiceImpl` |
| `adaptivePolicyEngineProvider` | 2 | `AdaptivePolicyEngineImpl` |
