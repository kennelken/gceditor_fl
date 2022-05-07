import 'package:collection/collection.dart';
import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_edit_table_cell_value.g.dart';

@JsonSerializable()
class DbCmdEditTableCellValue extends BaseDbCmd {
  late final String tableId;
  late final String fieldId;
  late final String rowId;
  late final DataTableCellValue value;

  DbCmdEditTableCellValue.values({
    String? id,
    required this.tableId,
    required this.fieldId,
    required this.rowId,
    required this.value,
  }) : super.withId(id) {
    $type = DbCmdType.editTableCellValue;
  }

  DbCmdEditTableCellValue();

  factory DbCmdEditTableCellValue.fromJson(Map<String, dynamic> json) => _$DbCmdEditTableCellValueFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdEditTableCellValueToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final table = dbModel.cache.getTable<TableMetaEntity>(tableId)!;
    final columnIndex = dbModel.cache.getAllFieldsById(table.classId)!.indexWhere((e) => e.id == fieldId);
    final rowIndex = table.rows.indexWhere((e) => e.id == rowId);

    table.rows[rowIndex].values[columnIndex] = value;

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final table = dbModel.cache.getTable(tableId);
    if (table == null) //
      return DbCmdResult.fail('TableMeta with id "$tableId" does not exist');

    if (table is! TableMetaEntity) //
      return DbCmdResult.fail('Entity with id "$tableId" is not a table');

    final allFields = dbModel.cache.getAllFieldsById(table.classId);
    if (allFields == null) //
      return DbCmdResult.fail('Table "$tableId" does not contain any fields');

    final field = allFields.firstWhereOrNull((e) => e.id == fieldId);
    if (field == null) //
      return DbCmdResult.fail('Field with id "$fieldId" was not found');

    final rowIndex = table.rows.indexWhere((e) => e.id == rowId);
    if (rowIndex <= -1) //
      return DbCmdResult.fail('Row with id "$rowId" was not found');

    if (!DbModelUtils.validateValue(field, value)) //
      return DbCmdResult.fail('Value "$value" can not be set to field "$fieldId"');

    final columnIndex = dbModel.cache.getAllFieldsById(table.classId)!.indexWhere((e) => e.id == fieldId);
    if (value == table.rows[rowIndex].values[columnIndex]) //
      return DbCmdResult.fail('Value "$value" is equal to the current value');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final table = dbModel.cache.getTable<TableMetaEntity>(tableId)!;
    final columnIndex = dbModel.cache.getAllFieldsById(table.classId)!.indexWhere((e) => e.id == fieldId);
    final rowIndex = table.rows.indexWhere((e) => e.id == rowId);

    return DbCmdEditTableCellValue.values(
      tableId: tableId,
      fieldId: fieldId,
      rowId: rowId,
      value: table.rows[rowIndex].values[columnIndex].copy(),
    );
  }
}
