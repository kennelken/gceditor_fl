// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_meta_entity_enum.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassMetaEntityEnum _$ClassMetaEntityEnumFromJson(Map<String, dynamic> json) =>
    ClassMetaEntityEnum()
      ..$type = $enumDecodeNullable(_$ClassMetaTypeEnumMap, json[r'$type'])
      ..id = json['id'] as String
      ..description = json['description'] as String
      ..values = (json['values'] as List<dynamic>)
          .map((e) => EnumValue.fromJson(e as Map<String, dynamic>))
          .toList()
      ..valueColumnWidth = (json['valueColumnWidth'] as num).toDouble();

Map<String, dynamic> _$ClassMetaEntityEnumToJson(ClassMetaEntityEnum instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$ClassMetaTypeEnumMap[instance.$type]);
  val['id'] = instance.id;
  val['description'] = instance.description;
  val['values'] = instance.values.map((e) => e.toJson()).toList();
  val['valueColumnWidth'] = instance.valueColumnWidth;
  return val;
}

const _$ClassMetaTypeEnumMap = {
  ClassMetaType.undefined: 'undefined',
  ClassMetaType.$group: r'$group',
  ClassMetaType.$class: r'$class',
  ClassMetaType.$enum: r'$enum',
};
