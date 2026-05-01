import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:eisen/core/theme/app_theme.dart';
import 'package:eisen/core/ui/text_scaling.dart';
import 'package:eisen/theme/density.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/appearance_preview_controller.dart';

/// Live preview card for Appearance settings.
///
/// Reflects the current values in [appearancePreviewProvider] without
/// touching the app-wide Theme until the user presses Apply.
class AppearancePreviewCard extends ConsumerWidget {
  const AppearancePreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(appearancePreviewProvider);
    final baseBrightness = switch (preview.themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => Theme.of(context).brightness,
    };

    // Base theme + minimal + density applied, mirroring EisenApp.
    final baseTheme = buildAppTheme(baseBrightness);
    final withMinimal = preview.minimal ? asMinimal(baseTheme) : baseTheme;

    final densityEnum = () {
      switch (preview.densityPreset) {
        case 'compact':
          return DensityPreset.compact;
        case 'ultra':
          return DensityPreset.ultra;
        case 'comfy':
          return DensityPreset.comfy;
        case 'auto':
        default:
          // Auto: compact on small screens, comfy otherwise.
          return deviceClassFromContext(context).isCompact
              ? DensityPreset.compact
              : DensityPreset.comfy;
      }
    }();
    final themed = applyDensity(withMinimal, densityEnum);

    // Apply text scale from user preview level only inside this card.
    final tsf = userLevelToFactor(preview.textScaleLevel);
    final mq = MediaQuery.of(context);
    final mqScaled = mq.copyWith(textScaler: TextScaler.linear(tsf));

    final cs = themed.colorScheme;

    return Theme(
      data: themed,
      child: MediaQuery(
        data: mqScaled,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tarea importante',
                    style: themed.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Q2 · Focus',
                      style: themed.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Bloque de 45 minutos para avanzar en lo importante sin urgencias.',
                style: themed.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Hoy · 09:30',
                    style: themed.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.drag_indicator,
                      size: 16, color: cs.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
