import 'package:collection/collection.dart';
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

    if (editParentClassId == true || classType == ClassType.interface) {
      final allTablesUsingClass = DbModelUtils.getAllTablesUsingClass(dbModel, entity);
      for (final table in allTablesUsingClass) {
        dataColumnsByTable[table.id] = DbModelUtils.getDataColumns(dbModel, table, prioritizedValues: dataColumnsByTable[table.id]);
      }

      entity.parent = parentClassId;
      if (classType == ClassType.interface) {
        entity.parent = null;
      }

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

    if (classType != null) {
      entity.classType = classType!;
    }

    for (final kvp in dataColumnsByTable.entries) {
      final table = dbModel.cache.getTable(kvp.key) as TableMetaEntity;
      DbModelUtils.applyDataColumns(dbModel, table, kvp.value);
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

    if (classType != null) {
      if (classType == ClassType.valueType) {
        if (entity.parent != null) //
          return DbCmdResult.fail('"${describeEnum(classType!)}" type can not have a parent class');

        final allSubclasses = dbModel.cache.getImplementingClasses(entity);
        if (allSubclasses.isNotEmpty) //
          return DbCmdResult.fail('"${describeEnum(classType!)}" type can not have subclasses');

        if (entity.interfaces.isNotEmpty) //
          return DbCmdResult.fail('"${describeEnum(classType!)}" type can\'t be set while the entity has interfaces');
      }

      if (classType == ClassType.interface) {
        final firstChildClass = dbModel.cache.allClasses.firstWhereOrNull((c) => c.parent == entity.id);
        if (firstChildClass != null) //
          return DbCmdResult.fail(
              'Can\'t change the classType to "${describeEnum(classType!)}" because it is used as parent in "${firstChildClass.id}"');

        final firstChildTable = dbModel.cache.allDataTables.firstWhereOrNull((c) => c.classId == entity.id);
        if (firstChildTable != null) //
          return DbCmdResult.fail(
              'Can\'t change the classType to "${describeEnum(classType!)}" because it is used as parent in "${firstChildTable.id}"');
      }

      if (classType != ClassType.interface) {
        final firstParentClass = dbModel.cache.allClasses.firstWhereOrNull((c) => c.interfaces.any((element) => element == entity.id));
        if (firstParentClass != null) //
          return DbCmdResult.fail(
              'Can\'t change the classType to "${describeEnum(classType!)}" because it is used as an interface in "${firstParentClass.id}"');
      }
    }
    if (editParentClassId == true) {
      if (parentClassId != null) {
        final newParentEntity = dbModel.cache.getClass(parentClassId);

        if (entity.classType == ClassType.interface) //
          return DbCmdResult.fail('Can\'t set a parent class of an interface');

        if (newParentEntity == null) //
          return DbCmdResult.fail('Entity with id "$parentClassId" does not exist');

        if (newParentEntity is! ClassMetaEntity) //
          return DbCmdResult.fail('Entity with id "$parentClassId" is not a class');

        if (newParentEntity.classType == ClassType.interface) //
          return DbCmdResult.fail('Can\'t set an interface "$parentClassId" as a parent class');

        if (dbModel.cache.getImplementingClasses(entity).contains(newParentEntity))
          return DbCmdResult.fail('Specified parent "$parentClassId" is incorrect because it is a child of entity "$entityId"');

        final parentFields = dbModel.cache.getAllFields(newParentEntity);
        for (var subclass in [entity, ...dbModel.cache.getImplementingClasses(entity)]) {
          for (var field in subclass.fields) {
            if (parentFields.any((f) => f.id == field.id))
              return DbCmdResult.fail('Specified parent "$parentClassId" already contains field "${field.id}" of "${subclass.id}"');
          }
        }

        if (newParentEntity.classType != ClassType.referenceType) //
          return DbCmdResult.fail('Inheritance is not supported for class type "${describeEnum(newParentEntity.classType)}"');
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
