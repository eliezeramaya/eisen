import 'package:eisen/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

class _DarkDemo extends StatelessWidget {
  const _DarkDemo();
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildAppTheme(Brightness.dark),
      child: Scaffold(
        appBar: AppBar(title: const Text('Dark AA Theme')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Body text (primary)'),
              const SizedBox(height: 8),
              const Text('Secondary text',
                  style: TextStyle(color: Color(0xFFB4BCC8))),
              const SizedBox(height: 12),
              TextField(
                  decoration: const InputDecoration(
                      labelText: 'Label', hintText: 'Hint')),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: const [
                FilterChip(label: Text('Chip'), onSelected: null),
                FilterChip(
                    label: Text('Selected'), selected: true, onSelected: null),
              ]),
              const SizedBox(height: 12),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Card content'))),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testGoldens('dark_theme_sample', (tester) async {
    await tester.pumpWidgetBuilder(const _DarkDemo(),
        surfaceSize: const Size(480, 800));
    await screenMatchesGolden(tester, 'dark_theme_sample');
  });
}
