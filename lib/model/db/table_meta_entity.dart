import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:json_annotation/json_annotation.dart';

part 'table_meta_entity.g.dart';

@JsonSerializable()
class TableMetaEntity extends TableMeta {
  String classId = '';
  double idsColumnWidth = 0;
  double? rowHeightMultiplier;
  bool? exportList;
  Map<String, double> columWidth = {};
  Map<String, List<double>> columnInnerCellFlex = {};

  List<DataTableRow> rows = <DataTableRow>[];

  TableMetaEntity() {
    $type = TableMetaType.$table;
  }

  factory TableMetaEntity.fromJson(Map<String, dynamic> json) => _$TableMetaEntityFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TableMetaEntityToJson(this);
}
