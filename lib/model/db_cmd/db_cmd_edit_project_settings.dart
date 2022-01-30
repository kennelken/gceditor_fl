import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/generator_json.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_edit_project_settings.g.dart';

@JsonSerializable()
class DbCmdEditProjectSettings extends BaseDbCmd {
  double? timezone;
  double? saveDelay;
  @JsonKey(toJson: BaseGenerator.encodeGenerators, fromJson: BaseGenerator.decodeGenerators)
  List<BaseGenerator>? generators;

  DbCmdEditProjectSettings.values({
    String? id,
    this.timezone,
    this.saveDelay,
    this.generators,
  }) : super.withId(id) {
    $type = DbCmdType.editProjectSettings;
  }

  DbCmdEditProjectSettings();

  factory DbCmdEditProjectSettings.fromJson(Map<String, dynamic> json) => _$DbCmdEditProjectSettingsFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdEditProjectSettingsToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    if (timezone != null) //
      dbModel.settings.timeZone = timezone!;

    if (saveDelay != null) //
      dbModel.settings.saveDelay = saveDelay!;

    if (generators != null) dbModel.settings.generators = generators!;

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    if (timezone != null) {
      if (timezone! % 0.5 != 0) //
        return DbCmdResult.fail('Timezone should be multiple of 0.5');
    }

    if (saveDelay != null) {
      if (saveDelay! > Config.maxSaveDelay) //
        return DbCmdResult.fail('saveDelay is too big. it is not recommended to set it to value higher than "${Config.maxSaveDelay}" seconds');
    }

    if (generators != null) {
      for (var generator in generators!) {
        if (generator.fileName.length < Config.generatorMinFileNameLength) //
          return DbCmdResult.fail('Generator file name "${generator.fileName}" is too short');

        if (generator.fileExtension.length < Config.generatorMinFileExtensionLength) //
          return DbCmdResult.fail('Generator file extension "${generator.fileExtension}" is too short');

        if (generator is GeneratorJson) {
          if (Config.validIndentationForJson.allMatches(generator.indentation).length != generator.indentation.length) //
            return DbCmdResult.fail('Incorrect indentation value');
        }
      }
    }

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdEditProjectSettings.values(
      timezone: timezone != null ? dbModel.settings.timeZone : null,
      generators: generators != null ? BaseGenerator.decodeGenerators(BaseGenerator.encodeGenerators(dbModel.settings.generators)) : null,
    );
  }
}
