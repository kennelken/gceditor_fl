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
      if (treeController.roots != newRoots) {
        final hadChildrenBefore = treeController.roots.isNotEmpty;
        final expandedIds = treeController.toggledNodes.map((e) => e.id).where((id) => id.isNotEmpty).toSet();

        treeController.roots = newRoots;
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
}
