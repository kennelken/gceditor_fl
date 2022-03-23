import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_cmd/common_class_interface_command.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:json_annotation/json_annotation.dart';

import '../db/class_meta_entity.dart';
import 'base_db_cmd.dart';
import 'db_cmd_delete_class_interface.dart';
import 'db_cmd_result.dart';

part 'db_cmd_add_class_interface.g.dart';

@JsonSerializable()
class DbCmdAddClassInterface extends BaseDbCmd with CommonClassInterfaceCommand {
  late String entityId;
  late int index;
  late String? interfaceId;

  Map<String, List<DataTableColumn>>? dataColumnsByTable;

  DbCmdAddClassInterface.values({
    String? id,
    required this.entityId,
    required this.index,
    required this.interfaceId,
    this.dataColumnsByTable,
  }) : super.withId(id) {
    $type = DbCmdType.addClassInterface;
  }

  DbCmdAddClassInterface();

  factory DbCmdAddClassInterface.fromJson(Map<String, dynamic> json) => _$DbCmdAddClassInterfaceFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdAddClassInterfaceToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass<ClassMetaEntity>(entityId)!;

    executeEdit(
      dbModel: dbModel,
      entity: entity,
      interfaceId: interfaceId,
      valuesByTable: dataColumnsByTable,
      interfaceIndex: index,
      insert: true,
      delete: false,
    );

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final sharedResult = validateEdit(
      dbModel: dbModel,
      entityId: entityId,
      index: -1,
      interfaceId: interfaceId,
      dataColumnsByTable: dataColumnsByTable,
    );
    if (!sharedResult.success) //
      return sharedResult;

    final entity = dbModel.cache.getClass<ClassMetaEntity>(entityId);
    if (entity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (index < 0 || index > entity.interfaces.length) //
      return DbCmdResult.fail('invalid index "$index"');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdDeleteClassInterface.values(
      entityId: entityId,
      index: index,
    );
  }
}
