import 'package:flutter/material.dart';

class ZenCompletionDialog extends StatelessWidget {
  const ZenCompletionDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Momento Zen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            Text('Cada animación es una respiración;\ncada color, una emoción;\ncada tarea completada, un instante de calma.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

