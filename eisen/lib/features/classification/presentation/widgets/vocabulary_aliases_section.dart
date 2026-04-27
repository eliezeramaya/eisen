import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/vocabulary_alias.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/vocabulary_alias_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VocabularyAliasesSection extends ConsumerWidget {
  const VocabularyAliasesSection({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aliases = ref.watch(vocabularyAliasControllerProvider);
    final categories = ref.watch(categoryConfigControllerProvider);
    final controller = ref.read(vocabularyAliasControllerProvider.notifier);

    final content = EisenCard(
      outlined: true,
      child: Column(
        children: [
          for (final alias in aliases)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${alias.term} → ${_aliasTarget(categories, alias)}'),
              subtitle: Text(_aliasSubtitle(alias)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: alias.isEnabled,
                    onChanged: (_) => controller.toggleEnabled(alias.id),
                  ),
                  IconButton(
                    tooltip: 'Editar alias',
                    onPressed: () => _openEditor(
                      context,
                      ref,
                      categories: categories,
                      initial: alias,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Eliminar alias',
                    onPressed: () => controller.remove(alias.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _openEditor(
                  context,
                  ref,
                  categories: categories,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo alias'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: controller.resetDefaults,
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              'Vocabulario personal',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          content,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EisenSectionHeader(
          title: 'Vocabulary aliases',
          subtitle:
              'Sinónimos y palabras propias como cliente, obra, luum o timmr.',
        ),
        content,
      ],
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    required List<CategoryConfig> categories,
    VocabularyAlias? initial,
  }) async {
    final result = await showModalBottomSheet<VocabularyAlias>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AliasEditorSheet(
        categories: categories,
        initial: initial,
      ),
    );
    if (result == null) return;
    final controller = ref.read(vocabularyAliasControllerProvider.notifier);
    if (initial == null) {
      await controller.add(result);
    } else {
      await controller.update(result);
    }
  }
}

String _categoryName(List<CategoryConfig> categories, VocabularyAlias alias) {
  for (final category in categories) {
    if (category.id == alias.mappedCategoryId) return category.name;
  }
  return 'Sin categoría';
}

String _aliasTarget(List<CategoryConfig> categories, VocabularyAlias alias) {
  final category = _categoryName(categories, alias);
  final quadrant = alias.suggestedQuadrant;
  if (quadrant == null) return category;
  final label = getQuadrantLabel(
    quadrant,
    QuadrantLabelStyle.professional,
  ).title;
  if (alias.mappedCategoryId == null) return label;
  return '$category · $label';
}

String _aliasSubtitle(VocabularyAlias alias) {
  final aliases = alias.aliases.join(', ');
  final kind = alias.mappedKind?.label;
  if (kind == null || kind.isEmpty) return aliases;
  if (aliases.isEmpty) return kind;
  return '$aliases · $kind';
}

class _AliasEditorSheet extends StatefulWidget {
  const _AliasEditorSheet({
    required this.categories,
    this.initial,
  });

  final List<CategoryConfig> categories;
  final VocabularyAlias? initial;

  @override
  State<_AliasEditorSheet> createState() => _AliasEditorSheetState();
}

class _AliasEditorSheetState extends State<_AliasEditorSheet> {
  late final TextEditingController _termController =
      TextEditingController(text: widget.initial?.term ?? '');
  late final TextEditingController _aliasesController = TextEditingController(
    text: widget.initial?.aliases.join(', ') ?? '',
  );
  late String? _categoryId = widget.initial?.mappedCategoryId;
  late EntryKind? _kind = widget.initial?.mappedKind;
  late Quadrant? _quadrant = widget.initial?.suggestedQuadrant;
  late bool _enabled = widget.initial?.enabled ?? true;

  @override
  void dispose() {
    _termController.dispose();
    _aliasesController.dispose();
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
            children: [
              Text(
                widget.initial == null ? 'Nuevo alias' : 'Editar alias',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _termController,
                decoration: const InputDecoration(labelText: 'Término base'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _aliasesController,
                decoration: const InputDecoration(
                  labelText: 'Variantes',
                  hintText: 'cliente, obra, luum, timmr, super',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin categoría'),
                  ),
                  for (final category in widget.categories)
                    DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EntryKind?>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Tipo sugerido'),
                items: [
                  const DropdownMenuItem<EntryKind?>(
                    value: null,
                    child: Text('Sin tipo'),
                  ),
                  for (final kind in EntryKind.values)
                    DropdownMenuItem<EntryKind?>(
                      value: kind,
                      child: Text(kind.label),
                    ),
                ],
                onChanged: (value) => setState(() => _kind = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Quadrant?>(
                initialValue: _quadrant,
                decoration: const InputDecoration(
                  labelText: 'Cuadrante sugerido',
                ),
                items: [
                  const DropdownMenuItem<Quadrant?>(
                    value: null,
                    child: Text('Sin cuadrante'),
                  ),
                  for (final quadrant in Quadrant.values)
                    DropdownMenuItem<Quadrant?>(
                      value: quadrant,
                      child: Text(
                        getQuadrantLabel(
                          quadrant,
                          QuadrantLabelStyle.professional,
                        ).title,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _quadrant = value),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
                title: const Text('Alias activo'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text(
                    widget.initial == null ? 'Crear alias' : 'Guardar alias'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final term = _termController.text.trim();
    if (term.isEmpty) return;
    final variants = _aliasesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    Navigator.of(context).pop(
      VocabularyAlias(
        id: widget.initial?.id ?? 'alias-$stamp',
        term: term,
        normalizedTerm: term.toLowerCase(),
        aliases: variants,
        mappedCategoryId: _categoryId,
        mappedKind: _kind,
        suggestedQuadrant: _quadrant,
        enabled: _enabled,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
