// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_request_git_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommandRequestGitPayload _$CommandRequestGitPayloadFromJson(
        Map<String, dynamic> json) =>
    CommandRequestGitPayload()
      ..refresh = json['refresh'] as bool?
      ..commit = json['commit'] as bool?
      ..push = json['push'] as bool?
      ..pull = json['pull'] as bool?
      ..items =
          (json['items'] as List<dynamic>?)?.map((e) => e as String).toList();

Map<String, dynamic> _$CommandRequestGitPayloadToJson(
    CommandRequestGitPayload instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('refresh', instance.refresh);
  writeNotNull('commit', instance.commit);
  writeNotNull('push', instance.push);
  writeNotNull('pull', instance.pull);
  writeNotNull('items', instance.items);
  return val;
}
