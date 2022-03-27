import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_class_field.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_class_interface.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_data_row.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_enum_value.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_new_class.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_new_table.dart';
import 'package:gceditor/model/db_cmd/db_cmd_copypaste.dart';
import 'package:gceditor/model/db_cmd/db_cmd_delete_class.dart';
import 'package:gceditor/model/db_cmd/db_cmd_delete_class_field.dart';
import 'package:gceditor/model/db_cmd/db_cmd_delete_data_row.dart';
import 'package:gceditor/model/db_cmd/db_cmd_delete_enum_value.dart';
import 'package:gceditor/model/db_cmd/db_cmd_delete_table.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_class.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_class_field.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_enum_value.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_meta_entity_description.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_meta_entity_id.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_project_settings.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_table.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_table_cell_value.dart';
import 'package:gceditor/model/db_cmd/db_cmd_fill_column.dart';
import 'package:gceditor/model/db_cmd/db_cmd_reorder_class_field.dart';
import 'package:gceditor/model/db_cmd/db_cmd_reorder_enum.dart';
import 'package:gceditor/model/db_cmd/db_cmd_reorder_meta_entity.dart';
import 'package:gceditor/model/db_cmd/db_cmd_resize_column.dart';
import 'package:gceditor/model/db_cmd/db_cmd_resize_dictionary_key_to_value.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import 'db_cmd_delete_class_interface.dart';
import 'db_cmd_edit_class_interface.dart';
import 'db_cmd_edit_table_row_id.dart';
import 'db_cmd_reorder_class_interface.dart';
import 'db_cmd_reorder_data_row.dart';
import 'db_cmd_result.dart';

abstract class BaseDbCmd {
  late final String id;
  DbCmdType? $type;

  BaseDbCmd();

  BaseDbCmd.withId([String? id]) {
    this.id = id ?? const Uuid().v4();
  }

  DbCmdResult execute(DbModel dbModel) {
    final validationResult = validate(dbModel);
    if (!validationResult.success) {
      return validationResult;
    }

    try {
      final result = doExecute(dbModel);
      if (result.success) //
        dbModel.cache.invalidate();

      return result;
    } catch (e, callstack) {
      return DbCmdResult.fail('${e.toString()}.\nclasstack: $callstack');
    }
  }

  @protected
  DbCmdResult doExecute(DbModel dbModel);
  DbCmdResult validate(DbModel dbModel);

  BaseDbCmd createUndoCmd(DbModel dbModel);

  Map<String, dynamic> toJson();

  static Map<String, dynamic> encode(BaseDbCmd element) {
    return element.toJson();
  }

  static BaseDbCmd decode(dynamic element) {
    final type = element['\$type'];
    final enumType = DbCmdType.values.firstWhereOrNull((e) => describeEnum(e) == type);

    switch (enumType) {
      case null:
      case DbCmdType.unknown:
        break;
      case DbCmdType.addNewTable:
        return DbCmdAddNewTable.fromJson(element);
      case DbCmdType.addNewClass:
        return DbCmdAddNewClass.fromJson(element);
      case DbCmdType.addDataRow:
        return DbCmdAddDataRow.fromJson(element);
      case DbCmdType.addEnumValue:
        return DbCmdAddEnumValue.fromJson(element);
      case DbCmdType.addClassField:
        return DbCmdAddClassField.fromJson(element);
      case DbCmdType.addClassInterface:
        return DbCmdAddClassInterface.fromJson(element);
      case DbCmdType.deleteClass:
        return DbCmdDeleteClass.fromJson(element);
      case DbCmdType.deleteTable:
        return DbCmdDeleteTable.fromJson(element);
      case DbCmdType.deleteEnumValue:
        return DbCmdDeleteEnumValue.fromJson(element);
      case DbCmdType.deleteClassField:
        return DbCmdDeleteClassField.fromJson(element);
      case DbCmdType.deleteClassInterface:
        return DbCmdDeleteClassInterface.fromJson(element);
      case DbCmdType.deleteDataRow:
        return DbCmdDeleteDataRow.fromJson(element);
      case DbCmdType.editMetaEntityId:
        return DbCmdEditMetaEntityId.fromJson(element);
      case DbCmdType.editMetaEntityDescription:
        return DbCmdEditMetaEntityDescription.fromJson(element);
      case DbCmdType.editEnumValue:
        return DbCmdEditEnumValue.fromJson(element);
      case DbCmdType.editClassField:
        return DbCmdEditClassField.fromJson(element);
      case DbCmdType.editClassInterface:
        return DbCmdEditClassInterface.fromJson(element);
      case DbCmdType.editClass:
        return DbCmdEditClass.fromJson(element);
      case DbCmdType.editTable:
        return DbCmdEditTable.fromJson(element);
      case DbCmdType.editTableRowId:
        return DbCmdEditTableRowId.fromJson(element);
      case DbCmdType.editTableCellValue:
        return DbCmdEditTableCellValue.fromJson(element);
      case DbCmdType.editProjectSettings:
        return DbCmdEditProjectSettings.fromJson(element);
      case DbCmdType.reorderMetaEntity:
        return DbCmdReorderMetaEntity.fromJson(element);
      case DbCmdType.reorderEnum:
        return DbCmdReorderEnum.fromJson(element);
      case DbCmdType.reorderClassField:
        return DbCmdReorderClassField.fromJson(element);
      case DbCmdType.reorderClassInterface:
        return DbCmdReorderClassInterface.fromJson(element);
      case DbCmdType.reorderDataRow:
        return DbCmdReorderDataRow.fromJson(element);
      case DbCmdType.resizeColumn:
        return DbCmdResizeColumn.fromJson(element);
      case DbCmdType.resizeDictionaryKeyToValue:
        return DbCmdResizeDictionaryKeyToValue.fromJson(element);
      case DbCmdType.copypaste:
        return DbCmdCopyPaste.fromJson(element);
      case DbCmdType.fillColumn:
        return DbCmdFillColumn.fromJson(element);
    }

    throw Exception('Can not decode command of type "$type"');
  }
}

@JsonEnum()
enum DbCmdType {
  unknown,
  addNewTable,
  addNewClass,
  addDataRow,
  addEnumValue,
  addClassField,
  addClassInterface,
  deleteClass,
  deleteTable,
  deleteEnumValue,
  deleteClassField,
  deleteClassInterface,
  deleteDataRow,
  editMetaEntityId,
  editMetaEntityDescription,
  editEnumValue,
  editClassField,
  editClassInterface,
  editClass,
  editTable,
  editTableRowId,
  editTableCellValue,
  editProjectSettings,
  reorderMetaEntity,
  reorderEnum,
  reorderClassField,
  reorderClassInterface,
  reorderDataRow,
  resizeColumn,
  resizeDictionaryKeyToValue,
  copypaste,
  fillColumn,
}
