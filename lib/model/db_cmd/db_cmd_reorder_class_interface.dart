import 'package:gceditor/model/db/db_model.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../utils/utils.dart';
import '../db/class_meta_entity.dart';
import '../db_network/data_table_column.dart';
import '../state/db_model_extensions.dart';
import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_reorder_class_interface.g.dart';

@JsonSerializable()
class DbCmdReorderClassInterface extends BaseDbCmd {
  late String entityId;
  late int indexFrom;
  late int indexTo;

  DbCmdReorderClassInterface.values({
    String? id,
    required this.entityId,
    required this.indexFrom,
    required this.indexTo,
  }) : super.withId(id) {
    $type = DbCmdType.reorderClassInterface;
  }

  DbCmdReorderClassInterface();

  factory DbCmdReorderClassInterface.fromJson(Map<String, dynamic> json) => _$DbCmdReorderClassInterfaceFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdReorderClassInterfaceToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getEntity<ClassMetaEntity>(entityId)!;

    final dataColumnsByTable = <String, List<DataTableColumn>>{};

    final allTablesUsingClass = DbModelUtils.getAllTablesUsingClass(dbModel, entity);
    for (final table in allTablesUsingClass) {
      dataColumnsByTable[table.id] = DbModelUtils.getDataColumns(dbModel, table, prioritizedValues: dataColumnsByTable[table.id]);
    }

    entity.interfaces.insert(indexTo, entity.interfaces[indexFrom]);
    final modifiedIndexes = Utils.getModifiedIndexesAfterReordering(indexFrom, indexTo);
    entity.interfaces.removeAt(modifiedIndexes.oldValue!);
    dbModel.cache.invalidate();

    for (final table in allTablesUsingClass) {
      final allFields = dbModel.cache.getAllFields(entity);
      final defaultValues = allFields.map((e) => DbModelUtils.parseDefaultValueByFieldOrDefault(dbModel, e, e.defaultValue)).toList();

      for (var i = 0; i < table.rows.length; i++) {
        table.rows[i].values.clear();
        table.rows[i].values.addAll(defaultValues);
      }
    }

    DbModelUtils.applyManyDataColumns(dbModel, dataColumnsByTable);

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final entity = dbModel.cache.getEntity(entityId);

    if (entity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (entity is! ClassMetaEntity) //
      return DbCmdResult.fail('Entity with id "$entityId" is not a class');

    if (indexFrom == indexTo) //
      return DbCmdResult.fail('indexFrom "$indexFrom" is equal to indexTo "$indexTo"');

    if (indexFrom < 0 || indexFrom >= entity.interfaces.length) //
      return DbCmdResult.fail('Incorrect indexFrom "$indexFrom"');

    if (indexTo < 0 || indexFrom > entity.interfaces.length) //
      return DbCmdResult.fail('Incorrect indexTo "$indexTo"');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final modifiedIndexes = Utils.getModifiedIndexesAfterReordering(indexFrom, indexTo);

    return DbCmdReorderClassInterface.values(
      entityId: entityId,
      indexFrom: modifiedIndexes.newValue!,
      indexTo: modifiedIndexes.oldValue!,
    );
  }
}
