import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:json_annotation/json_annotation.dart';

import '../db/class_meta_entity.dart';
import 'base_db_cmd.dart';
import 'common_class_interface_command.dart';
import 'db_cmd_result.dart';

part 'db_cmd_edit_class_interface.g.dart';

@JsonSerializable()
class DbCmdEditClassInterface extends BaseDbCmd with CommonClassInterfaceCommand {
  late String entityId;
  late int index;
  late String? interfaceId;
  Map<String, List<DataTableColumn>>? dataColumnsByTable;

  DbCmdEditClassInterface.values({
    String? id,
    required this.entityId,
    required this.index,
    required this.interfaceId,
    this.dataColumnsByTable,
  }) : super.withId(id) {
    $type = DbCmdType.editClassInterface;
  }

  DbCmdEditClassInterface();

  factory DbCmdEditClassInterface.fromJson(Map<String, dynamic> json) => _$DbCmdEditClassInterfaceFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdEditClassInterfaceToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass<ClassMetaEntity>(entityId)!;

    entity.interfaces[index] = interfaceId;
    dbModel.cache.invalidate();

    executeEdit(
      dbModel: dbModel,
      entity: entity,
      interfaceId: interfaceId,
      dataColumnsByTable: dataColumnsByTable,
    );

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final sharedResult = validateEdit(
      dbModel: dbModel,
      entityId: entityId,
      index: index,
      interfaceId: interfaceId,
      dataColumnsByTable: dataColumnsByTable,
    );
    if (!sharedResult.success) //
      return sharedResult;

    final entity = dbModel.cache.getClass<ClassMetaEntity>(entityId)!;

    if (index < 0 || index >= entity.interfaces.length) //
      return DbCmdResult.fail('index "$index" is out of bounds');

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final entity = dbModel.cache.getClass<ClassMetaEntity>(entityId)!;

    final interfaceId = entity.interfaces[index];
    final interfaceEntity = dbModel.cache.getClass<ClassMetaEntity>(interfaceId);

    return DbCmdEditClassInterface.values(
      entityId: entityId,
      index: index,
      interfaceId: interfaceId,
      dataColumnsByTable: getDataColumnsByTable(dbModel: dbModel, interfaceEntity: interfaceEntity),
    );
  }
}
