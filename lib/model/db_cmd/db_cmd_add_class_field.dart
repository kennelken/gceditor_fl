import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_delete_class_field.dart';
import 'db_cmd_result.dart';

part 'db_cmd_add_class_field.g.dart';

@JsonSerializable()
class DbCmdAddClassField extends BaseDbCmd {
  late String entityId;
  late int index;
  late ClassMetaFieldDescription field;

  Map<String, DataTableColumn>? dataColumnsByTable;

  DbCmdAddClassField.values({
    String? id,
    required this.entityId,
    required this.index,
    required this.field,
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
          DbModelUtils.applyDataColumns(dbModel, table, [dataColumnsByTable![table.id]!]);
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

    if (dataColumnsByTable != null) {
      for (var tableId in dataColumnsByTable!.keys) {
        final table = dbModel.cache.getTable(tableId);
        if (table == null) //
          return DbCmdResult.fail('Entity with id "$tableId" does not exist');

        if (table is! TableMetaEntity) //
          return DbCmdResult.fail('Entity with id "$tableId" is not a table');

        if (table.rows.length != dataColumnsByTable![tableId]!.values.length) //
          return DbCmdResult.fail('invalid rows count for table "$tableId"');
      }
    }

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
