import 'package:json_annotation/json_annotation.dart';

import 'db_model_shared.dart';
import 'generator_csharp.dart';

part 'generator_java.g.dart';

@JsonSerializable()
class GeneratorJava extends GeneratorCsharp {
  GeneratorJava() {
    $type = GeneratorType.java;
  }

  factory GeneratorJava.fromJson(Map<String, dynamic> json) => _$GeneratorJavaFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$GeneratorJavaToJson(this);
}
