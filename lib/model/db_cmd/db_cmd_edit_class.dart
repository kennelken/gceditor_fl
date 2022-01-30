import 'package:flutter/foundation.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_edit_class.g.dart';

@JsonSerializable()
class DbCmdEditClass extends BaseDbCmd {
  late final String entityId;
  late final String? parentClassId;
  late final bool? editParentClassId;
  late final ClassType? classType;
  late final bool? exportList;

  Map<String, List<DataTableColumn>>? valuesByTable;

  DbCmdEditClass.values({
    String? id,
    required this.entityId,
    this.parentClassId,
    this.editParentClassId,
    this.valuesByTable,
    this.classType,
    this.exportList,
  }) : super.withId(id) {
    $type = DbCmdType.editClass;
  }

  DbCmdEditClass();

  factory DbCmdEditClass.fromJson(Map<String, dynamic> json) => _$DbCmdEditClassFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdEditClassToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId)! as ClassMetaEntity;

    final dataColumnsByTable = valuesByTable ?? <String, List<DataTableColumn>>{};

    if (editParentClassId == true) {
      final allTablesUsingClass = DbModelUtils.getAllTablesUsingClass(dbModel, entity);
      for (final table in allTablesUsingClass) {
        if (dataColumnsByTable.containsKey(table.id)) //
          continue;

        dataColumnsByTable[table.id] = DbModelUtils.getDataColumns(dbModel, table);
      }

      entity.parent = parentClassId;
      dbModel.cache.invalidate();

      for (final table in allTablesUsingClass) {
        final allFields = dbModel.cache.getAllFields(entity);
        final defaultValues = allFields.map((e) => DbModelUtils.parseDefaultValueByFieldOrDefault(e, e.defaultValue)).toList();

        for (var i = 0; i < table.rows.length; i++) {
          table.rows[i].values.clear();
          table.rows[i].values.addAll(defaultValues);
        }
      }
    }

    for (final kvp in dataColumnsByTable.entries) {
      final table = dbModel.cache.getTable(kvp.key) as TableMetaEntity;
      DbModelUtils.applyDataColumns(dbModel, table, kvp.value);
    }

    if (classType != null) {
      entity.classType = classType!;
    }

    if (exportList != null) {
      entity.exportList = exportList!;
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

    if (editParentClassId == true) {
      if (parentClassId != null) {
        final parentEntity = dbModel.cache.getClass(parentClassId);

        if (parentEntity == null) //
          return DbCmdResult.fail('Entity with id "$parentClassId" does not exist');

        if (parentEntity is! ClassMetaEntity) //
          return DbCmdResult.fail('Entity with id "$parentClassId" is not a class');

        if (dbModel.cache.getSubClasses(entity).contains(parentEntity))
          return DbCmdResult.fail('Specified parent "$parentClassId" is incorrect because it is a child of entity "$entityId"');

        final parentFields = dbModel.cache.getAllFields(parentEntity);
        for (var subclass in [entity, ...dbModel.cache.getSubClasses(entity)]) {
          for (var field in subclass.fields) {
            if (parentFields.any((f) => f.id == field.id))
              return DbCmdResult.fail('Specified parent "$parentClassId" already contains field "${field.id}" of "${subclass.id}"');
          }
        }

        if (parentEntity.classType != ClassType.referenceType) //
          return DbCmdResult.fail('Inheritance is not supported for class type "${describeEnum(parentEntity.classType)}"');
      }
    }

    if (classType != null) {
      if (classType == ClassType.valueType) {
        if (entity.parent != null) //
          return DbCmdResult.fail('"${describeEnum(classType!)}" type can not have a parent class');

        final allSubclasses = dbModel.cache.getSubClasses(entity);
        if (allSubclasses.isNotEmpty) //
          return DbCmdResult.fail('"${describeEnum(classType!)}" type can not have subclasses');
      }
    }

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId) as ClassMetaEntity;

    final dataColumnsByTable = <String, List<DataTableColumn>>{};
    for (final table in DbModelUtils.getAllTablesUsingClass(dbModel, entity)) {
      dataColumnsByTable[table.id] = DbModelUtils.getDataColumns(dbModel, table);
    }

    return DbCmdEditClass.values(
      entityId: entityId,
      editParentClassId: editParentClassId,
      parentClassId: entity.parent,
      valuesByTable: dataColumnsByTable,
      classType: classType != null ? entity.classType : null,
      exportList: exportList != null ? (entity.exportList == true) : null,
    );
  }
}
