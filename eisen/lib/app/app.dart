import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/locale_provider.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'router.dart';
import 'package:flutter/services.dart';
import 'package:eisen/core/platform/platform_utils.dart';
import 'package:eisen/core/intents/open_settings_intent.dart';
import 'package:go_router/go_router.dart';
import 'package:device_preview/device_preview.dart';

class EisenApp extends ConsumerWidget {
  const EisenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(matrixControllerProvider.select((s) => s.themeMode));
    final minimal = ref.watch(matrixControllerProvider.select((s) => s.minimal));
    final userLocale = ref.watch(localeProvider);
    
    final light = buildAppTheme(Brightness.light);
    final dark = buildAppTheme(Brightness.dark);
    final theme = minimal ? asMinimal(light) : light;
    final darkTheme = minimal ? asMinimal(dark) : dark;

    return MaterialApp.router(
      locale: userLocale ?? DevicePreview.locale(context),
      builder: (ctx, child) {
        final wrapped = Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.comma): const OpenSettingsIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma): const OpenSettingsIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
                onInvoke: (_) {
                  if (isDesktop) {
                    // Use go_router context to navigate
                    GoRouter.of(ctx).push('/settings');
                  }
                  return null;
                },
              ),
            },
            child: FocusTraversalGroup(child: child ?? const SizedBox.shrink()),
          ),
        );
        return DevicePreview.appBuilder(ctx, wrapped);
      },
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: createRouter(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
