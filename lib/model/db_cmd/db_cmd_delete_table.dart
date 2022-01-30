import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_group.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_add_new_table.dart';
import 'db_cmd_result.dart';

part 'db_cmd_delete_table.g.dart';

@JsonSerializable()
class DbCmdDeleteTable extends BaseDbCmd {
  late String entityId;

  DbCmdDeleteTable.values({
    String? id,
    required this.entityId,
  }) : super.withId(id) {
    $type = DbCmdType.deleteTable;
  }

  DbCmdDeleteTable();

  factory DbCmdDeleteTable.fromJson(Map<String, dynamic> json) => _$DbCmdDeleteTableFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdDeleteTableToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final tableMeta = dbModel.cache.getTable(entityId);

    final group = dbModel.cache.getParentTable(tableMeta!);
    final index = dbModel.cache.getTableIndex(tableMeta);

    if (group != null) {
      group.entries.removeAt(index!);
    } else {
      dbModel.tables.removeAt(index!);
    }

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final tableMeta = dbModel.cache.getTable(entityId);

    if (tableMeta == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (tableMeta is TableMetaGroup) {
      if (tableMeta.entries.isNotEmpty) {
        return DbCmdResult.fail('Entity with id "$entityId" is not empty');
      }
    }

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final tableMeta = dbModel.cache.getTable(entityId)!;

    final deletedTable = tableMeta;
    final deletedTableParent = dbModel.cache.getParentTable(deletedTable);
    final deletedTableIndex = dbModel.cache.getTableIndex(deletedTable);

    return DbCmdAddNewTable.values(
      tableMeta: TableMeta.decode(deletedTable.toJson().clone()),
      parentId: deletedTableParent?.id,
      index: deletedTableIndex,
    );
  }
}
