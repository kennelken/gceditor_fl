// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_meta_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassMetaGroup _$ClassMetaGroupFromJson(Map<String, dynamic> json) =>
    ClassMetaGroup()
      ..$type = $enumDecodeNullable(_$ClassMetaTypeEnumMap, json[r'$type'])
      ..id = json['id'] as String
      ..description = json['description'] as String
      ..entries = ClassMeta.decodeEntries(json['entries'] as List);

Map<String, dynamic> _$ClassMetaGroupToJson(ClassMetaGroup instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$ClassMetaTypeEnumMap[instance.$type]);
  val['id'] = instance.id;
  val['description'] = instance.description;
  writeNotNull('entries', ClassMeta.encodeEntries(instance.entries));
  return val;
}

const _$ClassMetaTypeEnumMap = {
  ClassMetaType.undefined: 'undefined',
  ClassMetaType.$group: r'$group',
  ClassMetaType.$class: r'$class',
  ClassMetaType.$enum: r'$enum',
};
