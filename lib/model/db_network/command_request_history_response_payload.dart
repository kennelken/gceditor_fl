import 'package:gceditor/model/db_network/history_item_data.dart';
import 'package:json_annotation/json_annotation.dart';

part 'command_request_history_response_payload.g.dart';

@JsonSerializable()
class CommandRequestHistoryResponsePayload {
  List<HistoryItemData>? items;
  String? currentTag;

  CommandRequestHistoryResponsePayload();
  CommandRequestHistoryResponsePayload.values({
    required this.items,
    required this.currentTag,
  });

  factory CommandRequestHistoryResponsePayload.fromJson(Map<String, dynamic> json) => _$CommandRequestHistoryResponsePayloadFromJson(json);
  Map<String, dynamic> toJson() => _$CommandRequestHistoryResponsePayloadToJson(this);
}
