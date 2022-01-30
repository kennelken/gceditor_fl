import 'package:gceditor/model/db_network/history_item_data_entry.dart';
import 'package:json_annotation/json_annotation.dart';

part 'history_item_data.g.dart';

@JsonSerializable()
class HistoryItemData {
  late final String id;
  List<HistoryItemDataEntry>? items;

  HistoryItemData.values({
    required this.id,
    required this.items,
  });

  HistoryItemData();

  factory HistoryItemData.fromJson(Map<String, dynamic> json) => _$HistoryItemDataFromJson(json);
  Map<String, dynamic> toJson() => _$HistoryItemDataToJson(this);
}
