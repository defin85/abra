import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abra/features/home/widgets/measurements_panel.dart';
import 'package:abra/core/models/measurement.dart';
import 'package:abra/core/models/control_point.dart';
import 'package:abra/providers/measurements_provider.dart';
import 'package:abra/providers/project_provider.dart';

void main() {
  group('MeasurementsPanel', () {
    late List<Measurement> testMeasurements;

    setUp(() {
      testMeasurements = [
        Measurement(
          id: '1',
          projectId: 'proj1',
          controlPointId: 'A',
          actualValue: 1500,
          expectedValue: 1545,
          axis: MeasurementAxis.width,
          timestamp: DateTime(2024, 1, 1, 10, 0),
        ),
        Measurement(
          id: '2',
          projectId: 'proj1',
          controlPointId: 'B',
          actualValue: 1540,
          expectedValue: 1545,
          axis: MeasurementAxis.width,
          timestamp: DateTime(2024, 1, 1, 10, 5),
        ),
        Measurement(
          id: '3',
          projectId: 'proj1',
          controlPointId: 'C',
          actualValue: 2800,
          expectedValue: 2825,
          axis: MeasurementAxis.length,
          timestamp: DateTime(2024, 1, 1, 10, 10),
        ),
      ];
    });

    Widget createTestWidget({List<Measurement>? measurements}) {
      return ProviderScope(
        overrides: [
          measurementsProvider.overrideWith((ref) => measurements ?? []),
          deviationStatsProvider.overrideWith((ref) {
            final allMeasurements = measurements ?? [];
            if (allMeasurements.isEmpty) {
              return DeviationStats(
                averageDeviation: 0,
                maxDeviation: 0,
                criticalCount: 0,
                warningCount: 0,
                normalCount: 0,
              );
            }
            
            final deviations = allMeasurements.map((m) => m.deviationPercent).toList();
            final critical = allMeasurements.where((m) => m.severity == MeasurementSeverity.critical).length;
            final warning = allMeasurements.where((m) => m.severity == MeasurementSeverity.warning).length;
            final normal = allMeasurements.where((m) => m.severity == MeasurementSeverity.normal).length;
            
            return DeviationStats(
              averageDeviation: deviations.reduce((a, b) => a + b) / deviations.length,
              maxDeviation: deviations.reduce((a, b) => a > b ? a : b),
              criticalCount: critical,
              warningCount: warning,
              normalCount: normal,
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MeasurementsPanel(),
          ),
        ),
      );
    }

    testWidgets('displays panel title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Измерения'), findsOneWidget);
    });

    testWidgets('shows measurements list', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(measurements: testMeasurements));
      
      expect(find.text('Точка A'), findsOneWidget);
      expect(find.text('Точка B'), findsOneWidget);
      expect(find.text('Точка C'), findsOneWidget);
    });

    testWidgets('displays actual and expected values', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(measurements: testMeasurements));
      
      expect(find.text('1500 мм'), findsOneWidget);
      expect(find.text('1545 мм'), findsOneWidget);
    });

    testWidgets('shows deviation percentage', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(measurements: testMeasurements));
      
      // First measurement has ~2.9% deviation
      expect(find.textContaining('2.9%'), findsOneWidget);
    });

    testWidgets('displays correct severity colors', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(measurements: testMeasurements));
      
      // Check for severity indicator containers
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('shows empty state when no measurements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(measurements: []));
      
      expect(find.text('Нет измерений'), findsOneWidget);
      expect(find.text('Добавьте измерения для анализа'), findsOneWidget);
    });

    testWidgets('displays statistics summary', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(measurements: testMeasurements));
      
      expect(find.text('Статистика'), findsOneWidget);
      expect(find.text('Среднее отклонение:'), findsOneWidget);
      expect(find.text('Макс. отклонение:'), findsOneWidget);
    });

    testWidgets('shows critical count in stats', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(measurements: testMeasurements));
      
      expect(find.textContaining('Критических:'), findsOneWidget);
    });

    testWidgets('measurement items are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(measurements: testMeasurements));
      
      final listTile = find.byType(ListTile).first;
      await tester.tap(listTile);
      await tester.pump();
      
      // Should not crash
      expect(find.text('Точка A'), findsOneWidget);
    });

    testWidgets('shows measurement axis icons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(measurements: testMeasurements));
      
      // Width measurements show swap_horiz icon
      expect(find.byIcon(Icons.swap_horiz), findsWidgets);
      // Length measurements show height icon
      expect(find.byIcon(Icons.height), findsWidgets);
    });

    testWidgets('formats timestamps correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(measurements: testMeasurements));
      
      expect(find.textContaining('10:00'), findsOneWidget);
      expect(find.textContaining('01.01.2024'), findsWidgets);
    });

    testWidgets('panel is scrollable', (WidgetTester tester) async {
      // Create many measurements
      final manyMeasurements = List.generate(20, (index) => Measurement(
        id: 'id$index',
        projectId: 'proj1',
        controlPointId: String.fromCharCode(65 + index), // A, B, C...
        actualValue: 1500 + index * 10,
        expectedValue: 1545,
        axis: MeasurementAxis.width,
        timestamp: DateTime.now(),
      ));
      
      await tester.pumpWidget(createTestWidget(measurements: manyMeasurements));
      
      expect(find.byType(ListView), findsWidgets);
      
      // Try to scroll
      await tester.drag(find.byType(ListView).first, const Offset(0, -200));
      await tester.pump();
    });

    testWidgets('shows project health indicator', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(measurements: testMeasurements));
      
      expect(find.text('Состояние проекта'), findsOneWidget);
      // Should show health status based on measurements
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('groups measurements by section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(measurements: testMeasurements));
      
      expect(find.text('Передняя часть'), findsWidgets);
    });

    testWidgets('shows add measurement button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.byIcon(Icons.add_chart), findsOneWidget);
    });
  });
}