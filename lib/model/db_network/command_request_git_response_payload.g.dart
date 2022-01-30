// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_request_git_response_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommandRequestGitResponsePayload _$CommandRequestGitResponsePayloadFromJson(
        Map<String, dynamic> json) =>
    CommandRequestGitResponsePayload()
      ..items = (json['items'] as List<dynamic>?)
          ?.map((e) => GitItemData.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$CommandRequestGitResponsePayloadToJson(
    CommandRequestGitResponsePayload instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('items', instance.items?.map((e) => e.toJson()).toList());
  return val;
}
