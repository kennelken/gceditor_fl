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
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:gceditor/components/tree/base_tree_view.dart';
import 'package:gceditor/model/db/class_meta_group.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
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
}
