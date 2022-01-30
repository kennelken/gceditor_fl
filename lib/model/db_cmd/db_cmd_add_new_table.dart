import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db/table_meta_group.dart';
import 'package:gceditor/model/db_cmd/db_cmd_delete_table.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_add_new_table.g.dart';

@JsonSerializable()
class DbCmdAddNewTable extends BaseDbCmd {
  @JsonKey(toJson: TableMeta.encode, fromJson: TableMeta.decode)
  late TableMeta tableMeta;
  String? parentId;
  int? index;

  DbCmdAddNewTable.values({
    String? id,
    required this.tableMeta,
    this.parentId,
    this.index,
  }) : super.withId(id) {
    $type = DbCmdType.addNewTable;
  }

  DbCmdAddNewTable();

  factory DbCmdAddNewTable.fromJson(Map<String, dynamic> json) => _$DbCmdAddNewTableFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdAddNewTableToJson(this);

  factory DbCmdAddNewTable.fromType({
    required String entityId,
    required TableMetaType type,
    required int? index,
    required String? parentId,
  }) {
    TableMeta? entity;
    switch (type) {
      case TableMetaType.undefined:
        break;

      case TableMetaType.$group:
        entity = TableMetaGroup()
          ..id = entityId
          ..entries = <TableMeta>[]
          ..description = Config.newFolderDescription;
        break;

      case TableMetaType.$table:
        entity = TableMetaEntity()
          ..id = entityId
          ..rows = <DataTableRow>[]
          ..description = Config.newTableDescription;
        break;
    }

    return DbCmdAddNewTable.values(tableMeta: entity!, index: index, parentId: parentId);
  }

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    if (parentId != null) {
      final parent = dbModel.cache.getTable(parentId!) as TableMetaGroup;
      parent.entries.insert(index ?? 0, tableMeta);
    } else {
      dbModel.tables.insert(index ?? 0, tableMeta);
    }

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    if (!DbModelUtils.validateId(tableMeta.id)) //
      return DbCmdResult.fail('Id "${tableMeta.id}" is invalid. Valid format: "${Config.idFormatRegex.pattern}"');

    final existingEntity = dbModel.cache.getEntity(tableMeta.id);

    if (existingEntity != null) //
      return DbCmdResult.fail('Entity with id "${tableMeta.id}" already exists');

    var entriesCount = dbModel.classes.length;
    if (parentId != null) {
      final parent = dbModel.cache.getTable(parentId!);
      if (parent == null) {
        return DbCmdResult.fail('TableMeta with id "$parentId" does not exist');
      }
      if (parent is! TableMetaGroup) {
        return DbCmdResult.fail('TableMeta with id "$tableMeta.id" is not a group');
      }
      entriesCount = parent.entries.length;
    }

    final idx = index ?? 0;
    if (idx < 0 || idx > entriesCount) {
      return DbCmdResult.fail('Index "$index" is invalid');
    }

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdDeleteTable.values(
      entityId: tableMeta.id,
    );
  }
}
