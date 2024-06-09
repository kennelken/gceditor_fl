import 'package:collection/collection.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_resize_inner_cell.g.dart';

@JsonSerializable()
class DbCmdResizeInnerCell extends BaseDbCmd {
  late String tableId;
  late String fieldId;
  late List<double> flexes;
  late List<double> oldFlexes;

  DbCmdResizeInnerCell.values({
    String? id,
    required this.tableId,
    required this.fieldId,
    required this.flexes,
    required this.oldFlexes,
  }) : super.withId(id) {
    $type = DbCmdType.resizeInnerCell;
  }

  DbCmdResizeInnerCell();

  factory DbCmdResizeInnerCell.fromJson(Map<String, dynamic> json) => _$DbCmdResizeInnerCellFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdResizeInnerCellToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final table = dbModel.cache.getTable<TableMetaEntity>(tableId)!;

    final field = dbModel.cache.getField(fieldId, dbModel.cache.getClass<ClassMetaEntity>(table.classId))!;
    DbModelUtils.setInnerCellColumnFlex(dbModel, table, field, flex: flexes);

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

    final allFields = dbModel.cache.getAllFieldsByClassId(table.classId);
    if (allFields == null) //
      return DbCmdResult.fail('Table with id "$tableId" does not have any fields');

    final field = allFields.firstWhereOrNull((e) => e.id == fieldId);
    if (field == null) //
      return DbCmdResult.fail('Table with id "$tableId" does not have field "$fieldId"');

    if (flexes.any((e) => e < Config.minMainColumnHeightRatio)) //
      return DbCmdResult.fail('Specified invalid ratio $flexes');

    final sum = flexes.fold<double>(0, (v, e) => v + e);
    if (sum > 1.0001 || sum < 0.9999) {
      return DbCmdResult.fail('Sum of elements must be 1, but received "$sum"');
    }

    final columnsCount = DbModelUtils.getInnerCellsCount(dbModel, field);
    if (flexes.length != columnsCount) //
      return DbCmdResult.fail('Expected number of columns for dictionary must be "$columnsCount", but received "${flexes.length}"');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdResizeInnerCell.values(
      tableId: tableId,
      fieldId: fieldId,
      flexes: oldFlexes,
      oldFlexes: flexes,
    );
  }
}
