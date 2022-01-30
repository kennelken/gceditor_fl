import 'package:gceditor/model/db/data_table_cell_dictionary_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'data_table_cell_value.g.dart';

@JsonSerializable()
class DataTableCellValue {
  @JsonKey(includeIfNull: false, defaultValue: null)
  dynamic simpleValue;
  @JsonKey(includeIfNull: false)
  List<dynamic>? listCellValues;
  @JsonKey(includeIfNull: false)
  List<DataTableCellDictionaryItem>? dictionaryCellValues;

  DataTableCellValue();

  DataTableCellValue.simple(dynamic value) {
    simpleValue = value;
  }

  DataTableCellValue.list(List<dynamic> value) {
    listCellValues = value;
  }

  DataTableCellValue.dictionary(List<DataTableCellDictionaryItem> value) {
    dictionaryCellValues = value;
  }

  DataTableCellValue copy() {
    return DataTableCellValue()
      ..simpleValue = simpleValue
      ..listCellValues = listCellValues?.toList()
      ..dictionaryCellValues = dictionaryCellValues?.map((e) => e.copy()).toList();
  }

  factory DataTableCellValue.fromJson(Map<String, dynamic> json) => _$DataTableCellValueFromJson(json);
  Map<String, dynamic> toJson() => _$DataTableCellValueToJson(this);
}
