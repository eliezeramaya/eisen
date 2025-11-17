Architecture Overview

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
