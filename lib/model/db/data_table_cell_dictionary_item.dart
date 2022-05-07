import 'package:json_annotation/json_annotation.dart';

part 'data_table_cell_dictionary_item.g.dart';

@JsonSerializable()
class DataTableCellDictionaryItem {
  @JsonKey(name: 'k')
  dynamic key;
  @JsonKey(name: 'v')
  dynamic value;

  DataTableCellDictionaryItem();
  DataTableCellDictionaryItem.values({required this.key, required this.value});

  DataTableCellDictionaryItem copy() {
    return DataTableCellDictionaryItem.values(
      key: key,
      value: value,
    );
  }

  factory DataTableCellDictionaryItem.fromJson(Map<String, dynamic> json) => _$DataTableCellDictionaryItemFromJson(json);
  Map<String, dynamic> toJson() => _$DataTableCellDictionaryItemToJson(this);
}
