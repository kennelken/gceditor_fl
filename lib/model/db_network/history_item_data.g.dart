// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_item_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HistoryItemData _$HistoryItemDataFromJson(Map<String, dynamic> json) =>
    HistoryItemData()
      ..id = json['id'] as String
      ..items = (json['items'] as List<dynamic>?)
          ?.map((e) => HistoryItemDataEntry.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$HistoryItemDataToJson(HistoryItemData instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('items', instance.items?.map((e) => e.toJson()).toList());
  return val;
}
