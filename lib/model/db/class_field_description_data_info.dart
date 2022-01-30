import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:json_annotation/json_annotation.dart';

part 'class_field_description_data_info.g.dart';

@JsonSerializable()
class ClassFieldDescriptionDataInfo {
  ClassFieldType type = ClassFieldType.undefined;
  String? classId;

  ClassFieldDescriptionDataInfo.fromData({required this.type, this.classId});

  ClassFieldDescriptionDataInfo();

  factory ClassFieldDescriptionDataInfo.fromJson(Map<String, dynamic> json) => _$ClassFieldDescriptionDataInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ClassFieldDescriptionDataInfoToJson(this);
}
