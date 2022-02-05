// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_table_cell_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataTableCellValue _$DataTableCellValueFromJson(Map<String, dynamic> json) =>
    DataTableCellValue()
      ..simpleValue = json['v']
      ..listCellValues = json['lv'] as List<dynamic>?
      ..dictionaryCellValues = (json['dv'] as List<dynamic>?)
          ?.map((e) =>
              DataTableCellDictionaryItem.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$DataTableCellValueToJson(DataTableCellValue instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('v', instance.simpleValue);
  writeNotNull('lv', instance.listCellValues);
  writeNotNull(
      'dv', instance.dictionaryCellValues?.map((e) => e.toJson()).toList());
  return val;
}
