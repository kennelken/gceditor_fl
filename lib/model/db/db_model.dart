import 'package:gceditor/model/db/db_model_settings.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/state/db_model_cache.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

part 'db_model.g.dart';

@JsonSerializable()
class DbModel {
  @JsonKey(ignore: true)
  late final DbModelCache _cache = DbModelCache(this);
  @JsonKey(ignore: true)
  DbModelCache get cache => _cache;

  @JsonKey(toJson: ClassMeta.encodeEntries, fromJson: ClassMeta.decodeEntries)
  List<ClassMeta> classes = [];
  @JsonKey(toJson: TableMeta.encodeEntries, fromJson: TableMeta.decodeEntries)
  List<TableMeta> tables = [];
  DbModelSettings settings = DbModelSettings();

  DbModel();

  factory DbModel.fromJson(Map<String, dynamic> json) {
    final result = _$DbModelFromJson(json);
    DbModelUtils.specifyDataCellValues(result);
    return result;
  }
  Map<String, dynamic> toJson() => _$DbModelToJson(this);
}
