// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_table_column_inline_values.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataTableColumnInlineValues _$DataTableColumnInlineValuesFromJson(
        Map<String, dynamic> json) =>
    DataTableColumnInlineValues()
      ..columnId = json['columnId'] as String
      ..values = (json['values'] as List<dynamic>)
          .map((e) => e as List<dynamic>)
          .toList();

Map<String, dynamic> _$DataTableColumnInlineValuesToJson(
        DataTableColumnInlineValues instance) =>
    <String, dynamic>{
      'columnId': instance.columnId,
      'values': instance.values,
    };
