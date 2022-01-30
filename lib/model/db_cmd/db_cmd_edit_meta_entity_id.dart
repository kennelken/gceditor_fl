import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_edit_meta_entity_id.g.dart';

@JsonSerializable()
class DbCmdEditMetaEntityId extends BaseDbCmd {
  late String entityId;
  late String newValue;

  DbCmdEditMetaEntityId.values({
    String? id,
    required this.entityId,
    required this.newValue,
  }) : super.withId(id) {
    $type = DbCmdType.editMetaEntityId;
  }

  DbCmdEditMetaEntityId();

  factory DbCmdEditMetaEntityId.fromJson(Map<String, dynamic> json) => _$DbCmdEditMetaEntityIdFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdEditMetaEntityIdToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getEntity(entityId);

    entity!.id = newValue;

    if (entity is ClassMetaEntity || entity is ClassMetaEntityEnum) {
      for (var classEntity in dbModel.cache.allClasses) {
        if (classEntity.parent == entityId) //
          classEntity.parent = newValue;
      }

      for (var tableEntity in dbModel.cache.allDataTables) {
        if (tableEntity.classId == entityId) //
          tableEntity.classId = newValue;
      }

      dbModel.cache.invalidate();

      for (var classEntity in dbModel.cache.allClasses) {
        final allFields = dbModel.cache.getAllFields(classEntity);
        for (var field in allFields) {
          if (field.typeInfo.classId == entityId) //
            field.typeInfo.classId = newValue;

          if (field.keyTypeInfo?.classId == entityId) //
            field.keyTypeInfo!.classId = newValue;

          if (field.valueTypeInfo?.classId == entityId) //
            field.valueTypeInfo!.classId = newValue;
        }
      }
    }

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    if (!DbModelUtils.validateId(newValue)) //
      return DbCmdResult.fail('Id "$newValue" is invalid. Valid format: "${Config.idFormatRegex.pattern}"');

    final entityWithNewId = dbModel.cache.getEntity(newValue);

    if (entityWithNewId != null) //
      return DbCmdResult.fail('Entity with id "$newValue" already exists');

    final existingEntity = dbModel.cache.getEntity(entityId);

    if (existingEntity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (newValue.isEmpty) //
      return DbCmdResult.fail('Entity id must be at least 1 char long');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdEditMetaEntityId.values(
      entityId: newValue,
      newValue: entityId,
    );
  }
}
