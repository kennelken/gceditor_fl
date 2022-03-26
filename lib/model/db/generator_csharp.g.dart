// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generator_csharp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratorCsharp _$GeneratorCsharpFromJson(Map<String, dynamic> json) =>
    GeneratorCsharp()
      ..$type = $enumDecodeNullable(_$GeneratorTypeEnumMap, json[r'$type'])
      ..fileName = json['fileName'] as String
      ..fileExtension = json['fileExtension'] as String
      ..prefix = json['prefix'] as String
      ..prefixInterface = json['prefixInterface'] as String
      ..postfix = json['postfix'] as String;

Map<String, dynamic> _$GeneratorCsharpToJson(GeneratorCsharp instance) {
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
  val['prefixInterface'] = instance.prefixInterface;
  val['postfix'] = instance.postfix;
  return val;
}

const _$GeneratorTypeEnumMap = {
  GeneratorType.undefined: 'undefined',
  GeneratorType.json: 'json',
  GeneratorType.csharp: 'csharp',
};
