import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../features/matrix/application/matrix_controller.dart';
import 'router.dart';

class EisenApp extends ConsumerWidget {
  const EisenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(matrixControllerProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: createRouter(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
