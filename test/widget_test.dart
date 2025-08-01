import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abra/main.dart';

void main() {
  testWidgets('HomeScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AutoBodyRepairApp(),
      ),
    );

    // Verify that HomeScreen shows initial content
    expect(find.text('Auto Body Repair Assistant'), findsOneWidget);
    expect(find.byIcon(Icons.directions_car), findsOneWidget);
    
    // Verify that the app has loaded project info
    await tester.pump();
    expect(find.text('Toyota Camry - Демо'), findsOneWidget);
  });
}
