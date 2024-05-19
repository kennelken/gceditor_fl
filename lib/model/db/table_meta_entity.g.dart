// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_meta_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableMetaEntity _$TableMetaEntityFromJson(Map<String, dynamic> json) =>
    TableMetaEntity()
      ..$type = $enumDecodeNullable(_$TableMetaTypeEnumMap, json[r'$type'])
      ..id = json['id'] as String
      ..description = json['description'] as String
      ..classId = json['classId'] as String
      ..idsColumnWidth = (json['idsColumnWidth'] as num).toDouble()
      ..rowHeightMultiplier = (json['rowHeightMultiplier'] as num?)?.toDouble()
      ..exportList = json['exportList'] as bool?
      ..columWidth = (json['columWidth'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      )
      ..columnInnerCellFlex =
          (json['columnInnerCellFlex'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, (e as List<dynamic>).map((e) => (e as num).toDouble()).toList()),
      )
      ..rows = (json['rows'] as List<dynamic>)
          .map((e) => DataTableRow.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$TableMetaEntityToJson(TableMetaEntity instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$TableMetaTypeEnumMap[instance.$type]);
  val['id'] = instance.id;
  val['description'] = instance.description;
  val['classId'] = instance.classId;
  val['idsColumnWidth'] = instance.idsColumnWidth;
  writeNotNull('rowHeightMultiplier', instance.rowHeightMultiplier);
  writeNotNull('exportList', instance.exportList);
  val['columWidth'] = instance.columWidth;
  val['columnInnerCellFlex'] = instance.columnInnerCellFlex;
  val['rows'] = instance.rows.map((e) => e.toJson()).toList();
  return val;
}

const _$TableMetaTypeEnumMap = {
  TableMetaType.undefined: 'undefined',
  TableMetaType.$group: r'$group',
  TableMetaType.$table: r'$table',
};
