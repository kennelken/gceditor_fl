import 'package:json_annotation/json_annotation.dart';

part 'authentification_data.g.dart';

@JsonSerializable()
class AuthentificationData {
  String login = '';
  String secret = '';
  String password = '';

  AuthentificationData();

  AuthentificationData.values({
    required this.login,
    required this.secret,
    required this.password,
  });

  factory AuthentificationData.fromJson(Map<String, dynamic> json) => _$AuthentificationDataFromJson(json);
  Map<String, dynamic> toJson() => _$AuthentificationDataToJson(this);
}
