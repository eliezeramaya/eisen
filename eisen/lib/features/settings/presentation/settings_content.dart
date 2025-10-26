import 'package:flutter/material.dart';

class SettingsContent extends StatelessWidget {
  final String section;
  final ValueChanged<bool> onDirty;
  // Staged appearance values
  final ThemeMode themeMode;
  final bool compact;
  final bool minimal;
  final bool showAxisLegends;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<bool> onCompactChanged;
  final ValueChanged<bool> onMinimalChanged;
  final ValueChanged<bool> onAxisLegendsChanged;
  // Staged layout values
  final int topK;
  final double gamma;
  final double minAreaNormalized;
  final double quadrantPadding;
  final ValueChanged<int> onTopKChanged;
  final ValueChanged<double> onGammaChanged;
  final ValueChanged<double> onMinAreaChanged;
  final ValueChanged<double> onPaddingChanged;

  const SettingsContent({
    super.key,
    required this.section,
    required this.onDirty,
    required this.themeMode,
    required this.compact,
    required this.minimal,
    required this.showAxisLegends,
    required this.onThemeChanged,
    required this.onCompactChanged,
    required this.onMinimalChanged,
    required this.onAxisLegendsChanged,
    required this.topK,
    required this.gamma,
    required this.minAreaNormalized,
    required this.quadrantPadding,
    required this.onTopKChanged,
    required this.onGammaChanged,
    required this.onMinAreaChanged,
    required this.onPaddingChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case 'Appearance':
        return _AppearancePanel(
          themeMode: themeMode,
          compact: compact,
          minimal: minimal,
          showAxisLegends: showAxisLegends,
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
        );
      case 'Layout':
        return _LayoutPanel(
          topK: topK,
          gamma: gamma,
          minArea: minAreaNormalized,
          padding: quadrantPadding,
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
        );
      case 'Accessibility':
        return const _AccessibilityPanel();
      case 'Keyboard':
        return const _KeyboardPanel();
      case 'Data & Privacy':
        return const _PrivacyPanel();
      case 'About':
        return const _AboutPanel();
      default:
        return const _GeneralPanel();
    }
  }
}

class _GeneralPanel extends StatelessWidget {
  const _GeneralPanel();
  @override
  Widget build(BuildContext context) => const Text('General settings');
}

class _AppearancePanel extends StatelessWidget {
  final ThemeMode themeMode;
  final bool compact;
  final bool minimal;
  final bool showAxisLegends;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<bool> onCompactChanged;
  final ValueChanged<bool> onMinimalChanged;
  final ValueChanged<bool> onAxisLegendsChanged;
  const _AppearancePanel({
    required this.themeMode,
    required this.compact,
    required this.minimal,
    required this.showAxisLegends,
    required this.onThemeChanged,
    required this.onCompactChanged,
    required this.onMinimalChanged,
    required this.onAxisLegendsChanged,
  });
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ListTile(
          leading: Icon(Icons.palette_outlined),
          title: Text('Theme'),
          subtitle: Text('Light / Dark / System'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_suggest), label: Text('System')),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) => onThemeChanged(s.first),
          ),
        ),
        const Divider(height: 24),
        SwitchListTile(
          value: compact,
          onChanged: onCompactChanged,
          secondary: const Icon(Icons.density_medium),
          title: const Text('Compact density'),
        ),
        SwitchListTile(
          value: minimal,
          onChanged: onMinimalChanged,
          secondary: const Icon(Icons.filter_b_and_w),
          title: const Text('Minimal mode'),
        ),
        SwitchListTile(
          value: showAxisLegends,
          onChanged: onAxisLegendsChanged,
          secondary: const Icon(Icons.label_outline),
          title: const Text('Show axis legends'),
        ),
      ],
    );
  }
}

class _LayoutPanel extends StatelessWidget {
  final int topK;
  final double gamma;
  final double minArea;
  final double padding;
  final ValueChanged<int> onTopK;
  final ValueChanged<double> onGamma;
  final ValueChanged<double> onMinArea;
  final ValueChanged<double> onPadding;
  const _LayoutPanel({
    required this.topK,
    required this.gamma,
    required this.minArea,
    required this.padding,
    required this.onTopK,
    required this.onGamma,
    required this.onMinArea,
    required this.onPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ListTile(
          leading: Icon(Icons.grid_view_rounded),
          title: Text('Treemap · Layout'),
          subtitle: Text('Adjust visible tiles and smoothing'),
        ),
        _sliderTile<int>(
          context: context,
          label: 'Top-K per quadrant',
          helper: 'Higher = more visible tasks, less “+N”',
          value: topK,
          min: 5,
          max: 60,
          divisions: 55,
          toDouble: (v) => v.toDouble(),
          fromDouble: (d) => d.round(),
          onChanged: onTopK,
        ),
        _sliderTile<double>(
          context: context,
          label: 'Gamma (weight smoothing)',
          helper: '0.70 reduces dominance; 1.00 = linear',
          value: gamma,
          min: 0.70,
          max: 1.00,
          divisions: 30,
          toDouble: (v) => v,
          fromDouble: (d) => double.parse(d.toStringAsFixed(2)),
          onChanged: onGamma,
        ),
        _sliderTile<double>(
          context: context,
          label: 'Min area (normalized)',
          helper: 'Tiny tiles are stacked below this threshold',
          value: minArea,
          min: 0.00002,
          max: 0.0002,
          divisions: 18,
          toDouble: (v) => v,
          fromDouble: (d) => double.parse(d.toStringAsFixed(5)),
          onChanged: onMinArea,
        ),
        _sliderTile<double>(
          context: context,
          label: 'Quadrant padding',
          helper: 'Spacing inside each quadrant',
          value: padding,
          min: 0.0,
          max: 0.02,
          divisions: 20,
          toDouble: (v) => v,
          fromDouble: (d) => double.parse(d.toStringAsFixed(3)),
          onChanged: onPadding,
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
    required double Function(T) toDouble,
    required T Function(double) fromDouble,
    required ValueChanged<T> onChanged,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(helper),
          Slider(
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
        child: Text(toDouble(value).toString(), textAlign: TextAlign.end),
      ),
    );
  }
}

class _AccessibilityPanel extends StatelessWidget {
  const _AccessibilityPanel();
  @override
  Widget build(BuildContext context) => const Text('A11y options');
}

class _KeyboardPanel extends StatelessWidget {
  const _KeyboardPanel();
  @override
  Widget build(BuildContext context) => const Text('Shortcuts list');
}

class _PrivacyPanel extends StatelessWidget {
  const _PrivacyPanel();
  @override
  Widget build(BuildContext context) => const Text('Data & Privacy');
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel();
  @override
  Widget build(BuildContext context) => const Text('About');
}

class LivePreviewPane extends StatelessWidget {
  const LivePreviewPane({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: const Center(child: Text('Live Preview')),
    );
  }
}
