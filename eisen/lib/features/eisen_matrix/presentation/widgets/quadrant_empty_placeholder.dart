import 'package:flutter/material.dart';

class QuadrantEmptyPlaceholder extends StatelessWidget {
  const QuadrantEmptyPlaceholder({
    super.key,
    required this.title,
    required this.hint,
  });
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.outlineVariant.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(hint, style: t.bodySmall?.copyWith(color: c.onSurfaceVariant)),
        ],
      ),
    );
  }
}
