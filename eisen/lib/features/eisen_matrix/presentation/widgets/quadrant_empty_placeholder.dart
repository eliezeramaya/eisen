import 'package:eisen/core/responsive/layout_tokens.dart';
import 'package:flutter/material.dart';

class QuadrantEmptyPlaceholder extends StatelessWidget {
  const QuadrantEmptyPlaceholder({super.key, required this.title, required this.hint});
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.outlineVariant.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: AppSpacing.xs * 0.75), // 6px
          Text(hint, style: t.bodySmall?.copyWith(color: c.onSurfaceVariant)),
        ],
      ),
    );
  }
}
