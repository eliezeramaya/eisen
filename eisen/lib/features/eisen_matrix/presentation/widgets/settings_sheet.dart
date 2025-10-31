import 'package:eisen/core/providers/locale_provider.dart';
import 'package:eisen/core/responsive/layout_tokens.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/ui/app_text_scale.dart';
import 'package:eisen/core/responsive/responsive_wrapper.dart';
import 'package:eisen/l10n/app_localizations.dart';
import 'package:eisen/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsSheet extends ConsumerWidget {
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
    // Fall back to English localizations when not provided (e.g., in isolated widget tests)
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
            AppLocalizationsEn();
    final currentLocale = ref.watch(localeProvider);
    final prefs = ref.watch(uiPrefsControllerProvider);
    final cs = Theme.of(context).colorScheme;
    final r = Responsive.of(context);
    final bottomPad = MediaQuery.paddingOf(context).bottom + AppSpacing.md * r.paddingScale;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: MediaQuery(
          // AppTextScale applied: scale entire sheet typography
          data: MediaQuery.of(context).copyWith(textScaleFactor: AppTextScale.of(context, prefs)),
          child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md * r.paddingScale,
            AppSpacing.md * r.paddingScale,
            AppSpacing.md * r.paddingScale,
            bottomPad,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, size: 22),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.settingsTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
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
                title: Text(compact
                    ? l10n.settingsDensityCompact
                    : l10n.settingsDensityComfortable),
              ),
              // AppTextScale applied: vista previa en tiempo real + persistencia al soltar
              _TextScalePreviewControl(),
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
              const Divider(height: AppSpacing.lg),
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
                onChanged: (v) =>
                    ref.read(uiPrefsControllerProvider.notifier).setTopK(v),
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
                onChanged: (v) =>
                    ref.read(uiPrefsControllerProvider.notifier).setGamma(v),
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
                onChanged: (v) =>
                    ref.read(uiPrefsControllerProvider.notifier).setMinArea(v),
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
                onChanged: (v) =>
                    ref.read(uiPrefsControllerProvider.notifier).setPadding(v),
              ),
              if (onResetToDemo != null) ...[
                const Divider(height: 24),
                ListTile(
                  leading:
                      const Icon(Icons.refresh, size: 22, color: Colors.orange),
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
              const SizedBox(height: AppSpacing.xs),
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
}

// Generic slider tile helper, kept private to this file
class _SliderTile<T extends num> extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final v = toDouble(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          child: Text(helper, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  String _fmt(double d) => d >= 1
      ? d.toStringAsFixed(0)
      : (d >= 0.01 ? d.toStringAsFixed(2) : d.toStringAsExponential(2));
}

// AppTextScale applied: control deslizante con vista previa en tiempo real
class _TextScalePreviewControl extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TextScalePreviewControl> createState() => _TextScalePreviewControlState();
}

class _TextScalePreviewControlState extends ConsumerState<_TextScalePreviewControl> {
  int? _previewLevel; // null = usa prefs actuales

  int get _level => _previewLevel ?? ref.watch(uiPrefsProvider).textScaleLevel;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(uiPrefsProvider);
    final cs = Theme.of(context).colorScheme;
    final previewPrefs = prefs.copyWith(textScaleLevel: _level);
    final mq = AppTextScale.mediaWithAppScale(context, previewPrefs);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('Tamaño de texto'),
          subtitle: Slider(
            key: const Key('slider_text_scale'),
            value: _level.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_level',
            onChanged: (d) => setState(() => _previewLevel = d.round().clamp(1, 5)),
            onChangeEnd: (d) {
              final v = d.round().clamp(1, 5);
              setState(() => _previewLevel = v);
              ref.read(uiPrefsControllerProvider.notifier).setTextScaleLevel(v);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: MediaQuery(
            data: mq,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: .18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Título de ejemplo', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Cuerpo de ejemplo — observa tamaño y espaciado.', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: const [
                    FilledButton(onPressed: null, child: Text('Acción')),
                    OutlinedButton(onPressed: null, child: Text('Secundaria')),
                    Text('Etiqueta'),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
