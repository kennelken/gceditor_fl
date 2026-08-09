import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';

void main() {
  testWidgets('TooltipWrapper flips vertically when near bottom of screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 100,
                top: 570,
                child: TooltipWrapper(
                  message: 'Bottom Tooltip Test Message',
                  child: SizedBox(
                    width: 50,
                    height: 25,
                    child: Text('Target'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final targetFinder = find.text('Target');
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(targetFinder));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final tooltipTextFinder = find.text('Bottom Tooltip Test Message');
    expect(tooltipTextFinder, findsOneWidget);

    final tooltipRect = tester.getRect(tooltipTextFinder);
    // Should be flipped above target (top < 570)
    expect(tooltipRect.bottom, lessThanOrEqualTo(570.0));
    expect(tooltipRect.top, greaterThanOrEqualTo(8.0));
    expect(tooltipRect.bottom, lessThanOrEqualTo(600.0 - 8.0));
  });

  testWidgets('TooltipWrapper shifts left when near right of screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 720,
                top: 100,
                child: TooltipWrapper(
                  message: 'Right Edge Tooltip Test Message Long Text',
                  child: SizedBox(
                    width: 50,
                    height: 25,
                    child: Text('Right Target'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final targetFinder = find.text('Right Target');
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(targetFinder));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final tooltipTextFinder = find.text('Right Edge Tooltip Test Message Long Text');
    expect(tooltipTextFinder, findsOneWidget);

    final tooltipRect = tester.getRect(tooltipTextFinder);
    expect(tooltipRect.right, lessThanOrEqualTo(800.0 - 8.0));
    expect(tooltipRect.left, greaterThanOrEqualTo(8.0));
  });

  testWidgets('TooltipWrapper flips vertically and shifts left when near bottom right corner', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 740,
                top: 570,
                child: TooltipWrapper(
                  message: 'Corner Tooltip Test Message',
                  child: SizedBox(
                    width: 50,
                    height: 25,
                    child: Text('Corner Target'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final targetFinder = find.text('Corner Target');
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(targetFinder));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final tooltipTextFinder = find.text('Corner Tooltip Test Message');
    expect(tooltipTextFinder, findsOneWidget);

    final tooltipRect = tester.getRect(tooltipTextFinder);
    expect(tooltipRect.bottom, lessThanOrEqualTo(570.0));
    expect(tooltipRect.top, greaterThanOrEqualTo(8.0));
    expect(tooltipRect.right, lessThanOrEqualTo(800.0 - 8.0));
    expect(tooltipRect.left, greaterThanOrEqualTo(8.0));
  });
}
