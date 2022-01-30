// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_request_history_response_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommandRequestHistoryResponsePayload
    _$CommandRequestHistoryResponsePayloadFromJson(Map<String, dynamic> json) =>
        CommandRequestHistoryResponsePayload()
          ..items = (json['items'] as List<dynamic>?)
              ?.map((e) => HistoryItemData.fromJson(e as Map<String, dynamic>))
              .toList()
          ..currentTag = json['currentTag'] as String?;

Map<String, dynamic> _$CommandRequestHistoryResponsePayloadToJson(
    CommandRequestHistoryResponsePayload instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('items', instance.items?.map((e) => e.toJson()).toList());
  writeNotNull('currentTag', instance.currentTag);
  return val;
}
