import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_data_row.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_delete_data_row.g.dart';

@JsonSerializable()
class DbCmdDeleteDataRow extends BaseDbCmd {
  late String tableId;
  late String rowId;

  DbCmdDeleteDataRow.values({
    String? id,
    required this.tableId,
    required this.rowId,
  }) : super.withId(id) {
    $type = DbCmdType.deleteDataRow;
  }

  DbCmdDeleteDataRow();

  factory DbCmdDeleteDataRow.fromJson(Map<String, dynamic> json) => _$DbCmdDeleteDataRowFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdDeleteDataRowToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final table = dbModel.cache.getTable(tableId) as TableMetaEntity;

    final index = table.rows.indexWhere((element) => element.id == rowId);
    table.rows.removeAt(index);

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final table = dbModel.cache.getTable(tableId);
    if (table == null) //
      return DbCmdResult.fail('Table with id "$tableId" does not exist');

    if (table is! TableMetaEntity) //
      return DbCmdResult.fail('Entity with id "$tableId" is not a table');

    if (!table.rows.any((e) => e.id == rowId)) //
      return DbCmdResult.fail('Can not find row "$rowId"');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final table = dbModel.cache.getTable(tableId) as TableMetaEntity;

    final index = table.rows.indexWhere((element) => element.id == rowId);
    return DbCmdAddDataRow.values(
      tableId: tableId,
      index: index,
      rowId: rowId,
      tableRowValues: DataTableRow.fromJson(table.rows[index].toJson().clone()),
    );
  }
}
