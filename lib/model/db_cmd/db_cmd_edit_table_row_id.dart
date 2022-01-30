import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_edit_table_row_id.g.dart';

@JsonSerializable()
class DbCmdEditTableRowId extends BaseDbCmd {
  late final String tableId;
  late final String newId;
  late final String oldId;

  DbCmdEditTableRowId.values({
    String? id,
    required this.tableId,
    required this.newId,
    required this.oldId,
  }) : super.withId(id) {
    $type = DbCmdType.editTableRowId;
  }

  DbCmdEditTableRowId();

  factory DbCmdEditTableRowId.fromJson(Map<String, dynamic> json) => _$DbCmdEditTableRowIdFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdEditTableRowIdToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    DbModelUtils.editTableRowId(dbModel, oldId, newId);

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    if (!DbModelUtils.validateId(newId)) //
      return DbCmdResult.fail('Id "$newId" is invalid. Valid format: "${Config.idFormatRegex.pattern}"');

    final table = dbModel.cache.getTable(tableId);
    if (table == null) //
      return DbCmdResult.fail('TableMeta with id "$tableId" does not exist');

    if (table is! TableMetaEntity) //
      return DbCmdResult.fail('Entity with id "$tableId" is not a table');

    final existingEntity = dbModel.cache.getEntity(newId);
    if (existingEntity != null) //
      return DbCmdResult.fail('Entity with id "$newId" already exists');

    if (!table.rows.any((e) => e.id == oldId)) //
      return DbCmdResult.fail('Row with id "$oldId" was not found');

    final existingTableRow = dbModel.cache.getTableRow(newId);
    if (existingTableRow != null) //
      return DbCmdResult.fail('Entity with id "$newId" already exists in table "${existingTableRow.table.id}"');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdEditTableRowId.values(
      tableId: tableId,
      oldId: newId,
      newId: oldId,
    );
  }
}
