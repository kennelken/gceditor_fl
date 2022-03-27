import 'package:json_annotation/json_annotation.dart';

part 'authentication_data.g.dart';

@JsonSerializable()
class AuthenticationData {
  String login = '';
  String secret = '';
  String password = '';

  AuthenticationData();

  AuthenticationData.values({
    required this.login,
    required this.secret,
    required this.password,
  });

  factory AuthenticationData.fromJson(Map<String, dynamic> json) => _$AuthenticationDataFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticationDataToJson(this);
}
