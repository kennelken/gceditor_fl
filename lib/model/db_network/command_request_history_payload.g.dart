// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_request_history_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommandRequestHistoryPayload _$CommandRequestHistoryPayloadFromJson(
        Map<String, dynamic> json) =>
    CommandRequestHistoryPayload()
      ..refresh = json['refresh'] as bool?
      ..items =
          (json['items'] as List<dynamic>?)?.map((e) => e as String).toList();

Map<String, dynamic> _$CommandRequestHistoryPayloadToJson(
    CommandRequestHistoryPayload instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('refresh', instance.refresh);
  writeNotNull('items', instance.items);
  return val;
}
