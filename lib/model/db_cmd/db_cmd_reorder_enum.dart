import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_reorder_enum.g.dart';

@JsonSerializable()
class DbCmdReorderEnum extends BaseDbCmd {
  late String entityId;
  late int indexFrom;
  late int indexTo;

  DbCmdReorderEnum.values({
    String? id,
    required this.entityId,
    required this.indexFrom,
    required this.indexTo,
  }) : super.withId(id) {
    $type = DbCmdType.reorderEnum;
  }

  DbCmdReorderEnum();

  factory DbCmdReorderEnum.fromJson(Map<String, dynamic> json) => _$DbCmdReorderEnumFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdReorderEnumToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId)! as ClassMetaEntityEnum;
    entity.values = Utils.copyAndReorder(entity.values, indexFrom, indexTo);

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId);
    if (entity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (entity is! ClassMetaEntityEnum) //
      return DbCmdResult.fail('Entity with id "$entityId" is not enum');

    if (indexFrom == indexTo) //
      return DbCmdResult.fail('indexFrom "$indexFrom" is equial to indexTo "$indexTo"');

    if (indexFrom < 0 || indexFrom >= entity.values.length) //
      return DbCmdResult.fail('Incorrect indexFrom "$indexFrom"');

    if (indexTo < 0 || indexFrom > entity.values.length) //
      return DbCmdResult.fail('Incorrect indexTo "$indexTo"');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final modifiedIndexes = Utils.getModifiedIndexesAfterReordering(indexFrom, indexTo);

    return DbCmdReorderEnum.values(
      entityId: entityId,
      indexFrom: modifiedIndexes.newValue!,
      indexTo: modifiedIndexes.oldValue!,
    );
  }
}
