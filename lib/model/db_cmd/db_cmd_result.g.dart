// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_cmd_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbCmdResult _$DbCmdResultFromJson(Map<String, dynamic> json) => DbCmdResult()
  ..success = json['success'] as bool
  ..error = json['error'] as String?;

Map<String, dynamic> _$DbCmdResultToJson(DbCmdResult instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('error', instance.error);
  return val;
}
