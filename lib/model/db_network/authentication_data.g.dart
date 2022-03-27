// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticationData _$AuthenticationDataFromJson(Map<String, dynamic> json) =>
    AuthenticationData()
      ..login = json['login'] as String
      ..secret = json['secret'] as String
      ..password = json['password'] as String;

Map<String, dynamic> _$AuthenticationDataToJson(AuthenticationData instance) =>
    <String, dynamic>{
      'login': instance.login,
      'secret': instance.secret,
      'password': instance.password,
    };
