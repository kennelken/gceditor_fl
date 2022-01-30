import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'class_meta_entity_enum.g.dart';

@JsonSerializable()
class ClassMetaEntityEnum extends ClassMeta {
  List<EnumValue> values = <EnumValue>[];
  double valueColumnWidth = Config.enumColumnDefaultWidth;

  ClassMetaEntityEnum() {
    $type = ClassMetaType.$enum;
  }

  factory ClassMetaEntityEnum.fromJson(Map<String, dynamic> json) => _$ClassMetaEntityEnumFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ClassMetaEntityEnumToJson(this);
}
