// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_table_cell_list_inline_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataTableCellListInlineItem _$DataTableCellListInlineItemFromJson(Map<String, dynamic> json) =>
    DataTableCellListInlineItem()..values = json['vs'] as List<dynamic>?;

Map<String, dynamic> _$DataTableCellListInlineItemToJson(DataTableCellListInlineItem instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('vs', instance.values);
  return val;
}
