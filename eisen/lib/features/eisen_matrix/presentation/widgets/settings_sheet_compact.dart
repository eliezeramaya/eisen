import 'package:eisen/core/providers/locale_provider.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/l10n/app_localizations.dart';
import 'package:eisen/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact settings sheet optimized for mobile with icon-only menu
class SettingsSheetCompact extends ConsumerWidget {
  const SettingsSheetCompact({
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

  final VoidCallback onToggleTheme;
  final VoidCallback onToggleDensity;
  final bool compact;
  final bool showAxisLegends;
  final VoidCallback onToggleAxisLegends;
  final VoidCallback? onResetToDemo;
  final bool? minimal;
  final VoidCallback? onToggleMinimal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
            AppLocalizationsEn();
    final prefs = ref.watch(uiPrefsControllerProvider);
    final cs = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.paddingOf(context).bottom + 16;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, size: 22),
                  const SizedBox(width: 8),
                  Text(l10n.settingsTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 20),
              // Compact icon grid
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  _CompactIconButton(
                    icon: Icons.brightness_6,
                    label: 'Tema',
                    onTap: () {
                      onToggleTheme();
                      Navigator.of(context).pop();
                    },
                  ),
                  _CompactIconButton(
                    icon: Icons.density_medium,
                    label: compact ? 'Compacto' : 'Cómodo',
                    onTap: () {
                      onToggleDensity();
                      Navigator.of(context).pop();
                    },
                  ),
                  _CompactIconButton(
                    icon: Icons.text_fields,
                    label: 'Texto',
                    onTap: () =>
                        _showTextScaleDialog(context, ref, prefs, l10n),
                  ),
                  _CompactIconButton(
                    icon: Icons.label_outline,
                    label: 'Leyendas',
                    onTap: () {
                      onToggleAxisLegends();
                      Navigator.of(context).pop();
                    },
                  ),
                  if (minimal != null && onToggleMinimal != null)
                    _CompactIconButton(
                      icon: Icons.filter_b_and_w,
                      label: 'Minimal',
                      onTap: () {
                        onToggleMinimal!();
                        Navigator.of(context).pop();
                      },
                    ),
                  _CompactIconButton(
                    icon: Icons.language,
                    label: 'Idioma',
                    onTap: () => _showLanguageDialog(context, ref, l10n),
                  ),
                  _CompactIconButton(
                    icon: Icons.grid_view_rounded,
                    label: 'Layout',
                    onTap: () => _showLayoutDialog(context, ref, prefs, l10n),
                  ),
                  if (onResetToDemo != null)
                    _CompactIconButton(
                      icon: Icons.refresh,
                      label: 'Reset',
                      color: Colors.orange,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
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

  void _showTextScaleDialog(BuildContext context, WidgetRef ref,
      UiPrefsData prefs, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tamaño de texto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nivel actual: ${prefs.textScaleLevel}'),
            Slider(
              value: prefs.textScaleLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: prefs.textScaleLevel.toString(),
              onChanged: (v) => ref
                  .read(uiPrefsControllerProvider.notifier)
                  .setTextScaleLevel(v.round().clamp(1, 5)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showLayoutDialog(BuildContext context, WidgetRef ref, UiPrefsData prefs,
      AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configuración de Layout'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Top-K por cuadrante'),
                subtitle: Slider(
                  value: prefs.topKPerQuadrant.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 55,
                  label: prefs.topKPerQuadrant.toString(),
                  onChanged: (v) => ref
                      .read(uiPrefsControllerProvider.notifier)
                      .setTopK(v.round()),
                ),
              ),
              ListTile(
                title: const Text('Gamma'),
                subtitle: Slider(
                  value: prefs.gamma,
                  min: 0.70,
                  max: 1.00,
                  divisions: 30,
                  label: prefs.gamma.toStringAsFixed(2),
                  onChanged: (v) =>
                      ref.read(uiPrefsControllerProvider.notifier).setGamma(v),
                ),
              ),
              ListTile(
                title: const Text('Área mínima'),
                subtitle: Slider(
                  value: prefs.minAreaNormalized,
                  min: 0.00002,
                  max: 0.00020,
                  divisions: 20,
                  label: prefs.minAreaNormalized.toStringAsExponential(2),
                  onChanged: (v) => ref
                      .read(uiPrefsControllerProvider.notifier)
                      .setMinArea(v),
                ),
              ),
              ListTile(
                title: const Text('Padding cuadrante'),
                subtitle: Slider(
                  value: prefs.quadrantPadding,
                  min: 0.0,
                  max: 0.02,
                  divisions: 20,
                  label: prefs.quadrantPadding.toStringAsFixed(3),
                  onChanged: (v) => ref
                      .read(uiPrefsControllerProvider.notifier)
                      .setPadding(v),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color ?? cs.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    height: 1.2,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
