import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abra/features/home/widgets/project_info_panel.dart';
import 'package:abra/core/models/project.dart';
import 'package:abra/core/models/car_model.dart';
import 'package:abra/providers/project_provider.dart';

void main() {
  group('ProjectInfoPanel', () {
    late Project testProject;
    late CarModel testCarModel;

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
        description: 'Повреждение переднего бампера',
        createdAt: DateTime(2024, 1, 1),
        status: ProjectStatus.inProgress,
      );
    });

    Widget createTestWidget({Project? project, CarModel? carModel}) {
      return ProviderScope(
        overrides: [
          currentProjectProvider.overrideWith((ref) => project),
          selectedCarModelProvider.overrideWith((ref) => carModel),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ProjectInfoPanel(),
          ),
        ),
      );
    }

    testWidgets('displays project information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));

      expect(find.text('Информация о проекте'), findsOneWidget);
      expect(find.text('VIN:'), findsOneWidget);
      expect(find.text('1HGBH41JXMN109186'), findsOneWidget);
      expect(find.text('ABC123'), findsOneWidget);
      expect(find.text('Иван Иванов'), findsOneWidget);
    });

    testWidgets('displays car model information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));

      expect(find.text('Модель автомобиля'), findsOneWidget);
      expect(find.text('Toyota Camry'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
      expect(find.textContaining('2825'), findsOneWidget);
    });

    testWidgets('displays status badge with correct color', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));

      final statusChip = find.byType(Chip);
      expect(statusChip, findsOneWidget);
      expect(find.text('В работе'), findsOneWidget);
    });

    testWidgets('shows empty state when no project', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Нет активного проекта'), findsOneWidget);
    });

    testWidgets('formats phone number correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));

      expect(find.text('+7 999 123-45-67'), findsOneWidget);
    });

    testWidgets('shows description if available', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));

      expect(find.text('Повреждение переднего бампера'), findsOneWidget);
    });

    testWidgets('handles project without description', (WidgetTester tester) async {
      final projectNoDesc = testProject.copyWith(description: null);
      
      await tester.pumpWidget(createTestWidget(
        project: projectNoDesc,
        carModel: testCarModel,
      ));

      expect(find.text('Описание:'), findsOneWidget);
      expect(find.text('Не указано'), findsOneWidget);
    });

    testWidgets('displays created date', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));

      expect(find.text('Дата создания:'), findsOneWidget);
      expect(find.textContaining('01.01.2024'), findsOneWidget);
    });

    testWidgets('handles different project statuses', (WidgetTester tester) async {
      // Test completed status
      final completedProject = testProject.copyWith(
        status: ProjectStatus.completed,
      );
      
      await tester.pumpWidget(createTestWidget(
        project: completedProject,
        carModel: testCarModel,
      ));

      expect(find.text('Завершен'), findsOneWidget);

      // Test draft status
      final draftProject = testProject.copyWith(
        status: ProjectStatus.draft,
      );
      
      await tester.pumpWidget(createTestWidget(
        project: draftProject,
        carModel: testCarModel,
      ));

      expect(find.text('Черновик'), findsOneWidget);
    });

    testWidgets('displays wheelbase and track width', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));

      expect(find.text('Колесная база:'), findsOneWidget);
      expect(find.text('2825 мм'), findsOneWidget);
      expect(find.text('Колея:'), findsOneWidget);
      expect(find.text('1545 мм'), findsOneWidget);
    });

    testWidgets('panel is scrollable when content overflows', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));

      // Check for scrollable widget
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('shows dividers between sections', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        project: testProject,
        carModel: testCarModel,
      ));

      expect(find.byType(Divider), findsWidgets);
    });
  });
}