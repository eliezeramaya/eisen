import 'package:eisen/core/responsive/layout_tokens.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/eisen_matrix/domain/category_colors.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Category Manager page for customizing category colors.
///
/// Features:
/// - List of all categories extracted from existing tasks
/// - Visual preview of current color (hash-based or user override)
/// - Color picker dialog for customization
/// - Reset to default (hash-based) option
/// - Live preview in category pills
class CategoryManagerPage extends ConsumerWidget {
  const CategoryManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrixState = ref.watch(matrixControllerProvider);
    final tasks = matrixState.tasks;
    final uiPrefs = ref.watch(uiPrefsProvider);
    final colorService = uiPrefs.categoryColorService;

    // Extract unique categories from tasks
    final categories = tasks
        .where((t) => t.category != null && t.category!.isNotEmpty)
        .map((t) => t.category!)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Colors'),
        actions: [
          // Reset all button
          if (uiPrefs.categoryColors.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Reset all to defaults',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset All Colors'),
                    content: const Text(
                      'Reset all categories to default hash-based colors?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  final ctrl = ref.read(uiPrefsControllerProvider.notifier);
                  // Clear all overrides
                  await ctrl.overwrite(
                    uiPrefs.copyWith(categoryColors: const {}),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All colors reset to defaults'),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No categories yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Add categories to your tasks to customize colors',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = categories[index];
                final hasOverride = colorService.hasOverride(category);
                final color = colorService.getColorForCategory(category);
                final lightVariant = colorService.getLightVariant(category);
                final darkVariant = colorService.getDarkVariant(category);

                // Count tasks with this category
                final taskCount = tasks
                    .where((t) => t.category == category)
                    .length;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showColorPicker(
                      context,
                      ref,
                      category,
                      color,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          // Color preview circle
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: lightVariant,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: darkVariant,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.folder,
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),

                          // Category name and info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      category,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (hasOverride) ...[
                                      const SizedBox(width: AppSpacing.xs),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Custom',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$taskCount task${taskCount == 1 ? '' : 's'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          // Action buttons
                          if (hasOverride)
                            IconButton(
                              icon: const Icon(Icons.restore),
                              tooltip: 'Reset to default',
                              onPressed: () => _resetCategoryColor(
                                context,
                                ref,
                                category,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.palette_outlined),
                            tooltip: 'Change color',
                            onPressed: () => _showColorPicker(
                              context,
                              ref,
                              category,
                              color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showColorPicker(
    BuildContext context,
    WidgetRef ref,
    String category,
    Color currentColor,
  ) async {
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(
        category: category,
        currentColor: currentColor,
      ),
    );

    if (selectedColor != null && context.mounted) {
      final ctrl = ref.read(uiPrefsControllerProvider.notifier);
      await ctrl.updateCategoryColor(category, selectedColor);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Color updated for "$category"'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ctrl.updateCategoryColor(category, currentColor);
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _resetCategoryColor(
    BuildContext context,
    WidgetRef ref,
    String category,
  ) async {
    final ctrl = ref.read(uiPrefsControllerProvider.notifier);
    await ctrl.removeCategoryColor(category);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Color reset to default for "$category"'),
        ),
      );
    }
  }
}

/// Color picker dialog with Material Design 3 palette.
class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({
    required this.category,
    required this.currentColor,
  });

  final String category;
  final Color currentColor;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    // Use the base palette from CategoryColorService
    final palette = CategoryColorService.basePalette;

    return AlertDialog(
      title: Text('Choose color for "${widget.category}"'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _selectedColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedColor.withValues(alpha: 0.8),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder,
                    color: _selectedColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.category,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Color grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: palette.length,
              itemBuilder: (context, index) {
                final color = palette[index];
                final isSelected = color == _selectedColor;

                return InkWell(
                  onTap: () => setState(() => _selectedColor = color),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 32,
                          )
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
