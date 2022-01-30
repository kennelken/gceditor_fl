// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generator_json_root.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratorJsonRoot _$GeneratorJsonRootFromJson(Map<String, dynamic> json) =>
    GeneratorJsonRoot()
      ..date = json['date'] as String
      ..user = json['user'] as String
      ..classes = (json['classes'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, GeneratorJsonItemList.fromJson(e as Map<String, dynamic>)),
      );

Map<String, dynamic> _$GeneratorJsonRootToJson(GeneratorJsonRoot instance) =>
    <String, dynamic>{
      'date': instance.date,
      'user': instance.user,
      'classes': instance.classes.map((k, e) => MapEntry(k, e.toJson())),
    };
