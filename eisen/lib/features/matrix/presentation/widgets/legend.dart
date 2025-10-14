import 'package:flutter/material.dart';
import '../../../matrix/domain/entities.dart';

class Legend extends StatelessWidget {
  final List<Task> tasks;
  const Legend({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final double total = tasks.length.toDouble().clamp(1.0, double.infinity) as double;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip('Q1', Colors.redAccent, _pct(tasks, Quadrant.q1, total)),
          _chip('Q2', Colors.greenAccent, _pct(tasks, Quadrant.q2, total)),
          _chip('Q3', Colors.amberAccent, _pct(tasks, Quadrant.q3, total)),
          _chip('Q4', Colors.lightBlueAccent, _pct(tasks, Quadrant.q4, total)),
        ],
      ),
    );
  }

  double _pct(List<Task> tasks, Quadrant q, double total) => tasks.where((t) => t.quadrant == q).length.toDouble() / total;

  Widget _chip(String label, Color color, double p) {
    final pct = (p * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Chip(
        label: Text('$label $pct%'),
        avatar: CircleAvatar(backgroundColor: color, radius: 6),
      ),
    );
  }
}
