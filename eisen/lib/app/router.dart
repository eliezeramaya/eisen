import 'package:go_router/go_router.dart';
import 'package:eisen/features/eisen_matrix/presentation/pages/matrix_page.dart';
import 'package:eisen/features/settings/presentation/settings_page_desktop.dart';

// Keep a single router instance to avoid route reset on app rebuilds
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'matrix',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: MatrixPage(),
      ),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPageDesktop(),
    ),
  ],
);

GoRouter createRouter() => _router;
