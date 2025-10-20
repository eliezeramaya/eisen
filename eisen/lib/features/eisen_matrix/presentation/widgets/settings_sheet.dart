import 'package:flutter/material.dart';

class SettingsSheet extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleDensity;
  final bool compact;
  final bool showAxisLegends;
  final VoidCallback onToggleAxisLegends;
  final VoidCallback? onResetToDemo;
  
  const SettingsSheet({
    super.key,
    required this.onToggleTheme,
    required this.onToggleDensity,
    required this.compact,
    required this.showAxisLegends,
    required this.onToggleAxisLegends,
    this.onResetToDemo,
  });

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
            SwitchListTile(
              value: showAxisLegends,
              onChanged: (_) {
                onToggleAxisLegends();
                Navigator.of(context).pop();
              },
              secondary: const Icon(Icons.label_outline),
              title: const Text('Mostrar leyendas de ejes'),
            ),
            if (onResetToDemo != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: const Text('Restaurar tareas demo'),
                subtitle: const Text('Reemplazar todas las tareas con ejemplos'),
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('¿Restaurar tareas demo?'),
                      content: const Text('Esto eliminará todas tus tareas actuales y las reemplazará con 20 tareas de ejemplo.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            onResetToDemo!();
                          },
                          child: const Text('Restaurar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
