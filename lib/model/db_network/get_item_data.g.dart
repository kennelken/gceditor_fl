// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_item_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GitItemData _$GitItemDataFromJson(Map<String, dynamic> json) => GitItemData()
  ..id = json['id'] as String
  ..name = json['name'] as String
  ..branchName = json['branchName'] as String
  ..type = $enumDecodeNullable(_$GitItemTypeEnumMap, json['type']);

Map<String, dynamic> _$GitItemDataToJson(GitItemData instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'branchName': instance.branchName,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('type', _$GitItemTypeEnumMap[instance.type]);
  return val;
}

const _$GitItemTypeEnumMap = {
  GitItemType.undefined: 'undefined',
  GitItemType.project: 'project',
  GitItemType.authList: 'authList',
  GitItemType.generator: 'generator',
  GitItemType.history: 'history',
};
