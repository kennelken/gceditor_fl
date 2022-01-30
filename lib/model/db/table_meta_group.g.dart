// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_meta_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableMetaGroup _$TableMetaGroupFromJson(Map<String, dynamic> json) =>
    TableMetaGroup()
      ..$type = $enumDecodeNullable(_$TableMetaTypeEnumMap, json[r'$type'])
      ..id = json['id'] as String
      ..description = json['description'] as String
      ..entries = TableMeta.decodeEntries(json['entries'] as List);

Map<String, dynamic> _$TableMetaGroupToJson(TableMetaGroup instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$TableMetaTypeEnumMap[instance.$type]);
  val['id'] = instance.id;
  val['description'] = instance.description;
  writeNotNull('entries', TableMeta.encodeEntries(instance.entries));
  return val;
}

const _$TableMetaTypeEnumMap = {
  TableMetaType.undefined: 'undefined',
  TableMetaType.$group: r'$group',
  TableMetaType.$table: r'$table',
};
