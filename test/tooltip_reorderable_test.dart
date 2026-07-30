import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';

void main() {
  testWidgets('TooltipWrapper inside ReorderableListView does not crash during drag/reorder', (WidgetTester tester) async {
    final items = List.generate(5, (index) => 'Item $index');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ReorderableListView.builder(
                itemCount: items.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = items.removeAt(oldIndex);
                    items.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  return TooltipWrapper(
                    key: ValueKey(items[index]),
                    message: 'Tooltip for ${items[index]}',
                    child: ListTile(
                      key: ValueKey('listtile_${items[index]}'),
                      title: Text(items[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    // Hover over the first item to show tooltip
    final firstItemFinder = find.text('Item 0');
    final mouseGesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouseGesture.addPointer(location: Offset.zero);
    await mouseGesture.moveTo(tester.getCenter(firstItemFinder));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Tooltip is scheduled/shown

    // Start dragging Item 0
    final dragGesture = await tester.startGesture(tester.getCenter(firstItemFinder), kind: PointerDeviceKind.mouse);
    await tester.pump(); // Pointer down hides tooltip
    await tester.pump(const Duration(milliseconds: 500)); // Drag start

    // Move across items
    await dragGesture.moveBy(const Offset(0, 150));
    await tester.pump();
    await dragGesture.moveBy(const Offset(0, 50));
    await tester.pump();
    await dragGesture.up();
    await tester.pumpAndSettle();
  });
}
