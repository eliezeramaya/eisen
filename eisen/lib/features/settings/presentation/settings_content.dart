import 'package:flutter/material.dart';

class SettingsContent extends StatefulWidget {
  final String section;
  final ValueChanged<bool> onDirty;
  const SettingsContent({super.key, required this.section, required this.onDirty});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  @override
  Widget build(BuildContext context) {
    switch (widget.section) {
      case 'Appearance':
        return const _AppearancePanel();
      case 'Layout':
        return const _LayoutPanel();
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

// TODO: Integrate real controls and hook providers; mark dirty via onChanged.
class _GeneralPanel extends StatelessWidget {
  const _GeneralPanel();
  @override
  Widget build(BuildContext context) => const Text('General settings');
}

class _AppearancePanel extends StatelessWidget {
  const _AppearancePanel();
  @override
  Widget build(BuildContext context) => const Text('Theme, Minimal mode, Contrast');
}

class _LayoutPanel extends StatelessWidget {
  const _LayoutPanel();
  @override
  Widget build(BuildContext context) => const Text('Top-K, Gamma, minArea, Padding');
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

