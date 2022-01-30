import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:json_annotation/json_annotation.dart';

part 'table_meta_group.g.dart';

@JsonSerializable()
class TableMetaGroup extends TableMeta with MetaGroup<TableMeta> implements IMetaGroup<TableMeta> {
  @override
  @JsonKey(toJson: TableMeta.encodeEntries, fromJson: TableMeta.decodeEntries)
  List<TableMeta> entries = <TableMeta>[];

  TableMetaGroup() {
    $type = TableMetaType.$group;
  }

  factory TableMetaGroup.fromJson(Map<String, dynamic> json) => _$TableMetaGroupFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TableMetaGroupToJson(this);
}
