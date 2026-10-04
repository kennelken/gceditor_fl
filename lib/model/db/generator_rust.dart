import 'package:gceditor/consts/config.dart';
import 'package:json_annotation/json_annotation.dart';

import 'db_model_shared.dart';

part 'generator_rust.g.dart';

@JsonSerializable()
class GeneratorRust extends BaseGenerator {
  @JsonKey(defaultValue: Config.defaultGeneratorRustPrefix)
  String prefix = Config.defaultGeneratorRustPrefix;

  @JsonKey(defaultValue: Config.defaultGeneratorRustPostfix)
  String postfix = Config.defaultGeneratorRustPostfix;

  @JsonKey(defaultValue: Config.defaultGeneratorRustGeometryClasses)
  String geometryClasses = Config.defaultGeneratorRustGeometryClasses;

  @JsonKey(defaultValue: Config.defaultGeneratorRustJsonSerializer)
  String jsonSerializer = Config.defaultGeneratorRustJsonSerializer;

  GeneratorRust() {
    $type = GeneratorType.rust;
  }

  factory GeneratorRust.fromJson(Map<String, dynamic> json) => _$GeneratorRustFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$GeneratorRustToJson(this);
}
