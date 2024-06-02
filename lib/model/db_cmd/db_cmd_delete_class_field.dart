import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

import '../db/data_table_cell_multivalue_item.dart';
import 'base_db_cmd.dart';
import 'db_cmd_add_class_field.dart';
import 'db_cmd_result.dart';

part 'db_cmd_delete_class_field.g.dart';

@JsonSerializable()
class DbCmdDeleteClassField extends BaseDbCmd {
  late String entityId;
  late String fieldId;

  DbCmdDeleteClassField.values({
    String? id,
    required this.entityId,
    required this.fieldId,
  }) : super.withId(id) {
    $type = DbCmdType.deleteClassField;
  }

  DbCmdDeleteClassField();

  factory DbCmdDeleteClassField.fromJson(Map<String, dynamic> json) => _$DbCmdDeleteClassFieldFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdDeleteClassFieldToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId)! as ClassMetaEntity;
    final index = entity.fields.indexWhere((e) => e.id == fieldId);
    final field = entity.fields[index];

    final fieldsUsingInline = DbModelUtils.getFieldsUsingInlineClass(dbModel, entity);
    for (var fieldUsingInline in fieldsUsingInline) {
      for (var table in dbModel.cache.allDataTables) {
        final fields = dbModel.cache.getAllFieldsByClassId(table.classId)!;
        final columnIndex = fields.indexOf(fieldUsingInline.$2);
        if (columnIndex <= -1) //
          continue;

        final listInlineField = fields[columnIndex];
        final inlineColumns = DbModelUtils.getListMultiColumns(dbModel, listInlineField.valueTypeInfo!);
        final inlineColumnIndex = inlineColumns!.indexOf(field);

        if (table.columnInnerCellFlex.containsKey(listInlineField.id)) {
          final flexes = table.columnInnerCellFlex[listInlineField.id]!;
          flexes.removeAt(inlineColumnIndex);
          flexes.normalize();
        }

        for (var i = 0; i < table.rows.length; i++) {
          final row = table.rows[i];
          for (var cellValue in row.values[columnIndex].listCellValues!) {
            (cellValue as DataTableCellMultiValueItem).values!.removeAt(inlineColumnIndex);
          }
        }
      }
    }

    entity.fields.removeAt(index);

    for (final table in dbModel.cache.allDataTables) {
      final allFields = dbModel.cache.getAllFieldsByClassId(table.classId);
      final index = allFields?.indexOf(field) ?? -1;
      if (index > -1) {
        DbModelUtils.deleteRowValuesAtColumn(table, index);
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
      return DbCmdResult.fail('Entity with id "$entityId" is not enum');

    if (!entity.fields.any((element) => element.id == fieldId)) return DbCmdResult.fail('Field "$fieldId" was not found');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId) as ClassMetaEntity;
    final field = entity.fields.firstWhere((e) => e.id == fieldId);

    final dataColumnsByTable = <String, List<DataTableColumn>>{};
    for (final table in dbModel.cache.allDataTables) {
      final allFields = dbModel.cache.getAllFieldsByClassId(table.classId);
      if (allFields != null && allFields.contains(field)) {
        dataColumnsByTable[table.id] = DbModelUtils.getDataColumns(dbModel, table, columns: [field]);
      }
    }

    final listInlineValuesByTableColumn = <String, Map<int, List<List<dynamic>>>>{};
    final fieldsUsingInline = DbModelUtils.getFieldsUsingInlineClass(dbModel, entity);
    for (var fieldUsingInline in fieldsUsingInline) {
      for (var table in dbModel.cache.allDataTables) {
        final fields = dbModel.cache.getAllFieldsByClassId(table.classId)!;
        final columnIndex = fields.indexOf(fieldUsingInline.$2);
        if (columnIndex <= -1) //
          continue;

        final listInlineField = fields[columnIndex];
        final inlineColumns = DbModelUtils.getListMultiColumns(dbModel, listInlineField.valueTypeInfo!);
        final inlineColumnIndex = inlineColumns!.indexOf(field);

        listInlineValuesByTableColumn.addIfMissing(table.id, (_) => {});
        listInlineValuesByTableColumn[table.id]!.addIfMissing(inlineColumnIndex, (_) => []);

        for (var i = 0; i < table.rows.length; i++) {
          final row = table.rows[i];
          final cellValues = row.values[columnIndex].listCellValues!;

          listInlineValuesByTableColumn[table.id]![inlineColumnIndex]!.add([]);
          for (var j = 0; j < cellValues.length; j++) {
            final cellValue = cellValues[j];

            listInlineValuesByTableColumn[table.id]![inlineColumnIndex]![i]
                .add((cellValue as DataTableCellMultiValueItem).values![inlineColumnIndex]);
          }
        }
      }
    }

    return DbCmdAddClassField.values(
      entityId: entityId,
      index: entity.fields.indexWhere((e) => e.id == fieldId),
      field: ClassMetaFieldDescription.fromJson(field.toJson().clone()),
      dataColumnsByTable: dataColumnsByTable,
      listInlineValuesByTableColumn: listInlineValuesByTableColumn,
    );
  }
}
