import 'package:go_router/go_router.dart';
import '../features/matrix/presentation/pages/matrix_page.dart';

GoRouter createRouter() {
  return GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'matrix',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MatrixPage(),
        ),
      ),
    ],
  );
}
