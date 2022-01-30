// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentification_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthentificationData _$AuthentificationDataFromJson(
        Map<String, dynamic> json) =>
    AuthentificationData()
      ..login = json['login'] as String
      ..secret = json['secret'] as String
      ..password = json['password'] as String;

Map<String, dynamic> _$AuthentificationDataToJson(
        AuthentificationData instance) =>
    <String, dynamic>{
      'login': instance.login,
      'secret': instance.secret,
      'password': instance.password,
    };
