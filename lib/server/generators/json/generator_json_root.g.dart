// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generator_json_root.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratorJsonRoot _$GeneratorJsonRootFromJson(Map<String, dynamic> json) =>
    GeneratorJsonRoot()
      ..generationDate = json['generationDate'] as String
      ..generationUser = json['generationUser'] as String
      ..records = (json['records'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => e as Map<String, dynamic>)
                .toList()),
      );

Map<String, dynamic> _$GeneratorJsonRootToJson(GeneratorJsonRoot instance) =>
    <String, dynamic>{
      'generationDate': instance.generationDate,
      'generationUser': instance.generationUser,
      'records': instance.records,
    };
