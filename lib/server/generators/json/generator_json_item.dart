import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generator_json_item.g.dart';

@JsonSerializable()
class GeneratorJsonItem {
  String id = '';
  Map<String, DataTableCellValue> values = {};

  GeneratorJsonItem();

  factory GeneratorJsonItem.fromJson(Map<String, dynamic> json) => _$GeneratorJsonItemFromJson(json);
  Map<String, dynamic> toJson() => _$GeneratorJsonItemToJson(this);
}
