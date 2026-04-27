import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.selected = false,
  });

  final CategoryConfig category;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return Chip(
      avatar:
          Icon(iconForCategoryKey(category.iconName), size: 16, color: color),
      label: Text(category.label),
      backgroundColor: selected ? color.withValues(alpha: 0.14) : null,
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      visualDensity: VisualDensity.compact,
    );
  }
}

IconData iconForCategoryKey(String iconName) {
  return switch (iconName) {
    'work' => Icons.work_outline,
    'lightbulb' => Icons.lightbulb_outline,
    'favorite' => Icons.favorite_outline,
    'payments' => Icons.payments_outlined,
    'shopping_cart' => Icons.shopping_cart_outlined,
    'person' => Icons.person_outline,
    'architecture' => Icons.architecture_outlined,
    'rocket' => Icons.rocket_launch_outlined,
    'inventory' => Icons.inventory_2_outlined,
    'palette' => Icons.palette_outlined,
    'inbox' => Icons.inbox_outlined,
    _ => Icons.label_outline,
  };
}
