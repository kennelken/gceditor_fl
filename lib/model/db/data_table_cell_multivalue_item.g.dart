// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_table_cell_multivalue_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataTableCellMultiValueItem _$DataTableCellMultiValueItemFromJson(
        Map<String, dynamic> json) =>
    DataTableCellMultiValueItem()..values = json['vs'] as List<dynamic>?;

Map<String, dynamic> _$DataTableCellMultiValueItemToJson(
    DataTableCellMultiValueItem instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('vs', instance.values);
  return val;
}
