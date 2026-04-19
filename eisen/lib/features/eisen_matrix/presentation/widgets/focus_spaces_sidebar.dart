import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/focus_space_repository.dart';
import '../../domain/focus_space.dart';
import '../controllers/matrix_view_filter_controller.dart';

class FocusSpacesSidebar extends ConsumerWidget {
  const FocusSpacesSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsync = ref.watch(focusSpacesStreamProvider);
    final filter = ref.watch(matrixViewFilterProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Espacios',
            style: theme.textTheme.titleSmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: spacesAsync.when(
              data: (spaces) => ListView(
                children: [
                  for (final space in spaces)
                    _FocusSpaceTile(
                      space: space,
                      selected: filter.focusSpace.id == space.id,
                    ),
                  const SizedBox(height: 8),
                  const _NewSpaceButton(),
                ],
              ),
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusSpaceTile extends ConsumerWidget {
  const _FocusSpaceTile({
    required this.space,
    required this.selected,
  });

  final FocusSpace space;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSelectedColor = _parseColor(space.colorHex) ?? colorScheme.primary;
    final bgColor =
        selected ? onSelectedColor.withValues(alpha: 0.14) : Colors.transparent;

    return InkWell(
      onTap: () =>
          ref.read(matrixViewFilterProvider.notifier).setFocusSpace(space),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: onSelectedColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _iconForName(space.iconName),
                size: 16,
                color: onSelectedColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                space.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (!space.isDefault) _SpaceMenu(space: space),
          ],
        ),
      ),
    );
  }
}

class _SpaceMenu extends ConsumerWidget {
  const _SpaceMenu({required this.space});
  final FocusSpace space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (value) {
        switch (value) {
          case 'rename':
            _renameSpace(context, ref, space);
            break;
          case 'delete':
            _deleteSpace(context, ref, space);
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'rename',
          child: Text('Renombrar'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Eliminar'),
        ),
      ],
    );
  }

  Future<void> _renameSpace(
      BuildContext context, WidgetRef ref, FocusSpace space) async {
    final controller = TextEditingController(text: space.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar espacio'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                Navigator.of(ctx).pop();
              } else {
                Navigator.of(ctx).pop(name);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await ref
        .read(focusSpaceRepositoryProvider)
        .updateFocusSpace(space.copyWith(name: result));
  }

  Future<void> _deleteSpace(
      BuildContext context, WidgetRef ref, FocusSpace space) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar espacio'),
        content: Text(
          '¿Eliminar el espacio "${space.name}"? Tus tareas seguirán existiendo '
          'en la Matriz General.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(focusSpaceRepositoryProvider).deleteFocusSpace(space.id);
  }
}

class _NewSpaceButton extends ConsumerWidget {
  const _NewSpaceButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _createSpace(context, ref),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Nuevo espacio'),
    );
  }

  Future<void> _createSpace(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo espacio'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Trabajo, Familia, Proyecto 1...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                Navigator.of(ctx).pop();
              } else {
                Navigator.of(ctx).pop(name);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    if (!context.mounted) return;

    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.secondary;
    final colorHex = _colorToHex(primary);

    final space = FocusSpace(
      id: id,
      name: result,
      // Use the display name as category key; renaming the space later
      // does not change the underlying category filter.
      categoryId: result,
      colorHex: colorHex,
      iconName: 'work',
      isDefault: false,
    );

    await ref.read(focusSpaceRepositoryProvider).addFocusSpace(space);
    ref.read(matrixViewFilterProvider.notifier).setFocusSpace(space);
  }
}

IconData _iconForName(String name) {
  switch (name) {
    case 'work':
      return Icons.work_outline;
    case 'family':
      return Icons.family_restroom;
    case 'personal':
      return Icons.person_outline;
    case 'project':
      return Icons.folder_open;
    case 'health':
      return Icons.favorite_border;
    case 'learning':
      return Icons.school_outlined;
    default:
      return Icons.grid_view_rounded;
  }
}

Color? _parseColor(String hex) {
  if (hex.isEmpty) return null;
  var value = hex.trim();
  if (value.startsWith('#')) {
    value = value.substring(1);
  }
  if (value.length == 6) {
    value = 'FF$value';
  }
  try {
    final intColor = int.parse(value, radix: 16);
    return Color(intColor);
  } catch (_) {
    return null;
  }
}

String _colorToHex(Color color) {
  final value = color.toARGB32();
  return '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
}
