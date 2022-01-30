import 'package:json_annotation/json_annotation.dart';

import 'generator_json_item_list.dart';

part 'generator_json_root.g.dart';

@JsonSerializable()
class GeneratorJsonRoot {
  late String date = '';
  late String user = '';
  late Map<String, GeneratorJsonItemList> classes = {};

  GeneratorJsonRoot();

  factory GeneratorJsonRoot.fromJson(Map<String, dynamic> json) => _$GeneratorJsonRootFromJson(json);
  Map<String, dynamic> toJson() => _$GeneratorJsonRootToJson(this);
}
