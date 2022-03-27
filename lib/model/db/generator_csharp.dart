import 'package:gceditor/consts/config.dart';
import 'package:json_annotation/json_annotation.dart';

import 'db_model_shared.dart';

part 'generator_csharp.g.dart';

@JsonSerializable()
class GeneratorCsharp extends BaseGenerator {
  @JsonKey(defaultValue: Config.defaultGeneratorCsharpNamespace)
  String namespace = Config.defaultGeneratorCsharpNamespace;

  @JsonKey(defaultValue: Config.defaultGeneratorCsharpPrefix)
  String prefix = Config.defaultGeneratorCsharpPrefix;

  @JsonKey(defaultValue: Config.defaultGeneratorCsharpPrefixInterface)
  String prefixInterface = Config.defaultGeneratorCsharpPrefixInterface;

  @JsonKey(defaultValue: Config.defaultGeneratorCsharpPostfix)
  String postfix = Config.defaultGeneratorCsharpPostfix;

  GeneratorCsharp() {
    $type = GeneratorType.csharp;
  }

  factory GeneratorCsharp.fromJson(Map<String, dynamic> json) => _$GeneratorCsharpFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$GeneratorCsharpToJson(this);
}
