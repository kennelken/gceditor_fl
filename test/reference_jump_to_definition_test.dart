import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gceditor/components/properties/primitives/clickable_reference_text.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Jump to Definition Navigation Tests', () {
    late DbModel dbModel;
    late TableMetaEntity table;
    late DataTableRow row1;
    late DataTableRow row2;
    late ClassMetaEntity classEntity;
    late ClassMetaEntityEnum enumEntity;
    late EnumValue enumValue1;

    setUp(() {
      dbModel = DbModel();

      classEntity = ClassMetaEntity()
        ..id = 'ItemClass'
        ..fields = [
          ClassMetaFieldDescription()
            ..id = 'name'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.string),
        ];

      enumEntity = ClassMetaEntityEnum()..id = 'FruitEnum';
      enumValue1 = EnumValue()..id = 'Apple';
      enumEntity.values.add(enumValue1);

      table = TableMetaEntity()
        ..id = 'ItemsTable'
        ..classId = 'ItemClass';

      row1 = DataTableRow()
        ..id = 'item_01'
        ..values = [DataTableCellValue.simple('Sword')];

      row2 = DataTableRow()
        ..id = 'item_02'
        ..values = [DataTableCellValue.simple('Shield')];

      table.rows.addAll([row1, row2]);

      dbModel.classes.addAll([classEntity, enumEntity]);
      dbModel.tables.add(table);
      dbModel.cache.invalidate();

      // Set global clientModel for navigation service testing
      providerContainer.read(clientStateProvider).state.model = dbModel;
    });

    test('canJumpToDefinition correctly identifies valid definitions', () {
      final navService = ClientNavigationServiceStateNotifier(ClientNavigationService());

      // DataTableRow
      expect(navService.canJumpToDefinition(dbModel, row1), isTrue);
      expect(navService.canJumpToDefinition(dbModel, null, valueId: 'item_01'), isTrue);
      expect(navService.canJumpToDefinition(dbModel, null, valueId: 'non_existent'), isFalse);

      // EnumValue
      expect(navService.canJumpToDefinition(dbModel, enumValue1, classEntity: enumEntity), isTrue);
      expect(navService.canJumpToDefinition(dbModel, null, classEntity: enumEntity, valueId: 'Apple'), isTrue);

      // Class & Table
      expect(navService.canJumpToDefinition(dbModel, classEntity), isTrue);
      expect(navService.canJumpToDefinition(dbModel, table), isTrue);
    });

    test('jumpToDefinition sets navigationData correctly for table rows', () {
      final navService = ClientNavigationServiceStateNotifier(ClientNavigationService());

      final success = navService.jumpToDefinition(dbModel, row2);
      expect(success, isTrue);
      expect(navService.state.navigationData, isNotNull);
      expect(navService.state.navigationData!.tableId, 'ItemsTable');
      expect(navService.state.navigationData!.rowIndex, 1);
    });

    test('jumpToDefinition sets navigationData correctly for enum values', () {
      final navService = ClientNavigationServiceStateNotifier(ClientNavigationService());

      final success = navService.jumpToDefinition(dbModel, enumValue1, classEntity: enumEntity);
      expect(success, isTrue);
      expect(navService.state.navigationData, isNotNull);
      expect(navService.state.navigationData!.classId, 'FruitEnum');
      expect(navService.state.navigationData!.enumValueId, 'Apple');
    });

    test('navigationData clears automatically after highlight duration', () async {
      final navService = ClientNavigationServiceStateNotifier(ClientNavigationService());

      navService.jumpToDefinition(dbModel, row1);
      expect(navService.state.navigationData, isNotNull);

      // Fast forward past the 500ms flash timer
      await Future.delayed(const Duration(milliseconds: 600));
      expect(navService.state.navigationData, isNull);
    });
  });

  group('ClickableReferenceText Widget Tests', () {
    testWidgets('shows underline when hovered and Ctrl is pressed', (WidgetTester tester) async {
      bool jumped = false;

      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ClickableReferenceText(
                  text: 'ReferenceItem',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  canJump: true,
                  onJumpToDefinition: () {
                    jumped = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final textFinder = find.text('ReferenceItem');
      expect(textFinder, findsOneWidget);

      // Initially no underline
      Text textWidget = tester.widget(textFinder);
      expect(textWidget.style?.decoration, equals(TextDecoration.none));

      // Simulate mouse hover over text
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(textFinder));
      await tester.pump();

      // Hovered without Ctrl -> still no underline
      textWidget = tester.widget(textFinder);
      expect(textWidget.style?.decoration, equals(TextDecoration.none));

      // Press Ctrl key
      container.read(clientViewModeStateProvider).setControlKey(true);
      await tester.pump();

      // Hovered WITH Ctrl -> underline shown!
      textWidget = tester.widget(textFinder);
      expect(textWidget.style?.decoration, equals(TextDecoration.underline));

      // Release Ctrl key -> underline removed
      container.read(clientViewModeStateProvider).setControlKey(false);
      await tester.pump();

      textWidget = tester.widget(textFinder);
      expect(textWidget.style?.decoration, equals(TextDecoration.none));

      await gesture.removePointer();
    });
  });
}
