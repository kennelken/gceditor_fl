// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_cmd_resize_column.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbCmdResizeColumn _$DbCmdResizeColumnFromJson(Map<String, dynamic> json) =>
    DbCmdResizeColumn()
      ..id = json['id'] as String
      ..$type = $enumDecodeNullable(_$DbCmdTypeEnumMap, json[r'$type'])
      ..tableId = json['tableId'] as String
      ..fieldId = json['fieldId'] as String?
      ..toResizeIds = json['toResizeIds'] as bool?
      ..width = (json['width'] as num).toDouble()
      ..oldWidth = (json['oldWidth'] as num).toDouble();

Map<String, dynamic> _$DbCmdResizeColumnToJson(DbCmdResizeColumn instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$DbCmdTypeEnumMap[instance.$type]);
  val['tableId'] = instance.tableId;
  writeNotNull('fieldId', instance.fieldId);
  writeNotNull('toResizeIds', instance.toResizeIds);
  val['width'] = instance.width;
  val['oldWidth'] = instance.oldWidth;
  return val;
}

const _$DbCmdTypeEnumMap = {
  DbCmdType.unknown: 'unknown',
  DbCmdType.addNewTable: 'addNewTable',
  DbCmdType.addNewClass: 'addNewClass',
  DbCmdType.addDataRow: 'addDataRow',
  DbCmdType.addEnumValue: 'addEnumValue',
  DbCmdType.addClassField: 'addClassField',
  DbCmdType.addClassInterface: 'addClassInterface',
  DbCmdType.deleteClass: 'deleteClass',
  DbCmdType.deleteTable: 'deleteTable',
  DbCmdType.deleteEnumValue: 'deleteEnumValue',
  DbCmdType.deleteClassField: 'deleteClassField',
  DbCmdType.deleteClassInterface: 'deleteClassInterface',
  DbCmdType.deleteDataRow: 'deleteDataRow',
  DbCmdType.editMetaEntityId: 'editMetaEntityId',
  DbCmdType.editMetaEntityDescription: 'editMetaEntityDescription',
  DbCmdType.editEnumValue: 'editEnumValue',
  DbCmdType.editClassField: 'editClassField',
  DbCmdType.editClassInterface: 'editClassInterface',
  DbCmdType.editClass: 'editClass',
  DbCmdType.editTable: 'editTable',
  DbCmdType.editTableRowId: 'editTableRowId',
  DbCmdType.editTableCellValue: 'editTableCellValue',
  DbCmdType.editProjectSettings: 'editProjectSettings',
  DbCmdType.reorderMetaEntity: 'reorderMetaEntity',
  DbCmdType.reorderEnum: 'reorderEnum',
  DbCmdType.reorderClassField: 'reorderClassField',
  DbCmdType.reorderClassInterface: 'reorderClassInterface',
  DbCmdType.reorderDataRow: 'reorderDataRow',
  DbCmdType.resizeColumn: 'resizeColumn',
  DbCmdType.resizeDictionaryKeyToValue: 'resizeDictionaryKeyToValue',
  DbCmdType.copypaste: 'copypaste',
};
