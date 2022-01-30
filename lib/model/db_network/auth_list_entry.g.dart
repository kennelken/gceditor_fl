// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_list_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthListEntry _$AuthListEntryFromJson(Map<String, dynamic> json) =>
    AuthListEntry()
      ..login = json['login'] as String
      ..secret = json['secret'] as String
      ..salt = json['salt'] as String
      ..passwordHash = json['passwordHash'] as String?;

Map<String, dynamic> _$AuthListEntryToJson(AuthListEntry instance) {
  final val = <String, dynamic>{
    'login': instance.login,
    'secret': instance.secret,
    'salt': instance.salt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('passwordHash', instance.passwordHash);
  return val;
}
