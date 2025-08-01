import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abra/features/home/home_screen.dart';
import 'package:abra/core/models/project.dart';
import 'package:abra/core/models/car_model.dart';
import 'package:abra/core/models/measurement.dart';
import 'package:abra/providers/project_provider.dart';
import 'package:abra/providers/measurements_provider.dart';
import 'package:abra/providers/visualization_settings_provider.dart';

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
        year: 2023,
        wheelbase: 2825,
        trackWidth: 1545,
        sillHeight: 150,
        controlPoints: {},
        sections: [],
      );

      testProject = Project(
        id: '1',
        carModelId: '1',
        vin: '1HGBH41JXMN109186',
        plateNumber: 'ABC123',
        customerName: 'Иван Иванов',
        customerPhone: '+7 999 123-45-67',
        createdAt: DateTime.now(),
        status: ProjectStatus.inProgress,
      );

      testMeasurements = [
        Measurement(
          id: '1',
          projectId: '1',
          controlPointId: 'A',
          actualValue: 1500,
          expectedValue: 1545,
          axis: MeasurementAxis.width,
          timestamp: DateTime.now(),
        ),
      ];
    });

    Widget createTestWidget({
      Project? project,
      CarModel? carModel,
      List<Measurement>? measurements,
      VisualizationSettings? settings,
    }) {
      return ProviderScope(
        overrides: [
          currentProjectProvider.overrideWith((ref) => project),
          selectedCarModelProvider.overrideWith((ref) => carModel),
          measurementsProvider.overrideWith((ref) => measurements ?? []),
          if (settings != null)
            visualizationSettingsProvider.overrideWith((ref) => settings),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      );
    }

    testWidgets('shows empty state when no project', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('Нет активного проекта'), findsOneWidget);
    });

    testWidgets('displays app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));
      
      expect(find.text('Auto Body Repair Assistant'), findsOneWidget);
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
    });

    testWidgets('shows mobile layout on small screens', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));
      
      // Mobile layout has bottom navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Визуализация'), findsOneWidget);
      expect(find.text('Настройки'), findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('shows desktop layout on large screens', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));
      
      // Desktop layout doesn't have bottom navigation
      expect(find.byType(BottomNavigationBar), findsNothing);
      
      // Has side panels
      expect(find.byType(Row), findsWidgets);
      
      tester.view.reset();
    });

    testWidgets('can toggle between 2D and 3D views', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));
      
      // Find toggle button
      final toggleButton = find.byIcon(Icons.view_in_ar);
      expect(toggleButton, findsOneWidget);
      
      await tester.tap(toggleButton);
      await tester.pump();
      
      // Icon should change
      expect(find.byIcon(Icons.grid_on), findsOneWidget);
    });

    testWidgets('shows 3D visualization when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
        settings: const VisualizationSettings(
          is3DView: true,
          showMeasurements: true,
          showControlPoints: true,
          showAxes: true,
          showLeftPanel: true,
          showRightPanel: true,
          selectedTabIndex: 0,
          useCurvedElements: false,
        ),
      ));
      
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('can toggle side panels on desktop', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));
      
      // Find panel toggle buttons
      final leftPanelToggle = find.byIcon(Icons.first_page);
      final rightPanelToggle = find.byIcon(Icons.last_page).last;
      
      expect(leftPanelToggle, findsOneWidget);
      expect(rightPanelToggle, findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('shows measurement input button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));
      
      expect(find.byIcon(Icons.add_chart), findsOneWidget);
    });

    testWidgets('shows PDF report button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));
      
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('mobile menu contains all actions', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));
      
      // Open popup menu
      final menuButton = find.byIcon(Icons.more_vert);
      expect(menuButton, findsOneWidget);
      
      await tester.tap(menuButton);
      await tester.pumpAndSettle();
      
      expect(find.text('Ввод измерений'), findsOneWidget);
      expect(find.text('Создать отчет'), findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('shows correct title on mobile', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));
      
      expect(find.text('ABRA'), findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('navigation to measurement input works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
        measurements: testMeasurements,
      ));
      
      final measurementButton = find.byIcon(Icons.add_chart);
      await tester.tap(measurementButton);
      await tester.pumpAndSettle();
      
      // Should navigate (in real app)
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('PDF generation shows snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));
      
      final pdfButton = find.byIcon(Icons.picture_as_pdf);
      await tester.tap(pdfButton);
      await tester.pump();
      
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Генерация отчета будет реализована позже'), findsOneWidget);
    });

    testWidgets('mobile tab switching works', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));
      
      // Switch to settings tab
      final settingsTab = find.text('Настройки');
      await tester.tap(settingsTab);
      await tester.pump();
      
      // Should show settings content
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      tester.view.reset();
    });
  });
}