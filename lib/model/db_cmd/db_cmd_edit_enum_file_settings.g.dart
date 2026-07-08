// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_cmd_edit_enum_file_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbCmdEditEnumFileSettings _$DbCmdEditEnumFileSettingsFromJson(
        Map<String, dynamic> json) =>
    DbCmdEditEnumFileSettings()
      ..id = json['id'] as String
      ..$type = $enumDecodeNullable(_$DbCmdTypeEnumMap, json[r'$type'])
      ..entityId = json['entityId'] as String
      ..autoByFile = json['autoByFile'] as bool?
      ..filePathRegex = json['filePathRegex'] as String?
      ..filePathRegexExclude = json['filePathRegexExclude'] as String?
      ..fileContentRegexInclude = json['fileContentRegexInclude'] as String?
      ..fileContentRegexExclude = json['fileContentRegexExclude'] as String?
      ..enumNameFromRegex = json['enumNameFromRegex'] as String?
      ..pathValueFromRegex = json['pathValueFromRegex'] as String?
      ..autoByFileAutoRefresh = json['autoByFileAutoRefresh'] as bool?
      ..oldAutoByFile = json['oldAutoByFile'] as bool?
      ..oldFilePathRegex = json['oldFilePathRegex'] as String?
      ..oldFilePathRegexExclude = json['oldFilePathRegexExclude'] as String?
      ..oldFileContentRegexInclude =
          json['oldFileContentRegexInclude'] as String?
      ..oldFileContentRegexExclude =
          json['oldFileContentRegexExclude'] as String?
      ..oldEnumNameFromRegex = json['oldEnumNameFromRegex'] as String?
      ..oldPathValueFromRegex = json['oldPathValueFromRegex'] as String?
      ..oldAutoByFileAutoRefresh = json['oldAutoByFileAutoRefresh'] as bool?;

Map<String, dynamic> _$DbCmdEditEnumFileSettingsToJson(
    DbCmdEditEnumFileSettings instance) {
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
  writeNotNull('autoByFile', instance.autoByFile);
  writeNotNull('filePathRegex', instance.filePathRegex);
  writeNotNull('filePathRegexExclude', instance.filePathRegexExclude);
  writeNotNull('fileContentRegexInclude', instance.fileContentRegexInclude);
  writeNotNull('fileContentRegexExclude', instance.fileContentRegexExclude);
  writeNotNull('enumNameFromRegex', instance.enumNameFromRegex);
  writeNotNull('pathValueFromRegex', instance.pathValueFromRegex);
  writeNotNull('autoByFileAutoRefresh', instance.autoByFileAutoRefresh);
  writeNotNull('oldAutoByFile', instance.oldAutoByFile);
  writeNotNull('oldFilePathRegex', instance.oldFilePathRegex);
  writeNotNull('oldFilePathRegexExclude', instance.oldFilePathRegexExclude);
  writeNotNull(
      'oldFileContentRegexInclude', instance.oldFileContentRegexInclude);
  writeNotNull(
      'oldFileContentRegexExclude', instance.oldFileContentRegexExclude);
  writeNotNull('oldEnumNameFromRegex', instance.oldEnumNameFromRegex);
  writeNotNull('oldPathValueFromRegex', instance.oldPathValueFromRegex);
  writeNotNull('oldAutoByFileAutoRefresh', instance.oldAutoByFileAutoRefresh);
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
