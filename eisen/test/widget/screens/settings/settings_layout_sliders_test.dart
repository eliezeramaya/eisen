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

  testWidgets('SettingsSheet con controles de layout monta sin excepciones',
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

    expect(tester.takeException(), isNull);
  });
}
