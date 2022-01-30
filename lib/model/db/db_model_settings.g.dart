// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_model_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbModelSettings _$DbModelSettingsFromJson(Map<String, dynamic> json) =>
    DbModelSettings()
      ..timeZone = (json['timeZone'] as num).toDouble()
      ..saveDelay = (json['saveDelay'] as num?)?.toDouble() ?? 2.0
      ..generators =
          BaseGenerator.decodeGenerators(json['generators'] as List?);

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
  return val;
}
