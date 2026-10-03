import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db/table_meta_group.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:gceditor/components/tree/base_tree_view.dart';
import 'package:gceditor/model/db/class_meta_group.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/components/table/context_menu_button.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_list_inline_view.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_text_view.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_view.dart';
import 'package:gceditor/components/table/primitives/data_table_row_id_view.dart';
import 'package:gceditor/main.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';

void main() {
  test('rowToJson serializes row data correctly', () {
    final dbModel = DbModel();

    final classEntity = ClassMetaEntity()
      ..id = 'Player'
      ..fields = [
        ClassMetaFieldDescription()
          ..id = 'name'
          ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.string),
        ClassMetaFieldDescription()
          ..id = 'hp'
          ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.int),
        ClassMetaFieldDescription()
          ..id = 'created'
          ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.date),
      ];

    final table = TableMetaEntity()
      ..id = 'players'
      ..classId = 'Player';

    final row = DataTableRow()
      ..id = 'p1'
      ..values = [
        DataTableCellValue.simple('Alice'),
        DataTableCellValue.simple(100),
        DataTableCellValue.simple('2026.07.10 21:20'),
      ];

    table.rows.add(row);
    dbModel.classes.add(classEntity);
    dbModel.tables.add(table);
    dbModel.cache.invalidate();

    final jsonMap = DbModelUtils.rowToJson(dbModel, table, row);

    expect(jsonMap['id'], 'p1');
    expect(jsonMap['name'], 'Alice');
    expect(jsonMap['hp'], 100);
    // 2026.07.10 21:20:00 date is parsed to milliseconds since epoch
    final parsedDate = DbModelUtils.parseDate('2026.07.10 21:20');
    expect(jsonMap['created'], parsedDate?.millisecondsSinceEpoch);
  });

  test('tree view preserves folder expansion state when model is reinitialized', () {
    final controller = getTreeController();

    final group1 = ClassMetaGroup()..id = 'group1';
    final group2 = ClassMetaGroup()..id = 'group2';
    final initialRoots = <IIdentifiable>[group1, group2];

    void updateTreeRoots(TreeController<IIdentifiable> treeController, List<IIdentifiable> newRoots) {
      final hadChildrenBefore = treeController.roots.isNotEmpty;

      final Map<String, bool> expansionStates = {};
      void saveExpansionStates(Iterable<IIdentifiable> nodes) {
        for (final node in nodes) {
          if (node.id.isNotEmpty) {
            expansionStates[node.id] = treeController.getExpansionState(node);
          }
          final group = node.safeAs<IMetaGroup>();
          if (group != null) {
            saveExpansionStates(group.entries.cast<IIdentifiable>());
          }
        }
      }

      saveExpansionStates(treeController.roots);

      treeController.roots = List.of(newRoots);

      if (!hadChildrenBefore) {
        void expandAllNodes(Iterable<IIdentifiable> nodes) {
          for (final node in nodes) {
            treeController.setExpansionState(node, true);
            final group = node.safeAs<IMetaGroup>();
            if (group != null) {
              expandAllNodes(group.entries.cast<IIdentifiable>());
            }
          }
        }

        expandAllNodes(newRoots);
      } else {
        void restoreExpansionStates(Iterable<IIdentifiable> nodes) {
          for (final node in nodes) {
            if (expansionStates.containsKey(node.id)) {
              treeController.setExpansionState(node, expansionStates[node.id]!);
            } else {
              treeController.setExpansionState(node, true);
            }
            final group = node.safeAs<IMetaGroup>();
            if (group != null) {
              restoreExpansionStates(group.entries.cast<IIdentifiable>());
            }
          }
        }

        restoreExpansionStates(newRoots);
      }

      treeController.rebuild();
    }

    // Initial setup
    updateTreeRoots(controller, initialRoots);
    expect(controller.getExpansionState(group1), isTrue);
    expect(controller.getExpansionState(group2), isTrue);

    // User collapses group2
    controller.collapse(group2);
    expect(controller.getExpansionState(group1), isTrue);
    expect(controller.getExpansionState(group2), isFalse);

    // Subsequent build frame with same roots reference does NOT alter toggledNodes
    updateTreeRoots(controller, initialRoots);
    expect(controller.getExpansionState(group1), isTrue);
    expect(controller.getExpansionState(group2), isFalse);

    // Reinitialize model: new instances with same IDs
    final reinitGroup1 = ClassMetaGroup()..id = 'group1';
    final reinitGroup2 = ClassMetaGroup()..id = 'group2';
    final reinitRoots = <IIdentifiable>[reinitGroup1, reinitGroup2];

    updateTreeRoots(controller, reinitRoots);

    expect(controller.getExpansionState(reinitGroup1), isTrue);
    expect(controller.getExpansionState(reinitGroup2), isFalse);
  });

  test('tree controller updates roots when items are added or removed from same list instance', () {
    final controller = getTreeController();
    final modelRoots = <IIdentifiable>[];

    void updateTreeRoots(TreeController<IIdentifiable> treeController, List<IIdentifiable> newRoots) {
      final hadChildrenBefore = treeController.roots.isNotEmpty;
      final expandedIds = treeController.toggledNodes.map((e) => e.id).where((id) => id.isNotEmpty).toSet();

      treeController.roots = List.of(newRoots);
      treeController.toggledNodes.clear();

      if (!hadChildrenBefore) {
        void expandAllNodes(Iterable<IIdentifiable> nodes) {
          for (final node in nodes) {
            treeController.setExpansionState(node, true);
            final group = node.safeAs<IMetaGroup>();
            if (group != null) {
              expandAllNodes(group.entries.cast<IIdentifiable>());
            }
          }
        }

        expandAllNodes(newRoots);
      } else {
        void restoreExpanded(Iterable<IIdentifiable> nodes) {
          for (final node in nodes) {
            if (expandedIds.contains(node.id)) {
              treeController.setExpansionState(node, true);
            }
            final group = node.safeAs<IMetaGroup>();
            if (group != null) {
              restoreExpanded(group.entries.cast<IIdentifiable>());
            }
          }
        }

        restoreExpanded(newRoots);
      }
    }

    final table1 = TableMetaEntity()..id = 'table1';
    modelRoots.add(table1);

    updateTreeRoots(controller, modelRoots);
    expect(controller.roots.length, 1);
    expect(controller.roots.first.id, 'table1');

    // Add table2 to the same modelRoots list instance
    final table2 = TableMetaEntity()..id = 'table2';
    modelRoots.add(table2);

    updateTreeRoots(controller, modelRoots);
    expect(controller.roots.length, 2);
    expect(controller.roots.last.id, 'table2');

    // Delete table1 from the modelRoots list
    modelRoots.remove(table1);

    updateTreeRoots(controller, modelRoots);
    expect(controller.roots.length, 1);
    expect(controller.roots.first.id, 'table2');
  });

  testWidgets('BaseTreeView preserves scroll position across clientState version updates', (WidgetTester tester) async {
    final controller = getTreeController();
    final items = List.generate(50, (index) => TableMetaEntity()..id = 'table_$index');

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final clientNotifier = container.read(clientStateProvider);
    clientNotifier.setModel(DbModel());
    clientNotifier.state.model.tables.addAll(items);
    clientNotifier.state.isInitialized = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: BaseTreeView(
                treeController: controller,
                data: () => items,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scrollableState = tester.state<ScrollableState>(find.byType(Scrollable));
    scrollableState.position.jumpTo(150.0);
    await tester.pumpAndSettle();

    expect(scrollableState.position.pixels, 150.0);

    // Increment version (simulating generators run / Ctrl+R or command execution)
    clientNotifier.incrementVersion();
    await tester.pumpAndSettle();

    // Verify scroll position is still 150.0 and has not reset to 0.0
    expect(scrollableState.position.pixels, 150.0);
  });

  testWidgets('BaseTreeView updates hierarchy when a class definition is moved inside a folder', (WidgetTester tester) async {
    final controller = getTreeController();
    final group = ClassMetaGroup()..id = 'Folder1';
    final class1 = ClassMetaEntity()..id = 'Class1';
    final class2 = ClassMetaEntity()..id = 'Class2';
    group.entries.addAll([class1, class2]);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final clientNotifier = container.read(clientStateProvider);
    clientNotifier.setModel(DbModel());
    clientNotifier.state.model.classes.add(group);
    clientNotifier.state.isInitialized = true;
    clientNotifier.state.model.cache.invalidate();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: BaseTreeView(
                treeController: controller,
                data: () => clientNotifier.state.model.classes,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial order: Folder1 -> Class1 -> Class2
    final textsBefore = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).where((t) => t != null && t.isNotEmpty && !t.startsWith('(')).toList();
    expect(textsBefore, containsAllInOrder(['Folder1', 'Class1', 'Class2']));

    // Move Class2 before Class1 inside Folder1
    group.entries.clear();
    group.entries.addAll([class2, class1]);
    clientNotifier.state.model.cache.invalidate();
    clientNotifier.incrementVersion();

    await tester.pumpAndSettle();

    // Verify updated order: Folder1 -> Class2 -> Class1
    final textsAfter = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).where((t) => t != null && t.isNotEmpty && !t.startsWith('(')).toList();
    expect(textsAfter, containsAllInOrder(['Folder1', 'Class2', 'Class1']));
  });

  testWidgets('BaseTreeView updates hierarchy when a table is moved between folders', (WidgetTester tester) async {
    final controller = getTreeController();
    final group1 = TableMetaGroup()..id = 'FolderA';
    final group2 = TableMetaGroup()..id = 'FolderB';
    final table1 = TableMetaEntity()..id = 'Table1';
    final table2 = TableMetaEntity()..id = 'Table2';
    group1.entries.add(table1);
    group2.entries.add(table2);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final clientNotifier = container.read(clientStateProvider);
    clientNotifier.setModel(DbModel());
    clientNotifier.state.model.tables.addAll([group1, group2]);
    clientNotifier.state.isInitialized = true;
    clientNotifier.state.model.cache.invalidate();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: BaseTreeView(
                treeController: controller,
                data: () => clientNotifier.state.model.tables,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Move Table1 from FolderA to FolderB
    group1.entries.remove(table1);
    group2.entries.insert(0, table1);
    clientNotifier.state.model.cache.invalidate();
    clientNotifier.incrementVersion();

    await tester.pumpAndSettle();

    // Verify updated order: FolderA -> FolderB -> Table1 -> Table2
    final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).where((t) => t != null && t.isNotEmpty && !t.startsWith('(')).toList();
    expect(texts, containsAllInOrder(['FolderA', 'FolderB', 'Table1', 'Table2']));
  });

  testWidgets('DataTableCellListInlineView sets field default values for newly added inline items', (tester) async {
    final dbModel = DbModel();
    final inlineClass = ClassMetaEntity()
      ..id = 'InlineItem'
      ..fields = [
        ClassMetaFieldDescription()
          ..id = 'count'
          ..defaultValue = '42'
          ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.int),
        ClassMetaFieldDescription()
          ..id = 'name'
          ..defaultValue = 'default_name'
          ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.string),
      ];

    final mainClass = ClassMetaEntity()
      ..id = 'MainClass'
      ..fields = [
        ClassMetaFieldDescription()
          ..id = 'items'
          ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.listInline)
          ..valueTypeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.reference, classId: 'InlineItem'),
      ];

    final table = TableMetaEntity()
      ..id = 'mainTable'
      ..classId = 'MainClass';

    final row = DataTableRow()
      ..id = 'r1'
      ..values = [
        DataTableCellValue.listInline([]),
      ];
    table.rows.add(row);

    dbModel.classes.addAll([inlineClass, mainClass]);
    dbModel.tables.add(table);
    dbModel.cache.invalidate();

    providerContainer.read(clientStateProvider).setModel(dbModel);

    DataTableCellValue? updatedValue;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providerContainer,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: DataTableCellListInlineView(
              coordinates: DataTableValueCoordinates(table: table, field: mainClass.fields[0], rowIndex: 0),
              fieldType: mainClass.fields[0].typeInfo,
              valueFieldType: mainClass.fields[0].valueTypeInfo!,
              value: row.values[0],
              cellFactory: ({
                Key? key,
                required DataTableValueCoordinates coordinates,
                required ClassFieldDescriptionDataInfo fieldInfo,
                required dynamic value,
                dynamic defaultValue,
                required ValueChanged<dynamic> onValueChanged,
              }) => const SizedBox(),
              onValueChanged: (val) {
                updatedValue = val;
              },
            ),
          ),
        ),
      ),
    );

    // Tap the plus icon button to add an inline item
    await tester.tap(find.byType(IconPlus));
    await tester.pumpAndSettle();

    expect(updatedValue, isNotNull);
    final inlineItems = updatedValue!.listInlineCellValues()!;
    expect(inlineItems.length, 1);
    expect(inlineItems[0].values, [42, 'default_name']);
  });

  test('DbModelUtils.selectAll selects entire text', () {
    final controller = TextEditingController(text: 'hello world');
    expect(controller.selection, const TextSelection.collapsed(offset: -1));

    DbModelUtils.selectAll(controller);
    expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 11));
  });

  testWidgets('selecting field inside cell selects current textual value', (tester) async {
    final dbModel = DbModel();
    final classEntity = ClassMetaEntity()
      ..id = 'Item'
      ..fields = [
        ClassMetaFieldDescription()
          ..id = 'title'
          ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.string),
      ];
    final table = TableMetaEntity()
      ..id = 'items'
      ..classId = 'Item';
    final row = DataTableRow()
      ..id = 'row_01'
      ..values = [DataTableCellValue.simple('My Title')];
    table.rows.add(row);
    dbModel.classes.add(classEntity);
    dbModel.tables.add(table);
    dbModel.cache.invalidate();
    providerContainer.read(clientStateProvider).setModel(dbModel);

    // Test DataTableCellTextView
    dynamic changedVal;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providerContainer,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: DataTableCellTextView(
              coordinates: DataTableValueCoordinates(table: table, field: classEntity.fields[0], rowIndex: 0),
              fieldType: classEntity.fields[0].typeInfo,
              value: 'My Title',
              defaultValue: '',
              onValueChanged: (v) => changedVal = v,
            ),
          ),
        ),
      ),
    );

    final cellTextFieldFinder = find.byType(TextField);
    final TextField cellTextField = tester.widget(cellTextFieldFinder);
    expect(cellTextField.controller!.selection, const TextSelection.collapsed(offset: -1));

    // Tap to select field
    await tester.tap(cellTextFieldFinder);
    await tester.pumpAndSettle();

    expect(cellTextField.controller!.selection, const TextSelection(baseOffset: 0, extentOffset: 8));

    // Test DataTableRowIdView
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providerContainer,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 50,
                child: DataTableRowIdView(
                  table: table,
                  row: row,
                  index: 0,
                  isPinnedItem: false,
                  coordinates: DataTableValueCoordinates(table: table, field: null, rowIndex: 0),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final idTextFieldFinder = find.byType(TextField);
    final TextField idTextField = tester.widget(idTextFieldFinder);

    await tester.tap(idTextFieldFinder);
    await tester.pumpAndSettle();

    expect(idTextField.controller!.selection, const TextSelection(baseOffset: 0, extentOffset: 6));
  });

  testWidgets('DataTableRowIdView container width is fixed and child AnimatedContainer does not animate width', (tester) async {
    final dbModel = DbModel();
    final classEntity = ClassMetaEntity()
      ..id = 'Item'
      ..fields = [];
    final table = TableMetaEntity()
      ..id = 'items'
      ..classId = 'Item';
    table.idsColumnWidth = 150;
    final row = DataTableRow()..id = 'row_01';
    table.rows.add(row);
    dbModel.classes.add(classEntity);
    dbModel.tables.add(table);
    dbModel.cache.invalidate();
    providerContainer.read(clientStateProvider).setModel(dbModel);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providerContainer,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 50,
                child: DataTableRowIdView(
                  table: table,
                  row: row,
                  index: 0,
                  isPinnedItem: false,
                  coordinates: DataTableValueCoordinates(table: table, field: null, rowIndex: 0),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final outerContainer = tester.widget<Container>(find.descendant(of: find.byType(DataTableRowIdView), matching: find.byType(Container)).first);
    expect(outerContainer.constraints?.minWidth, 150.0 * kScale);
    expect(outerContainer.constraints?.maxWidth, 150.0 * kScale);

    final animatedContainer = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(animatedContainer.constraints, isNull);
  });

  test('text selection color is set to dark/less bright selection color for readability', () {
    providerContainer.read(styleStateProvider).init();
    expect(kStyle.kAppTheme.textSelectionTheme.selectionColor, kColorTextSelection);
    expect(kStyle.kAppTheme.textSelectionTheme.selectionColor, isNot(kColorPrimaryLight));
    expect(kStyle.kInputThemeLight.textSelectionTheme.selectionColor, kColorTextSelection);
  });
}
