import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/widgets/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryManagementSection extends ConsumerWidget {
  const CategoryManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(categoryConfigControllerProvider.notifier);
    final categories = [...ref.watch(categoryConfigControllerProvider)]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EisenSectionHeader(
          title: 'Categories',
          subtitle:
              'Crea, edita, reordena y oculta las categorías maestras del sistema.',
        ),
        EisenCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in categories.take(6))
                    Opacity(
                      opacity: category.isHidden ? 0.45 : 1,
                      child: CategoryChip(category: category, selected: true),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                onReorder: controller.reorder,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final color = Color(category.colorValue);
                  return ListTile(
                    key: ValueKey(category.id),
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      foregroundColor: color,
                      child: Icon(iconForCategoryKey(category.iconKey)),
                    ),
                    title: Text(category.name),
                    subtitle: Text(
                      category.isHidden
                          ? 'Oculta en filtros y UI'
                          : 'Visible en clasificación y filtros',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar categoría',
                          onPressed: () => _openEditor(
                            context,
                            ref,
                            initial: category,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        Switch(
                          value: !category.isHidden,
                          onChanged: (_) =>
                              controller.toggleEnabled(category.id),
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.drag_handle),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _openEditor(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva categoría'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: controller.resetDefaults,
                    child: const Text('Restaurar defaults'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    CategoryConfig? initial,
  }) async {
    final result = await showModalBottomSheet<CategoryConfig>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CategoryEditorSheet(initial: initial),
    );
    if (result == null) return;

    final controller = ref.read(categoryConfigControllerProvider.notifier);
    if (initial == null) {
      await controller.add(result);
    } else {
      await controller.update(result);
    }
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({this.initial});

  final CategoryConfig? initial;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _keywordsController = TextEditingController(
    text: widget.initial?.keywords.join(', ') ?? '',
  );
  late String _iconKey = widget.initial?.iconKey ?? _iconChoices.first;
  late int _colorValue =
      widget.initial?.colorValue ?? _colorChoices.first.toARGB32();
  late bool _isHidden = widget.initial?.isHidden ?? false;

  @override
  void dispose() {
    _nameController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.initial == null ? 'Nueva categoría' : 'Editar categoría',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _keywordsController,
                decoration: const InputDecoration(
                  labelText: 'Keywords',
                  hintText: 'cliente, renders, entrega',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Color',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in _colorChoices)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _colorValue = color.toARGB32()),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: _colorValue == color.toARGB32()
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Icono',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final iconKey in _iconChoices)
                    ChoiceChip(
                      selected: _iconKey == iconKey,
                      onSelected: (_) => setState(() => _iconKey = iconKey),
                      avatar: Icon(iconForCategoryKey(iconKey), size: 16),
                      label: Text(iconKey),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: !_isHidden,
                onChanged: (value) => setState(() => _isHidden = !value),
                title: const Text('Mostrar en filtros y UI'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text(
                  widget.initial == null
                      ? 'Crear categoría'
                      : 'Guardar cambios',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final normalizedId =
        name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    Navigator.of(context).pop(
      CategoryConfig(
        id: widget.initial?.id ?? normalizedId,
        name: name,
        colorValue: _colorValue,
        iconKey: _iconKey,
        keywords: _keywordsController.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        isHidden: _isHidden,
        sortOrder: widget.initial?.sortOrder ?? 999,
        isSystem: widget.initial?.isSystem ?? false,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

const _iconChoices = <String>[
  'work',
  'lightbulb',
  'favorite',
  'payments',
  'shopping_cart',
  'person',
  'architecture',
  'rocket',
  'inventory',
  'palette',
];

const _colorChoices = <Color>[
  Color(0xFF275EFE),
  Color(0xFFFF8A00),
  Color(0xFF1F9D55),
  Color(0xFF7C3AED),
  Color(0xFFFB7185),
  Color(0xFF0891B2),
  Color(0xFFE11D48),
  Color(0xFF4F46E5),
];
