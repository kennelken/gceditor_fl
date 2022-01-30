import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'auth_list_entry.g.dart';

@JsonSerializable()
class AuthListEntry {
  String login = '';
  String secret = '';
  String salt = '';
  String? passwordHash;

  AuthListEntry();

  AuthListEntry.newUser({required this.login, required this.secret}) {
    salt = const Uuid().v4();
  }

  factory AuthListEntry.fromJson(Map<String, dynamic> json) => _$AuthListEntryFromJson(json);
  Map<String, dynamic> toJson() => _$AuthListEntryToJson(this);
}
