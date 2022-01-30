import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enum_value.g.dart';

@JsonSerializable()
class EnumValue implements IIdentifiable, IDescribable {
  @override
  String id = '';
  @override
  String description = '';

  EnumValue();

  factory EnumValue.fromJson(Map<String, dynamic> json) => _$EnumValueFromJson(json);
  Map<String, dynamic> toJson() => _$EnumValueToJson(this);
}
