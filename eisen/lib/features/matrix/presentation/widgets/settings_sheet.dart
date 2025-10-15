import 'package:flutter/material.dart';

class SettingsSheet extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleDensity;
  final bool compact;
  const SettingsSheet({super.key, required this.onToggleTheme, required this.onToggleDensity, required this.compact});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings),
                const SizedBox(width: 8),
                Text('Settings', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Toggle theme'),
              onTap: () {
                onToggleTheme();
                Navigator.of(context).pop();
              },
            ),
            SwitchListTile(
              value: compact,
              onChanged: (_) {
                onToggleDensity();
                Navigator.of(context).pop();
              },
              secondary: const Icon(Icons.density_medium),
              title: Text(compact ? 'Compact density' : 'Comfortable density'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
