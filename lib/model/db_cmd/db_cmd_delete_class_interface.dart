import 'package:gceditor/model/db/db_model.dart';
import 'package:json_annotation/json_annotation.dart';

import '../db/class_meta_entity.dart';
import 'base_db_cmd.dart';
import 'common_class_interface_command.dart';
import 'db_cmd_add_class_interface.dart';
import 'db_cmd_result.dart';

part 'db_cmd_delete_class_interface.g.dart';

@JsonSerializable()
class DbCmdDeleteClassInterface extends BaseDbCmd with CommonClassInterfaceCommand {
  late String entityId;
  late int index;

  DbCmdDeleteClassInterface.values({
    String? id,
    required this.entityId,
    required this.index,
  }) : super.withId(id) {
    $type = DbCmdType.deleteClassInterface;
  }

  DbCmdDeleteClassInterface();

  factory DbCmdDeleteClassInterface.fromJson(Map<String, dynamic> json) => _$DbCmdDeleteClassInterfaceFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdDeleteClassInterfaceToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass<ClassMetaEntity>(entityId)!;

    executeEdit(
      dbModel: dbModel,
      entity: entity,
      interfaceId: null,
      valuesByTable: null,
      interfaceIndex: index,
      insert: false,
      delete: true,
    );

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId);
    if (entity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (entity is! ClassMetaEntity) //
      return DbCmdResult.fail('Entity with id "$entityId" is not a class');

    if (index < 0 || index >= entity.interfaces.length) //
      return DbCmdResult.fail('index "$index" is out of bounds');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final entity = dbModel.cache.getClass<ClassMetaEntity>(entityId)!;

    final interfaceId = entity.interfaces[index];
    final interfaceEntity = dbModel.cache.getClass<ClassMetaEntity>(interfaceId);

    return DbCmdAddClassInterface.values(
      entityId: entityId,
      index: index,
      interfaceId: entity.interfaces[index],
      dataColumnsByTable: getDataColumnsByTable(dbModel: dbModel, interfaceEntity: interfaceEntity),
    );
  }
}
