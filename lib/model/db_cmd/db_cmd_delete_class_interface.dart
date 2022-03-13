import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_delete_class_interface.g.dart';

@JsonSerializable()
class DbCmdDeleteClassInterface extends BaseDbCmd {
  late String entityId;
  late int index;
  late String? interfaceId;

  Map<String, DataTableColumn>? dataColumnsByTable;

  DbCmdDeleteClassInterface.values({
    String? id,
    required this.entityId,
    required this.index,
    required this.interfaceId,
    this.dataColumnsByTable,
  }) : super.withId(id) {
    $type = DbCmdType.addClassInterface;
  }

  DbCmdDeleteClassInterface();

  factory DbCmdDeleteClassInterface.fromJson(Map<String, dynamic> json) => _$DbCmdDeleteClassInterfaceFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdDeleteClassInterfaceToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdDeleteClassInterface.values(
      // TODO! replace with delete interface command
      entityId: entityId,
      index: index,
      interfaceId: interfaceId,
      dataColumnsByTable: dataColumnsByTable,
    );
  }
}
