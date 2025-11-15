import 'package:flutter/material.dart';

/// Zoom control widget with slider.
///
/// Allows user to adjust zoom factor from 0.7x to 1.4x.
/// Displays current zoom percentage.
class ZoomControl extends StatelessWidget {
  const ZoomControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value; // 0.7 - 1.4
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final percent = (value * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Icon(
            Icons.zoom_out,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          Expanded(
            child: Slider(
              value: value,
              min: 0.7,
              max: 1.4,
              divisions: 14,
              label: '$percent%',
              onChanged: onChanged,
            ),
          ),
          Icon(
            Icons.zoom_in,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              '$percent%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
