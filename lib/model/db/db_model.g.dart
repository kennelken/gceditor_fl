// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbModel _$DbModelFromJson(Map<String, dynamic> json) => DbModel()
  ..classes = ClassMeta.decodeEntries(json['classes'] as List)
  ..tables = TableMeta.decodeEntries(json['tables'] as List)
  ..settings =
      DbModelSettings.fromJson(json['settings'] as Map<String, dynamic>);

Map<String, dynamic> _$DbModelToJson(DbModel instance) => <String, dynamic>{
      'classes': ClassMeta.encodeEntries(instance.classes),
      'tables': TableMeta.encodeEntries(instance.tables),
      'settings': instance.settings.toJson(),
    };
