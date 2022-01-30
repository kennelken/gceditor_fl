// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_cmd_add_new_class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbCmdAddNewClass _$DbCmdAddNewClassFromJson(Map<String, dynamic> json) =>
    DbCmdAddNewClass()
      ..id = json['id'] as String
      ..$type = $enumDecodeNullable(_$DbCmdTypeEnumMap, json[r'$type'])
      ..classMeta = ClassMeta.decode(json['classMeta'] as Map<String, dynamic>)
      ..parentId = json['parentId'] as String?
      ..index = json['index'] as int?;

Map<String, dynamic> _$DbCmdAddNewClassToJson(DbCmdAddNewClass instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$DbCmdTypeEnumMap[instance.$type]);
  writeNotNull('classMeta', ClassMeta.encode(instance.classMeta));
  writeNotNull('parentId', instance.parentId);
  writeNotNull('index', instance.index);
  return val;
}

const _$DbCmdTypeEnumMap = {
  DbCmdType.unknown: 'unknown',
  DbCmdType.addNewTable: 'addNewTable',
  DbCmdType.addNewClass: 'addNewClass',
  DbCmdType.addDataRow: 'addDataRow',
  DbCmdType.addEnumValue: 'addEnumValue',
  DbCmdType.addClassField: 'addClassField',
  DbCmdType.deleteClass: 'deleteClass',
  DbCmdType.deleteTable: 'deleteTable',
  DbCmdType.deleteEnumValue: 'deleteEnumValue',
  DbCmdType.deleteClassField: 'deleteClassField',
  DbCmdType.deleteDataRow: 'deleteDataRow',
  DbCmdType.editMetaEntityId: 'editMetaEntityId',
  DbCmdType.editMetaEntityDescription: 'editMetaEntityDescription',
  DbCmdType.editEnumValue: 'editEnumValue',
  DbCmdType.editClassField: 'editClassField',
  DbCmdType.editClass: 'editClass',
  DbCmdType.editTable: 'editTable',
  DbCmdType.editTableRowId: 'editTableRowId',
  DbCmdType.editTableCellValue: 'editTableCellValue',
  DbCmdType.editProjectSettings: 'editProjectSettings',
  DbCmdType.reorderMetaEntity: 'reorderMetaEntity',
  DbCmdType.reorderEnum: 'reorderEnum',
  DbCmdType.reorderClassField: 'reorderClassField',
  DbCmdType.reorderDataRow: 'reorderDataRow',
  DbCmdType.resizeColumn: 'resizeColumn',
  DbCmdType.resizeDictionaryKeyToValue: 'resizeDictionaryKeyToValue',
  DbCmdType.copypaste: 'copypaste',
};
