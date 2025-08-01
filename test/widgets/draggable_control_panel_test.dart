import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abra/features/visualization/widgets/draggable_control_panel.dart';

void main() {
  group('DraggableControlPanel', () {
    late Widget testWidget;

    setUp(() {
      testWidget = const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DraggableControlPanel(
                title: 'Test Panel',
                initialPosition: Offset(100, 100),
                child: Text('Test Content'),
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('displays title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      expect(find.text('Test Panel'), findsOneWidget);
    });

    testWidgets('displays content when not collapsed', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('hides content when collapsed', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      // Find and tap collapse button
      final collapseButton = find.byIcon(Icons.expand_less);
      expect(collapseButton, findsOneWidget);
      
      await tester.tap(collapseButton);
      await tester.pumpAndSettle();
      
      // Content should be hidden
      expect(find.text('Test Content'), findsNothing);
      // Expand button should be visible
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('can be dragged to new position', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      // Find the drag handle area
      final dragHandle = find.byIcon(Icons.drag_indicator);
      expect(dragHandle, findsOneWidget);
      
      // Get initial position
      final initialPosition = tester.getTopLeft(find.byType(AnimatedContainer).first);
      
      // Drag the panel
      await tester.drag(dragHandle, const Offset(50, 50));
      await tester.pumpAndSettle();
      
      // Check new position
      final newPosition = tester.getTopLeft(find.byType(AnimatedContainer).first);
      expect(newPosition, equals(initialPosition + const Offset(50, 50)));
    });

    testWidgets('respects screen boundaries when dragging', (WidgetTester tester) async {
      // Create panel at edge of screen
      const edgeWidget = MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DraggableControlPanel(
                title: 'Test Panel',
                initialPosition: Offset.zero,
                initialWidth: 200,
                child: Text('Test Content'),
              ),
            ],
          ),
        ),
      );
      
      await tester.pumpWidget(edgeWidget);
      
      // Try to drag beyond screen boundaries
      final dragHandle = find.byIcon(Icons.drag_indicator);
      await tester.drag(dragHandle, const Offset(-100, -100));
      await tester.pumpAndSettle();
      
      // Position should be clamped to screen boundaries
      final position = tester.getTopLeft(find.byType(AnimatedContainer).first);
      expect(position.dx, greaterThanOrEqualTo(0));
      expect(position.dy, greaterThanOrEqualTo(0));
    });

    testWidgets('can be resized using resize handle', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      // Find resize handle by its icon
      final resizeHandle = find.byIcon(Icons.zoom_out_map);
      
      expect(resizeHandle, findsOneWidget);
      
      // Get initial size
      final initialSize = tester.getSize(find.byType(AnimatedContainer).first);
      
      // Drag resize handle
      await tester.drag(resizeHandle, const Offset(50, 50));
      await tester.pumpAndSettle();
      
      // Check new size
      final newSize = tester.getSize(find.byType(AnimatedContainer).first);
      expect(newSize.width, greaterThan(initialSize.width));
      expect(newSize.height, greaterThan(initialSize.height));
    });

    testWidgets('respects min/max size constraints', (WidgetTester tester) async {
      const constrainedWidget = MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DraggableControlPanel(
                title: 'Test Panel',
                initialPosition: Offset(100, 100),
                initialWidth: 300,
                initialHeight: 300,
                minWidth: 250,
                maxWidth: 350,
                minHeight: 200,
                maxHeight: 400,
                child: Text('Test Content'),
              ),
            ],
          ),
        ),
      );
      
      await tester.pumpWidget(constrainedWidget);
      
      final resizeHandle = find.byIcon(Icons.zoom_out_map);
      
      // Try to resize beyond max constraints
      await tester.drag(resizeHandle, const Offset(200, 200));
      await tester.pumpAndSettle();
      
      final size = tester.getSize(find.byType(AnimatedContainer).first);
      expect(size.width, lessThanOrEqualTo(350));
      expect(size.height, lessThanOrEqualTo(400));
    });

    testWidgets('panel has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(BorderRadius.circular(12)));
      expect(decoration.border?.top.width, equals(2));
      expect(decoration.boxShadow?.length, equals(1));
    });

    testWidgets('content is scrollable when overflowing', (WidgetTester tester) async {
      final overflowWidget = MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DraggableControlPanel(
                title: 'Test Panel',
                initialPosition: const Offset(100, 100),
                initialHeight: 200,
                child: Column(
                  children: List.generate(
                    20,
                    (index) => Text('Item $index'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      
      await tester.pumpWidget(overflowWidget);
      
      // Check that SingleChildScrollView exists
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      
      // Check that first and some middle items are visible
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 5'), findsOneWidget);
      
      // Due to the container height, some items won't be visible
      // We'll check by trying to scroll to them
      
      // Scroll to bottom
      await tester.dragUntilVisible(
        find.text('Item 19'),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      
      // Now last item should be visible
      expect(find.text('Item 19'), findsOneWidget);
    });
  });
}