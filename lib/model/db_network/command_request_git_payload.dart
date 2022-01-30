import 'package:json_annotation/json_annotation.dart';

part 'command_request_git_payload.g.dart';

@JsonSerializable()
class CommandRequestGitPayload {
  bool? refresh;
  bool? commit;
  bool? push;
  bool? pull;
  List<String>? items;

  CommandRequestGitPayload();
  CommandRequestGitPayload.values({
    this.refresh,
    this.commit,
    this.push,
    this.pull,
    this.items,
  });

  factory CommandRequestGitPayload.fromJson(Map<String, dynamic> json) => _$CommandRequestGitPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$CommandRequestGitPayloadToJson(this);
}
