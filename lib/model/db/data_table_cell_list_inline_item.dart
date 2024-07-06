import 'package:json_annotation/json_annotation.dart';

part 'data_table_cell_list_inline_item.g.dart';

@JsonSerializable()
class DataTableCellListInlineItem {
  @JsonKey(name: 'vs')
  List<dynamic>? values;

  DataTableCellListInlineItem();
  DataTableCellListInlineItem.values({required this.values});

  DataTableCellListInlineItem copy() {
    return DataTableCellListInlineItem.values(
      values: values?.toList(),
    );
  }

  factory DataTableCellListInlineItem.fromJson(Map<String, dynamic> json) => _$DataTableCellListInlineItemFromJson(json);
  Map<String, dynamic> toJson() => _$DataTableCellListInlineItemToJson(this);
}
