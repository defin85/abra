import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abra/features/home/widgets/measurements_panel.dart';
import 'package:abra/core/models/measurement.dart';
import 'package:abra/providers/measurements_provider.dart';

void main() {
  group('MeasurementsPanel', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementsProvider.overrideWith(
              (ref) => MeasurementsNotifier(ref, null, null)..state = <Measurement>[],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MeasurementsPanel(),
            ),
          ),
        ),
      );

      expect(find.byType(MeasurementsPanel), findsOneWidget);
    });
  });
}