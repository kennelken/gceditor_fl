// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_item_data_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HistoryItemDataEntry _$HistoryItemDataEntryFromJson(
        Map<String, dynamic> json) =>
    HistoryItemDataEntry()
      ..id = json['id'] as String
      ..command = BaseDbCmd.decode(json['command'])
      ..time = DateTime.parse(json['time'] as String)
      ..user = json['user'] as String;

Map<String, dynamic> _$HistoryItemDataEntryToJson(
        HistoryItemDataEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'command': BaseDbCmd.encode(instance.command),
      'time': instance.time.toIso8601String(),
      'user': instance.user,
    };
