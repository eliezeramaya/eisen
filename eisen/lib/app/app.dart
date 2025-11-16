import 'package:device_preview/device_preview.dart';
import 'package:eisen/core/intents/open_settings_intent.dart';
import 'package:eisen/core/platform/platform_utils.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/ui/text_scaling.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/l10n/app_localizations.dart';
import 'package:eisen/theme/density.dart';
import 'package:eisen/utils/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/locale_provider.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class EisenApp extends ConsumerWidget {
  const EisenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      matrixControllerProvider.select((s) => s.themeMode),
    );
    final minimal = ref.watch(
      matrixControllerProvider.select((s) => s.minimal),
    );
    final userLocale = ref.watch(localeProvider);

    final light = buildAppTheme(Brightness.light);
    final dark = buildAppTheme(Brightness.dark);
    final theme = minimal ? asMinimal(light) : light;
    final darkTheme = minimal ? asMinimal(dark) : dark;

    // Density selection (auto by breakpoint, user override via UiPrefs)
    final densityPref = ref.watch(uiPrefsProvider).densityPreset;
    final view = View.of(context);
    final logicalWidth = view.physicalSize.width / view.devicePixelRatio;
    final DensityPreset preset = () {
      if (densityPref != 'auto') {
        switch (densityPref) {
          case 'compact':
            return DensityPreset.compact;
          case 'ultra':
            return DensityPreset.ultra;
          case 'comfy':
          default:
            return DensityPreset.comfy;
        }
      }
      if (logicalWidth >= bpWidescreen) return DensityPreset.ultra;
      if (logicalWidth >= bpDesktop) return DensityPreset.compact;
      return DensityPreset.comfy;
    }();

    final themed = applyDensity(theme, preset);
    final darkThemed = applyDensity(darkTheme, preset);

    return MaterialApp.router(
      builder: (ctx, child) {
        // Apply user text scaling on top of device scale with responsive clamps
        final prefs = ref.watch(uiPrefsProvider);
        final tsf = effectiveTextScaleFactor(ctx, prefs);
        final mq = MediaQuery.of(ctx);
        final scaledChild = MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(tsf)),
          child: child ?? const SizedBox.shrink(),
        );

        final wrappedShortcuts = Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.comma):
                const OpenSettingsIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma):
                const OpenSettingsIntent(),
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
            child: FocusTraversalGroup(child: scaledChild),
          ),
        );
        return DevicePreview.appBuilder(ctx, wrappedShortcuts);
      },
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: themed,
      darkTheme: darkThemed,
      themeMode: themeMode,
      routerConfig: createRouter(),
      locale: _resolveLocale(ref.watch(uiPrefsProvider)),
      localeResolutionCallback: (device, supported) {
        final forced = _resolveLocale(ref.read(uiPrefsProvider));
        return forced ?? device;
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

Locale? _resolveLocale(UiPrefsData prefs) {
  if (prefs.languageCode == 'system') return null;
  final lang = prefs.languageCode;
  final region = prefs.regionCode == 'system' ? null : prefs.regionCode;
  return Locale.fromSubtags(languageCode: lang, countryCode: region);
}
