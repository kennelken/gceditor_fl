// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_table_cell_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataTableCellValue _$DataTableCellValueFromJson(Map<String, dynamic> json) =>
    DataTableCellValue()
      ..simpleValue = json['simpleValue']
      ..listCellValues = json['listCellValues'] as List<dynamic>?
      ..dictionaryCellValues = (json['dictionaryCellValues'] as List<dynamic>?)
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

  writeNotNull('simpleValue', instance.simpleValue);
  writeNotNull('listCellValues', instance.listCellValues);
  writeNotNull('dictionaryCellValues',
      instance.dictionaryCellValues?.map((e) => e.toJson()).toList());
  return val;
}
