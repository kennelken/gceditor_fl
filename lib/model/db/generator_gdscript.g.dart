// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generator_gdscript.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratorGdscript _$GeneratorGdscriptFromJson(Map<String, dynamic> json) =>
    GeneratorGdscript()
      ..$type = $enumDecodeNullable(_$GeneratorTypeEnumMap, json[r'$type'])
      ..fileName = json['fileName'] as String
      ..fileExtension = json['fileExtension'] as String
      ..prefix = json['prefix'] as String? ?? 'Model'
      ..postfix = json['postfix'] as String? ?? '';

Map<String, dynamic> _$GeneratorGdscriptToJson(GeneratorGdscript instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$GeneratorTypeEnumMap[instance.$type]);
  val['fileName'] = instance.fileName;
  val['fileExtension'] = instance.fileExtension;
  val['prefix'] = instance.prefix;
  val['postfix'] = instance.postfix;
  return val;
}

const _$GeneratorTypeEnumMap = {
  GeneratorType.undefined: 'undefined',
  GeneratorType.json: 'json',
  GeneratorType.csharp: 'csharp',
  GeneratorType.java: 'java',
  GeneratorType.gdscript: 'gdscript',
  GeneratorType.rust: 'rust',
};
