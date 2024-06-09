// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_meta_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassMetaEntity _$ClassMetaEntityFromJson(Map<String, dynamic> json) =>
    ClassMetaEntity()
      ..$type = $enumDecodeNullable(_$ClassMetaTypeEnumMap, json[r'$type'])
      ..id = json['id'] as String
      ..description = json['description'] as String
      ..parent = json['parent'] as String?
      ..classType = $enumDecode(_$ClassTypeEnumMap, json['classType'])
      ..exportList = json['exportList'] as bool?
      ..fields = (json['fields'] as List<dynamic>)
          .map((e) =>
              ClassMetaFieldDescription.fromJson(e as Map<String, dynamic>))
          .toList()
      ..interfaces = (json['interfaces'] as List<dynamic>?)
              ?.map((e) => e as String?)
              .toList() ??
          [];

Map<String, dynamic> _$ClassMetaEntityToJson(ClassMetaEntity instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$ClassMetaTypeEnumMap[instance.$type]);
  val['id'] = instance.id;
  val['description'] = instance.description;
  writeNotNull('parent', instance.parent);
  val['classType'] = _$ClassTypeEnumMap[instance.classType]!;
  writeNotNull('exportList', instance.exportList);
  val['fields'] = instance.fields.map((e) => e.toJson()).toList();
  val['interfaces'] = instance.interfaces;
  return val;
}

const _$ClassMetaTypeEnumMap = {
  ClassMetaType.undefined: 'undefined',
  ClassMetaType.$group: r'$group',
  ClassMetaType.$class: r'$class',
  ClassMetaType.$enum: r'$enum',
};

const _$ClassTypeEnumMap = {
  ClassType.undefined: 'undefined',
  ClassType.referenceType: 'referenceType',
  ClassType.valueType: 'valueType',
  ClassType.interface: 'interface',
};
