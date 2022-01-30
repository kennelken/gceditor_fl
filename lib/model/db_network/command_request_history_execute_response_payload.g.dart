// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_request_history_execute_response_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommandRequestHistoryExecuteResponsePayload
    _$CommandRequestHistoryExecuteResponsePayloadFromJson(
            Map<String, dynamic> json) =>
        CommandRequestHistoryExecuteResponsePayload()
          ..results = (json['results'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList()
          ..errors = (json['errors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList();

Map<String, dynamic> _$CommandRequestHistoryExecuteResponsePayloadToJson(
    CommandRequestHistoryExecuteResponsePayload instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('results', instance.results);
  writeNotNull('errors', instance.errors);
  return val;
}
