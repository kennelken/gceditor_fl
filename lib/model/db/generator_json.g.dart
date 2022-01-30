// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generator_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratorJson _$GeneratorJsonFromJson(Map<String, dynamic> json) =>
    GeneratorJson()
      ..$type = $enumDecodeNullable(_$GeneratorTypeEnumMap, json[r'$type'])
      ..fileName = json['fileName'] as String
      ..fileExtension = json['fileExtension'] as String
      ..indentation = json['indentation'] as String;

Map<String, dynamic> _$GeneratorJsonToJson(GeneratorJson instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$GeneratorTypeEnumMap[instance.$type]);
  val['fileName'] = instance.fileName;
  val['fileExtension'] = instance.fileExtension;
  val['indentation'] = instance.indentation;
  return val;
}

const _$GeneratorTypeEnumMap = {
  GeneratorType.undefined: 'undefined',
  GeneratorType.json: 'json',
  GeneratorType.csharp: 'csharp',
};
