// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generator_json_root.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratorJsonRoot _$GeneratorJsonRootFromJson(Map<String, dynamic> json) =>
    GeneratorJsonRoot()
      ..generationDate = json['generationDate'] as String
      ..generationUser = json['generationUser'] as String
      ..tables = (json['tables'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => e as Map<String, dynamic>)
                .toList()),
      )
      ..pathByEnum = (json['pathByEnum'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, Map<String, String>.from(e as Map)),
      );

Map<String, dynamic> _$GeneratorJsonRootToJson(GeneratorJsonRoot instance) {
  final val = <String, dynamic>{
    'generationDate': instance.generationDate,
    'generationUser': instance.generationUser,
    'tables': instance.tables,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('pathByEnum', instance.pathByEnum);
  return val;
}
