import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/settings/presentation/widgets/appearance_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mobile-friendly Appearance panel.
///
/// Changes are applied immediately to global controllers (no staging).
class AppearanceMobilePanel extends ConsumerWidget {
  const AppearanceMobilePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(matrixControllerProvider.select((s) => s.themeMode));
    final compact =
        ref.watch(matrixControllerProvider.select((s) => s.compact));
    final minimal =
        ref.watch(matrixControllerProvider.select((s) => s.minimal));
    final showAxisLegends =
        ref.watch(matrixControllerProvider.select((s) => s.showAxisLegends));
    final densityPreset = ref.watch(uiPrefsProvider).densityPreset;

    void setThemeMode(ThemeMode target) {
      final ctrl = ref.read(matrixControllerProvider.notifier);
      var guard = 0;
      while (ref.read(matrixControllerProvider).themeMode != target &&
          guard < 3) {
        ctrl.toggleTheme();
        guard++;
      }
    }

    void setCompact(bool value) {
      final ctrl = ref.read(matrixControllerProvider.notifier);
      final current =
          ref.read(matrixControllerProvider.select((s) => s.compact));
      if (current != value) {
        ctrl.toggleCompact();
      }
    }

    void setMinimal(bool value) {
      final ctrl = ref.read(matrixControllerProvider.notifier);
      final current =
          ref.read(matrixControllerProvider.select((s) => s.minimal));
      if (current != value) {
        ctrl.toggleMinimal();
      }
    }

    void setShowAxisLegends(bool value) {
      final ctrl = ref.read(matrixControllerProvider.notifier);
      final current =
          ref.read(matrixControllerProvider.select((s) => s.showAxisLegends));
      if (current != value) {
        ctrl.toggleAxisLegends();
      }
    }

    Future<void> setDensity(String preset) async {
      await ref
          .read(uiPrefsControllerProvider.notifier)
          .setDensityPreset(preset);
    }

    return ListView(
      children: [
        const AppearancePreviewCard(),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.palette_outlined),
          title: Text('Theme'),
          subtitle: Text('Light / Dark / System'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light')),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark')),
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_suggest),
                  label: Text('System')),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) {
              final mode = s.first;
              setThemeMode(mode);
            },
          ),
        ),
        const Divider(height: 24),
        const ListTile(
          leading: Icon(Icons.density_medium),
          title: Text('Density'),
          subtitle: Text('Comfy / Compact / Ultra / Auto'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'comfy', label: Text('Comfy')),
              ButtonSegment(value: 'compact', label: Text('Compact')),
              ButtonSegment(value: 'ultra', label: Text('Ultra')),
              ButtonSegment(value: 'auto', label: Text('Auto')),
            ],
            selected: {densityPreset},
            onSelectionChanged: (s) {
              final preset = s.first;
              setDensity(preset);
            },
          ),
        ),
        const Divider(height: 24),
        SwitchListTile(
          value: compact,
          onChanged: setCompact,
          secondary: const Icon(Icons.density_medium),
          title: const Text('Compact density'),
        ),
        SwitchListTile(
          value: minimal,
          onChanged: setMinimal,
          secondary: const Icon(Icons.filter_b_and_w),
          title: const Text('Minimal mode'),
        ),
        SwitchListTile(
          value: showAxisLegends,
          onChanged: setShowAxisLegends,
          secondary: const Icon(Icons.label_outline),
          title: const Text('Show axis legends'),
        ),
      ],
    );
  }
}

