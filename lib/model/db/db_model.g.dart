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

Map<String, dynamic> _$DbModelToJson(DbModel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('classes', ClassMeta.encodeEntries(instance.classes));
  writeNotNull('tables', TableMeta.encodeEntries(instance.tables));
  val['settings'] = instance.settings.toJson();
  return val;
}
