import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:json_annotation/json_annotation.dart';

part 'class_meta_group.g.dart';

@JsonSerializable()
class ClassMetaGroup extends ClassMeta with MetaGroup<ClassMeta> implements IMetaGroup<ClassMeta> {
  @JsonKey(toJson: ClassMeta.encodeEntries, fromJson: ClassMeta.decodeEntries)
  @override
  List<ClassMeta> entries = <ClassMeta>[];

  ClassMetaGroup() {
    $type = ClassMetaType.$group;
  }

  factory ClassMetaGroup.fromJson(Map<String, dynamic> json) => _$ClassMetaGroupFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ClassMetaGroupToJson(this);
}
