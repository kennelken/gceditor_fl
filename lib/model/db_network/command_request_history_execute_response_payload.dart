import 'package:json_annotation/json_annotation.dart';

part 'command_request_history_execute_response_payload.g.dart';

@JsonSerializable()
class CommandRequestHistoryExecuteResponsePayload {
  List<bool>? results;
  List<String>? errors;

  CommandRequestHistoryExecuteResponsePayload();
  CommandRequestHistoryExecuteResponsePayload.values({
    required this.results,
    required this.errors,
  });

  factory CommandRequestHistoryExecuteResponsePayload.fromJson(Map<String, dynamic> json) =>
      _$CommandRequestHistoryExecuteResponsePayloadFromJson(json);
  Map<String, dynamic> toJson() => _$CommandRequestHistoryExecuteResponsePayloadToJson(this);
}
