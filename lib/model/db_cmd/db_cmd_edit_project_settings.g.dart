// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_cmd_edit_project_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbCmdEditProjectSettings _$DbCmdEditProjectSettingsFromJson(
        Map<String, dynamic> json) =>
    DbCmdEditProjectSettings()
      ..id = json['id'] as String
      ..$type = $enumDecodeNullable(_$DbCmdTypeEnumMap, json[r'$type'])
      ..timezone = (json['timezone'] as num?)?.toDouble()
      ..saveDelay = (json['saveDelay'] as num?)?.toDouble()
      ..generators =
          BaseGenerator.decodeGenerators(json['generators'] as List?);

Map<String, dynamic> _$DbCmdEditProjectSettingsToJson(
    DbCmdEditProjectSettings instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$DbCmdTypeEnumMap[instance.$type]);
  writeNotNull('timezone', instance.timezone);
  writeNotNull('saveDelay', instance.saveDelay);
  writeNotNull(
      'generators', BaseGenerator.encodeGenerators(instance.generators));
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
