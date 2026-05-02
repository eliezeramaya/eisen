Architecture Overview

**Last reviewed**: 2026-05-02

## Project Structure

This Flutter application follows a **feature-first Clean Architecture** pattern with clear separation between domain, application, and presentation layers.

### Core Principles

- **Feature-first**: Each feature module (`features/eisen_matrix`, `features/focus`, etc.) contains its own domain, data, and presentation layers
- **Clean Architecture**: Business logic (domain) is independent of frameworks and UI
- **Dependency Rule**: Dependencies point inward (presentation → application → domain)
- **Single Responsibility**: Each layer has a clear, focused purpose

### Directory Layout

```
lib/
├── app/                          # Application bootstrap & routing
│   ├── router.dart              # GoRouter configuration
│   ├── theme.dart               # App theme configuration
│   └── app_shell.dart           # Responsive navigation scaffold
├── core/                         # Shared infrastructure
│   ├── analytics/               # Event tracking & user behavior
│   ├── backend/                 # Supabase client (stub, not initialized)
│   ├── design_system/           # Design tokens & base widgets
│   ├── notifications/           # Local notification service
│   ├── responsive/              # Responsive breakpoints & helpers
│   ├── services/                # Shared services (UI prefs, telemetry)
│   └── storage/                 # Local persistence wrappers
├── features/                     # Feature modules (feature-first)
│   ├── eisen_matrix/            # Core Eisenhower Matrix (treemap)
│   ├── tasks/                   # Task domain & CRUD
│   ├── stats/                   # Statistics & analytics views
│   ├── settings/                # App settings & preferences
│   ├── calendar_gantt/          # Timeline/Gantt view
│   ├── completed_tasks/         # Completed tasks history
│   ├── focus/                   # Focus mode & Pomodoro timer
│   ├── insights/                # Smart nudges system
│   ├── insights_ml/             # ML scoring (heuristic)
│   ├── insights_adaptive/       # Adaptive bandits & clustering
│   ├── importance/              # Importance scoring (Bayesian)
│   ├── habits/                  # Streaks service
│   ├── filters/                 # Category filters
│   ├── classification/          # Task classification
│   ├── atlas/                   # Atlas visualization
│   ├── pomodoro/                # Pomodoro page (placeholder)
│   └── onboarding/              # Onboarding flows (partial)
└── theme/                        # Theme extensions & tokens
```

### Feature Module Structure

Each feature follows Clean Architecture layers:

```
feature_name/
├── data/                        # Data layer (repositories, data sources)
│   ├── repositories/           # Repository implementations
│   ├── models/                 # DTOs and data models
│   └── datasources/            # Local/remote data sources (optional)
├── domain/                      # Business logic layer (framework-agnostic)
│   ├── entities/               # Core business objects
│   ├── repositories/           # Repository interfaces (contracts)
│   └── use_cases/              # Business rules & operations (optional)
├── application/                 # Application layer (optional)
│   └── controllers/            # State management (Riverpod)
└── presentation/                # UI layer
    ├── pages/                  # Full screen views (routes)
    ├── widgets/                # Reusable UI components
    └── controllers/            # UI-specific state (Riverpod Notifiers)
```

## State Management

**Technology**: Riverpod 3.x

**Key Patterns**:
- `Notifier<T>` / `AsyncNotifier<T>` - For mutable state with complex logic
- `Provider<T>` - For computed/derived state
- `FutureProvider<T>` - For async data loading
- `StreamProvider<T>` - For real-time updates

**Example**:
```dart
// Notifier for feature state
final matrixControllerProvider = 
    NotifierProvider<MatrixController, MatrixState>(
  MatrixController.new,
);

// Derived/computed state
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final state = ref.watch(matrixControllerProvider);
  final filter = ref.watch(filterProvider);
  return applyFilter(state.tasks, filter);
});
```

**Key Controllers**:
- `MatrixController` - Matrix state, CRUD, filters, zoom
- `FocusController` - Focus sessions, timer state
- `StatsController` - Statistics aggregation
- `SettingsController` - App preferences

## Routing & Navigation

**Technology**: GoRouter 17.x

**Routes** (defined in `app/router.dart`):
- `/matrix` - Eisenhower Matrix (home)
- `/focus` - Focus mode dashboard
- `/stats` - Statistics & insights
- `/workflow-plan` - Calendar/Gantt view
- `/settings` - App settings (with sub-routes)
- `/completed` - Completed tasks archive

**Features**:
- Type-safe navigation with route parameters
- Deep linking support
- Nested routes for complex UIs
- Redirect logic for auth/onboarding (future)

## Data Architecture

### Current: Local-First

**Storage**: SharedPreferences with JSON serialization
- Tasks stored as JSON arrays
- Settings as key-value pairs
- No database (Isar was removed)
- Fully offline-capable

### Future: Supabase Sync

**Status**: Prepared but not initialized

**Components**:
- `BackendClient` interface (`core/backend/backend_client.dart`)
- `SupabaseBackendClient` stub implementation
- Activated only when `ENABLE_CLOUD_SYNC=true`

See `/docs/SUPABASE_READINESS.md` for details.

## Domain Model

### Core Entities

**Task** (`features/tasks/domain/entities/task.dart`):
- Core business object
- Properties: id, title, description, quadrant, durationMinutes, dueDate, project, tags
- Immutable (copyWith pattern)
- Validation rules in domain layer

**Quadrant** (`features/eisen_matrix/domain/quadrant.dart`):
```dart
enum Quadrant {
  q1, // Urgent & Important (Do first)
  q2, // Not urgent & Important (Schedule)
  q3, // Urgent & Not important (Delegate)
  q4, // Not urgent & Not important (Eliminate)
}
```

**FocusSession** (`features/focus/domain/focus_session.dart`):
- Focus mode session tracking
- Types: Pomodoro, Deep Work, Sprint
- Duration, completion status, linked task

### Eisenhower Matrix Domain

The matrix uses a custom **squarified treemap algorithm**:

**Key Components**:
- `TreemapRect` - Normalized layout rectangle [0..1]
- `computeSquarifiedLayout()` - Layout algorithm
- `EisenTreemapHybrid` - Hybrid layout with quadrant grouping

**Layout Process**:
1. Group tasks by quadrant
2. Apply squarified algorithm per quadrant
3. Normalize to [0..1] coordinate space
4. Map to canvas coordinates in painter

**Rendering**: `CustomPainter` with hit-testing for interaction

**State**: 
- matrixControllerProvider is a NotifierProvider<MatrixController, MatrixState>.
- MatrixState includes tasks, selectedId, zoom quadrant, theme mode, search query, and density.

**Persistence**:
- MatrixRepository abstracts persistence. LocalPrefsMatrixRepository uses shared_preferences with compact JSON.

**Treemap**:
- computeSquarifiedLayout groups by quadrant when not zoomed and lays out each quadrant independently within its quadrant cell.
- When zoom is set, the selected quadrant consumes the entire canvas.

## Responsive Design

**System**: Breakpoint-based adaptive layouts

| Breakpoint | Width | Navigation | Device |
|------------|-------|------------|--------|
| compact | < 600px | BottomNavigationBar | Mobile |
| medium | 600-904px | BottomNavigationBar | Tablet portrait |
| expanded | 905-1239px | NavigationRail | Tablet landscape |
| large | ≥ 1240px | NavigationDrawer | Desktop |

**Implementation**: `AppShell` widget adapts navigation automatically based on screen width.

**Extensions**: `context.deviceClass`, `context.isCompact`, etc.

See `/docs/RESPONSIVE_GUIDE.md` for details.

## Analytics & AI Architecture

### Three-Layer AI System

**Capa 0 - Instrumentation** (✅ Complete):
- `UserEvent` - Event tracking model
- `AnalyticsService` - Event collection & persistence
- `UserBehaviorService` - Behavior aggregation
- `UserBehaviorSnapshot` - Daily/weekly metrics
- Location: `lib/core/analytics/`

**Capa 1 - ML Scoring** (✅ Implemented with heuristics):
- Productivity scoring (overload, procrastination, focus windows)
- Task completion prediction
- Heuristic models (designed to be replaced with trained models)
- Location: `lib/features/insights_ml/`

**Capa 2 - Adaptive AI** (✅ Complete):
- Thompson Sampling bandits for nudge selection
- Productivity clustering (morning/night, sprinter/marathoner)
- Contextual recommendations
- Location: `lib/features/insights_adaptive/`

**Capa 3 - Generative AI** (🚧 Planned, not implemented):
- LLM integration for planning assistance
- Natural language task breakdown
- Daily plan generation
- Future implementation

### Nudges System

**Components** (`features/insights/`):
- 9 rule-based nudges with semantic categories
- 14 actionable suggestions with deep links
- Tracking: seen/dismissed/acted
- Push notifications with quiet hours
- UI feedback: "Útil/No relevante", "¿Por qué veo esto?"

**Integration**: Stats page, notifications, adaptive selection

## Design System

**Theme**: Material 3 with custom "liquid-glass" tokens

**Tokens** (`lib/core/design_system/`):
- Spacing: 8pt grid (4, 8, 12, 16, 24, 32, 48)
- Border radius: 8, 12, 20
- Typography: Material 3 text styles
- Colors: Adaptive light/dark with opacity layers

**Accessibility**:
- WCAG 2.1 Level AA target
- Touch targets: 48×48px (mobile), ≥40×40px (desktop)
- Semantic labels for screen readers
- Keyboard navigation support

See `/docs/THEME_TOKENS.md` for full token reference.

## Performance Strategies

**Key Optimizations**:
- Layout memoization with LRU caches
- Viewport culling for large datasets
- Incremental state updates (avoid full rebuilds)
- Path caching in `CustomPainter`
- Lazy loading where appropriate
- Image caching for assets

See `/docs/PERFORMANCE_GUIDELINES.md` for guidelines.

## Testing Architecture

**Structure**:
- `test/unit/` - Domain logic, algorithms, services (pure Dart)
- `test/widget/` - UI components with `ProviderScope`
- `integration_test/` - End-to-end flows

**Coverage**: 500+ tests across unit and widget categories

**Tools**:
- `flutter_test` for unit/widget tests
- `IntegrationTestWidgetsFlutterBinding` for E2E
- Provider overrides for isolation
- Mock repositories for testing

**Note**: Golden tests were removed; visual regression validated manually.

See `/docs/testing_plan.md` for full strategy.

## Privacy & Security

**Principles**:
- **Privacy-first**: All data on-device by default
- **Opt-in analytics**: Telemetry requires explicit consent
- **Anonymous IDs**: User IDs are SHA-256 hashed and resettable
- **No tracking**: No third-party analytics without permission
- **Data portability**: Export all user data as JSON

**Settings** (Settings > General):
- UiPrefsData in `lib/core/services/ui_prefs.dart` centralizes UI preferences (language, region, date/time formats, text scale, notifications, workflow plan, layout sliders).
- Settings > General (`lib/features/settings/presentation/sections/general_panel.dart`) reads/writes UiPrefs via `uiPrefsControllerProvider`, including Workflow Plan which toggles the Gantt/Workflow button in the main toolbar.

See `/docs/PRIVACY_IMPLEMENTATION.md` and `/docs/PRIVACY.md`.

## Key Feature Architectures

### Eisenhower Matrix
- Custom treemap layout with squarified algorithm
- Drag-drop between quadrants
- Zoom into single quadrant
- Resize by duration
- Responsive canvas with hit-testing

### Focus Mode
- Complete Pomodoro/Deep Work/Sprint timer
- Session history tracking
- Audio + haptic feedback
- Task linking for focused work
- Countdown with circular progress

### Calendar/Gantt
- Real task integration (due dates → timeline spans)
- Drag-to-resize and drag-to-move with snapping
- Multiple scales (day/week/month)
- Dependency arrows (optional)
- Keyboard navigation + accessibility
- Viewport culling for performance

See `/docs/CALENDAR_GANTT.md`.

### Statistics
- Weekly/monthly/quarterly views
- Quadrant balance visualization
- Focus trend charts with fl_chart
- Productivity insights and nudges
- Export to JSON/CSV

## Future Architecture Plans

**Not Yet Implemented**:
1. **Supabase Sync** - Multi-device cloud backup
2. **Generative AI** - LLM integration for assistance
3. **ML Models** - Replace heuristics with trained models
4. **Offline-first Sync** - Conflict resolution engine
5. **Advanced Classification** - Auto-categorization of tasks

See `/docs/project_status.md` for full roadmap.

---

**Related Documentation**:
- [Development Guide](../../README.md)
- [Testing Plan](testing_plan.md)
- [Responsive Guide](RESPONSIVE_GUIDE.md)
- [Calendar/Gantt](CALENDAR_GANTT.md)
- [Theme Tokens](THEME_TOKENS.md)
- [Privacy Implementation](PRIVACY_IMPLEMENTATION.md)
- [Project Status & Roadmap](/docs/project_status.md)

- Feature-first structure: features/eisen_matrix contains domain, presentation (controllers/widgets/pages), and data (repos/datasources).
- Domain: Task and Quadrant, weight formula, and squarified treemap layout producing normalized rects [0..1].
- Application: Riverpod Notifier (MatrixController) handles CRUD, filters, zoom, theme mode, and persistence.
- Presentation: CustomPainter-based TreemapCanvas for drawing and hit-testing, Toolbar, Legend, Minimap, and Inspector Drawer for editing.
- Core: Liquid-glass ThemeExtension tokens, a11y helpers, and shared preferences wrapper.

Routing
- go_router with a single route for the matrix page (extensible for future views).

State
- matrixControllerProvider is a NotifierProvider<MatrixController, MatrixState>.
- MatrixState includes tasks, selectedId, zoom quadrant, theme mode, search query, and density.

Persistence
- MatrixRepository abstracts persistence. LocalPrefsMatrixRepository uses shared_preferences with compact JSON.

Treemap
- computeSquarifiedLayout groups by quadrant when not zoomed and lays out each quadrant independently within its quadrant cell.
- When zoom is set, the selected quadrant consumes the entire canvas.

Settings · General
- UiPrefsData in `lib/core/services/ui_prefs.dart` centralizes UI preferences (language, region, date/time formats, text scale, notifications, workflow plan, layout sliders).
- Settings > General (`lib/features/settings/presentation/sections/general_panel.dart`) reads/writes UiPrefs via `uiPrefsControllerProvider`, including Workflow Plan which toggles the Gantt/Workflow button in the main toolbar.
