// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_table_column.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataTableColumn _$DataTableColumnFromJson(Map<String, dynamic> json) =>
    DataTableColumn()
      ..id = json['id'] as String
      ..values = (json['values'] as List<dynamic>)
          .map((e) => DataTableCellValue.fromJson(e))
          .toList();

Map<String, dynamic> _$DataTableColumnToJson(DataTableColumn instance) =>
    <String, dynamic>{
      'id': instance.id,
      'values': instance.values.map((e) => e.toJson()).toList(),
    };
