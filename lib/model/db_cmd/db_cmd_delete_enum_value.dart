import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_add_enum_value.dart';
import 'db_cmd_result.dart';

part 'db_cmd_delete_enum_value.g.dart';

@JsonSerializable()
class DbCmdDeleteEnumValue extends BaseDbCmd {
  late String entityId;
  late String valueId;

  DbCmdDeleteEnumValue.values({
    String? id,
    required this.entityId,
    required this.valueId,
  }) : super.withId(id) {
    $type = DbCmdType.deleteEnumValue;
  }

  DbCmdDeleteEnumValue();

  factory DbCmdDeleteEnumValue.fromJson(Map<String, dynamic> json) => _$DbCmdDeleteEnumValueFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdDeleteEnumValueToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId)! as ClassMetaEntityEnum;

    final index = entity.values.indexWhere((element) => element.id == valueId);
    entity.values.removeAt(index);

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId);
    if (entity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (entity is! ClassMetaEntityEnum) //
      return DbCmdResult.fail('Entity with id "$entityId" is not enum');

    if (!entity.values.any((element) => element.id == valueId)) //
      return DbCmdResult.fail('Can not find enum value "$valueId"');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId) as ClassMetaEntityEnum;

    final index = entity.values.indexWhere((element) => element.id == valueId);
    final value = entity.values[index];

    return DbCmdAddEnumValue.values(
      entityId: entityId,
      index: index,
      value: value.id,
      description: value.description,
    );
  }
}
