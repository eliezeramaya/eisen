import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:eisen/core/theme/app_theme.dart';

class _Demo extends StatelessWidget {
  final bool minimal;
  const _Demo(this.minimal);
  @override
  Widget build(BuildContext context) {
    final light = buildAppTheme(Brightness.light);
    final theme = minimal ? asMinimal(light) : light;
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(title: Text(minimal ? 'Minimal ON' : 'Minimal OFF')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Body'),
              const SizedBox(height: 8),
              TextField(decoration: const InputDecoration(labelText: 'Label', hintText: 'Hint')),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: const [
                FilterChip(label: Text('Chip'), onSelected: null),
                FilterChip(label: Text('Selected'), selected: true, onSelected: null),
              ]),
              const SizedBox(height: 8),
              Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('Card content'))),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testGoldens('minimal_theme_off', (tester) async {
    await tester.pumpWidgetBuilder(const _Demo(false), surfaceSize: const Size(480, 800));
    await screenMatchesGolden(tester, 'minimal_theme_off');
  });

  testGoldens('minimal_theme_on', (tester) async {
    await tester.pumpWidgetBuilder(const _Demo(true), surfaceSize: const Size(480, 800));
    await screenMatchesGolden(tester, 'minimal_theme_on');
  });
}

