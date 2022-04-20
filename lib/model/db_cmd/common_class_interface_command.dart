import 'package:flutter/cupertino.dart';

import '../db/class_meta_entity.dart';
import '../db/db_model.dart';
import '../db/db_model_shared.dart';
import '../db_network/data_table_column.dart';
import '../state/db_model_extensions.dart';
import 'db_cmd_result.dart';

mixin CommonClassInterfaceCommand {
  @protected
  DbCmdResult validateEdit({
    required DbModel dbModel,
    required String entityId,
    required String? interfaceId,
    required int index,
    required Map<String, List<DataTableColumn>>? dataColumnsByTable,
  }) {
    final entity = dbModel.cache.getClass(entityId);
    if (entity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (entity is! ClassMetaEntity) //
      return DbCmdResult.fail('Entity with id "$entityId" is not a class');

    if (interfaceId != null) {
      final interface = dbModel.cache.getClass(interfaceId);

      if (interface == null) //
        return DbCmdResult.fail('Can not find specified entity "$interfaceId"');

      if (interface is! ClassMetaEntity) //
        return DbCmdResult.fail('Specified entity "$interfaceId" is not a class entity');

      if (interface.classType != ClassType.interface) //
        return DbCmdResult.fail('Specified entity "$interfaceId"\'s type is not an interface');

      if (interface == entity) //
        return DbCmdResult.fail('Can\'t specify self as a parent interface "$interfaceId"');

      final subclasses = [entity, ...dbModel.cache.getImplementingClasses(entity)];

      ClassMetaEntity? interfaceToReplace;
      if (index >= 0 && index <= entity.interfaces.length - 1) {
        final currentInterfaceId = entity.interfaces[index];
        interfaceToReplace = dbModel.cache.getClass<ClassMetaEntity>(currentInterfaceId);
      }

      var allInterfaceFields = dbModel.cache.getAllFields(interface);
      if (interfaceToReplace != null) {
        final interfaceToReplaceFields = dbModel.cache.getAllFields(interfaceToReplace);
        allInterfaceFields = allInterfaceFields.toList();
        allInterfaceFields.removeWhere((e) => interfaceToReplaceFields.contains(e));
      }

      for (final subclass in subclasses) {
        var allFields = dbModel.cache.getAllFields(subclass);
        if (subclass == entity) {
          allFields = allFields.toList();
          allFields.removeWhere((e) => allInterfaceFields.contains(e));
        }

        for (final interfaceField in allInterfaceFields) {
          if (allFields.any((e) => e.id == interfaceField.id)) //
            return DbCmdResult.fail('Field with id "${interfaceField.id}" already exists in class "${subclass.id}"');
        }

        var allInterfaces = dbModel.cache.getParentInterfaces(entity);
        if (interfaceToReplace != null) {
          final interfaceToReplaceInterfaces = [interfaceToReplace, ...dbModel.cache.getParentInterfaces(interfaceToReplace)];
          allInterfaces = allInterfaces.toList();
          allInterfaces.removeWhere((e) => interfaceToReplaceInterfaces.contains(e));
        }

        if (allInterfaces.contains(interface)) //
          return DbCmdResult.fail('Subclass "${subclass.id}" already contains interface "$interfaceId"');
      }
    }

    final validateDataColumnsResult = DbModelUtils.validateDataByColumns(dbModel, dataColumnsByTable);
    if (!validateDataColumnsResult.success) //
      return validateDataColumnsResult;

    return DbCmdResult.success();
  }

  @protected
  Map<String, List<DataTableColumn>> getDataColumnsByTable({required DbModel dbModel, required ClassMetaEntity? interfaceEntity}) {
    final dataColumnsByTable = <String, List<DataTableColumn>>{};
    if (interfaceEntity != null) {
      final interfaceFields = dbModel.cache.getAllFields(interfaceEntity).toSet();

      for (final table in dbModel.cache.allDataTables) {
        final allFields = dbModel.cache.getAllFieldsById(table.classId);
        final interferingFields = allFields!.where((f) => interfaceFields.contains(f)).toList();

        final dataColumns = DbModelUtils.getDataColumns(dbModel, table, columns: interferingFields);
        if (dataColumns.isNotEmpty) //
          dataColumnsByTable[table.id] = dataColumns;
      }
    }
    return dataColumnsByTable;
  }

  @protected
  void executeEdit({
    required DbModel dbModel,
    required ClassMetaEntity entity,
    required String? interfaceId,
    required int interfaceIndex,
    required bool insert,
    required Map<String, List<DataTableColumn>>? valuesByTable,
    required bool delete,
  }) {
    final dataColumnsByTable = valuesByTable ?? <String, List<DataTableColumn>>{};

    final allTablesUsingClass = DbModelUtils.getAllTablesUsingClass(dbModel, entity);
    for (final table in allTablesUsingClass) {
      dataColumnsByTable[table.id] = DbModelUtils.getDataColumns(dbModel, table, prioritizedValues: dataColumnsByTable[table.id]);
    }

    if (delete) {
      entity.interfaces.removeAt(interfaceIndex);
    } else if (insert) {
      entity.interfaces.insert(interfaceIndex, interfaceId);
    } else {
      entity.interfaces[interfaceIndex] = interfaceId;
    }
    dbModel.cache.invalidate();

    for (final table in allTablesUsingClass) {
      final allFields = dbModel.cache.getAllFieldsById(table.classId)!;
      final defaultValues = allFields.map((e) => DbModelUtils.parseDefaultValueByFieldOrDefault(e, e.defaultValue)).toList();

      for (var i = 0; i < table.rows.length; i++) {
        table.rows[i].values.clear();
        table.rows[i].values.addAll(defaultValues);
      }
    }

    DbModelUtils.applyManyDataColumns(dbModel, dataColumnsByTable);
  }
}
