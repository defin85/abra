import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abra/features/home/home_screen.dart';
import 'package:abra/core/models/project.dart';
import 'package:abra/core/models/car_model.dart';
import 'package:abra/core/models/measurement.dart';
import 'package:abra/core/models/control_point.dart';
import 'package:abra/providers/project_provider.dart';
import 'package:abra/providers/measurements_provider.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('HomeScreen', () {
    late Project testProject;
    late CarModel testCarModel;
    late List<Measurement> testMeasurements;

    setUp(() {
      testCarModel = CarModel(
        id: '1',
        manufacturer: 'Toyota',
        model: 'Camry',
        year: '2023',
        controlPoints: [
          ControlPoint(
            id: 'A',
            name: 'Передняя левая стойка',
            code: 'A',
            position: Vector3(100, 50, 0),
          ),
          ControlPoint(
            id: 'B',
            name: 'Передняя правая стойка',
            code: 'B',
            position: Vector3(100, -50, 0),
          ),
        ],
      );

      testProject = Project(
        id: '1',
        name: 'Тестовый проект',
        carModelId: '1',
        carModel: testCarModel,
        vin: '1HGBH41JXMN109186',
        plateNumber: 'ABC123',
        customerName: 'Иван Иванов',
        createdAt: DateTime.now(),
        status: ProjectStatus.active,
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
      ];
    });

    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProjectProvider.overrideWith(
              (ref) => ProjectNotifier()..state = testProject,
            ),
            measurementsProvider.overrideWith(
              (ref) => MeasurementsNotifier(ref, testProject, testCarModel)..state = testMeasurements,
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('displays project name', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProjectProvider.overrideWith(
              (ref) => ProjectNotifier()..state = testProject,
            ),
            measurementsProvider.overrideWith(
              (ref) => MeasurementsNotifier(ref, testProject, testCarModel)..state = testMeasurements,
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.text('Тестовый проект'), findsOneWidget);
    });

    testWidgets('shows customer info', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProjectProvider.overrideWith(
              (ref) => ProjectNotifier()..state = testProject,
            ),
            measurementsProvider.overrideWith(
              (ref) => MeasurementsNotifier(ref, testProject, testCarModel)..state = testMeasurements,
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.text('Иван Иванов'), findsOneWidget);
    });

    testWidgets('displays measurements panel', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProjectProvider.overrideWith(
              (ref) => ProjectNotifier()..state = testProject,
            ),
            measurementsProvider.overrideWith(
              (ref) => MeasurementsNotifier(ref, testProject, testCarModel)..state = testMeasurements,
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Проверяем наличие панели измерений
      expect(find.text('Измерения'), findsOneWidget);
    });

    testWidgets('shows visualization controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProjectProvider.overrideWith(
              (ref) => ProjectNotifier()..state = testProject,
            ),
            measurementsProvider.overrideWith(
              (ref) => MeasurementsNotifier(ref, testProject, testCarModel)..state = testMeasurements,
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Проверяем наличие элементов управления визуализацией
      expect(find.text('Режим:'), findsOneWidget);
    });

    testWidgets('displays car model info', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProjectProvider.overrideWith(
              (ref) => ProjectNotifier()..state = testProject,
            ),
            measurementsProvider.overrideWith(
              (ref) => MeasurementsNotifier(ref, testProject, testCarModel)..state = testMeasurements,
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.text('Toyota Camry'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
    });

    testWidgets('shows no project message when project is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProjectProvider.overrideWith(
              (ref) => ProjectNotifier()..state = null,
            ),
            measurementsProvider.overrideWith(
              (ref) => MeasurementsNotifier(ref, null, null)..state = <Measurement>[],
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.text('Нет активного проекта'), findsOneWidget);
    });
  });
}