// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_request_history_execute_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommandRequestHistoryExecutePayload
    _$CommandRequestHistoryExecutePayloadFromJson(Map<String, dynamic> json) =>
        CommandRequestHistoryExecutePayload()
          ..items = (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  HistoryItemDataEntry.fromJson(e as Map<String, dynamic>))
              .toList();

Map<String, dynamic> _$CommandRequestHistoryExecutePayloadToJson(
    CommandRequestHistoryExecutePayload instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('items', instance.items?.map((e) => e.toJson()).toList());
  return val;
}
