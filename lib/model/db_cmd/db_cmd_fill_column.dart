import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_fill_column.g.dart';

@JsonSerializable()
class DbCmdFillColumn extends BaseDbCmd {
  Map<String, List<DataTableColumn>>? dataColumnsByTable;

  DbCmdFillColumn.values({
    String? id,
    required this.dataColumnsByTable,
  }) : super.withId(id) {
    $type = DbCmdType.fillColumn;
  }

  DbCmdFillColumn();

  factory DbCmdFillColumn.fromJson(Map<String, dynamic> json) => _$DbCmdFillColumnFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdFillColumnToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    DbModelUtils.applyManyDataColumns(dbModel, dataColumnsByTable!);
    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final validateDataColumnsResult = DbModelUtils.validateDataByColumns(dbModel, dataColumnsByTable);
    if (!validateDataColumnsResult.success) //
      return validateDataColumnsResult;

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final dataColumnsByTable = <String, List<DataTableColumn>>{};

    for (final tableId in this.dataColumnsByTable!.keys) {
      final table = dbModel.cache.getTable<TableMetaEntity>(tableId)!;
      final allFields = dbModel.cache.getAllFieldsById(table.classId);
      dataColumnsByTable[table.id] = DbModelUtils.getDataColumns(dbModel, table, columns: allFields);
    }

    return DbCmdFillColumn.values(
      dataColumnsByTable: dataColumnsByTable,
    );
  }
}
