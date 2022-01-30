import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:json_annotation/json_annotation.dart';

part 'data_table_row.g.dart';

@JsonSerializable()
class DataTableRow implements IIdentifiable {
  @override
  String id = '';
  List<DataTableCellValue> values = [];

  DataTableRow();

  factory DataTableRow.fromJson(Map<String, dynamic> json) => _$DataTableRowFromJson(json);
  Map<String, dynamic> toJson() => _$DataTableRowToJson(this);
}
