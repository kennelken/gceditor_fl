// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generator_json_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratorJsonItem _$GeneratorJsonItemFromJson(Map<String, dynamic> json) =>
    GeneratorJsonItem()
      ..id = json['id'] as String
      ..values = (json['values'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, DataTableCellValue.fromJson(e)),
      );

Map<String, dynamic> _$GeneratorJsonItemToJson(GeneratorJsonItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'values': instance.values.map((k, e) => MapEntry(k, e.toJson())),
    };
