import 'package:json_annotation/json_annotation.dart';

part 'command_request_history_payload.g.dart';

@JsonSerializable()
class CommandRequestHistoryPayload {
  bool? refresh;
  List<String>? items;

  CommandRequestHistoryPayload();
  CommandRequestHistoryPayload.values({
    this.refresh,
    this.items,
  });

  factory CommandRequestHistoryPayload.fromJson(Map<String, dynamic> json) => _$CommandRequestHistoryPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$CommandRequestHistoryPayloadToJson(this);
}
