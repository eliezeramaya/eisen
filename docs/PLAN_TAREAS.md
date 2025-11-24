# 📋 Plan de Tareas Pendientes - Eisen

**Fecha de creación**: 23 de Noviembre 2025  
**Estado global**: 92% completo

---

## 🎯 P0 - Crítico para Release 1.0

**Objetivo**: App lista para producción

### Testing Core (CRÍTICO)

- [ ] **Testing CRUD tareas**
  - [ ] Tests CreateTaskUseCase
  - [ ] Tests UpdateTaskUseCase
  - [ ] Tests DeleteTaskUseCase
  - [ ] Tests validaciones (título, cuadrante, duración)
  - [ ] Tests edge cases (límites, nulls, valores inválidos)
  - **Estado**: ❌ No iniciado
  - **Módulo**: `test/unit/tasks/`

- [ ] **Testing Settings persistence**
  - [ ] Tests UiPrefs save/load
  - [ ] Tests NotificationPrefs
  - [ ] Tests LanguageController
  - [ ] Tests AccessibilityController
  - [ ] Tests SharedPreferences integration
  - **Estado**: ❌ No iniciado
  - **Módulo**: `test/unit/settings/`

- [ ] **Testing Stats calculations**
  - [ ] Tests WeeklyStats aggregation
  - [ ] Tests BalanceBreakdown
  - [ ] Tests TrendPoints
  - [ ] Tests filtros (rango + proyecto)
  - [ ] Tests providers integration
  - **Estado**: ❌ No iniciado
  - **Módulo**: `test/unit/stats/`

### Polish & Performance

- [ ] **Fix responsive mobile issues**
  - [ ] Verificar Matrix en móvil
  - [ ] Verificar Settings panels
  - [ ] Verificar Stats page
  - [ ] Verificar Gantt en mobile
  - [ ] Ajustar overflows y layouts
  - **Estado**: ⚠️ Parcial (algunos ajustes hechos)
  - **Módulo**: Multiple

- [ ] **Performance audit**
  - [ ] Profiling Matrix treemap
  - [ ] Lazy loading tareas grandes
  - [ ] Optimizar builds de widgets
  - [ ] Cache de cálculos Stats
  - [ ] Debouncing de filtros
  - **Estado**: ❌ No iniciado
  - **Módulo**: Multiple

- [ ] **Mejorar narrativa insights/nudges**
  - [ ] Textos más contextuales
  - [ ] Métricas más claras
  - [ ] Mejores explicaciones "Por qué veo esto"
  - **Estado**: ⚠️ Básico (funciona pero mejorable)
  - **Módulo**: `features/insights/`, `features/stats/`

---

## 🔨 P1 - Alta Prioridad

**Objetivo**: Experiencia excepcional

### Design System

- [ ] **Unificar Design System**
  - [ ] Consolidar todos los widgets custom
  - [ ] Crear catálogo de componentes
  - [ ] Documentar uso de cada componente
  - [ ] Eliminar duplicados
  - [ ] Aplicar tokens consistentemente
  - **Estado**: ⚠️ Tokens definidos, sin unificar
  - **Módulo**: `core/design_system/`

### Testing Avanzado

- [ ] **Widget tests componentes**
  - [ ] MatrixPage interactions
  - [ ] TaskEditor form
  - [ ] Settings panels
  - [ ] Stats widgets
  - [ ] Focus/Pomodoro timer
  - [ ] Gantt interactions
  - **Estado**: ⚠️ Algunos tests básicos
  - **Módulo**: `test/widget/`

- [ ] **Golden tests pantallas**
  - [ ] Matrix responsive breakpoints
  - [ ] Settings Desktop/Mobile
  - [ ] Stats page
  - [ ] Gantt view
  - [ ] Dark/Light modes
  - **Estado**: ⚠️ Solo Matrix básico
  - **Módulo**: `test/golden/`

### UX Enhancements

- [ ] **Accessibility audit completo**
  - [ ] Semantic labels en todos los widgets
  - [ ] Screen reader testing
  - [ ] Contrast ratios (WCAG AA)
  - [ ] Focus indicators
  - [ ] Keyboard navigation
  - **Estado**: ⚠️ Básico implementado
  - **Módulo**: Multiple

- [ ] **Performance: Lazy loading**
  - [ ] Virtualización lista tareas
  - [ ] Pagination en completed tasks
  - [ ] Lazy load imágenes/assets
  - **Estado**: ❌ No iniciado
  - **Módulo**: `eisen_matrix/`, `completed_tasks/`

- [ ] **Búsqueda de tareas**
  - [ ] Search bar en Matrix
  - [ ] Filtro por título
  - [ ] Filtro por proyecto
  - [ ] Filtro por tags
  - [ ] Historial de búsquedas
  - **Estado**: ❌ No iniciado
  - **Módulo**: Multiple

- [ ] **Mejorar empty states**
  - [ ] Ilustraciones más claras
  - [ ] CTAs más prominentes
  - [ ] Tutoriales inline
  - **Estado**: ⚠️ Básicos implementados
  - **Módulo**: Multiple

---

## 📦 P2 - Media Prioridad

**Objetivo**: Features diferenciadores

### Sincronización Cloud

- [ ] **Backend implementation**
  - [ ] Elegir backend (Firebase/Supabase/custom)
  - [ ] Setup proyecto
  - [ ] API endpoints
  - [ ] Database schema
  - **Estado**: ❌ Solo interfaces definidas
  - **Módulo**: `core/sync/`

- [ ] **Auth flow completo**
  - [ ] Email/password
  - [ ] Google Sign-In
  - [ ] Apple Sign-In (opcional)
  - [ ] Password reset
  - [ ] Session management
  - **Estado**: ❌ No iniciado
  - **Módulo**: `features/auth/` (nuevo)

- [ ] **Offline-first sync**
  - [ ] Queue de operaciones
  - [ ] Reconciliación bidireccional
  - [ ] Conflict detection
  - [ ] Retry logic
  - **Estado**: ❌ No iniciado
  - **Módulo**: `core/sync/`

### Export & Import

- [ ] **Export datos**
  - [ ] Export JSON
  - [ ] Export CSV
  - [ ] Export PDF (stats)
  - [ ] Share via email/cloud
  - **Estado**: ❌ No iniciado (solo Stats básico)
  - **Módulo**: `features/export/` (nuevo)

### Documentación

- [ ] **Docs Design System**
  - [ ] Guía de componentes
  - [ ] Showcase/Storybook
  - [ ] Guidelines de uso
  - **Estado**: ❌ No iniciado
  - **Módulo**: `docs/design_system/`

---

## 💎 P3 - Baja Prioridad / Nice-to-have

**Estado**: ✅ **100% COMPLETADO**

### Features Implementados

- ✅ **Focus/Pomodoro completo** - Timer funcional, notificaciones, tracking
- ✅ **Haptic feedback mobile** - 4 intensidades, respeta preferencias
- ✅ **Advanced Stats** - Tendencias, gráficas, insights
- ✅ **Notification tones** - 5 tonos, preview, personalización
- ✅ **Gantt dependencies** - 4 tipos, validación ciclos, UI completa
- ✅ **P2 Nudges completo** - 9 reglas, acciones, tracking, notificaciones

### Features Documentados (No implementados)

- [ ] **Keyboard shortcuts**
  - [ ] Definir shortcuts principales
  - [ ] Implementar handlers
  - [ ] Ayuda contextual
  - **Estado**: ⚠️ Parcial (algunos básicos)

- [ ] **Onboarding tutorial**
  - [ ] First-time user flow
  - [ ] Feature discovery
  - [ ] Interactive tutorial
  - **Estado**: ❌ No iniciado

- [ ] **Conflict resolution (Sync)**
  - [ ] Merge strategies
  - [ ] User conflict resolver UI
  - **Estado**: ❌ Depende de Sync P2

---

## 🤖 Estrategia de IA/ML (P3 Futuro)

**Estado**: ✅ **100% DOCUMENTADO** (~1,400 líneas)

### Capa 0: Instrumentación y Datos

- [ ] **UserEvent system**
  - [ ] Definir esquema de eventos
  - [ ] Implementar AnalyticsService
  - [ ] Logging automático en eventos clave
  - [ ] UserBehaviorSnapshot aggregations
  - **Estado**: ❌ No iniciado
  - **Documentación**: ✅ Completa

- [ ] **Privacy controls**
  - [ ] UI en Settings
  - [ ] "Borrar historial"
  - [ ] "Restablecer ID anónimo"
  - [ ] Export datos ML
  - **Estado**: ⚠️ UI básica existe
  - **Documentación**: ✅ Completa

### Capa 1: IA Clásica (Modelos Predictivos)

- [ ] **TaskCompletionModel**
  - [ ] Training con datos sintéticos
  - [ ] Feature engineering
  - [ ] Export a Dart weights
  - [ ] Integration en UI
  - **Estado**: ❌ No iniciado
  - **Documentación**: ✅ Completa con código

- [ ] **OverloadRiskModel**
  - [ ] Scoring 0-1
  - [ ] Widget "Riesgo sobrecarga"
  - [ ] Sugerencias automáticas
  - **Estado**: ❌ No iniciado
  - **Documentación**: ✅ Completa con código

- [ ] **FocusWindowModel**
  - [ ] Detección mejores horas
  - [ ] Widget "Tu mejor hora"
  - [ ] CTA crear bloque
  - **Estado**: ❌ No iniciado
  - **Documentación**: ✅ Completa con código

- [ ] **ProcrastinationModel**
  - [ ] Score por tipo de tarea
  - [ ] Badges en Matrix
  - [ ] Nudges preventivos
  - **Estado**: ❌ No iniciado
  - **Documentación**: ✅ Completa con código

### Capa 2: IA Adaptativa (Personalización)

- [ ] **Multi-armed bandits**
  - [ ] Thompson Sampling implementation
  - [ ] Contextual bandits
  - [ ] Reward tracking (inmediata + diferida)
  - [ ] Adaptive nudge selection
  - **Estado**: ❌ No iniciado
  - **Documentación**: ✅ Completa con algoritmo

- [ ] **Clustering arquetipos**
  - [ ] K-means simple
  - [ ] 6 arquetipos definidos
  - [ ] UI "Tu perfil"
  - [ ] Personalización por arquetipo
  - **Estado**: ❌ No iniciado
  - **Documentación**: ✅ Completa con código

### Capa 3: IA Generativa (LLM Integration)

- [ ] **Daily Planner AI**
  - [ ] OpenAI integration
  - [ ] Prompt engineering
  - [ ] Modal interactivo UI
  - [ ] Apply plan → update tasks
  - **Estado**: ❌ No iniciado
  - **Documentación**: ✅ Completa con mockups

- [ ] **Task Breakdown Assistant**
  - [ ] LLM subtask generation
  - [ ] Bottom sheet UI
  - [ ] Cherry-picking subtasks
  - [ ] Auto-create tasks
  - **Estado**: ❌ No iniciado
  - **Documentación**: ✅ Completa con mockups

- [ ] **Natural Language explanations**
  - [ ] Explicaciones en Stats
  - [ ] "Por qué veo esto" enriquecido
  - [ ] Análisis semanal narrativo
  - **Estado**: ⚠️ Básico manual existe
  - **Documentación**: ✅ Completa con ejemplos

- [ ] **Privacy flows LLM**
  - [ ] Opt-in toggle
  - [ ] Data disclosure
  - [ ] Local LLM option (Ollama)
  - **Estado**: ❌ No iniciado
  - **Documentación**: ✅ Completa

---

## 📊 Resumen de Estados

### Por Prioridad

| Prioridad | Total Tareas | Completadas | En Progreso | Pendientes | % Completo |
|-----------|-------------|-------------|-------------|------------|------------|
| **P0** | 6 | 0 | 2 | 4 | 0% |
| **P1** | 10 | 2 | 3 | 5 | 20% |
| **P2** | 5 | 0 | 0 | 5 | 0% |
| **P3** | 6 | 6 | 0 | 0 | 100% |
| **ML Capa 0** | 2 | 0 | 0 | 2 | 0% |
| **ML Capa 1** | 4 | 0 | 0 | 4 | 0% |
| **ML Capa 2** | 2 | 0 | 0 | 2 | 0% |
| **ML Capa 3** | 4 | 0 | 0 | 4 | 0% |

### Por Categoría

| Categoría | Completadas | Pendientes | Estado |
|-----------|-------------|------------|--------|
| **Testing** | 25% | 75% | ⚠️ En progreso |
| **Performance** | 0% | 100% | ❌ No iniciado |
| **UX Polish** | 30% | 70% | ⚠️ Parcial |
| **Design System** | 20% | 80% | ⚠️ Tokens definidos |
| **Sync/Backend** | 0% | 100% | ❌ Solo interfaces |
| **IA/ML** | 0% | 100% | ✅ Documentado |

---

## 🎯 Recomendación de Orden de Ejecución

### Camino Rápido a Release 1.0 (Prioridad sugerida)

1. **Testing P0** (CRÍTICO)
   - CRUD tareas tests
   - Settings persistence tests
   - Stats calculations tests

2. **Polish P0**
   - Fix responsive issues
   - Performance audit básico

3. **Release 1.0** ✅
   - Beta testing
   - Bug fixes críticos
   - Store submissions

4. **Post-Release P1**
   - Design System unification
   - Widget/Golden tests
   - Accessibility audit
   - UX enhancements

5. **Post-Release P2**
   - Backend + Auth
   - Offline-first sync
   - Export features

6. **Futuro P3 ML** (Incremental)
   - Capa 0: Instrumentación
   - Capa 1: Modelos básicos
   - Capa 2: Personalización
   - Capa 3: IA Generativa

---

## 📝 Notas

- **Tests P0**: Críticos para prevenir regresiones antes de release
- **Performance**: Importante pero no bloqueante si la app funciona
- **ML Strategy**: Completamente documentada, lista para implementación progresiva
- **P3 Features**: Ya completadas en su mayoría (Focus, Stats avanzados, Nudges completo)

**Última actualización**: 23 de Noviembre 2025
