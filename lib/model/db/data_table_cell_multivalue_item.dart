import 'package:json_annotation/json_annotation.dart';

part 'data_table_cell_multivalue_item.g.dart';

@JsonSerializable()
class DataTableCellMultiValueItem {
  @JsonKey(name: 'vs')
  List<dynamic>? values;

  DataTableCellMultiValueItem();
  DataTableCellMultiValueItem.values({required this.values});

  DataTableCellMultiValueItem copy() {
    return DataTableCellMultiValueItem.values(
      values: values?.toList(),
    );
  }

  factory DataTableCellMultiValueItem.fromJson(Map<String, dynamic> json) => _$DataTableCellMultiValueItemFromJson(json);
  Map<String, dynamic> toJson() => _$DataTableCellMultiValueItemToJson(this);
}
