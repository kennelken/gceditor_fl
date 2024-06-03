import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

import '../db/data_table_cell_multivalue_item.dart';
import '../db_network/data_table_column_inline_values.dart';
import 'base_db_cmd.dart';
import 'db_cmd_delete_class_field.dart';
import 'db_cmd_result.dart';

part 'db_cmd_add_class_field.g.dart';

@JsonSerializable()
class DbCmdAddClassField extends BaseDbCmd {
  late String entityId;
  late int index;
  late ClassMetaFieldDescription field;
  late Map<String, List<DataTableColumnInlineValues>>? listInlineValuesByTableColumn;

  Map<String, List<DataTableColumn>>? dataColumnsByTable;

  DbCmdAddClassField.values({
    String? id,
    required this.entityId,
    required this.index,
    required this.field,
    this.listInlineValuesByTableColumn,
    this.dataColumnsByTable,
  }) : super.withId(id) {
    $type = DbCmdType.addClassField;
  }

  DbCmdAddClassField();

  factory DbCmdAddClassField.fromJson(Map<String, dynamic> json) => _$DbCmdAddClassFieldFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdAddClassFieldToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId)! as ClassMetaEntity;

    entity.fields.insert(index, field);
    dbModel.cache.invalidate();

    final allClasses = [entity, ...dbModel.cache.getImplementingClasses(entity)];
    for (final classEntity in allClasses) {
      final allTables = dbModel.cache.allDataTables.where((e) => e.classId == classEntity.id);
      for (final table in allTables) {
        final allFields = dbModel.cache.getAllFields(classEntity);
        final fieldIndex = allFields.indexOf(field);

        DbModelUtils.insertDefaultValues(dbModel, table, fieldIndex);
        if (dataColumnsByTable?[table.id] != null) {
          DbModelUtils.applyDataColumns(dbModel, table, dataColumnsByTable![table.id]!);
        }
      }

      dbModel.cache.invalidate();

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
            final newColumnFlex = 1.0 / inlineColumns.length;
            final flexes = table.columnInnerCellFlex[listInlineField.id]!;
            flexes.insert(inlineColumnIndex, newColumnFlex);
            flexes.normalize();
          }

          for (var i = 0; i < table.rows.length; i++) {
            final row = table.rows[i];
            final cellValues = row.values[columnIndex].listCellValues!;
            for (var j = 0; j < cellValues.length; j++) {
              final cellValue = cellValues[j];
              final value = DbModelUtils.getInnerCellValue(dbModel, listInlineValuesByTableColumn?[table.id], field.id, i, j) ??
                  dbModel.cache.getDefaultValue(field).simpleValue;
              (cellValue as DataTableCellMultiValueItem).values!.insert(inlineColumnIndex, value);
            }
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

    if (!DbModelUtils.validateId(field.id)) //
      return DbCmdResult.fail('Id "${field.id}" is invalid. Valid format: "${Config.idFormatRegex.pattern}"');

    if (index < 0 || index > entity.fields.length) //
      return DbCmdResult.fail('invalid index "$index"');

    for (final subclass in [entity, ...dbModel.cache.getImplementingClasses(entity)]) {
      final allFields = dbModel.cache.getAllFields(subclass);
      if (allFields.any((e) => e.id == field.id)) //
        return DbCmdResult.fail('Field with id "${field.id}" already exists in class "${subclass.id}"');
    }

    final validateDataColumnsResult = DbModelUtils.validateDataByColumns(dbModel, dataColumnsByTable);
    if (!validateDataColumnsResult.success) //
      return validateDataColumnsResult;

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdDeleteClassField.values(
      entityId: entityId,
      fieldId: field.id,
    );
  }
}
