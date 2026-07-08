import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_cmd/db_cmd_result.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';

part 'db_cmd_edit_enum_file_settings.g.dart';

@JsonSerializable()
class DbCmdEditEnumFileSettings extends BaseDbCmd {
  late String entityId;
  bool? autoByFile;
  String? filePathRegex;
  String? filePathRegexExclude;
  String? fileContentRegexInclude;
  String? fileContentRegexExclude;
  String? enumNameFromRegex;
  String? pathValueFromRegex;
  bool? autoByFileAutoRefresh;

  // For undo
  bool? oldAutoByFile;
  String? oldFilePathRegex;
  String? oldFilePathRegexExclude;
  String? oldFileContentRegexInclude;
  String? oldFileContentRegexExclude;
  String? oldEnumNameFromRegex;
  String? oldPathValueFromRegex;
  bool? oldAutoByFileAutoRefresh;

  DbCmdEditEnumFileSettings.values({
    String? id,
    required this.entityId,
    this.autoByFile,
    this.filePathRegex,
    this.filePathRegexExclude,
    this.fileContentRegexInclude,
    this.fileContentRegexExclude,
    this.enumNameFromRegex,
    this.pathValueFromRegex,
    this.autoByFileAutoRefresh,
  }) : super.withId(id) {
    $type = DbCmdType.editEnumFileSettings;
  }

  DbCmdEditEnumFileSettings();

  factory DbCmdEditEnumFileSettings.fromJson(Map<String, dynamic> json) => _$DbCmdEditEnumFileSettingsFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdEditEnumFileSettingsToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId) as ClassMetaEntityEnum;

    oldAutoByFile = entity.autoByFile;
    oldFilePathRegex = entity.filePathRegex;
    oldFilePathRegexExclude = entity.filePathRegexExclude;
    oldFileContentRegexInclude = entity.fileContentRegexInclude;
    oldFileContentRegexExclude = entity.fileContentRegexExclude;
    oldEnumNameFromRegex = entity.enumNameFromRegex;
    oldPathValueFromRegex = entity.pathValueFromRegex;
    oldAutoByFileAutoRefresh = entity.autoByFileAutoRefresh;

    if (autoByFile != null) entity.autoByFile = autoByFile!;
    if (filePathRegex != null) entity.filePathRegex = filePathRegex!;
    if (filePathRegexExclude != null) entity.filePathRegexExclude = filePathRegexExclude!;
    if (fileContentRegexInclude != null) entity.fileContentRegexInclude = fileContentRegexInclude!;
    if (fileContentRegexExclude != null) entity.fileContentRegexExclude = fileContentRegexExclude!;
    if (enumNameFromRegex != null) entity.enumNameFromRegex = enumNameFromRegex!;
    if (pathValueFromRegex != null) entity.pathValueFromRegex = pathValueFromRegex!;
    if (autoByFileAutoRefresh != null) entity.autoByFileAutoRefresh = autoByFileAutoRefresh!;

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId);
    if (entity == null) {
      return DbCmdResult.fail('Entity "$entityId" not found');
    }
    if (entity is! ClassMetaEntityEnum) {
      return DbCmdResult.fail('Entity "$entityId" is not an enum');
    }
    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdEditEnumFileSettings.values(
      entityId: entityId,
      autoByFile: oldAutoByFile,
      filePathRegex: oldFilePathRegex,
      filePathRegexExclude: oldFilePathRegexExclude,
      fileContentRegexInclude: oldFileContentRegexInclude,
      fileContentRegexExclude: oldFileContentRegexExclude,
      enumNameFromRegex: oldEnumNameFromRegex,
      pathValueFromRegex: oldPathValueFromRegex,
      autoByFileAutoRefresh: oldAutoByFileAutoRefresh,
    );
  }
}
