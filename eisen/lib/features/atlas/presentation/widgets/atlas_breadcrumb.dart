import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:flutter/material.dart';

class AtlasBreadcrumb extends StatelessWidget {
  const AtlasBreadcrumb({
    super.key,
    required this.path,
    this.onRoot,
    this.onSelect,
  });

  final List<AtlasNode> path;
  final VoidCallback? onRoot;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(onPressed: onRoot, child: const Text('Root')),
          for (var i = 0; i < path.length; i++) ...[
            const Icon(Icons.chevron_right, size: 16),
            TextButton(
              onPressed: () => onSelect?.call(i),
              child: Text(path[i].label),
            ),
          ],
        ],
      ),
    );
  }
}
