// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_table_cell_dictionary_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataTableCellDictionaryItem _$DataTableCellDictionaryItemFromJson(
        Map<String, dynamic> json) =>
    DataTableCellDictionaryItem()
      ..key = json['key']
      ..value = json['value'];

Map<String, dynamic> _$DataTableCellDictionaryItemToJson(
    DataTableCellDictionaryItem instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('key', instance.key);
  writeNotNull('value', instance.value);
  return val;
}
