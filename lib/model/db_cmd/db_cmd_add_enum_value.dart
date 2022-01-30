import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_delete_enum_value.dart';
import 'db_cmd_result.dart';

part 'db_cmd_add_enum_value.g.dart';

@JsonSerializable()
class DbCmdAddEnumValue extends BaseDbCmd {
  late String entityId;
  late int index;
  late String value;
  String? description;

  DbCmdAddEnumValue.values({
    String? id,
    required this.entityId,
    required this.index,
    required this.value,
    this.description,
  }) : super.withId(id) {
    $type = DbCmdType.addEnumValue;
  }

  DbCmdAddEnumValue();

  factory DbCmdAddEnumValue.fromJson(Map<String, dynamic> json) => _$DbCmdAddEnumValueFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdAddEnumValueToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId)! as ClassMetaEntityEnum;

    entity.values.insert(
        index,
        EnumValue()
          ..id = value
          ..description = description ?? Config.newEnumValueDefaultDescription);

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId);
    if (entity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (entity is! ClassMetaEntityEnum) //
      return DbCmdResult.fail('Entity with id "$entityId" is not enum');

    if (!DbModelUtils.validateId(value)) //
      return DbCmdResult.fail('Id "$value" is invalid. Valid format: "${Config.idFormatRegex.pattern}"');

    if (index < 0 || index > entity.values.length) //
      return DbCmdResult.fail('invalid index "$index"');

    if (entity.values.any((e) => e.id == value)) //
      return DbCmdResult.fail('Enum value "$value" already exists');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdDeleteEnumValue.values(
      entityId: entityId,
      valueId: value,
    );
  }
}
