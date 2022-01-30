import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:json_annotation/json_annotation.dart';

part 'db_model_settings.g.dart';

@JsonSerializable()
class DbModelSettings {
  double timeZone = 0.0;
  @JsonKey(defaultValue: 2.0)
  double saveDelay = Config.defaultSaveDelay;
  @JsonKey(toJson: BaseGenerator.encodeGenerators, fromJson: BaseGenerator.decodeGenerators)
  List<BaseGenerator>? generators = [];

  DbModelSettings();

  Map<String, dynamic> toJson() => _$DbModelSettingsToJson(this);
  factory DbModelSettings.fromJson(Map<String, dynamic> json) => _$DbModelSettingsFromJson(json);
}
