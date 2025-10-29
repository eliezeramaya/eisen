import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/user_categories_repository.dart';
import '../../filters_providers.dart';

class CategoryFiltersBar extends ConsumerWidget {
  const CategoryFiltersBar({super.key, this.padding = const EdgeInsets.all(8)});
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(userCategoriesProvider);
    final active = ref.watch(activeCategoryFiltersProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final cat in all)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat),
                selected: active.contains(cat),
                onSelected: (sel) {
                  final curr = [...active];
                  sel ? curr.add(cat) : curr.remove(cat);
                  ref.read(activeCategoryFiltersProvider.notifier).state =
                      curr.toSet().toList();
                },
              ),
            ),
          const SizedBox(width: 8),
          const _ManageFiltersButton(),
        ],
      ),
    );
  }
}

class _ManageFiltersButton extends ConsumerWidget {
  const _ManageFiltersButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      key: const Key('btn_manage_filters'),
      onPressed: () => _openDialog(context, ref),
      icon: const Icon(Icons.tune),
      label: const Text('Agregar/Editar filtros'),
    );
  }

  Future<void> _openDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (ctx) => const _ManageFiltersDialog(),
    );
  }
}

class _ManageFiltersDialog extends ConsumerStatefulWidget {
  const _ManageFiltersDialog();
  @override
  ConsumerState<_ManageFiltersDialog> createState() => _ManageFiltersDialogState();
}

class _ManageFiltersDialogState extends ConsumerState<_ManageFiltersDialog> {
  final _controller = TextEditingController();
  String? _editing;

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(userCategoriesProvider);
    return AlertDialog(
      title: const Text('Filtros (categorías)'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: _editing == null
                        ? 'Nueva categoría'
                        : 'Renombrar categoría',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  await ref
                      .read(userCategoriesProvider.notifier)
                      .addOrRename(from: _editing, to: text);
                  setState(() {
                    _editing = null;
                    _controller.clear();
                  });
                },
                child: Text(_editing == null ? 'Agregar' : 'Guardar'),
              ),
            ]),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemBuilder: (_, i) {
                  final c = cats[i];
                  return ListTile(
                    dense: true,
                    title: Text(c),
                    trailing: Wrap(spacing: 8, children: [
                      IconButton(
                        tooltip: 'Renombrar',
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            _editing = c;
                            _controller.text = c;
                          });
                        },
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref
                              .read(userCategoriesProvider.notifier)
                              .remove(c);
                          if (_editing == c) {
                            setState(() {
                              _editing = null;
                              _controller.clear();
                            });
                          }
                        },
                      ),
                    ]),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: cats.length,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

