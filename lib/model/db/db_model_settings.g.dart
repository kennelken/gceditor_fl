// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_model_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbModelSettings _$DbModelSettingsFromJson(Map<String, dynamic> json) =>
    DbModelSettings()
      ..timeZone = (json['timeZone'] as num).toDouble()
      ..saveDelay = (json['saveDelay'] as num?)?.toDouble() ?? 2.0
      ..generators = BaseGenerator.decodeGenerators(json['generators'] as List?)
      ..autoGenerateEnumValues = json['autoGenerateEnumValues'] as bool? ?? true
      ..outputPath = json['outputPath'] as String?
      ..historyPath = json['historyPath'] as String?
      ..authPath = json['authPath'] as String?
      ..appFilesPath = json['appFilesPath'] as String? ?? '.'
      ..appFilesPathExcludeRegex = json['appFilesPathExcludeRegex'] as String? ?? r'(?:^|\/)\.[^.\/]';

Map<String, dynamic> _$DbModelSettingsToJson(DbModelSettings instance) {
  final val = <String, dynamic>{
    'timeZone': instance.timeZone,
    'saveDelay': instance.saveDelay,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'generators', BaseGenerator.encodeGenerators(instance.generators));
  val['autoGenerateEnumValues'] = instance.autoGenerateEnumValues;
  writeNotNull('outputPath', instance.outputPath);
  writeNotNull('historyPath', instance.historyPath);
  writeNotNull('authPath', instance.authPath);
  val['appFilesPath'] = instance.appFilesPath;
  val['appFilesPathExcludeRegex'] = instance.appFilesPathExcludeRegex;
  return val;
}
