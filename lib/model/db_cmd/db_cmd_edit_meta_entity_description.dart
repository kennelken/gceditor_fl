import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_edit_meta_entity_description.g.dart';

@JsonSerializable()
class DbCmdEditMetaEntityDescription extends BaseDbCmd {
  late String entityId;
  late String newValue;

  DbCmdEditMetaEntityDescription.values({
    String? id,
    required this.entityId,
    required this.newValue,
  }) : super.withId(id) {
    $type = DbCmdType.editMetaEntityDescription;
  }

  DbCmdEditMetaEntityDescription();

  factory DbCmdEditMetaEntityDescription.fromJson(Map<String, dynamic> json) => _$DbCmdEditMetaEntityDescriptionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdEditMetaEntityDescriptionToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getEntity(entityId);

    (entity as IDescribable).description = newValue;

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final entity = dbModel.cache.getEntity(entityId);

    if (entity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (entity is! IDescribable) //
      return DbCmdResult.fail('Entity with id "$entityId" is not IDescribable');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    String? oldValue;

    final entity = dbModel.cache.getEntity(entityId);
    oldValue = (entity as IDescribable).description;

    return DbCmdEditMetaEntityDescription.values(
      entityId: entityId,
      newValue: oldValue,
    );
  }
}
