import 'package:gceditor/consts/config.dart';
import 'package:json_annotation/json_annotation.dart';

import 'db_model_shared.dart';

part 'generator_gdscript.g.dart';

@JsonSerializable()
class GeneratorGdscript extends BaseGenerator {
  @JsonKey(defaultValue: Config.defaultGeneratorGdscriptPrefix)
  String prefix = Config.defaultGeneratorGdscriptPrefix;

  @JsonKey(defaultValue: Config.defaultGeneratorGdscriptPostfix)
  String postfix = Config.defaultGeneratorGdscriptPostfix;

  GeneratorGdscript() {
    $type = GeneratorType.gdscript;
  }

  factory GeneratorGdscript.fromJson(Map<String, dynamic> json) => _$GeneratorGdscriptFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$GeneratorGdscriptToJson(this);
}
