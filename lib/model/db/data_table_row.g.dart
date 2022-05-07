// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_table_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataTableRow _$DataTableRowFromJson(Map<String, dynamic> json) => DataTableRow()
  ..id = json['id'] as String
  ..values = (json['values'] as List<dynamic>)
      .map((e) => DataTableCellValue.fromJson(e))
      .toList();

Map<String, dynamic> _$DataTableRowToJson(DataTableRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'values': instance.values.map((e) => e.toJson()).toList(),
    };
