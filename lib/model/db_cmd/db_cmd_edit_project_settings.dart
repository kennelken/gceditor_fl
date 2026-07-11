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
  bool? autoGenerateEnumValues;
  String? outputPath;
  String? historyPath;
  String? authPath;
  String? appFilesPath;
  String? appFilesPathExcludeRegex;
  double? tooltipDelay;

  DbCmdEditProjectSettings.values({
    String? id,
    this.timezone,
    this.saveDelay,
    this.generators,
    this.autoGenerateEnumValues,
    this.outputPath,
    this.historyPath,
    this.authPath,
    this.appFilesPath,
    this.appFilesPathExcludeRegex,
    this.tooltipDelay,
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

    if (autoGenerateEnumValues != null) dbModel.settings.autoGenerateEnumValues = autoGenerateEnumValues!;

    if (outputPath != null) {
      if (outputPath!.isEmpty)
        dbModel.settings.outputPath = null;
      else
        dbModel.settings.outputPath = outputPath;
    }

    if (historyPath != null) {
      if (historyPath!.isEmpty)
        dbModel.settings.historyPath = null;
      else
        dbModel.settings.historyPath = historyPath;
    }

    if (authPath != null) {
      if (authPath!.isEmpty)
        dbModel.settings.authPath = null;
      else
        dbModel.settings.authPath = authPath;
    }

    if (appFilesPath != null) {
      dbModel.settings.appFilesPath = appFilesPath!;
    }

    if (appFilesPathExcludeRegex != null) {
      dbModel.settings.appFilesPathExcludeRegex = appFilesPathExcludeRegex!;
    }

    if (tooltipDelay != null) {
      dbModel.settings.tooltipDelay = tooltipDelay!;
    }

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

    if (tooltipDelay != null) {
      if (tooltipDelay! > Config.maxTooltipDelay) //
        return DbCmdResult.fail('tooltipDelay is too big. it is not recommended to set it to value higher than "${Config.maxTooltipDelay}" seconds');
    }

    if (appFilesPathExcludeRegex != null) {
      try {
        RegExp(appFilesPathExcludeRegex!);
      } catch (_) {
        return DbCmdResult.fail('Invalid exclude regex syntax');
      }
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
      autoGenerateEnumValues: autoGenerateEnumValues != null ? dbModel.settings.autoGenerateEnumValues : null,
      outputPath: outputPath != null ? dbModel.settings.outputPath : null,
      historyPath: historyPath != null ? dbModel.settings.historyPath : null,
      authPath: authPath != null ? dbModel.settings.authPath : null,
      appFilesPath: appFilesPath != null ? dbModel.settings.appFilesPath : null,
      appFilesPathExcludeRegex: appFilesPathExcludeRegex != null ? dbModel.settings.appFilesPathExcludeRegex : null,
      tooltipDelay: tooltipDelay != null ? dbModel.settings.tooltipDelay : null,
    );
  }
}
