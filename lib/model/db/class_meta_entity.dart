import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:json_annotation/json_annotation.dart';

part 'class_meta_entity.g.dart';

@JsonSerializable()
class ClassMetaEntity extends ClassMeta {
  String? parent;
  ClassType classType = ClassType.referenceType;
  bool? exportList;
  List<ClassMetaFieldDescription> fields = <ClassMetaFieldDescription>[];

  ClassMetaEntity() {
    $type = ClassMetaType.$class;
  }

  factory ClassMetaEntity.fromJson(Map<String, dynamic> json) => _$ClassMetaEntityFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ClassMetaEntityToJson(this);
}
