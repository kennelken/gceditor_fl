import 'package:gceditor/model/db_network/history_item_data_entry.dart';
import 'package:json_annotation/json_annotation.dart';

part 'command_request_history_execute_payload.g.dart';

@JsonSerializable()
class CommandRequestHistoryExecutePayload {
  List<HistoryItemDataEntry>? items;

  CommandRequestHistoryExecutePayload();
  CommandRequestHistoryExecutePayload.values({
    required this.items,
  });

  factory CommandRequestHistoryExecutePayload.fromJson(Map<String, dynamic> json) => _$CommandRequestHistoryExecutePayloadFromJson(json);
  Map<String, dynamic> toJson() => _$CommandRequestHistoryExecutePayloadToJson(this);
}
