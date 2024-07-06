import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:json_annotation/json_annotation.dart';

import '../db/data_table_cell_list_inline_item.dart';
import '../state/db_model_extensions.dart';
import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_reorder_class_field.g.dart';

@JsonSerializable()
class DbCmdReorderClassField extends BaseDbCmd {
  late String entityId;
  late int fieldIndex;
  late int indexDelta;

  DbCmdReorderClassField.values({
    String? id,
    required this.entityId,
    required this.fieldIndex,
    required this.indexDelta,
  }) : super.withId(id) {
    $type = DbCmdType.reorderClassField;
  }

  DbCmdReorderClassField();

  factory DbCmdReorderClassField.fromJson(Map<String, dynamic> json) => _$DbCmdReorderClassFieldFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdReorderClassFieldToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId)! as ClassMetaEntity;
    final field = entity.fields[fieldIndex];

    entity.fields.removeAt(fieldIndex);
    entity.fields.insert(fieldIndex + indexDelta, field);

    final allTables = dbModel.cache.allDataTables;
    for (final table in allTables) {
      if (table.classId.isEmpty) //
        continue;

      final allFields = dbModel.cache.getAllFieldsByClassId(table.classId);
      final indexInTable = allFields?.indexOf(field) ?? -1;

      if (indexInTable > -1) //
      {
        for (final row in table.rows) {
          final value = row.values.removeAt(indexInTable);
          row.values.insert(indexInTable + indexDelta, value);
        }
      }
    }

    final fieldsUsingInline = DbModelUtils.getFieldsUsingInlineClass(dbModel, entity);
    for (var fieldUsingInline in fieldsUsingInline) {
      for (var table in dbModel.cache.allDataTables) {
        final fields = dbModel.cache.getAllFieldsByClassId(table.classId)!;
        final columnIndex = fields.indexOf(fieldUsingInline.$2);
        if (columnIndex <= -1) //
          continue;

        final listInlineField = fields[columnIndex];
        final inlineColumns = DbModelUtils.getListInlineColumns(dbModel, listInlineField.valueTypeInfo!);
        final inlineColumnIndexFrom = inlineColumns!.indexOf(field);

        if (table.columnInnerCellFlex.containsKey(listInlineField.id)) {
          final flexes = table.columnInnerCellFlex[listInlineField.id]!;
          final flex = flexes.removeAt(inlineColumnIndexFrom);
          flexes.insert(inlineColumnIndexFrom + indexDelta, flex);
        }

        for (var i = 0; i < table.rows.length; i++) {
          final row = table.rows[i];
          final cellValues = row.values[columnIndex].listCellValues!;

          for (var j = 0; j < cellValues.length; j++) {
            final cellValue = cellValues[j];
            final innerValues = (cellValue as DataTableCellListInlineItem).values!;
            final innerValue = innerValues.removeAt(inlineColumnIndexFrom);
            innerValues.insert(inlineColumnIndexFrom + indexDelta, innerValue);
          }
        }
      }
    }

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId);
    if (entity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (entity is! ClassMetaEntity) //
      return DbCmdResult.fail('Entity with id "$entityId" is not a class');

    if (indexDelta == 0) //
      return DbCmdResult.fail('indexDelta "$indexDelta" is invalid');

    if (fieldIndex < 0 || fieldIndex >= entity.fields.length) //
      return DbCmdResult.fail('Incorrect indexFrom "$fieldIndex"');

    if (fieldIndex + indexDelta < 0 || fieldIndex + indexDelta > entity.fields.length) //
      return DbCmdResult.fail('Incorrect (fieldIndex + indexDelta) "${(fieldIndex + indexDelta)}"');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdReorderClassField.values(
      entityId: entityId,
      fieldIndex: fieldIndex + indexDelta,
      indexDelta: -indexDelta,
    );
  }
}
