import 'package:device_preview/device_preview.dart';
import 'package:eisen/core/intents/open_settings_intent.dart';
import 'package:eisen/core/notifications/notifications_service.dart';
import 'package:eisen/core/platform/platform_utils.dart';
import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/ui/text_scaling.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/settings/domain/accessibility_controller.dart';
import 'package:eisen/features/settings/domain/language_controller.dart';
import 'package:eisen/l10n/app_localizations.dart';
import 'package:eisen/theme/density.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final router = createRouter();
    NotificationsService.setOnNudgeSelected((payload) async {
      switch (payload) {
        case 'lowQ2':
        case 'procrastination':
        case 'noFocusSessions':
          router.go('/focus');
          break;
        case 'dailyOverload':
        case 'overload':
          router.go('/matrix');
          break;
        case 'quadrantImbalance':
        case 'excessiveReschedules':
          router.go('/stats');
          break;
        default:
          router.go('/stats');
      }
    });

    final light = buildAppTheme(Brightness.light);
    final dark = buildAppTheme(Brightness.dark);
    final theme = minimal ? asMinimal(light) : light;
    final darkTheme = minimal ? asMinimal(dark) : dark;

    // Density selection (auto by breakpoint, user override via UiPrefs)
    final densityPref = ref.watch(uiPrefsProvider).densityPreset;
    final logicalWidth = _logicalWidthForDensity(context);
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
      if (logicalWidth >= _ultraDensityMinWidth) return DensityPreset.ultra;
      if (deviceClassOf(logicalWidth).isLarge) return DensityPreset.compact;
      return DensityPreset.comfy;
    }();

    final themedBase = applyDensity(theme, preset);
    final darkThemedBase = applyDensity(darkTheme, preset);

    final a11y = ref.watch(accessibilityControllerProvider).maybeWhen(
          data: (v) => v,
          orElse: () => null,
        );
    final themed =
        a11y?.highContrast == true ? _withHighContrast(themedBase) : themedBase;
    final darkThemed = a11y?.highContrast == true
        ? _withHighContrast(darkThemedBase)
        : darkThemedBase;
    final languageLocale = ref.watch(languageControllerProvider).maybeWhen(
          data: (v) => v.locale,
          orElse: () => null,
        );
    final previewLocale = DevicePreview.locale(context);
    final prefsLocale = _resolveLocale(ref.watch(uiPrefsProvider));
    final resolvedLocale = _resolveSupportedLocale(
      languageLocale ?? previewLocale ?? prefsLocale,
      AppLocalizations.supportedLocales,
    );

    return MaterialApp.router(
      // ignore: deprecated_member_use
      useInheritedMediaQuery: true,
      builder: (ctx, child) {
        // Apply user text scaling on top of device scale with responsive clamps
        final prefs = ref.watch(uiPrefsProvider);
        final tsfBase = effectiveTextScaleFactor(ctx, prefs);
        final tsf = a11y?.largeText == true ? tsfBase * 1.15 : tsfBase;
        final mq = MediaQuery.of(ctx);
        final scaledChild = MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(tsf),
            accessibleNavigation:
                a11y?.reduceAnimations == true ? true : mq.accessibleNavigation,
            highContrast: a11y?.highContrast == true ? true : mq.highContrast,
          ),
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
      theme: a11y?.reduceAnimations == true
          ? themed.copyWith(pageTransitionsTheme: _noTransitions)
          : themed,
      darkTheme: a11y?.reduceAnimations == true
          ? darkThemed.copyWith(pageTransitionsTheme: _noTransitions)
          : darkThemed,
      themeMode: themeMode,
      routerConfig: router,
      locale: resolvedLocale,
      localeResolutionCallback: (device, supported) {
        final preferredLocale = ref
                .read(languageControllerProvider)
                .maybeWhen(data: (v) => v.locale, orElse: () => null) ??
            DevicePreview.locale(context) ??
            _resolveLocale(ref.read(uiPrefsProvider));
        if (preferredLocale != null) {
          return _resolveSupportedLocale(preferredLocale, supported);
        }
        return _resolveSupportedLocale(device, supported);
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

Locale _resolveSupportedLocale(
  Locale? locale,
  Iterable<Locale> supportedLocales,
) {
  final supported = supportedLocales.toList(growable: false);
  if (locale == null) {
    return supported.first;
  }

  for (final candidate in supported) {
    if (candidate.languageCode == locale.languageCode &&
        (candidate.countryCode == null ||
            candidate.countryCode == locale.countryCode)) {
      return candidate;
    }
  }

  if (locale.languageCode.toLowerCase() == 'c') {
    return supported.first;
  }

  final exactLanguage = supported.where(
    (supported) => supported.languageCode == locale.languageCode,
  );
  if (exactLanguage.isNotEmpty) {
    return exactLanguage.first;
  }

  return supported.first;
}

double _logicalWidthForDensity(BuildContext context) {
  final mediaQuery = MediaQuery.maybeOf(context);
  if (mediaQuery != null) {
    return mediaQuery.size.width;
  }

  final view = View.maybeOf(context);
  if (view != null && view.devicePixelRatio > 0) {
    return view.physicalSize.width / view.devicePixelRatio;
  }

  final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
  final implicitView = platformDispatcher.implicitView ??
      (platformDispatcher.views.isNotEmpty
          ? platformDispatcher.views.first
          : null);
  if (implicitView != null && implicitView.devicePixelRatio > 0) {
    return implicitView.physicalSize.width / implicitView.devicePixelRatio;
  }

  return AppBreakpoints.large;
}

const double _ultraDensityMinWidth = 1600;

Locale? _resolveLocale(UiPrefsData prefs) {
  if (prefs.languageCode == 'system') return null;
  final lang = prefs.languageCode;
  final region = prefs.regionCode == 'system' ? null : prefs.regionCode;
  return Locale.fromSubtags(languageCode: lang, countryCode: region);
}

ThemeData _withHighContrast(ThemeData base) {
  final cs = base.colorScheme;
  final onSurface =
      cs.brightness == Brightness.dark ? Colors.white : Colors.black;
  final onSurfaceVariant =
      cs.brightness == Brightness.dark ? Colors.white70 : Colors.black87;
  final surface =
      cs.brightness == Brightness.dark ? Colors.black : Colors.white;
  return base.copyWith(
    colorScheme: cs.copyWith(
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surface: surface,
      surfaceTint: Colors.transparent,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    ),
  );
}

const _noTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _NoTransitionsBuilder(),
    TargetPlatform.iOS: _NoTransitionsBuilder(),
    TargetPlatform.macOS: _NoTransitionsBuilder(),
    TargetPlatform.linux: _NoTransitionsBuilder(),
    TargetPlatform.windows: _NoTransitionsBuilder(),
  },
);

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return child;
  }
}
