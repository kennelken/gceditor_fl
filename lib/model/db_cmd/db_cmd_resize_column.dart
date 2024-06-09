import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_resize_column.g.dart';

@JsonSerializable()
class DbCmdResizeColumn extends BaseDbCmd {
  late String tableId;
  String? fieldId;
  bool? toResizeIds;
  late double width;
  late double oldWidth;

  DbCmdResizeColumn.values({
    String? id,
    required this.tableId,
    required this.width,
    required this.oldWidth,
    this.fieldId,
    this.toResizeIds,
  }) : super.withId(id) {
    $type = DbCmdType.resizeColumn;
  }

  DbCmdResizeColumn();

  factory DbCmdResizeColumn.fromJson(Map<String, dynamic> json) => _$DbCmdResizeColumnFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdResizeColumnToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final table = dbModel.cache.getTable<TableMetaEntity>(tableId)!;

    if (fieldId != null) {
      final field = dbModel.cache.getField(fieldId!, dbModel.cache.getClass<ClassMetaEntity>(table.classId))!;
      DbModelUtils.setColumnWidth(table, field, width: width);
    }
    if (toResizeIds == true) {
      DbModelUtils.setIdsColumnWidth(table, width: width);
    }

    DbModelUtils.removeInvalidColumnWidth(dbModel, table);

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final table = dbModel.cache.getTable(tableId);
    if (table == null) //
      return DbCmdResult.fail('Table with id "$table" does not exist');

    if (table is! TableMetaEntity) //
      return DbCmdResult.fail('Entity with id "$tableId" is not a table');

    if (fieldId != null) {
      final allFields = dbModel.cache.getAllFieldsByClassId(table.classId);
      if (allFields == null) //
        return DbCmdResult.fail('Table with id "$tableId" does not have any fields');

      if (!allFields.any((e) => e.id == fieldId)) //
        return DbCmdResult.fail('Table with id "$tableId" does not have field "$fieldId"');
    }

    if (fieldId != null && toResizeIds == true) //
      return DbCmdResult.fail('Only one of the following can be specified: "fieldId", "toResizeIds"');

    if (fieldId == null && toResizeIds != true) //
      return DbCmdResult.fail('At least one of the following should be specified: "fieldId", "toResizeIds"');

    if (width < Config.minColumnWidth)
      return DbCmdResult.fail('Specified width $width is less then minimal allowed value "${Config.minColumnWidth}"');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdResizeColumn.values(
      tableId: tableId,
      fieldId: fieldId,
      toResizeIds: toResizeIds,
      width: oldWidth,
      oldWidth: width,
    );
  }
}
