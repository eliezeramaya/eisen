import 'package:eisen/features/calendar_gantt/presentation/pages/workflow_plan_page.dart';
import 'package:eisen/features/completed_tasks/presentation/pages/completed_matrix_page.dart';
import 'package:eisen/features/eisen_matrix/presentation/pages/matrix_page.dart';
import 'package:eisen/features/settings/presentation/pages/settings_screen.dart';
import 'package:eisen/ui/list_mode/list_mode_screen.dart';
import 'package:go_router/go_router.dart';

// Keep a single router instance to avoid route reset on app rebuilds
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'matrix',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: MatrixPage()),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/workflow-plan',
      name: 'workflow-plan',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: WorkflowPlanPage()),
    ),
    GoRoute(
      path: '/list-mode',
      name: 'list-mode',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: ListModeScreen()),
    ),
    GoRoute(
      path: '/completed-matrix',
      name: 'completed-matrix',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: CompletedMatrixPage()),
    ),
  ],
);

GoRouter createRouter() => _router;
