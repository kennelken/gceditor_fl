import 'package:gceditor/consts/config.dart';
import 'package:json_annotation/json_annotation.dart';

import 'db_model_shared.dart';

part 'generator_json.g.dart';

@JsonSerializable()
class GeneratorJson extends BaseGenerator {
  String indentation = Config.defaultGeneratorJsonIndentation;

  GeneratorJson() {
    $type = GeneratorType.json;
  }

  factory GeneratorJson.fromJson(Map<String, dynamic> json) => _$GeneratorJsonFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$GeneratorJsonToJson(this);
}
