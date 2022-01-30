// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_state_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginListData _$LoginListDataFromJson(Map<String, dynamic> json) =>
    LoginListData()
      ..users = (json['users'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, AuthListEntry.fromJson(e as Map<String, dynamic>)),
      );

Map<String, dynamic> _$LoginListDataToJson(LoginListData instance) =>
    <String, dynamic>{
      'users': instance.users.map((k, e) => MapEntry(k, e.toJson())),
    };
