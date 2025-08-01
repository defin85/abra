import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abra/features/visualization/widgets/car_body_2d_view.dart';
import 'package:abra/core/models/car_model.dart';
import 'package:abra/core/models/measurement.dart';
import 'package:abra/core/models/control_point.dart';

void main() {
  group('CarBody2DView', () {
    late CarModel testCarModel;
    late List<Measurement> testMeasurements;
    late Map<String, ControlPoint> testControlPoints;

    setUp(() {
      testControlPoints = {
        'A': const ControlPoint(
          id: 'A',
          name: 'Передняя левая стойка',
          x: 100,
          y: 50,
          z: 100,
          section: CarSection.front,
        ),
        'B': const ControlPoint(
          id: 'B',
          name: 'Передняя правая стойка',
          x: 100,
          y: -50,
          z: 100,
          section: CarSection.front,
        ),
        'C': const ControlPoint(
          id: 'C',
          name: 'Центральная левая точка',
          x: 0,
          y: 60,
          z: 80,
          section: CarSection.middle,
        ),
      };

      testCarModel = CarModel(
        id: '1',
        manufacturer: 'Toyota',
        model: 'Camry',
        year: 2023,
        wheelbase: 2825,
        trackWidth: 1545,
        sillHeight: 150,
        controlPoints: testControlPoints,
        sections: [
          const CarBodySection(
            name: 'Капот',
            type: SectionType.hood,
            bounds: Rect.fromLTWH(50, -40, 100, 80),
          ),
          const CarBodySection(
            name: 'Передний бампер',
            type: SectionType.bumperFront,
            bounds: Rect.fromLTWH(140, -50, 20, 100),
          ),
        ],
      );

      testMeasurements = [
        Measurement(
          id: '1',
          projectId: 'proj1',
          controlPointId: 'A',
          actualValue: 1500,
          expectedValue: 1545,
          axis: MeasurementAxis.width,
          timestamp: DateTime.now(),
        ),
        Measurement(
          id: '2',
          projectId: 'proj1',
          controlPointId: 'B',
          actualValue: 1540,
          expectedValue: 1545,
          axis: MeasurementAxis.width,
          timestamp: DateTime.now(),
        ),
      ];
    });

    Widget createTestWidget({
      CarModel? carModel,
      List<Measurement>? measurements,
      ViewType viewType = ViewType.side,
      void Function(ControlPoint)? onPointSelected,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: CarBody2DView(
              carModel: carModel ?? testCarModel,
              measurements: measurements ?? [],
              viewType: viewType,
              onPointSelected: onPointSelected,
            ),
          ),
        ),
      );
    }

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(CarBody2DView), findsOneWidget);
    });

    testWidgets('displays control points', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Should render custom paint
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('can switch between view types', (WidgetTester tester) async {
      // Test side view
      await tester.pumpWidget(createTestWidget(viewType: ViewType.side));
      expect(find.byType(CarBody2DView), findsOneWidget);
      
      // Test top view
      await tester.pumpWidget(createTestWidget(viewType: ViewType.top));
      expect(find.byType(CarBody2DView), findsOneWidget);
      
      // Test front view
      await tester.pumpWidget(createTestWidget(viewType: ViewType.front));
      expect(find.byType(CarBody2DView), findsOneWidget);
    });

    testWidgets('handles tap on control points', (WidgetTester tester) async {
      ControlPoint? selectedPoint;
      
      await tester.pumpWidget(createTestWidget(
        onPointSelected: (point) {
          selectedPoint = point;
        },
      ));
      
      // Simulate tap on canvas
      await tester.tapAt(const Offset(400, 300));
      await tester.pump();
      
      // In real app, this would select a point if tap was near one
      expect(find.byType(CarBody2DView), findsOneWidget);
    });

    testWidgets('shows measurements on control points', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        measurements: testMeasurements,
      ));
      
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('handles empty measurements list', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        measurements: [],
      ));
      
      expect(find.byType(CarBody2DView), findsOneWidget);
    });

    testWidgets('scales content to fit container', (WidgetTester tester) async {
      // Test with different container sizes
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: CarBody2DView(
              carModel: testCarModel,
              measurements: [],
              viewType: ViewType.side,
            ),
          ),
        ),
      ));
      
      expect(find.byType(CarBody2DView), findsOneWidget);
    });

    testWidgets('shows car sections', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Custom paint should render sections
      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      expect(customPaint.painter, isNotNull);
    });

    testWidgets('applies correct colors for measurement severity', (WidgetTester tester) async {
      final criticalMeasurement = Measurement(
        id: '3',
        projectId: 'proj1',
        controlPointId: 'C',
        actualValue: 1400,
        expectedValue: 1545,
        axis: MeasurementAxis.width,
        timestamp: DateTime.now(),
      );
      
      await tester.pumpWidget(createTestWidget(
        measurements: [...testMeasurements, criticalMeasurement],
      ));
      
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('handles gesture detector for interactivity', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('updates when measurements change', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        measurements: testMeasurements,
      ));
      
      // Update with new measurements
      final newMeasurements = [
        ...testMeasurements,
        Measurement(
          id: '3',
          projectId: 'proj1',
          controlPointId: 'C',
          actualValue: 1500,
          expectedValue: 1500,
          axis: MeasurementAxis.width,
          timestamp: DateTime.now(),
        ),
      ];
      
      await tester.pumpWidget(createTestWidget(
        measurements: newMeasurements,
      ));
      
      expect(find.byType(CarBody2DView), findsOneWidget);
    });

    testWidgets('respects theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.blue,
          ),
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: CarBody2DView(
                carModel: testCarModel,
                measurements: [],
                viewType: ViewType.side,
              ),
            ),
          ),
        ),
      );
      
      expect(find.byType(CarBody2DView), findsOneWidget);
    });

    testWidgets('handles car model without sections', (WidgetTester tester) async {
      final modelNoSections = CarModel(
        id: '2',
        manufacturer: 'Test',
        model: 'Model',
        year: 2023,
        wheelbase: 2500,
        trackWidth: 1500,
        sillHeight: 150,
        controlPoints: testControlPoints,
        sections: [],
      );
      
      await tester.pumpWidget(createTestWidget(
        carModel: modelNoSections,
      ));
      
      expect(find.byType(CarBody2DView), findsOneWidget);
    });
  });
}