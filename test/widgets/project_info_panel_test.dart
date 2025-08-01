import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abra/features/home/widgets/project_info_panel.dart';
import 'package:abra/core/models/project.dart';
import 'package:abra/providers/project_provider.dart';

void main() {
  group('ProjectInfoPanel', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      final testProject = Project(
        id: '1',
        name: 'Test Project',
        carModelId: '1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProjectProvider.overrideWith(
              (ref) => ProjectNotifier()..state = testProject,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProjectInfoPanel(),
            ),
          ),
        ),
      );

      expect(find.byType(ProjectInfoPanel), findsOneWidget);
    });
  });
}