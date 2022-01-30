import 'package:json_annotation/json_annotation.dart';

import 'get_item_data.dart';

part 'command_request_git_response_payload.g.dart';

@JsonSerializable()
class CommandRequestGitResponsePayload {
  List<GitItemData>? items;

  CommandRequestGitResponsePayload();
  CommandRequestGitResponsePayload.values({
    required this.items,
  });

  factory CommandRequestGitResponsePayload.fromJson(Map<String, dynamic> json) => _$CommandRequestGitResponsePayloadFromJson(json);
  Map<String, dynamic> toJson() => _$CommandRequestGitResponsePayloadToJson(this);
}
