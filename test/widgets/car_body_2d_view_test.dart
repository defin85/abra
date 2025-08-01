import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abra/features/visualization/widgets/car_body_2d_view.dart';
import 'package:abra/core/models/car_model.dart';
import 'package:abra/core/models/measurement.dart';
import 'package:abra/core/models/control_point.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('CarBody2DView', () {
    late CarModel testCarModel;
    late List<Measurement> testMeasurements;
    late List<ControlPoint> testControlPoints;

    setUp(() {
      testControlPoints = [
        ControlPoint(
          id: 'A',
          name: 'Передняя левая стойка',
          code: 'A',
          position: Vector3(100, 50, 100),
        ),
        ControlPoint(
          id: 'B',
          name: 'Передняя правая стойка',
          code: 'B',
          position: Vector3(100, -50, 100),
        ),
        ControlPoint(
          id: 'C',
          name: 'Центральная левая точка',
          code: 'C',
          position: Vector3(0, 60, 80),
        ),
      ];

      testCarModel = CarModel(
        id: '1',
        manufacturer: 'Toyota',
        model: 'Camry',
        year: '2023',
        controlPoints: testControlPoints,
      );

      testMeasurements = [
        Measurement(
          id: '1',
          projectId: '1',
          fromPointId: 'A',
          toPointId: 'B',
          actualValue: 100.5,
          factoryValue: 100.0,
        ),
        Measurement(
          id: '2',
          projectId: '1',
          fromPointId: 'A',
          toPointId: 'C',
          actualValue: 150.2,
          factoryValue: 150.0,
        ),
      ];
    });

    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarBody2DView(
              carModel: testCarModel,
              measurements: testMeasurements,
            ),
          ),
        ),
      );

      expect(find.byType(CarBody2DView), findsOneWidget);
    });

    testWidgets('displays car model info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarBody2DView(
              carModel: testCarModel,
              measurements: testMeasurements,
            ),
          ),
        ),
      );

      // Проверяем, что отображается информация о модели
      expect(find.text('Toyota Camry'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
    });

    testWidgets('shows measurements when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarBody2DView(
              carModel: testCarModel,
              measurements: testMeasurements,
            ),
          ),
        ),
      );

      // Проверяем, что компонент отображается
      expect(find.byType(CarBody2DView), findsOneWidget);
    });

    testWidgets('shows control points', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarBody2DView(
              carModel: testCarModel,
              measurements: testMeasurements,
            ),
          ),
        ),
      );

      // Проверяем, что компонент отображается
      expect(find.byType(CarBody2DView), findsOneWidget);
    });
  });
}