// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_cmd_generate_enum_values_from_files.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbCmdGenerateEnumValuesFromFiles _$DbCmdGenerateEnumValuesFromFilesFromJson(
        Map<String, dynamic> json) =>
    DbCmdGenerateEnumValuesFromFiles()
      ..id = json['id'] as String
      ..$type = $enumDecodeNullable(_$DbCmdTypeEnumMap, json[r'$type'])
      ..entityId = json['entityId'] as String
      ..newValues = (json['newValues'] as List<dynamic>?)
          ?.map((e) => EnumValue.fromJson(e as Map<String, dynamic>))
          .toList()
      ..oldValues = (json['oldValues'] as List<dynamic>?)
          ?.map((e) => EnumValue.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$DbCmdGenerateEnumValuesFromFilesToJson(
    DbCmdGenerateEnumValuesFromFiles instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$DbCmdTypeEnumMap[instance.$type]);
  val['entityId'] = instance.entityId;
  writeNotNull(
      'newValues', instance.newValues?.map((e) => e.toJson()).toList());
  writeNotNull(
      'oldValues', instance.oldValues?.map((e) => e.toJson()).toList());
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
  DbCmdType.resizeInnerCell: 'resizeInnerCell',
  DbCmdType.copypaste: 'copypaste',
  DbCmdType.fillColumn: 'fillColumn',
  DbCmdType.editEnumFileSettings: 'editEnumFileSettings',
  DbCmdType.generateEnumValuesFromFiles: 'generateEnumValuesFromFiles',
};
