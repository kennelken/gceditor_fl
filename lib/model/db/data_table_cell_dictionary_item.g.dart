// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_table_cell_dictionary_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataTableCellDictionaryItem _$DataTableCellDictionaryItemFromJson(
        Map<String, dynamic> json) =>
    DataTableCellDictionaryItem()
      ..key = json['k']
      ..value = json['v'];

Map<String, dynamic> _$DataTableCellDictionaryItemToJson(
    DataTableCellDictionaryItem instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('k', instance.key);
  writeNotNull('v', instance.value);
  return val;
}
