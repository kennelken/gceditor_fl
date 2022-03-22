import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_cmd/db_cmd_result.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';

part 'db_cmd_edit_enum_value.g.dart';

@JsonSerializable()
class DbCmdEditEnumValue extends BaseDbCmd {
  late String entityId;
  String? valueId;
  String? newId;
  String? newDescription;
  double? newWidthRatio;

  DbCmdEditEnumValue.values({
    String? id,
    required this.entityId,
    this.valueId,
    this.newId,
    this.newDescription,
    this.newWidthRatio,
  }) : super.withId(id) {
    $type = DbCmdType.editEnumValue;
  }

  DbCmdEditEnumValue();

  factory DbCmdEditEnumValue.fromJson(Map<String, dynamic> json) => _$DbCmdEditEnumValueFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdEditEnumValueToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId) as ClassMetaEntityEnum;
    final index = valueId == null ? -1 : entity.values.indexWhere((element) => element.id == valueId);

    if (newWidthRatio != null) //
      entity.valueColumnWidth = newWidthRatio!;

    if (newDescription != null) //
      entity.values[index].description = newDescription!;

    if (newId != null) {
      final oldId = entity.values[index].id;
      entity.values[index].id = newId!;
      DbModelUtils.updateEnumReferences(dbModel, oldId, newId!, entity);
    }

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId);
    if (entity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (entity is! ClassMetaEntityEnum) //
      return DbCmdResult.fail('Entity with id "$entityId" is not enum');

    if (newWidthRatio != null && (newWidthRatio! < Config.enumColumnMinWidth || newWidthRatio! > Config.enumColumnMaxWidth)) //
      return DbCmdResult.fail('Invalid newRatio value "$newWidthRatio"');

    if ((newId != null || newDescription != null) && valueId == null) //
      return DbCmdResult.fail('index is not specified');

    if (valueId != null && !entity.values.any((e) => e.id == valueId)) //
      return DbCmdResult.fail('Can not find enum value "$valueId"');

    if (newId != null) {
      if (newId!.isEmpty) //
        return DbCmdResult.fail('value can not be empty');

      if (!DbModelUtils.validateId(newId!)) //
        return DbCmdResult.fail('Id "$newId" is invalid. Valid format: "${Config.idFormatRegex.pattern}"');

      if (entity.values.any((e) => e.id == newId)) //
        return DbCmdResult.fail('Specified value "$newId" already exists');
    }

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId) as ClassMetaEntityEnum;

    final newWidthRatio = this.newWidthRatio != null ? entity.valueColumnWidth : null;

    final index = entity.values.indexWhere((element) => element.id == valueId);

    final newValueId = this.newId ?? valueId;
    final newId = this.newId != null ? entity.values[index].id : null;
    final newDescription = this.newDescription != null ? entity.values[index].description : null;

    return DbCmdEditEnumValue.values(
      entityId: entityId,
      valueId: newValueId,
      newWidthRatio: newWidthRatio,
      newId: newId,
      newDescription: newDescription,
    );
  }
}
