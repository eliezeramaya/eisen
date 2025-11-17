import 'package:flutter/material.dart';

class ProfileSheet extends StatelessWidget {
  const ProfileSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final title = isEs ? 'Mi perfil' : 'My profile';
    // Datos de ejemplo; en una integración real se obtendrían de un servicio/auth
    const name = 'Usuario Demo';
    const email = 'demo@example.com';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_circle, size: 48),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            _RowItem(label: isEs ? 'Nombre' : 'Name', value: name),
            const SizedBox(height: 8),
            _RowItem(label: 'Email', value: email),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(isEs ? 'Cerrar' : 'Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
