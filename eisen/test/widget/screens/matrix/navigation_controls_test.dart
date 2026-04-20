import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/toolbar.dart';
import 'package:eisen/ui/widgets/app_logo_home_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('AppToolbar shows a usable back action while zoomed',
      (tester) async {
    var didExitZoom = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: AppToolbar(
              onToggleTheme: () {},
              onQuery: (_) {},
              themeMode: ThemeMode.system,
              isSearchOpen: false,
              searchQuery: '',
              onToggleSearch: () {},
              canExitZoom: true,
              onExitZoom: () {
                didExitZoom = true;
              },
            ),
          ),
        ),
      ),
    );

    final backButton = find.byKey(const Key('toolbar-back-button'));
    expect(backButton, findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(backButton);
    await tester.pump();

    expect(didExitZoom, isTrue);
  });

  testWidgets('AppLogoHomeButton resets zoom and navigates to matrix home',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(matrixControllerProvider.notifier).setZoom(Quadrant.q3);
    expect(container.read(matrixZoomProvider), Quadrant.q3);

    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
          path: '/detail',
          builder: (context, state) => Scaffold(
            body: Center(
              child: SizedBox(
                key: const Key('home-hit-area'),
                width: 78,
                height: 70,
                child: const AppLogoHomeButton(
                  key: Key('toolbar-home-button'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/matrix',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Matrix home')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('home-hit-area'))).width, 78);
    expect(tester.getSize(find.byKey(const Key('home-hit-area'))).height, 70);

    await tester.tap(find.byKey(const Key('toolbar-home-button')));
    await tester.pumpAndSettle();

    expect(find.text('Matrix home'), findsOneWidget);
    expect(container.read(matrixZoomProvider), isNull);
  });
}
