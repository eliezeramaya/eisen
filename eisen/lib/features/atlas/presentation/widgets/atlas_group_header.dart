import 'package:flutter/material.dart';

class AtlasGroupHeader extends StatelessWidget {
  const AtlasGroupHeader({
    super.key,
    required this.label,
    required this.weight,
  });

  final String label;
  final double weight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Text(
          weight.toStringAsFixed(0),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
