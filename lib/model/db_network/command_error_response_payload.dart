import 'package:gceditor/model/db/db_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'command_error_response_payload.g.dart';

@JsonSerializable()
class CommandErrorResponsePayload {
  late String? message;
  DbModel? model;

  CommandErrorResponsePayload();
  CommandErrorResponsePayload.values(this.message, this.model);

  factory CommandErrorResponsePayload.fromJson(Map<String, dynamic> json) => _$CommandErrorResponsePayloadFromJson(json);
  Map<String, dynamic> toJson() => _$CommandErrorResponsePayloadToJson(this);
}
