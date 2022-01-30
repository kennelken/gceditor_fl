// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_meta_field_description.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassMetaFieldDescription _$ClassMetaFieldDescriptionFromJson(
        Map<String, dynamic> json) =>
    ClassMetaFieldDescription()
      ..id = json['id'] as String
      ..description = json['description'] as String
      ..isUniqueValue = json['isUniqueValue'] as bool
      ..toExport = json['toExport'] as bool
      ..typeInfo = ClassFieldDescriptionDataInfo.fromJson(
          json['typeInfo'] as Map<String, dynamic>)
      ..keyTypeInfo = json['keyTypeInfo'] == null
          ? null
          : ClassFieldDescriptionDataInfo.fromJson(
              json['keyTypeInfo'] as Map<String, dynamic>)
      ..valueTypeInfo = json['valueTypeInfo'] == null
          ? null
          : ClassFieldDescriptionDataInfo.fromJson(
              json['valueTypeInfo'] as Map<String, dynamic>)
      ..defaultValue = json['defaultValue'] as String;

Map<String, dynamic> _$ClassMetaFieldDescriptionToJson(
    ClassMetaFieldDescription instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'description': instance.description,
    'isUniqueValue': instance.isUniqueValue,
    'toExport': instance.toExport,
    'typeInfo': instance.typeInfo.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('keyTypeInfo', instance.keyTypeInfo?.toJson());
  writeNotNull('valueTypeInfo', instance.valueTypeInfo?.toJson());
  val['defaultValue'] = instance.defaultValue;
  return val;
}
