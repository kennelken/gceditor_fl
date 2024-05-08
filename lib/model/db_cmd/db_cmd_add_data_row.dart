import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_cmd/db_cmd_delete_data_row.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_add_data_row.g.dart';

@JsonSerializable()
class DbCmdAddDataRow extends BaseDbCmd {
  late String tableId;
  late String rowId;
  late int index;
  DataTableRow? tableRowValues;

  DbCmdAddDataRow.values({
    String? id,
    required this.tableId,
    required this.rowId,
    required this.index,
    this.tableRowValues,
  }) : super.withId(id) {
    $type = DbCmdType.addDataRow;
  }

  DbCmdAddDataRow();

  factory DbCmdAddDataRow.fromJson(Map<String, dynamic> json) => _$DbCmdAddDataRowFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdAddDataRowToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final newRow = DbModelUtils.buildNewRow(
      model: dbModel,
      rowId: rowId,
      tableId: tableId,
      tableRowValues: tableRowValues,
    );
    final table = dbModel.cache.getTable(tableId) as TableMetaEntity;
    table.rows.insert(index, newRow);

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final table = dbModel.cache.getTable(tableId);
    if (table == null) //
      return DbCmdResult.fail('Table with id "$tableId" does not exist');

    if (table is! TableMetaEntity) //
      return DbCmdResult.fail('Entity with id "$tableId" is not a table');

    if (table.classId.isEmpty) //
      return DbCmdResult.fail('Table "$tableId" does not have a class specified');

    if (index < 0 || index > table.rows.length) //
      return DbCmdResult.fail('invalid index "$index"');

    final allFields = dbModel.cache.getAllFieldsById(table.classId) ?? [];
    if (tableRowValues != null) {
      if (tableRowValues!.values.length != allFields.length) {
        return DbCmdResult.fail('Invalid data length ("${tableRowValues!.values.length}" != "${allFields.length}")');
      }

      for (var i = 0; i < tableRowValues!.values.length; i++) {
        if (!DbModelUtils.validateValue(dbModel, allFields[i], tableRowValues!.values[i])) //
          return DbCmdResult.fail('Invalid value "${tableRowValues!.values[i]}" at index "$index"');
      }
    }

    if (dbModel.cache.getTableRow(rowId) != null) {
      return DbCmdResult.fail('Row with id "$rowId" already exists');
    }

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdDeleteDataRow.values(
      tableId: tableId,
      rowId: rowId,
    );
  }
}
