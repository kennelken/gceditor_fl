import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_resize_dictionary_key_to_value.g.dart';

@JsonSerializable()
class DbCmdResizeDictionaryKeyToValue extends BaseDbCmd {
  late String tableId;
  late String fieldId;
  late double ratio;
  late double oldRatio;

  DbCmdResizeDictionaryKeyToValue.values({
    String? id,
    required this.tableId,
    required this.fieldId,
    required this.ratio,
    required this.oldRatio,
  }) : super.withId(id) {
    $type = DbCmdType.resizeDictionaryKeyToValue;
  }

  DbCmdResizeDictionaryKeyToValue();

  factory DbCmdResizeDictionaryKeyToValue.fromJson(Map<String, dynamic> json) => _$DbCmdResizeDictionaryKeyToValueFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdResizeDictionaryKeyToValueToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final table = dbModel.cache.getTable<TableMetaEntity>(tableId)!;

    final field = dbModel.cache.getField(fieldId, dbModel.cache.getClass<ClassMetaEntity>(table.classId))!;
    DbModelUtils.setDictionaryColumnRatio(table, field, ratio: ratio);

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

    final allFields = dbModel.cache.getAllFieldsById(table.classId);
    if (allFields == null) //
      return DbCmdResult.fail('Table with id "$tableId" does not have any fields');

    if (!allFields.any((e) => e.id == fieldId)) //
      return DbCmdResult.fail('Table with id "$tableId" does not have field "$fieldId"');

    if (ratio < Config.minMainColumnHeightRatio || ratio > (1 - Config.minMainColumnHeightRatio))
      return DbCmdResult.fail('Specified invalid ratio $ratio');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdResizeDictionaryKeyToValue.values(
      tableId: tableId,
      fieldId: fieldId,
      ratio: oldRatio,
      oldRatio: ratio,
    );
  }
}
