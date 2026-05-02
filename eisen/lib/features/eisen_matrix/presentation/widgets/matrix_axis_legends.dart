import 'package:eisen/l10n/app_localizations.dart';
import 'package:eisen/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';

class MatrixTopAxisLegends extends StatelessWidget {
  const MatrixTopAxisLegends({this.minimal = false, required this.textScale, required this.headerHeight});
  final bool minimal;
  // AppTextScale applied
  final double textScale;
  final double headerHeight;
  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizationsEn();
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );
    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                l10n.axisUrgent,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                textScaler: TextScaler.linear(textScale),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                l10n.axisNotUrgent,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                textScaler: TextScaler.linear(textScale),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MatrixLeftAxisLegends extends StatelessWidget {
  const MatrixLeftAxisLegends({this.minimal = false, required this.textScale, required this.headerHeight});
  final bool minimal;
  // AppTextScale applied
  final double textScale;
  final double headerHeight;
  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizationsEn();
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );
    return SizedBox(
      width: 64,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Reserve the same vertical space as the top axis headers
            SizedBox(height: headerHeight),
            // Two equal halves for vertical centering within each quadrant
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      l10n.axisImportant,
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      textScaler: TextScaler.linear(textScale),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      l10n.axisNotImportant,
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      textScaler: TextScaler.linear(textScale),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

