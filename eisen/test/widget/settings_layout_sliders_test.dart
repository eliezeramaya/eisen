import 'package:eisen/features/eisen_matrix/domain/layout/layout_providers.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/settings_sheet.dart';
import 'package:eisen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Layout sliders update prefs and layout config + bump layoutVersion',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    // Simple host showing Settings and current cfg/layoutVersion
    Widget host() => ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
            ],
            supportedLocales: const [
              ...AppLocalizations.supportedLocales,
            ],
            home: Scaffold(
              body: Column(
                children: [
                  // Force MatrixController to build and listen to uiPrefs
                  Consumer(builder: (context, ref, _) {
                    final lv = ref.watch(matrixControllerProvider
                        .select((s) => s.layoutVersion));
                    final cfg = ref.watch(layoutConfigProvider);
                    return Column(
                      children: [
                        Text('lv=$lv', key: const Key('lv')),
                        Text('gamma=${cfg.gamma.toStringAsFixed(2)}',
                            key: const Key('gamma')),
                      ],
                    );
                  }),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SettingsSheet(
                        onToggleTheme: () {},
                        onToggleDensity: () {},
                        compact: false,
                        showAxisLegends: true,
                        onToggleAxisLegends: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Initial expectations
    expect(find.byKey(const Key('gamma')), findsOneWidget);
    expect(find.text('gamma=1.00'), findsOneWidget);
    expect(find.byKey(const Key('lv')), findsOneWidget);
    expect(find.text('lv=0'), findsOneWidget);

    // Drag the gamma slider left to reduce it
    final gammaSlider = find.byKey(const Key('slider_gamma'));
    expect(gammaSlider, findsOneWidget);
    await tester.ensureVisible(gammaSlider);
    await tester.pumpAndSettle();
    await tester.drag(gammaSlider, const Offset(-200, 0));
    await tester.pumpAndSettle();

    // gamma in layoutConfig should be < 1.00 now
    final gammaText = tester.widget<Text>(find.byKey(const Key('gamma')));
    expect(gammaText.data, isNot('gamma=1.00'));

    // layoutVersion should have bumped >= 1 due to ref.listen in controller
    final lvText = tester.widget<Text>(find.byKey(const Key('lv')));
    expect(lvText.data, isNot('lv=0'));
  });
}
