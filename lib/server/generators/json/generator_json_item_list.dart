import 'package:gceditor/server/generators/json/generator_json_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generator_json_item_list.g.dart';

@JsonSerializable()
class GeneratorJsonItemList {
  List<GeneratorJsonItem> items = [];

  GeneratorJsonItemList();

  factory GeneratorJsonItemList.fromJson(Map<String, dynamic> json) => _$GeneratorJsonItemListFromJson(json);
  Map<String, dynamic> toJson() => _$GeneratorJsonItemListToJson(this);
}
