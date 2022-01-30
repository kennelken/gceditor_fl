import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'data_table_column.g.dart';

@JsonSerializable()
class DataTableColumn {
  String id = '';
  List<DataTableCellValue> values = <DataTableCellValue>[];

  DataTableColumn();
  DataTableColumn.data(this.id, this.values);

  factory DataTableColumn.fromJson(Map<String, dynamic> json) => _$DataTableColumnFromJson(json);
  Map<String, dynamic> toJson() => _$DataTableColumnToJson(this);
}
