import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abra/features/home/widgets/visualization_controls.dart';

void main() {
  group('VisualizationControls', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VisualizationControls(),
            ),
          ),
        ),
      );

      expect(find.byType(VisualizationControls), findsOneWidget);
    });
  });
}