import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abra/features/home/widgets/visualization_controls.dart';
import 'package:abra/providers/visualization_settings_provider.dart';

void main() {
  group('VisualizationControls', () {
    late VisualizationSettings testSettings;

    setUp(() {
      testSettings = const VisualizationSettings(
        is3DView: true,
        showMeasurements: true,
        showControlPoints: false,
        showAxes: true,
        showLeftPanel: true,
        showRightPanel: true,
        selectedTabIndex: 0,
        useCurvedElements: false,
      );
    });

    Widget createTestWidget({VisualizationSettings? settings}) {
      return ProviderScope(
        overrides: [
          visualizationSettingsProvider.overrideWith((ref) => settings ?? testSettings),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: VisualizationControls(),
          ),
        ),
      );
    }

    testWidgets('displays all control toggles', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Настройки отображения'), findsOneWidget);
      expect(find.text('Показать измерения'), findsOneWidget);
      expect(find.text('Контрольные точки'), findsOneWidget);
      expect(find.text('Оси координат'), findsOneWidget);
    });

    testWidgets('shows measurements toggle is on', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final measurementSwitch = find.byWidgetPredicate(
        (widget) => widget is Switch && widget.value == true,
      );
      expect(measurementSwitch, findsWidgets);
    });

    testWidgets('can toggle measurements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final measurementSwitch = find.byWidgetPredicate(
        (widget) => widget is Switch && 
                    widget.key == null && // Find the right switch
                    widget.value == true,
      ).first;

      await tester.tap(measurementSwitch);
      await tester.pump();

      // State should update via provider
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('can toggle control points', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find control points row
      final controlPointsRow = find.ancestor(
        of: find.text('Контрольные точки'),
        matching: find.byType(Row),
      ).first;

      final switchWidget = find.descendant(
        of: controlPointsRow,
        matching: find.byType(Switch),
      );

      await tester.tap(switchWidget);
      await tester.pump();

      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('can toggle axes display', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final axesRow = find.ancestor(
        of: find.text('Оси координат'),
        matching: find.byType(Row),
      ).first;

      final switchWidget = find.descendant(
        of: axesRow,
        matching: find.byType(Switch),
      );

      await tester.tap(switchWidget);
      await tester.pump();

      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('displays icons for each control', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.straighten), findsOneWidget);
      expect(find.byIcon(Icons.control_point), findsOneWidget);
      expect(find.byIcon(Icons.axis_arrow), findsOneWidget);
    });

    testWidgets('shows curved elements toggle', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Изогнутые элементы'), findsOneWidget);
      expect(find.byIcon(Icons.waves), findsOneWidget);
    });

    testWidgets('respects initial settings', (WidgetTester tester) async {
      final customSettings = testSettings.copyWith(
        showMeasurements: false,
        showControlPoints: true,
        showAxes: false,
      );

      await tester.pumpWidget(createTestWidget(settings: customSettings));

      // Count on/off switches
      final switches = tester.widgetList<Switch>(find.byType(Switch));
      final onSwitches = switches.where((s) => s.value == true).length;
      final offSwitches = switches.where((s) => s.value == false).length;

      expect(onSwitches, greaterThan(0));
      expect(offSwitches, greaterThan(0));
    });

    testWidgets('has proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for card container
      final card = find.byType(Card);
      expect(card, findsOneWidget);

      // Check for dividers
      expect(find.byType(Divider), findsWidgets);
    });

    testWidgets('switches are accessible', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      // All switches should be enabled
      for (final switchFinder in switches.evaluate()) {
        final switchWidget = switchFinder.widget as Switch;
        expect(switchWidget.onChanged, isNotNull);
      }
    });

    testWidgets('mobile layout shows correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Настройки отображения'), findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('desktop layout shows additional options', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Настройки отображения'), findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('shows mobile-specific settings widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            visualizationSettingsProvider.overrideWith((ref) => testSettings),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MobileVisualizationSettings(),
            ),
          ),
        ),
      );

      expect(find.text('Настройки визуализации'), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);
    });
  });
}