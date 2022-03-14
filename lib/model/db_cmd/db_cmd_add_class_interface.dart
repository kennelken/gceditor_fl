import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../consts/config.dart';
import '../db/class_meta_entity.dart';
import '../db/table_meta_entity.dart';
import '../state/db_model_extensions.dart';
import 'base_db_cmd.dart';
import 'db_cmd_delete_class_interface.dart';
import 'db_cmd_result.dart';

part 'db_cmd_add_class_interface.g.dart';

@JsonSerializable()
class DbCmdAddClassInterface extends BaseDbCmd {
  late String entityId;
  late int index;
  late String? interfaceId;

  Map<String, List<DataTableColumn>>? dataColumnsByTable;

  DbCmdAddClassInterface.values({
    String? id,
    required this.entityId,
    required this.index,
    required this.interfaceId,
    this.dataColumnsByTable,
  }) : super.withId(id) {
    $type = DbCmdType.addClassInterface;
  }

  DbCmdAddClassInterface();

  factory DbCmdAddClassInterface.fromJson(Map<String, dynamic> json) => _$DbCmdAddClassInterfaceFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdAddClassInterfaceToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId)! as ClassMetaEntity;

    entity.interfaces.insert(index, interfaceId);
    dbModel.cache.invalidate();

    final allClasses = [entity, ...dbModel.cache.getSubClasses(entity)];
    final interface = dbModel.cache.getClass<ClassMetaEntity>(interfaceId);
    if (interface != null) {
      final allInterfaceFields = dbModel.cache.getAllFields(interface);

      for (final classEntity in allClasses) {
        final allTables = dbModel.cache.allDataTables.where((e) => e.classId == classEntity.id);
        for (final table in allTables) {
          final allFields = dbModel.cache.getAllFields(classEntity);

          for (final interfaceField in allInterfaceFields) {
            final fieldIndex = allFields.indexOf(interfaceField);

            DbModelUtils.insertDefaultValues(dbModel, table, fieldIndex);
            if (dataColumnsByTable?[table.id] != null) {
              DbModelUtils.applyDataColumns(dbModel, table, dataColumnsByTable![table.id]!);
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

    if (interfaceId != null && !DbModelUtils.validateId(interfaceId!)) //
      return DbCmdResult.fail('Id "$interfaceId" is invalid. Valid format: "${Config.idFormatRegex.pattern}"');

    if (index < 0 || index > entity.interfaces.length) //
      return DbCmdResult.fail('invalid index "$index"');

    final interface = dbModel.cache.getClass<ClassMetaEntity>(interfaceId);
    if (interfaceId != null && interface == null) //
      return DbCmdResult.fail('Could not find entity with id "$interfaceId"');

    if (interface != null) {
      if (interface.classType != ClassType.interface) //
        return DbCmdResult.fail('Specified entity "$interfaceId" is not an interface');

      final subclasses = [entity, ...dbModel.cache.getSubClasses(entity)];

      final allInterfaceFields = dbModel.cache.getAllFields(interface);

      for (final subclass in subclasses) {
        final allFields = dbModel.cache.getAllFields(subclass);

        for (final interfaceField in allInterfaceFields) {
          if (allFields.any((e) => e.id == interfaceField.id)) //
            return DbCmdResult.fail('Field with id "${interfaceField.id}" already exists in class "${subclass.id}"');
        }
      }
    }

    if (dataColumnsByTable != null) {
      for (var tableId in dataColumnsByTable!.keys) {
        final table = dbModel.cache.getTable(tableId);
        if (table == null) //
          return DbCmdResult.fail('Entity with id "$tableId" does not exist');

        if (table is! TableMetaEntity) //
          return DbCmdResult.fail('Entity with id "$tableId" is not a table');

        if (dataColumnsByTable![tableId]!.any((e) => e.values.length != table.rows.length)) //
          return DbCmdResult.fail('invalid rows count for table "$tableId"');
      }
    }

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdDeleteClassInterface.values(
      entityId: entityId,
      index: index,
    );
  }
}
