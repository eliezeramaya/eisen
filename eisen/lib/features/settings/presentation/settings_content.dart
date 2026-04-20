import 'package:eisen/features/eisen_matrix/domain/layout/treemap_density_resolver.dart';
import 'package:eisen/features/eisen_matrix/presentation/pages/category_manager_page.dart';
import 'package:eisen/features/settings/application/appearance_preview_controller.dart';
import 'package:eisen/features/settings/domain/accessibility_controller.dart';
import 'package:eisen/features/settings/presentation/widgets/appearance_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sections/general_panel.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({
    super.key,
    required this.section,
    required this.onDirty,
    required this.themeMode,
    required this.compact,
    required this.minimal,
    required this.showAxisLegends,
    required this.densityPreset,
    required this.treemapDensityProfile,
    required this.onThemeChanged,
    required this.onCompactChanged,
    required this.onMinimalChanged,
    required this.onAxisLegendsChanged,
    required this.onDensityPresetChanged,
    required this.topK,
    required this.gamma,
    required this.minAreaNormalized,
    required this.quadrantPadding,
    required this.minTileSizePx,
    required this.onTopKChanged,
    required this.onGammaChanged,
    required this.onMinAreaChanged,
    required this.onPaddingChanged,
    required this.onTreemapDensityProfileChanged,
    required this.onMinTileSizeChanged,
    required this.previewEnabled,
    required this.onPreviewChanged,
    required this.ganttTimeScale,
    required this.ganttShowBadges,
    required this.ganttCompactLanes,
    required this.ganttWorkweekOnly,
    required this.ganttShowTodayLine,
    required this.onGanttTimeScaleChanged,
    required this.onGanttShowBadgesChanged,
    required this.onGanttCompactLanesChanged,
    required this.onGanttWorkweekOnlyChanged,
    required this.onGanttShowTodayLineChanged,
  });
  final String section;
  final ValueChanged<bool> onDirty;
  // Staged appearance values
  final ThemeMode themeMode;
  final bool compact;
  final bool minimal;
  final bool showAxisLegends;
  final String densityPreset; // 'auto' | 'comfy' | 'compact' | 'ultra'
  final String treemapDensityProfile;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<bool> onCompactChanged;
  final ValueChanged<bool> onMinimalChanged;
  final ValueChanged<bool> onAxisLegendsChanged;
  final ValueChanged<String> onDensityPresetChanged;
  // Staged layout values
  final int topK;
  final double gamma;
  final double minAreaNormalized;
  final double quadrantPadding;
  final double minTileSizePx;
  final ValueChanged<int> onTopKChanged;
  final ValueChanged<double> onGammaChanged;
  final ValueChanged<double> onMinAreaChanged;
  final ValueChanged<double> onPaddingChanged;
  final ValueChanged<String> onTreemapDensityProfileChanged;
  final ValueChanged<double> onMinTileSizeChanged;
  final bool previewEnabled;
  final ValueChanged<bool> onPreviewChanged;
  // Gantt staged values & callbacks
  final String ganttTimeScale; // 'days' | 'weeks' | 'months'
  final bool ganttShowBadges;
  final bool ganttCompactLanes;
  final bool ganttWorkweekOnly;
  final bool ganttShowTodayLine;
  final ValueChanged<String> onGanttTimeScaleChanged;
  final ValueChanged<bool> onGanttShowBadgesChanged;
  final ValueChanged<bool> onGanttCompactLanesChanged;
  final ValueChanged<bool> onGanttWorkweekOnlyChanged;
  final ValueChanged<bool> onGanttShowTodayLineChanged;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case 'Appearance':
        return _AppearancePanel(
          themeMode: themeMode,
          compact: compact,
          minimal: minimal,
          showAxisLegends: showAxisLegends,
          densityPreset: densityPreset,
          onThemeChanged: (v) {
            onThemeChanged(v);
            onDirty(true);
          },
          onCompactChanged: (v) {
            onCompactChanged(v);
            onDirty(true);
          },
          onMinimalChanged: (v) {
            onMinimalChanged(v);
            onDirty(true);
          },
          onAxisLegendsChanged: (v) {
            onAxisLegendsChanged(v);
            onDirty(true);
          },
          onDensityPresetChanged: (v) {
            onDensityPresetChanged(v);
            onDirty(true);
          },
        );
      case 'Layout':
        return TreemapLayoutPanel(
          treemapDensityProfile: treemapDensityProfile,
          topK: topK,
          gamma: gamma,
          minArea: minAreaNormalized,
          padding: quadrantPadding,
          minTileSizePx: minTileSizePx,
          onTreemapDensityProfileChanged: (v) {
            onTreemapDensityProfileChanged(v);
            onDirty(true);
          },
          onTopK: (v) {
            onTopKChanged(v);
            onDirty(true);
          },
          onGamma: (v) {
            onGammaChanged(v);
            onDirty(true);
          },
          onMinArea: (v) {
            onMinAreaChanged(v);
            onDirty(true);
          },
          onPadding: (v) {
            onPaddingChanged(v);
            onDirty(true);
          },
          onMinTileSize: (v) {
            onMinTileSizeChanged(v);
            onDirty(true);
          },
          preview: previewEnabled,
          onPreview: onPreviewChanged,
          advancedInitiallyExpanded:
              treemapDensityProfile == TreemapDensityProfiles.custom,
        );
      case 'Notifications':
        return const NotificationsPanel();
      case 'Language':
        return const LanguageRegionPanel();
      case 'Accessibility':
        return const _AccessibilityPanel();
      case 'Calendar/Gantt':
        return _GanttPanel(
          timeScale: ganttTimeScale,
          showBadges: ganttShowBadges,
          compactLanes: ganttCompactLanes,
          workweekOnly: ganttWorkweekOnly,
          showTodayLine: ganttShowTodayLine,
          onTimeScale: (v) {
            onGanttTimeScaleChanged(v);
            onDirty(true);
          },
          onShowBadges: (v) {
            onGanttShowBadgesChanged(v);
            onDirty(true);
          },
          onCompactLanes: (v) {
            onGanttCompactLanesChanged(v);
            onDirty(true);
          },
          onWorkweekOnly: (v) {
            onGanttWorkweekOnlyChanged(v);
            onDirty(true);
          },
          onShowTodayLine: (v) {
            onGanttShowTodayLineChanged(v);
            onDirty(true);
          },
        );
      case 'Keyboard':
        return const _KeyboardPanel();
      case 'Data & Privacy':
        return const _PrivacyPanel();
      case 'About':
        return const _AboutPanel();
      case 'General':
        return const GeneralPanel();
      default:
        return const GeneralPanel();
    }
  }
}

// GeneralPanel UI moved to sections/general_panel.dart

class _AppearancePanel extends ConsumerWidget {
  const _AppearancePanel({
    required this.themeMode,
    required this.compact,
    required this.minimal,
    required this.showAxisLegends,
    required this.densityPreset,
    required this.onThemeChanged,
    required this.onCompactChanged,
    required this.onMinimalChanged,
    required this.onAxisLegendsChanged,
    required this.onDensityPresetChanged,
  });
  final ThemeMode themeMode;
  final bool compact;
  final bool minimal;
  final bool showAxisLegends;
  final String densityPreset;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<bool> onCompactChanged;
  final ValueChanged<bool> onMinimalChanged;
  final ValueChanged<bool> onAxisLegendsChanged;
  final ValueChanged<String> onDensityPresetChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onThemeChanged(mode);
              ref.read(appearancePreviewProvider.notifier).setThemeMode(mode);
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
              onDensityPresetChanged(preset);
              ref
                  .read(appearancePreviewProvider.notifier)
                  .setDensityPreset(preset);
            },
          ),
        ),
        const Divider(height: 24),
        SwitchListTile(
          value: compact,
          onChanged: (v) {
            onCompactChanged(v);
            ref.read(appearancePreviewProvider.notifier).setCompact(v);
          },
          secondary: const Icon(Icons.density_medium),
          title: const Text('Compact density'),
        ),
        SwitchListTile(
          value: minimal,
          onChanged: (v) {
            onMinimalChanged(v);
            ref.read(appearancePreviewProvider.notifier).setMinimal(v);
          },
          secondary: const Icon(Icons.filter_b_and_w),
          title: const Text('Minimal mode'),
        ),
        SwitchListTile(
          value: showAxisLegends,
          onChanged: onAxisLegendsChanged,
          secondary: const Icon(Icons.label_outline),
          title: const Text('Show axis legends'),
        ),
        const Divider(height: 24),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Category Colors'),
          subtitle: const Text('Customize colors for task categories'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const CategoryManagerPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class TreemapLayoutPanel extends StatelessWidget {
  const TreemapLayoutPanel({
    super.key,
    required this.treemapDensityProfile,
    required this.topK,
    required this.gamma,
    required this.minArea,
    required this.padding,
    required this.minTileSizePx,
    required this.onTreemapDensityProfileChanged,
    required this.onTopK,
    required this.onGamma,
    required this.onMinArea,
    required this.onPadding,
    required this.onMinTileSize,
    required this.preview,
    required this.onPreview,
    this.inlinePreview,
    this.advancedInitiallyExpanded = false,
  });

  final String treemapDensityProfile;
  final int topK;
  final double gamma;
  final double minArea;
  final double padding;
  final double minTileSizePx;
  final ValueChanged<String> onTreemapDensityProfileChanged;
  final ValueChanged<int> onTopK;
  final ValueChanged<double> onGamma;
  final ValueChanged<double> onMinArea;
  final ValueChanged<double> onPadding;
  final ValueChanged<double> onMinTileSize;
  final bool preview;
  final ValueChanged<bool> onPreview;
  final Widget? inlinePreview;
  final bool advancedInitiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isDesktopDensityContext =
        TreemapDensityResolver.usesDesktopProfile(screenSize);
    final minTileFloor = isDesktopDensityContext ? 30.0 : 40.0;
    final minTileDivisions = ((44.0 - minTileFloor) * 2).round();
    final isCustom = treemapDensityProfile == TreemapDensityProfiles.custom;

    void markCustom() {
      if (!isCustom) {
        onTreemapDensityProfileChanged(TreemapDensityProfiles.custom);
      }
    }

    return ListView(
      children: [
        const ListTile(
          leading: Icon(Icons.grid_view_rounded),
          title: Text('Treemap density'),
          subtitle: Text(
            'Adjust how many tasks are visible and how much space each tile gets.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _profileOrder.map((profile) {
              final label = _profileLabel(profile);
              return ChoiceChip(
                key: Key('treemap-density-profile-$profile'),
                label: Text(label),
                selected: treemapDensityProfile == profile,
                onSelected: (_) => onTreemapDensityProfileChanged(profile),
              );
            }).toList(growable: false),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _profileIcon(treemapDensityProfile),
                    color: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profileLabel(treemapDensityProfile),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          TreemapDensityResolver.descriptionForProfile(
                            treemapDensityProfile,
                          ),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SwitchListTile(
          value: preview,
          onChanged: onPreview,
          secondary: const Icon(Icons.visibility),
          title: const Text('Preview changes'),
        ),
        if (inlinePreview != null && preview) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              height: 260,
              child: inlinePreview,
            ),
          ),
        ],
        ExpansionTile(
          key: const Key('treemap-density-advanced-tuning'),
          initiallyExpanded: advancedInitiallyExpanded || isCustom,
          leading: const Icon(Icons.tune),
          title: const Text('Advanced tuning'),
          subtitle: Text(
            isCustom
                ? 'Fine-tune the exact treemap behavior.'
                : 'Manual changes will switch this profile to Custom.',
          ),
          children: [
            _sliderTile<int>(
              context: context,
              label: 'Top-K per quadrant',
              helper: 'Higher = more visible tasks and fewer stacked groups.',
              value: topK,
              min: 5,
              max: 100,
              divisions: 95,
              valueText: topK.toString(),
              sliderKey: const Key('treemap-density-topk-slider'),
              toDouble: (v) => v.toDouble(),
              fromDouble: (d) => d.round(),
              onChanged: (v) {
                markCustom();
                onTopK(v);
              },
            ),
            _sliderTile<double>(
              context: context,
              label: 'Min tile size',
              helper:
                  'Keeps tiles readable and touch-safe as density increases.',
              value: minTileSizePx,
              min: minTileFloor,
              max: 44.0,
              divisions: minTileDivisions,
              valueText: '${minTileSizePx.toStringAsFixed(0)}px',
              sliderKey: const Key('treemap-density-min-tile-slider'),
              toDouble: (v) => v,
              fromDouble: (d) => double.parse(d.toStringAsFixed(1)),
              onChanged: (v) {
                markCustom();
                onMinTileSize(v);
              },
            ),
            _sliderTile<double>(
              context: context,
              label: 'Gamma (weight smoothing)',
              helper: '0.70 reduces dominance; 1.00 = linear.',
              value: gamma,
              min: 0.70,
              max: 1.00,
              divisions: 30,
              valueText: gamma.toStringAsFixed(2),
              sliderKey: const Key('treemap-density-gamma-slider'),
              toDouble: (v) => v,
              fromDouble: (d) => double.parse(d.toStringAsFixed(2)),
              onChanged: (v) {
                markCustom();
                onGamma(v);
              },
            ),
            _sliderTile<double>(
              context: context,
              label: 'Min area',
              helper: 'Tiles smaller than this threshold are stacked.',
              value: minArea,
              min: 0.00002,
              max: 0.0002,
              divisions: 18,
              valueText: minArea.toStringAsFixed(5),
              sliderKey: const Key('treemap-density-min-area-slider'),
              toDouble: (v) => v,
              fromDouble: (d) => double.parse(d.toStringAsFixed(5)),
              onChanged: (v) {
                markCustom();
                onMinArea(v);
              },
            ),
            _sliderTile<double>(
              context: context,
              label: 'Quadrant padding',
              helper: 'Adds breathing room inside each quadrant.',
              value: padding,
              min: 0.0,
              max: 0.02,
              divisions: 20,
              valueText: padding.toStringAsFixed(3),
              sliderKey: const Key('treemap-density-padding-slider'),
              toDouble: (v) => v,
              fromDouble: (d) => double.parse(d.toStringAsFixed(3)),
              onChanged: (v) {
                markCustom();
                onPadding(v);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _sliderTile<T extends num>({
    required BuildContext context,
    required String label,
    required String helper,
    required T value,
    required double min,
    required double max,
    required int divisions,
    required String valueText,
    required Key sliderKey,
    required double Function(T) toDouble,
    required T Function(double) fromDouble,
    required ValueChanged<T> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(label)),
          Tooltip(
            message: helper,
            child: Icon(
              Icons.help_outline,
              size: 16,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            helper,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          Slider(
            key: sliderKey,
            value: toDouble(value),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (d) => onChanged(fromDouble(d)),
          ),
        ],
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 64),
        child: Text(
          valueText,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  static const List<String> _profileOrder = <String>[
    TreemapDensityProfiles.airy,
    TreemapDensityProfiles.balanced,
    TreemapDensityProfiles.compact,
    TreemapDensityProfiles.detailed,
    TreemapDensityProfiles.custom,
  ];

  String _profileLabel(String profile) {
    return switch (profile) {
      TreemapDensityProfiles.airy => 'Airy',
      TreemapDensityProfiles.balanced => 'Balanced',
      TreemapDensityProfiles.compact => 'Compact',
      TreemapDensityProfiles.detailed => 'Detailed',
      TreemapDensityProfiles.custom => 'Custom',
      _ => 'Balanced',
    };
  }

  IconData _profileIcon(String profile) {
    return switch (profile) {
      TreemapDensityProfiles.airy => Icons.air_rounded,
      TreemapDensityProfiles.balanced => Icons.tune_rounded,
      TreemapDensityProfiles.compact => Icons.view_comfy_alt_outlined,
      TreemapDensityProfiles.detailed => Icons.dashboard_customize_outlined,
      TreemapDensityProfiles.custom => Icons.handyman_outlined,
      _ => Icons.tune_rounded,
    };
  }
}

class _GanttPanel extends StatelessWidget {
  const _GanttPanel({
    required this.timeScale,
    required this.showBadges,
    required this.compactLanes,
    required this.workweekOnly,
    required this.showTodayLine,
    required this.onTimeScale,
    required this.onShowBadges,
    required this.onCompactLanes,
    required this.onWorkweekOnly,
    required this.onShowTodayLine,
  });
  final String timeScale; // 'days' | 'weeks' | 'months'
  final bool showBadges;
  final bool compactLanes;
  final bool workweekOnly;
  final bool showTodayLine;
  final ValueChanged<String> onTimeScale;
  final ValueChanged<bool> onShowBadges;
  final ValueChanged<bool> onCompactLanes;
  final ValueChanged<bool> onWorkweekOnly;
  final ValueChanged<bool> onShowTodayLine;
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ListTile(
          leading: Icon(Icons.view_timeline),
          title: Text('Calendar / Gantt'),
          subtitle: Text('Escala de tiempo y visibilidad'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'days', label: Text('Días')),
              ButtonSegment(value: 'weeks', label: Text('Semanas')),
              ButtonSegment(value: 'months', label: Text('Meses')),
            ],
            selected: {timeScale},
            onSelectionChanged: (s) => onTimeScale(s.first),
          ),
        ),
        const Divider(height: 24),
        SwitchListTile(
          value: showBadges,
          onChanged: onShowBadges,
          secondary: const Icon(Icons.loyalty_outlined),
          title: const Text('Mostrar badges de duración'),
          subtitle: const Text('Ej. 3d al extremo derecho de la barra'),
        ),
        SwitchListTile(
          value: compactLanes,
          onChanged: onCompactLanes,
          secondary: const Icon(Icons.density_small),
          title: const Text('Lanes compactos'),
          subtitle: const Text('Reduce la altura y separación de lanes'),
        ),
        SwitchListTile(
          value: workweekOnly,
          onChanged: onWorkweekOnly,
          secondary: const Icon(Icons.work_outline),
          title: const Text('Solo semana laboral'),
          subtitle: const Text('Oculta fines de semana en el header (visual)'),
        ),
        SwitchListTile(
          value: showTodayLine,
          onChanged: onShowTodayLine,
          secondary: const Icon(Icons.today_outlined),
          title: const Text('Mostrar línea de hoy'),
          subtitle: const Text('Resalta el “Ahora” en el Gantt'),
        ),
      ],
    );
  }
}

class _AccessibilityPanel extends ConsumerWidget {
  const _AccessibilityPanel();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final asyncA11y = ref.watch(accessibilityControllerProvider);
    final a11y = asyncA11y.maybeWhen(data: (v) => v, orElse: () => null);
    final ctrl = ref.read(accessibilityControllerProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Text('Accessibility',
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Ajustes de legibilidad y navegación por teclado',
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        if (a11y == null)
          const LinearProgressIndicator(minHeight: 2)
        else ...[
          SwitchListTile(
            value: a11y.largeText,
            onChanged: ctrl.toggleLargeText,
            title: const Text('Texto más grande'),
            subtitle: const Text('Aplica un aumento global de legibilidad'),
            secondary: const Icon(Icons.text_increase),
          ),
          SwitchListTile(
            value: a11y.highContrast,
            onChanged: ctrl.toggleHighContrast,
            title: const Text('Alto contraste'),
            subtitle: const Text('Colores y superficies con mayor contraste'),
            secondary: const Icon(Icons.contrast),
          ),
          SwitchListTile(
            value: a11y.reduceAnimations,
            onChanged: ctrl.toggleReduceAnimations,
            title: const Text('Reducir animaciones'),
            subtitle:
                const Text('Transiciones simples y navegación sin motion'),
            secondary: const Icon(Icons.motion_photos_off),
          ),
          SwitchListTile(
            value: a11y.hapticsEnabled,
            onChanged: ctrl.toggleHaptics,
            title: const Text('Haptics'),
            subtitle: const Text('Vibración ligera en interacciones clave'),
            secondary: const Icon(Icons.vibration),
          ),
          const Divider(),
          const Text(
            'Escala de texto',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const TextScaleCard(),
        ],
      ],
    );
  }
}

/// Public wrapper used by mobile Settings to reuse the Accessibility content.
class AccessibilityPanel extends StatelessWidget {
  const AccessibilityPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AccessibilityPanel();
  }
}

class _KeyboardPanel extends StatelessWidget {
  const _KeyboardPanel();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Text('Keyboard',
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Atajos de teclado más usados',
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        DataTable(columns: const [
          DataColumn(label: Text('Acción')),
          DataColumn(label: Text('Atajo')),
        ], rows: const [
          DataRow(cells: [
            DataCell(Text('Abrir Settings')),
            DataCell(Text('Ctrl + , / ⌘ + ,'))
          ]),
          DataRow(cells: [DataCell(Text('Nueva tarea')), DataCell(Text('N'))]),
          DataRow(cells: [
            DataCell(Text('Cambiar tema')),
            DataCell(Text('Ctrl + T'))
          ]),
          DataRow(cells: [
            DataCell(Text('Mostrar estadísticas')),
            DataCell(Text('Ctrl + Shift + S'))
          ]),
        ]),
      ],
    );
  }
}

class _PrivacyPanel extends StatelessWidget {
  const _PrivacyPanel();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Text('Data & Privacy',
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Importación/exportación y telemetría',
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        _bullet('Exportar tareas en JSON/CSV para respaldo'),
        _bullet('Importar desde archivo con validación básica'),
        _bullet('Consentimiento de telemetría anónima (opt-in)'),
        _bullet('Restablecer datos locales a estado inicial'),
        _bullet('Editar preferencias de privacidad en cualquier momento'),
      ],
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Text('About',
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Versión y créditos',
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        const Text('Eisen – Productivity Matrix'),
        const SizedBox(height: 8),
        const Text('Version: 1.0.0'),
        const SizedBox(height: 8),
        const Text('Plan smart. Move fast.'),
        const SizedBox(height: 12),
        const Text('Creado con Flutter y Riverpod, con foco en UX accesible.'),
        const SizedBox(height: 12),
        const Text('Feedback y soporte: team@eisen.app'),
      ],
    );
  }
}

/// Public wrappers for mobile sections.
class DataPrivacyPanel extends StatelessWidget {
  const DataPrivacyPanel({super.key});

  @override
  Widget build(BuildContext context) => const _PrivacyPanel();
}

class AboutPanel extends StatelessWidget {
  const AboutPanel({super.key});

  @override
  Widget build(BuildContext context) => const _AboutPanel();
}

Widget _bullet(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        const Icon(Icons.circle, size: 6),
        const SizedBox(width: 8),
        Text(text)
      ]),
    );

// LivePreviewPane moved to its own file: settings/presentation/live_preview_pane.dart
