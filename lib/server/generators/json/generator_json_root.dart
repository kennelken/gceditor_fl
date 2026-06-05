import 'package:json_annotation/json_annotation.dart';

part 'generator_json_root.g.dart';

@JsonSerializable()
class GeneratorJsonRoot {
  late String generationDate = '';
  late String generationUser = '';
  late Map<String, List<Map<String, dynamic>>> records = {};

  GeneratorJsonRoot();

  factory GeneratorJsonRoot.fromJson(Map<String, dynamic> json) => _$GeneratorJsonRootFromJson(json);
  Map<String, dynamic> toJson() => _$GeneratorJsonRootToJson(this);
}
