import 'package:json_annotation/json_annotation.dart';

part 'db_cmd_result.g.dart';

@JsonSerializable()
class DbCmdResult {
  bool success = false;
  String? error;

  DbCmdResult();

  factory DbCmdResult.fail(String? error) {
    return DbCmdResult()
      ..success = false
      ..error = error ?? 'Error has occured';
  }

  factory DbCmdResult.success() {
    return DbCmdResult()
      ..success = true
      ..error = null;
  }

  factory DbCmdResult.fromJson(Map<String, dynamic> json) => _$DbCmdResultFromJson(json);
  Map<String, dynamic> toJson() => _$DbCmdResultToJson(this);
}
