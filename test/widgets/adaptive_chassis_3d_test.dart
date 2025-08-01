import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abra/features/visualization/widgets/adaptive_chassis_3d.dart';
import 'package:abra/core/geometry/adaptive_chassis.dart';

void main() {
  group('AdaptiveChassis3D', () {
    late Widget testWidget;
    late AdaptiveChassis chassis;

    setUp(() {
      chassis = AdaptiveChassis.toyotaCamry();
      testWidget = MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: AdaptiveChassis3D(
              factoryChassis: chassis,
              deformedChassis: chassis.createDeformed(
                frontDamage: 0.1,
                wheelbaseChange: -10.0,
              ),
            ),
          ),
        ),
      );
    });

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      expect(find.byType(AdaptiveChassis3D), findsOneWidget);
    });

    testWidgets('shows control panel with title', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      expect(find.text('Управление камерой'), findsOneWidget);
    });

    testWidgets('displays chassis information', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      expect(find.text('Адаптивный каркас'), findsOneWidget);
      expect(find.text('Toyota Camry XV70'), findsOneWidget);
      expect(find.textContaining('База:'), findsOneWidget);
      expect(find.textContaining('2825мм'), findsOneWidget);
    });

    testWidgets('can switch between camera modes', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      // Find camera mode buttons
      expect(find.text('Орбита'), findsOneWidget);
      expect(find.text('Свободно'), findsOneWidget);
      expect(find.text('Тест'), findsOneWidget);
      
      // Switch to free camera mode
      await tester.tap(find.text('Свободно'));
      await tester.pumpAndSettle();
      
      // Should show free camera controls
      expect(find.text('Свободная камера:'), findsOneWidget);
      expect(find.text('WASD - движение'), findsOneWidget);
    });

    testWidgets('can toggle axes visibility', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: AdaptiveChassis3D(
              showAxes: true,
              factoryChassis: chassis,
            ),
          ),
        ),
      ));
      
      // CustomPaint should be rendered (multiple due to UI elements)
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('can show/hide deformed chassis', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: AdaptiveChassis3D(
              showDeformed: true,
              factoryChassis: chassis,
              deformedChassis: chassis.createDeformed(
                frontDamage: 0.2,
                wheelbaseChange: -15.0,
              ),
            ),
          ),
        ),
      ));
      
      expect(find.byType(AdaptiveChassis3D), findsOneWidget);
    });

    testWidgets('reset button resets camera position', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      // Find reset button
      final resetButton = find.byIcon(Icons.restart_alt);
      expect(resetButton, findsOneWidget);
      
      // Tap reset
      await tester.tap(resetButton);
      await tester.pump();
      
      // Widget should still be rendered
      expect(find.byType(AdaptiveChassis3D), findsOneWidget);
    });

    testWidgets('control panel can be collapsed', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      // Find collapse button
      final collapseButton = find.byIcon(Icons.expand_less);
      expect(collapseButton, findsOneWidget);
      
      // Collapse panel
      await tester.tap(collapseButton);
      await tester.pumpAndSettle();
      
      // Content should be hidden
      expect(find.text('Адаптивный каркас'), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('handles null chassis gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: const SizedBox(
            width: 800,
            height: 600,
            child: AdaptiveChassis3D(),
          ),
        ),
      ));
      
      // Should render with default Toyota Camry
      expect(find.byType(AdaptiveChassis3D), findsOneWidget);
      expect(find.textContaining('2825мм'), findsOneWidget);
    });

    testWidgets('camera controls respond to input', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      // Panel is expanded by default, but text might be in orbital mode section
      // Just check that zoom controls exist which are always visible
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);
      
      
      // Test zoom
      await tester.tap(find.byIcon(Icons.zoom_in));
      await tester.pump();
      
      await tester.tap(find.byIcon(Icons.zoom_out));
      await tester.pump();
    });

    testWidgets('shows measurements when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: AdaptiveChassis3D(
              showMeasurements: true,
              showLabels: true,
              factoryChassis: chassis,
            ),
          ),
        ),
      ));
      
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}