// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generator_json_item_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratorJsonItemList _$GeneratorJsonItemListFromJson(
        Map<String, dynamic> json) =>
    GeneratorJsonItemList()
      ..items = (json['items'] as List<dynamic>)
          .map((e) => GeneratorJsonItem.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$GeneratorJsonItemListToJson(
        GeneratorJsonItemList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
