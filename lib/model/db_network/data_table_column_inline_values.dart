import 'package:json_annotation/json_annotation.dart';

part 'data_table_column_inline_values.g.dart';

@JsonSerializable()
class DataTableColumnInlineValues {
  String columnId = '';
  List<List<dynamic>> values = <List<dynamic>>[];

  DataTableColumnInlineValues();
  DataTableColumnInlineValues.data(this.columnId, this.values);

  factory DataTableColumnInlineValues.fromJson(Map<String, dynamic> json) => _$DataTableColumnInlineValuesFromJson(json);
  Map<String, dynamic> toJson() => _$DataTableColumnInlineValuesToJson(this);

  dynamic getValue(int rawIndex, int innerRowIndex) {
    return values[rawIndex][innerRowIndex]!;
  }
}
