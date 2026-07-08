import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'class_meta_entity_enum.g.dart';

@JsonSerializable()
class ClassMetaEntityEnum extends ClassMeta {
  List<EnumValue> values = <EnumValue>[];
  double valueColumnWidth = Config.enumColumnDefaultWidth;
  @JsonKey(defaultValue: false)
  bool autoByFile = false;
  @JsonKey(defaultValue: '')
  String filePathRegex = '';
  @JsonKey(defaultValue: '')
  String filePathRegexExclude = '';
  @JsonKey(defaultValue: '')
  String fileContentRegexInclude = '';
  @JsonKey(defaultValue: '')
  String fileContentRegexExclude = '';
  @JsonKey(defaultValue: '')
  String enumNameFromRegex = '';
  @JsonKey(defaultValue: '')
  String pathValueFromRegex = '';
  @JsonKey(defaultValue: false)
  bool autoByFileAutoRefresh = false;

  ClassMetaEntityEnum() {
    $type = ClassMetaType.$enum;
  }

  factory ClassMetaEntityEnum.fromJson(Map<String, dynamic> json) => _$ClassMetaEntityEnumFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ClassMetaEntityEnumToJson(this);
}
