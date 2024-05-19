import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_reorder_class_field.g.dart';

@JsonSerializable()
class DbCmdReorderClassField extends BaseDbCmd {
  late String entityId;
  late int indexFrom;
  late int indexTo;

  DbCmdReorderClassField.values({
    String? id,
    required this.entityId,
    required this.indexFrom,
    required this.indexTo,
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
    final field = entity.fields[indexFrom];

    // get affected tables and index offsets for them
    final indexOffsetByTable = <TableMetaEntity, int>{};

    final allTables = dbModel.cache.allDataTables;
    for (final table in allTables) {
      if (table.classId.isEmpty) //
        continue;

      final allFields = dbModel.cache.getAllFieldsByClassId(table.classId);
      final index = allFields?.indexOf(field) ?? -1;
      if (index > -1) //
        indexOffsetByTable[table] = index - indexFrom;
    }

    // insert duplicate field
    final fieldFrom = entity.fields[indexFrom];
    entity.fields.insert(indexTo, fieldFrom);

    for (final kvp in indexOffsetByTable.entries) {
      for (final row in kvp.key.rows) {
        row.values.insert(indexTo + kvp.value, row.values[indexFrom + kvp.value]);
      }
    }

    // remove old value (duplicating)
    final modifiedIndexes = Utils.getModifiedIndexesAfterReordering(indexFrom, indexTo);
    entity.fields.removeAt(modifiedIndexes.oldValue!);

    for (final kvp in indexOffsetByTable.entries) {
      for (final row in kvp.key.rows) {
        row.values.removeAt(modifiedIndexes.oldValue! + kvp.value);
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

    if (indexFrom == indexTo) //
      return DbCmdResult.fail('indexFrom "$indexFrom" is equal to indexTo "$indexTo"');

    if (indexFrom < 0 || indexFrom >= entity.fields.length) //
      return DbCmdResult.fail('Incorrect indexFrom "$indexFrom"');

    if (indexTo < 0 || indexFrom > entity.fields.length) //
      return DbCmdResult.fail('Incorrect indexTo "$indexTo"');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final modifiedIndexes = Utils.getModifiedIndexesAfterReordering(indexFrom, indexTo);

    return DbCmdReorderClassField.values(
      entityId: entityId,
      indexFrom: modifiedIndexes.newValue!,
      indexTo: modifiedIndexes.oldValue!,
    );
  }
}
