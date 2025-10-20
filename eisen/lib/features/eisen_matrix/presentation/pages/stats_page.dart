import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matrixControllerProvider);
    final tasks = state.tasks;
    final total = tasks.isEmpty ? 1 : tasks.length;

    int count(Quadrant q) => tasks.where((t) => t.quadrant == q).length;
    int minutes(Quadrant q) => tasks.where((t) => t.quadrant == q).fold(0, (a, b) => a + b.minutes);

    final isEs = Localizations.localeOf(context).languageCode == 'es';
    String qName(Quadrant q) {
      switch (q) {
        case Quadrant.q1:
          return isEs ? 'Urgente e Importante' : 'Urgent & Important';
        case Quadrant.q2:
          return isEs ? 'No urgente, Importante' : 'Not urgent, Important';
        case Quadrant.q3:
          return isEs ? 'Urgente, No importante' : 'Urgent, Not important';
        case Quadrant.q4:
          return isEs ? 'No urgente ni importante' : 'Neither urgent nor important';
      }
    }

    Widget card(Quadrant q, Color color) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(qName(q), style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
              const SizedBox(height: 8),
              Text(isEs ? 'Tareas: ${count(q)}' : 'Tasks: ${count(q)}'),
              Text(isEs ? 'Minutos: ${minutes(q)}' : 'Minutes: ${minutes(q)}'),
            ],
          ),
        ),
      );
    }

    double pct(Quadrant q) => (tasks.where((t) => t.quadrant == q).length / total * 100).clamp(0, 100).toDouble();

    Widget summaryChips() {
      Widget chip(String label, Color color, double percent) {
        return Chip(
          label: Text('$label ${percent.toStringAsFixed(0)}%'),
          avatar: CircleAvatar(backgroundColor: color, radius: 6),
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          chip('Q1', const Color(0xFFEF476F), pct(Quadrant.q1)),
          chip('Q2', const Color(0xFF06D6A0), pct(Quadrant.q2)),
          chip('Q3', const Color(0xFFFFB300), pct(Quadrant.q3)),
          chip('Q4', const Color(0xFF118AB2), pct(Quadrant.q4)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEs ? 'Estadísticas' : 'Statistics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          summaryChips(),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 720 ? 2 : 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              card(Quadrant.q1, const Color(0xFFEF476F)),
              card(Quadrant.q2, const Color(0xFF06D6A0)),
              card(Quadrant.q3, const Color(0xFFFFB300)),
              card(Quadrant.q4, const Color(0xFF118AB2)),
            ],
          ),
        ],
      ),
    );
  }
}
