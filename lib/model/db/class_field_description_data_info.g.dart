// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_field_description_data_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassFieldDescriptionDataInfo _$ClassFieldDescriptionDataInfoFromJson(
        Map<String, dynamic> json) =>
    ClassFieldDescriptionDataInfo()
      ..type = $enumDecode(_$ClassFieldTypeEnumMap, json['type'])
      ..classId = json['classId'] as String?;

Map<String, dynamic> _$ClassFieldDescriptionDataInfoToJson(
    ClassFieldDescriptionDataInfo instance) {
  final val = <String, dynamic>{
    'type': _$ClassFieldTypeEnumMap[instance.type]!,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('classId', instance.classId);
  return val;
}

const _$ClassFieldTypeEnumMap = {
  ClassFieldType.undefined: 'undefined',
  ClassFieldType.bool: 'bool',
  ClassFieldType.int: 'int',
  ClassFieldType.long: 'long',
  ClassFieldType.float: 'float',
  ClassFieldType.double: 'double',
  ClassFieldType.string: 'string',
  ClassFieldType.text: 'text',
  ClassFieldType.reference: 'reference',
  ClassFieldType.list: 'list',
  ClassFieldType.listInline: 'listInline',
  ClassFieldType.set: 'set',
  ClassFieldType.dictionary: 'dictionary',
  ClassFieldType.date: 'date',
  ClassFieldType.duration: 'duration',
  ClassFieldType.color: 'color',
  ClassFieldType.vector2: 'vector2',
  ClassFieldType.vector2Int: 'vector2Int',
  ClassFieldType.vector3: 'vector3',
  ClassFieldType.vector3Int: 'vector3Int',
  ClassFieldType.vector4: 'vector4',
  ClassFieldType.vector4Int: 'vector4Int',
  ClassFieldType.rectangle: 'rectangle',
  ClassFieldType.rectangleInt: 'rectangleInt',
};
