import 'package:eisen/features/calendar_gantt/presentation/pages/workflow_plan_page.dart';
import 'package:eisen/features/completed_tasks/presentation/pages/completed_matrix_page.dart';
import 'package:eisen/features/eisen_matrix/presentation/pages/matrix_page.dart';
import 'package:eisen/features/focus/presentation/pages/focus_dashboard_page.dart';
import 'package:eisen/features/focus/presentation/pages/pomodoro_session_page.dart';
import 'package:eisen/features/settings/presentation/pages/settings_screen.dart';
import 'package:eisen/features/stats/presentation/pages/stats_page.dart';
import 'package:eisen/ui/list_mode/list_mode_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Keep a single router instance to avoid route reset on app rebuilds
final GoRouter _router = GoRouter(
  initialLocation: '/matrix',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      redirect: (_, __) => '/matrix',
    ),
    GoRoute(
      path: '/matrix',
      name: 'matrix',
      pageBuilder: (context, state) =>
          _fadeSlidePage(state, const MatrixPage()),
    ),
    GoRoute(
      path: '/stats',
      name: 'stats',
      pageBuilder: (context, state) => _fadeSlidePage(
        state,
        const StatsPage(),
      ),
    ),
    GoRoute(
      path: '/focus',
      name: 'focus',
      pageBuilder: (context, state) =>
          _fadeSlidePage(state, const FocusDashboardPage()),
      routes: [
        GoRoute(
          path: 'session',
          name: 'pomodoro-session',
          pageBuilder: (context, state) {
            final durationMinutes = int.tryParse(
                  state.uri.queryParameters['minutes'] ?? '',
                ) ??
                25;
            final presetLabel = state.uri.queryParameters['label'];
            return _fadeSlidePage(
              state,
              PomodoroSessionPage(
                initialDuration: Duration(minutes: durationMinutes),
                presetLabel: presetLabel,
                autoStart: true,
              ),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => _fadeSlidePage(
        state,
        SettingsScreen(
          initialSection: state.uri.queryParameters['section'],
        ),
      ),
      routes: [
        GoRoute(
          path: 'appearance',
          name: 'settings-appearance',
          pageBuilder: (context, state) => _fadeSlidePage(
            state,
            const SettingsScreen(initialSection: 'Appearance'),
          ),
        ),
        GoRoute(
          path: 'notifications',
          name: 'settings-notifications',
          pageBuilder: (context, state) => _fadeSlidePage(
            state,
            const SettingsScreen(initialSection: 'Notifications'),
          ),
        ),
        GoRoute(
          path: 'language',
          name: 'settings-language',
          pageBuilder: (context, state) => _fadeSlidePage(
            state,
            const SettingsScreen(initialSection: 'Language'),
          ),
        ),
        GoRoute(
          path: 'accessibility',
          name: 'settings-accessibility',
          pageBuilder: (context, state) => _fadeSlidePage(
            state,
            const SettingsScreen(initialSection: 'Accessibility'),
          ),
        ),
      ],
    ),
    // Legacy/secondary routes kept for now with the same soft transition
    GoRoute(
      path: '/workflow-plan',
      name: 'workflow-plan',
      pageBuilder: (context, state) =>
          _fadeSlidePage(state, const WorkflowPlanPage()),
    ),
    GoRoute(
      path: '/list-mode',
      name: 'list-mode',
      pageBuilder: (context, state) =>
          _fadeSlidePage(state, const ListModeScreen()),
    ),
    GoRoute(
      path: '/completed-matrix',
      name: 'completed-matrix',
      pageBuilder: (context, state) =>
          _fadeSlidePage(state, const CompletedMatrixPage()),
    ),
  ],
);

GoRouter createRouter() => _router;

CustomTransitionPage<void> _fadeSlidePage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}
