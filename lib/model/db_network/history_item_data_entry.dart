import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:json_annotation/json_annotation.dart';

part 'history_item_data_entry.g.dart';

@JsonSerializable()
class HistoryItemDataEntry {
  late final String id;
  @JsonKey(toJson: BaseDbCmd.encode, fromJson: BaseDbCmd.decode)
  late final BaseDbCmd command;
  late final DateTime time;
  late final String user;

  HistoryItemDataEntry.values({
    required this.id,
    required this.command,
    required this.time,
    required this.user,
  });
  HistoryItemDataEntry();

  factory HistoryItemDataEntry.fromJson(Map<String, dynamic> json) => _$HistoryItemDataEntryFromJson(json);
  Map<String, dynamic> toJson() => _$HistoryItemDataEntryToJson(this);
}
