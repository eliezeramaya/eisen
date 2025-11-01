import 'package:flutter/material.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/ui/lists/quadrant_list.dart';
import 'package:eisen/theme/density.dart';

class MatrixDesktop extends StatelessWidget {
  final List<Task> q1;
  final List<Task> q2;
  final List<Task> q3;
  final List<Task> q4;
  final void Function(Task task)? onToggle;
  final void Function(Task task)? onOpen;
  const MatrixDesktop({
    super.key,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
    this.onToggle,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final gutter = (w * 0.006).clamp(6, 12).toDouble();
    final t = Theme.of(context);
    final s = t.extension<SpacingTokens>();

    Widget buildHeader(String title, int count, Color color) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(
          horizontal: (s?.insetMd ?? 12),
        ),
        child: Row(
          children: [
            Container(width: 6, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text('$title ($count)', style: t.textTheme.titleMedium),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(gutter),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: gutter,
        crossAxisSpacing: gutter,
        childAspectRatio: 1,
        children: [
          _cell(context, Quadrant.q1, q1, buildHeader('Q1', q1.length, t.colorScheme.error)),
          _cell(context, Quadrant.q2, q2, buildHeader('Q2', q2.length, t.colorScheme.primary)),
          _cell(context, Quadrant.q3, q3, buildHeader('Q3', q3.length, t.colorScheme.tertiary)),
          _cell(context, Quadrant.q4, q4, buildHeader('Q4', q4.length, t.colorScheme.secondary)),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, Quadrant q, List<Task> tasks, Widget header) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: QuadrantList(
        tasks: tasks,
        header: header,
        onToggle: onToggle,
        onOpen: onOpen,
      ),
    );
  }
}

