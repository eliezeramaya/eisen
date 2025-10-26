import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/l10n/app_localizations.dart';
import 'package:eisen/core/providers/locale_provider.dart';

class SettingsSheet extends ConsumerWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleDensity;
  final bool compact;
  final bool showAxisLegends;
  final VoidCallback onToggleAxisLegends;
  final VoidCallback? onResetToDemo;
  final bool? minimal;
  final VoidCallback? onToggleMinimal;
  
  const SettingsSheet({
    super.key,
    required this.onToggleTheme,
    required this.onToggleDensity,
    required this.compact,
    required this.showAxisLegends,
    required this.onToggleAxisLegends,
    this.onResetToDemo,
    this.minimal,
    this.onToggleMinimal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);
    
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
                Text(l10n.settingsTitle, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: Text(l10n.settingsTheme),
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
              title: Text(compact ? l10n.settingsDensityCompact : l10n.settingsDensityComfortable),
            ),
            SwitchListTile(
              value: showAxisLegends,
              onChanged: (_) {
                onToggleAxisLegends();
                Navigator.of(context).pop();
              },
              secondary: const Icon(Icons.label_outline),
              title: Text(l10n.settingsShowAxisLegends),
            ),
            if (minimal != null && onToggleMinimal != null)
              SwitchListTile(
                value: minimal!,
                onChanged: (_) {
                  onToggleMinimal!();
                  Navigator.of(context).pop();
                },
                secondary: const Icon(Icons.filter_b_and_w),
                title: Text(l10n.settingsMinimalMode),
              ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.settingsLanguage),
              subtitle: Text(_getLanguageLabel(currentLocale, l10n)),
              onTap: () => _showLanguageDialog(context, ref, l10n),
            ),
            if (onResetToDemo != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: Text(l10n.settingsResetDemo),
                subtitle: Text(l10n.settingsResetDemoSubtitle),
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.settingsResetDemoDialogTitle),
                      content: Text(l10n.settingsResetDemoDialogContent),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(l10n.settingsCancel),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            onResetToDemo!();
                          },
                          child: Text(l10n.settingsRestore),
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

  String _getLanguageLabel(Locale? locale, AppLocalizations l10n) {
    if (locale == null) return l10n.languageSystem;
    switch (locale.languageCode) {
      case 'en':
        return l10n.languageEnglish;
      case 'es':
        return l10n.languageSpanish;
      default:
        return l10n.languageSystem;
    }
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currentLocale = ref.read(localeProvider);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              title: Text(l10n.languageSystem),
              value: null,
              groupValue: currentLocale?.languageCode,
              onChanged: (_) {
                ref.read(localeProvider.notifier).setLocale(null);
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageEnglish),
              value: 'en',
              groupValue: currentLocale?.languageCode,
              onChanged: (_) {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageSpanish),
              value: 'es',
              groupValue: currentLocale?.languageCode,
              onChanged: (_) {
                ref.read(localeProvider.notifier).setLocale(const Locale('es'));
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
