// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enum_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnumValue _$EnumValueFromJson(Map<String, dynamic> json) => EnumValue()
  ..id = json['id'] as String
  ..description = json['description'] as String
  ..fullPath = json['fullPath'] as String?;

Map<String, dynamic> _$EnumValueToJson(EnumValue instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'description': instance.description,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('fullPath', instance.fullPath);
  return val;
}
