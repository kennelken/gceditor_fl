import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_reorder_data_row.g.dart';

@JsonSerializable()
class DbCmdReorderDataRow extends BaseDbCmd {
  late String tableId;
  late int indexFrom;
  late int indexTo;

  DbCmdReorderDataRow.values({
    String? id,
    required this.tableId,
    required this.indexFrom,
    required this.indexTo,
  }) : super.withId(id) {
    $type = DbCmdType.reorderDataRow;
  }

  DbCmdReorderDataRow();

  factory DbCmdReorderDataRow.fromJson(Map<String, dynamic> json) => _$DbCmdReorderDataRowFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdReorderDataRowToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final table = dbModel.cache.getTable(tableId)! as TableMetaEntity;

    // insert duplicate field
    final rowFrom = table.rows[indexFrom];
    table.rows.insert(indexTo, rowFrom);

    // remove old value (duplicating)
    final modifiedIndexes = Utils.getModifiedIndexesAfterReordering(indexFrom, indexTo);
    table.rows.removeAt(modifiedIndexes.oldValue!);

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final table = dbModel.cache.getTable(tableId);
    if (table == null) //
      return DbCmdResult.fail('Table with id "$tableId" does not exist');

    if (table is! TableMetaEntity) //
      return DbCmdResult.fail('Entity with id "$tableId" is not a table');

    if (indexFrom == indexTo) //
      return DbCmdResult.fail('indexFrom "$indexFrom" is equial to indexTo "$indexTo"');

    if (indexFrom < 0 || indexFrom >= table.rows.length) //
      return DbCmdResult.fail('Incorrect indexFrom "$indexFrom"');

    if (indexTo < 0 || indexFrom > table.rows.length) //
      return DbCmdResult.fail('Incorrect indexTo "$indexTo"');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final modifiedIndexes = Utils.getModifiedIndexesAfterReordering(indexFrom, indexTo);

    return DbCmdReorderDataRow.values(
      tableId: tableId,
      indexFrom: modifiedIndexes.newValue!,
      indexTo: modifiedIndexes.oldValue!,
    );
  }
}
