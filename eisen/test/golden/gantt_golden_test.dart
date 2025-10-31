import 'package:eisen/features/calendar_gantt/application/gantt_lanes.dart';
import 'package:eisen/features/calendar_gantt/demo/gantt_demo_data.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gantt goldens (dark)', () {
    Future<void> pumpChart(WidgetTester tester,
        {required TimeScale scale, required String name}) async {
      final spans = assignLanes(demoSpans());
      final viewStart = DateTime(2025, 2, 10);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(useMaterial3: true),
            home: Scaffold(
              backgroundColor: const Color(0xFF0B0E14),
              body: SizedBox(
                width: 900,
                height: 360,
                child: GanttChart(
                  spans: spans,
                  scale: scale,
                  viewStart: viewStart,
                ),
              ),
            ),
          ),
        ),
      );
      await screenMatchesGolden(tester, name);
    }

    testGoldens('gantt_day_scale', (tester) async {
      await pumpChart(tester, scale: TimeScale.days, name: 'gantt_day_scale');
    });

    testGoldens('gantt_week_scale', (tester) async {
      await pumpChart(tester, scale: TimeScale.weeks, name: 'gantt_week_scale');
    });

    testGoldens('gantt_month_scale', (tester) async {
      await pumpChart(tester,
          scale: TimeScale.months, name: 'gantt_month_scale');
    });
  });
}
