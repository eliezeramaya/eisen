import 'package:flutter/material.dart';

class FabAddTask extends StatelessWidget {
  final bool visible;
  final VoidCallback onPressed;
  const FabAddTask({super.key, required this.visible, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      minimum: EdgeInsets.only(right: 16, bottom: bottom + 8),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 160),
        offset: visible ? Offset.zero : const Offset(0, 0.3),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: visible ? 1 : 0,
          child: Semantics(
            label: 'Agregar tarea',
            button: true,
            enabled: true,
            child: FloatingActionButton.extended(
              heroTag: 'fab_add_task',
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
          ),
        ),
      ),
    );
  }
}

