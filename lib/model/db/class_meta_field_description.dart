import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:json_annotation/json_annotation.dart';

part 'class_meta_field_description.g.dart';

@JsonSerializable()
class ClassMetaFieldDescription implements IIdentifiable, IDescribable {
  @override
  String id = '';
  @override
  String description = '';
  bool isUniqueValue = false; //for simple data types only
  bool toExport = true;

  ClassFieldDescriptionDataInfo typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.int);
  ClassFieldDescriptionDataInfo? keyTypeInfo;
  ClassFieldDescriptionDataInfo? valueTypeInfo;
  String defaultValue = '';

  ClassMetaFieldDescription();

  factory ClassMetaFieldDescription.fromJson(Map<String, dynamic> json) => _$ClassMetaFieldDescriptionFromJson(json);
  Map<String, dynamic> toJson() => _$ClassMetaFieldDescriptionToJson(this);
}
