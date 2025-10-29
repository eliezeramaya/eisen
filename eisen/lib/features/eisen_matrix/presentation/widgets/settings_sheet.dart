import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/l10n/app_localizations.dart';
import 'package:eisen/l10n/app_localizations_en.dart';
import 'package:eisen/core/providers/locale_provider.dart';
import 'package:eisen/core/services/ui_prefs.dart';

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
  // Fall back to English localizations when not provided (e.g., in isolated widget tests)
  final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizationsEn();
    final currentLocale = ref.watch(localeProvider);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, size: 22),
                  const SizedBox(width: 8),
                  Text(l10n.settingsTitle, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.palette_outlined, size: 22),
                minLeadingWidth: 32,
                title: Text('Estilo visual'),
                subtitle: Text('Tema, densidad y leyendas de ejes'),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6, size: 22),
                minLeadingWidth: 32,
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
              secondary: const Icon(Icons.density_medium, size: 22),
              title: Text(compact ? l10n.settingsDensityCompact : l10n.settingsDensityComfortable),
            ),
            _SliderTile<int>(
              sliderKey: const Key('slider_text_scale'),
              label: 'Tamaño de texto',
              value: prefs.textScaleLevel,
              min: 1,
              max: 5,
              divisions: 4,
              helper: 'Escala del texto en la aplicación (1–5).',
              toDouble: (v) => v.toDouble(),
              fromDouble: (d) => d.round().clamp(1, 5),
              onChanged: (v) => ref.read(uiPrefsControllerProvider.notifier).setTextScaleLevel(v),
            ),
            SwitchListTile(
              value: showAxisLegends,
              onChanged: (_) {
                onToggleAxisLegends();
                Navigator.of(context).pop();
              },
              secondary: const Icon(Icons.label_outline, size: 22),
              title: Text(l10n.settingsShowAxisLegends),
            ),
            if (minimal != null && onToggleMinimal != null)
              SwitchListTile(
                value: minimal!,
                onChanged: (_) {
                  onToggleMinimal!();
                  Navigator.of(context).pop();
                },
                secondary: const Icon(Icons.filter_b_and_w, size: 22),
                title: Text(l10n.settingsMinimalMode),
              ),
            ListTile(
              leading: const Icon(Icons.language, size: 22),
              minLeadingWidth: 32,
              title: Text(l10n.settingsLanguage),
              subtitle: Text(_getLanguageLabel(currentLocale, l10n)),
              onTap: () => _showLanguageDialog(context, ref, l10n),
            ),
            const Divider(height: 24),
            const ListTile(
              leading: Icon(Icons.grid_view_rounded, size: 22),
              minLeadingWidth: 32,
              title: Text('Treemap · Layout'),
              subtitle: Text('Ajusta proporcionalidad y densidad visual'),
            ),
            _SliderTile<int>(
              sliderKey: const Key('slider_topk'),
              label: 'Top-K por cuadrante',
              value: prefs.topKPerQuadrant,
              min: 5,
              max: 60,
              divisions: 55,
              helper: 'Más alto = más tareas visibles, menos “+N”.',
              toDouble: (v) => v.toDouble(),
              fromDouble: (d) => d.round(),
              onChanged: (v) => ref.read(uiPrefsControllerProvider.notifier).setTopK(v),
            ),
            _SliderTile<double>(
              sliderKey: const Key('slider_gamma'),
              label: 'Gamma (suavizado de pesos)',
              value: prefs.gamma,
              min: 0.70,
              max: 1.00,
              divisions: 30,
              helper: '0.70 reduce dominantes; 1.00 = lineal.',
              toDouble: (v) => v,
              fromDouble: (d) => double.parse(d.toStringAsFixed(2)),
              onChanged: (v) => ref.read(uiPrefsControllerProvider.notifier).setGamma(v),
            ),
            _SliderTile<double>(
              sliderKey: const Key('slider_min_area'),
              label: 'Área mínima normalizada',
              value: prefs.minAreaNormalized,
              min: 0.00002,
              max: 0.00020,
              divisions: 20,
              helper: 'Más alto = menos micro-tiles, más “+N”.',
              toDouble: (v) => v,
              fromDouble: (d) => double.parse(d.toStringAsExponential(5)),
              onChanged: (v) => ref.read(uiPrefsControllerProvider.notifier).setMinArea(v),
            ),
            _SliderTile<double>(
              sliderKey: const Key('slider_padding'),
              label: 'Padding interno de cuadrante',
              value: prefs.quadrantPadding,
              min: 0.0,
              max: 0.02,
              divisions: 20,
              helper: 'Separación interna para legibilidad.',
              toDouble: (v) => v,
              fromDouble: (d) => double.parse(d.toStringAsFixed(3)),
              onChanged: (v) => ref.read(uiPrefsControllerProvider.notifier).setPadding(v),
            ),
            if (onResetToDemo != null) ...[
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.refresh, size: 22, color: Colors.orange),
                minLeadingWidth: 32,
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

// Generic slider tile helper, kept private to this file
class _SliderTile<T extends num> extends StatelessWidget {
  final String label;
  final T value;
  final double min;
  final double max;
  final int divisions;
  final String helper;
  final double Function(T) toDouble;
  final T Function(double) fromDouble;
  final ValueChanged<T> onChanged;
  final Key? sliderKey;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.helper,
    required this.toDouble,
    required this.fromDouble,
    required this.onChanged,
    this.sliderKey,
  });

  @override
  Widget build(BuildContext context) {
    final v = toDouble(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(label),
          subtitle: Slider(
            key: sliderKey,
            value: v.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: _fmt(v),
            onChanged: (d) => onChanged(fromDouble(d)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(helper, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  String _fmt(double d) => d >= 1
      ? d.toStringAsFixed(0)
      : (d >= 0.01 ? d.toStringAsFixed(2) : d.toStringAsExponential(2));
}
