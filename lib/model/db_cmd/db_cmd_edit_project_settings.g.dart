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
      ..generators = BaseGenerator.decodeGenerators(json['generators'] as List?)
      ..autoGenerateEnumValues = json['autoGenerateEnumValues'] as bool?
      ..outputPath = json['outputPath'] as String?
      ..historyPath = json['historyPath'] as String?
      ..authPath = json['authPath'] as String?
      ..appFilesPath = json['appFilesPath'] as String?
      ..appFilesPathExcludeRegex = json['appFilesPathExcludeRegex'] as String?;

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
  writeNotNull('autoGenerateEnumValues', instance.autoGenerateEnumValues);
  writeNotNull('outputPath', instance.outputPath);
  writeNotNull('historyPath', instance.historyPath);
  writeNotNull('authPath', instance.authPath);
  writeNotNull('appFilesPath', instance.appFilesPath);
  writeNotNull('appFilesPathExcludeRegex', instance.appFilesPathExcludeRegex);
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
