import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/settings/generators_view.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/app_local_storage.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_project_settings.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/auth_list_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:path/path.dart' as path;

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  SettingsViewState createState() => SettingsViewState();
}

class SettingsViewState extends ConsumerState<SettingsView> {
  late final TextEditingController _loginTextController;
  late final TextEditingController _secretTextController;
  TextEditingController? _authPathController;
  TextEditingController? _outputPathController;
  TextEditingController? _historyPathController;
  TextEditingController? _appFilesPathController;
  final FocusNode _appFilesPathFocusNode = FocusNode();
  String _resolvedAppFilesPath = '';
  bool _isAppFilesPathValid = true;

  TextEditingController? _appFilesPathExcludeRegexController;
  final FocusNode _appFilesPathExcludeRegexFocusNode = FocusNode();
  bool _isAppFilesPathExcludeRegexValid = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loginTextController = TextEditingController();
    _secretTextController = TextEditingController();
  }

  @override
  void dispose() {
    _loginTextController.dispose();
    _secretTextController.dispose();
    _appFilesPathController?.dispose();
    _appFilesPathFocusNode.dispose();
    _appFilesPathExcludeRegexController?.dispose();
    _appFilesPathExcludeRegexFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(clientStateProvider).state.model;
    final authListState = ref.watch(authListStateProvider).state;
    ref.watch(styleStateProvider);

    if (!_initialized) {
      _initialized = true;
      providerContainer.read(authListStateProvider).readFromFile();
    }

    final tz = model.settings.timeZone;
    final timezoneController = TextEditingController(text: Utils.floatWithSign(tz));
    final timezoneFocusNode = FocusNode();
    timezoneFocusNode.addListener(() => _handleTimezoneFocus(timezoneFocusNode, timezoneController));

    final saveDelayController = TextEditingController(text: model.settings.saveDelay.toString());
    final saveDelayFocusNode = FocusNode();
    saveDelayFocusNode.addListener(() => _handleSaveDelayFocus(saveDelayFocusNode, saveDelayController));

    final outputPathController = TextEditingController(text: model.settings.outputPath ?? './${Config.newOutputListDefaultName}');
    _outputPathController = outputPathController;

    final historyPathController = TextEditingController(text: model.settings.historyPath ?? './${Config.newHistoryListDefaultName}');
    _historyPathController = historyPathController;

    final authPathController = TextEditingController(text: model.settings.authPath ?? './${Config.newAuthListDefaultName}');
    _authPathController = authPathController;

    if (_appFilesPathController == null) {
      _appFilesPathController = TextEditingController(text: model.settings.appFilesPath);
      _computeAppFilesPathValidation(model.settings.appFilesPath);
    } else {
      final dbValue = model.settings.appFilesPath;
      if (dbValue != _appFilesPathController!.text && !_appFilesPathFocusNode.hasFocus) {
        _appFilesPathController!.text = dbValue;
        _computeAppFilesPathValidation(dbValue);
      }
    }

    if (_appFilesPathExcludeRegexController == null) {
      _appFilesPathExcludeRegexController = TextEditingController(text: model.settings.appFilesPathExcludeRegex);
      _computeAppFilesPathExcludeRegexValidation(model.settings.appFilesPathExcludeRegex);
    } else {
      final dbValue = model.settings.appFilesPathExcludeRegex;
      if (dbValue != _appFilesPathExcludeRegexController!.text && !_appFilesPathExcludeRegexFocusNode.hasFocus) {
        _appFilesPathExcludeRegexController!.text = dbValue;
        _computeAppFilesPathExcludeRegexValidation(dbValue);
      }
    }

    final users = authListState.loginListData?.users.entries.toList() ?? [];

    _loginTextController.text = AppLocalStorage.instance.newLogin ?? Config.defaultNewLogin;
    _secretTextController.text = AppLocalStorage.instance.newSecret ?? Config.defaultNewSecret;

    return Container(
      width: 1100 * kScale,
      height: 860 * kScale,
      color: kTextColorLightest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            alignment: Alignment.center,
            height: 50 * kScale,
            color: kColorAccentBlue2,
            child: Text(
              Loc.get.projectSettingsTitle,
              style: kStyle.kTextBig,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20 * kScale),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            Loc.get.projectSettingsSaveDelay,
                            style: kStyle.kTextRegular.copyWith(color: kTextColorDark),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: saveDelayController,
                            decoration: kStyle.kInputTextStyleSettingsProperties,
                            inputFormatters: Config.filterCellTypeFloat,
                            focusNode: saveDelayFocusNode,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            Loc.get.projectSettingsTimezoneTitle,
                            style: kStyle.kTextRegular.copyWith(color: kTextColorDark),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: timezoneController,
                            decoration: kStyle.kInputTextStyleSettingsProperties,
                            inputFormatters: Config.filterTimeZone,
                            focusNode: timezoneFocusNode,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * kScale),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            Loc.get.outputPath,
                            style: kStyle.kTextRegular.copyWith(color: kTextColorDark),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: kCardBorder,
                            child: TextField(
                              controller: outputPathController,
                              decoration: kStyle.kInputTextStyleSettingsProperties,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        TooltipWrapper(
                          message: 'save',
                          child: IconButtonTransparent(
                            size: 30 * kScale,
                            icon: Icon(
                              FontAwesomeIcons.floppyDisk,
                              size: 12 * kScale,
                              color: kColorAccentBlue,
                            ),
                            onClick: _handleOutputPathSave,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5 * kScale),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            Loc.get.historyPath,
                            style: kStyle.kTextRegular.copyWith(color: kTextColorDark),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: kCardBorder,
                            child: TextField(
                              controller: historyPathController,
                              decoration: kStyle.kInputTextStyleSettingsProperties,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        TooltipWrapper(
                          message: 'save',
                          child: IconButtonTransparent(
                            size: 30 * kScale,
                            icon: Icon(
                              FontAwesomeIcons.floppyDisk,
                              size: 12 * kScale,
                              color: kColorAccentBlue,
                            ),
                            onClick: _handleHistoryPathSave,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5 * kScale),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            Loc.get.authListPath,
                            style: kStyle.kTextRegular.copyWith(color: kTextColorDark),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: kCardBorder,
                            child: TextField(
                              controller: authPathController,
                              decoration: kStyle.kInputTextStyleSettingsProperties,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        TooltipWrapper(
                          message: 'save',
                          child: IconButtonTransparent(
                            size: 30 * kScale,
                            icon: Icon(
                              FontAwesomeIcons.floppyDisk,
                              size: 12 * kScale,
                              color: kColorAccentBlue,
                            ),
                            onClick: _handleAuthPathSave,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5 * kScale),
                    Row(
                       children: [
                         Expanded(
                           flex: 4,
                           child: Text(
                             Loc.get.appFilesPath,
                             style: kStyle.kTextRegular.copyWith(color: kTextColorDark),
                           ),
                         ),
                         Expanded(
                           flex: 3,
                           child: TooltipWrapper(
                             message: Loc.get.appFilesPathTooltip(_resolvedAppFilesPath),
                             child: ClipRRect(
                               borderRadius: kCardBorder,
                               child: TextField(
                                 controller: _appFilesPathController,
                                 focusNode: _appFilesPathFocusNode,
                                 decoration: kStyle.kInputTextStyleSettingsProperties.copyWith(
                                   fillColor: _isAppFilesPathValid ? null : kColorAccentRed.withOpacity(0.15),
                                   focusColor: _isAppFilesPathValid ? null : kColorAccentRed.withOpacity(0.15),
                                   hoverColor: _isAppFilesPathValid ? null : kColorAccentRed.withOpacity(0.15),
                                 ),
                                 textAlign: TextAlign.left,
                                 onChanged: _handleAppFilesPathChanged,
                               ),
                             ),
                           ),
                         ),
                         TooltipWrapper(
                           message: 'save',
                           child: IconButtonTransparent(
                             size: 30 * kScale,
                             enabled: _isAppFilesPathValid,
                             icon: Icon(
                               FontAwesomeIcons.floppyDisk,
                               size: 12 * kScale,
                               color: _isAppFilesPathValid ? kColorAccentBlue : kColorAccentBlue.withOpacity(0.3),
                             ),
                             onClick: _handleAppFilesPathSave,
                           ),
                         ),
                       ],
                    ),
                    SizedBox(height: 5 * kScale),
                    Row(
                       children: [
                         Expanded(
                           flex: 4,
                           child: Text(
                             Loc.get.appFilesPathExcludeRegex,
                             style: kStyle.kTextRegular.copyWith(color: kTextColorDark),
                           ),
                         ),
                         Expanded(
                           flex: 3,
                           child: TooltipWrapper(
                             message: Loc.get.appFilesPathExcludeRegexTooltip,
                             child: ClipRRect(
                               borderRadius: kCardBorder,
                               child: TextField(
                                 controller: _appFilesPathExcludeRegexController,
                                 focusNode: _appFilesPathExcludeRegexFocusNode,
                                 decoration: kStyle.kInputTextStyleSettingsProperties.copyWith(
                                   fillColor: _isAppFilesPathExcludeRegexValid ? null : kColorAccentRed.withOpacity(0.15),
                                   focusColor: _isAppFilesPathExcludeRegexValid ? null : kColorAccentRed.withOpacity(0.15),
                                   hoverColor: _isAppFilesPathExcludeRegexValid ? null : kColorAccentRed.withOpacity(0.15),
                                 ),
                                 textAlign: TextAlign.left,
                                 onChanged: _handleAppFilesPathExcludeRegexChanged,
                               ),
                             ),
                           ),
                         ),
                         TooltipWrapper(
                           message: 'save',
                           child: IconButtonTransparent(
                             size: 30 * kScale,
                             enabled: _isAppFilesPathExcludeRegexValid,
                             icon: Icon(
                               FontAwesomeIcons.floppyDisk,
                               size: 12 * kScale,
                               color: _isAppFilesPathExcludeRegexValid ? kColorAccentBlue : kColorAccentBlue.withOpacity(0.3),
                             ),
                             onClick: _handleAppFilesPathExcludeRegexSave,
                           ),
                         ),
                       ],
                    ),
                    SizedBox(height: 10 * kScale),
                    const Divider(height: 1),
                    SizedBox(height: 10 * kScale),
                    Container(
                      color: kTextColorLight,
                      width: 9999,
                      height: 229 * kScale,
                      child: Padding(
                        padding: EdgeInsets.all(8.0 * kScale),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 30 * kScale,
                              child: Row(
                                children: [
                                  Text(
                                    'Registered users',
                                    style: kStyle.kTextRegular.copyWith(color: kColorTextButton),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _loginTextController,
                                    decoration: kStyle.kInputTextStyleSettingsProperties.copyWith(
                                      hintText: Loc.get.newLoginHint,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 7 * kScale, vertical: 13 * kScale),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10 * kScale),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _secretTextController,
                                    decoration: kStyle.kInputTextStyleSettingsProperties.copyWith(
                                      hintText: Loc.get.newSecretHint,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 7 * kScale, vertical: 13 * kScale),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10 * kScale),
                                TooltipWrapper(
                                  message: Loc.get.buttonRegisterNewLogin,
                                  child: IconButtonTransparent(
                                    size: 35 * kScale,
                                    icon: Icon(
                                      FontAwesomeIcons.plus,
                                      size: 14 * kScale,
                                      color: kColorAccentBlue,
                                    ),
                                    onClick: _handleRegisterLoginClick,
                                  ),
                                ),
                              ],
                            ),
                            if (users.isNotEmpty) ...[
                              SizedBox(height: 8 * kScale),
                              Expanded(
                                child: ScrollConfiguration(
                                  behavior: kScrollDraggable,
                                  child: ListView.builder(
                                    scrollDirection: Axis.vertical,
                                    itemCount: users.length,
                                    itemBuilder: (context, index) {
                                      final user = users[index];
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 4 * kScale),
                                        child: Container(
                                          height: 30 * kScale,
                                          color: kTextColorLightest,
                                          child: Padding(
                                            padding: EdgeInsets.only(left: 5 * kScale, right: 8 * kScale),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    user.key,
                                                    style: kStyle.kTextExtraSmall.copyWith(color: kTextColorDark),
                                                  ),
                                                ),
                                                TooltipWrapper(
                                                  message: Loc.get.buttonUnregisterLogin,
                                                  child: IconButtonTransparent(
                                                    size: 28 * kScale,
                                                    icon: Icon(
                                                      FontAwesomeIcons.trashCan,
                                                      size: 12 * kScale,
                                                      color: kColorAccentRed,
                                                    ),
                                                    onClick: () => _handleRemoveUser(user.key),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10 * kScale),
                    GeneratorsView(
                      key: ValueKey(ref.watch(clientStateProvider).state.version),
                    ),
                    SizedBox(height: 10 * kScale),
                    TooltipWrapper(
                      message: Loc.get.autoGenerateEnumValuesTooltip,
                      child: SizedBox(
                        height: 30 * kScale,
                        child: Row(
                          children: [
                            kStyle.wrapCheckbox(
                              Checkbox(
                                value: model.settings.autoGenerateEnumValues,
                                onChanged: (val) {
                                  providerContainer.read(clientOwnCommandsStateProvider).addCommand(
                                        DbCmdEditProjectSettings.values(
                                          autoGenerateEnumValues: val ?? false,
                                        ),
                                      );
                                },
                              ),
                            ),
                            Text(
                              Loc.get.autoGenerateEnumValues,
                              style: kStyle.kTextRegular.copyWith(color: kTextColorDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRegisterLoginClick() {
    final authPathString = _authPathController?.text;
    if (authPathString != null) {
      final projectFile = providerContainer.read(appStateProvider).state.projectFile;
      if (projectFile != null) {
        final projectDir = path.dirname(projectFile.path);
        const defaultPath = './${Config.newAuthListDefaultName}';
        final resolved = authPathString == defaultPath ? path.join(projectDir, Config.newAuthListDefaultName) : path.join(projectDir, authPathString);
        providerContainer.read(authListStateProvider).setPath(resolved);
      }
    }

    providerContainer.read(authListStateProvider).registerNewLogin(_loginTextController.text, _secretTextController.text);
    AppLocalStorage.instance.newLogin = _loginTextController.text;
    AppLocalStorage.instance.newSecret = _secretTextController.text;
  }

  void _handleRemoveUser(String login) {
    providerContainer.read(authListStateProvider).removeLogin(login);
  }

  void _handleTimezoneFocus(FocusNode focus, TextEditingController textComponent) {
    if (focus.hasFocus) //
      return;

    final match = Config.validTimezoneFormat.firstMatch(textComponent.text);
    if (match == null) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Invalid timezone. Valid format example "+1.5"'));
      providerContainer.read(clientStateProvider).dispatchChange();
      return;
    }

    final value = textComponent.text.replaceAll('+', '');
    final newTimezone = double.parse(value);

    if (newTimezone == clientModel.settings.timeZone) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditProjectSettings.values(
            timezone: newTimezone,
          ),
        );
  }

  void _handleSaveDelayFocus(FocusNode focus, TextEditingController textComponent) {
    if (focus.hasFocus) //
      return;

    final value = textComponent.text;
    final match = Config.validCharactersForCellTypeFloat.firstMatch(value);
    if (match == null || double.tryParse(value) == null) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Invalid float value. Valid format example "2.0"'));
      providerContainer.read(clientStateProvider).dispatchChange();
      return;
    }

    final newSaveDelay = double.parse(value);

    if (newSaveDelay == clientModel.settings.saveDelay) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditProjectSettings.values(
            saveDelay: newSaveDelay,
          ),
        );
  }

  void _handleOutputPathSave() {
    final rawValue = _outputPathController?.text;
    if (rawValue == null) //
      return;

    const defaultValue = './${Config.newOutputListDefaultName}';
    final value = rawValue.trim().isEmpty ? defaultValue : rawValue;
    final modelValue = value == defaultValue ? '' : value;

    if (modelValue.isEmpty && clientModel.settings.outputPath == null) //
      return;
    if (modelValue.isNotEmpty && modelValue == clientModel.settings.outputPath) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditProjectSettings.values(
            outputPath: modelValue,
          ),
        );
  }

  void _handleHistoryPathSave() {
    final rawValue = _historyPathController?.text;
    if (rawValue == null) //
      return;

    const defaultValue = './${Config.newHistoryListDefaultName}';
    final value = rawValue.trim().isEmpty ? defaultValue : rawValue;
    final modelValue = value == defaultValue ? '' : value;

    if (modelValue.isEmpty && clientModel.settings.historyPath == null) //
      return;
    if (modelValue.isNotEmpty && modelValue == clientModel.settings.historyPath) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditProjectSettings.values(
            historyPath: modelValue,
          ),
        );
  }

  void _handleAuthPathSave() {
    final projectFile = providerContainer.read(appStateProvider).state.projectFile;
    if (projectFile == null) //
      return;

    final projectDir = path.dirname(projectFile.path);
    final rawValue = _authPathController?.text;
    if (rawValue == null) //
      return;

    const defaultValue = './${Config.newAuthListDefaultName}';
    final value = rawValue.trim().isEmpty ? defaultValue : rawValue;
    final relPath = value == defaultValue ? Config.newAuthListDefaultName : value;
    final newPath = path.join(projectDir, relPath);

    final currentPath = providerContainer.read(authListStateProvider).state.filePath;
    if (currentPath != newPath) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Auth file path changed to "$newPath"'));
      providerContainer.read(authListStateProvider).renameFile(newPath);
    }

    final modelValue = value == defaultValue ? '' : value;
    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditProjectSettings.values(
            authPath: modelValue,
          ),
        );
  }

  void _computeAppFilesPathValidation(String value) {
    final projectFile = providerContainer.read(appStateProvider).state.projectFile;
    if (projectFile == null) {
      _resolvedAppFilesPath = '';
      _isAppFilesPathValid = false;
      return;
    }
    final projectDir = path.dirname(projectFile.path);
    final rawPaths = value.trim().isEmpty ? <String>[] : value.split(RegExp(r'[;,]'));
    final List<String> resolvedPaths = [];
    bool allExist = true;
    for (final rawPath in rawPaths) {
      final trimmed = rawPath.trim();
      if (trimmed.isEmpty) continue;
      final resolved = path.normalize(path.absolute(path.join(projectDir, trimmed)));
      resolvedPaths.add(resolved);
      if (!Directory(resolved).existsSync()) {
        allExist = false;
      }
    }
    _resolvedAppFilesPath = resolvedPaths.isEmpty ? 'No paths specified (scanning disabled)' : resolvedPaths.join('\n');
    _isAppFilesPathValid = allExist;
  }

  void _handleAppFilesPathChanged(String value) {
    setState(() {
      _computeAppFilesPathValidation(value);
    });
  }

  void _handleAppFilesPathSave() {
    final rawValue = _appFilesPathController?.text;
    if (rawValue == null) return;

    final value = rawValue.trim();
    if (value == clientModel.settings.appFilesPath) return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditProjectSettings.values(
            appFilesPath: value,
          ),
        );
  }

  void _computeAppFilesPathExcludeRegexValidation(String value) {
    if (value.isEmpty) {
      _isAppFilesPathExcludeRegexValid = true;
      return;
    }
    try {
      RegExp(value);
      _isAppFilesPathExcludeRegexValid = true;
    } catch (_) {
      _isAppFilesPathExcludeRegexValid = false;
    }
  }

  void _handleAppFilesPathExcludeRegexChanged(String value) {
    setState(() {
      _computeAppFilesPathExcludeRegexValidation(value);
    });
  }

  void _handleAppFilesPathExcludeRegexSave() {
    final rawValue = _appFilesPathExcludeRegexController?.text;
    if (rawValue == null) return;

    final value = rawValue.trim();
    if (value == clientModel.settings.appFilesPathExcludeRegex) return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditProjectSettings.values(
            appFilesPathExcludeRegex: value,
          ),
        );
  }
}
