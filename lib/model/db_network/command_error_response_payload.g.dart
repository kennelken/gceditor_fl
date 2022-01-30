// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_error_response_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommandErrorResponsePayload _$CommandErrorResponsePayloadFromJson(
        Map<String, dynamic> json) =>
    CommandErrorResponsePayload()
      ..message = json['message'] as String?
      ..model = json['model'] == null
          ? null
          : DbModel.fromJson(json['model'] as Map<String, dynamic>);

Map<String, dynamic> _$CommandErrorResponsePayloadToJson(
    CommandErrorResponsePayload instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  writeNotNull('model', instance.model?.toJson());
  return val;
}
