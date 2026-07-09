import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/add_new_enum_value_button.dart';
import 'package:gceditor/components/properties/primitives/class_meta_properties_container.dart';
import 'package:gceditor/components/properties/primitives/enum_value_view.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/properties/primitives/property_string_view.dart';
import 'package:gceditor/components/properties/primitives/property_title.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_enum_value.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_enum_file_settings.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_meta_entity_description.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_meta_entity_id.dart';
import 'package:gceditor/model/db_cmd/db_cmd_generate_enum_values_from_files.dart';
import 'package:gceditor/model/db_cmd/db_cmd_reorder_enum.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';

class ClassMetaEnumPropertiesViewProperties extends StatefulWidget {
  final ClassMetaEntityEnum data;

  const ClassMetaEnumPropertiesViewProperties({
    super.key,
    required this.data,
  });

  @override
  State<ClassMetaEnumPropertiesViewProperties> createState() => _ClassMetaEnumPropertiesViewPropertiesState();
}

class _ClassMetaEnumPropertiesViewPropertiesState extends State<ClassMetaEnumPropertiesViewProperties> {
  late List<EnumValue> values;
  bool _showSettings = false;

  late final TextEditingController _filePathRegexController = TextEditingController();
  late final TextEditingController _filePathRegexExcludeController = TextEditingController();
  late final TextEditingController _fileContentRegexIncludeController = TextEditingController();
  late final TextEditingController _fileContentRegexExcludeController = TextEditingController();
  late final TextEditingController _enumNameFromRegexController = TextEditingController();
  late final TextEditingController _pathValueFromRegexController = TextEditingController();

  @override
  void initState() {
    super.initState();
    providerContainer.read(clientStateProvider).addListener(_handleClientStateChanges);
    _handleClientStateChanges(false);

    providerContainer.read(enumValueWidthRatioProvider).setValue(widget.data.valueColumnWidth, true);
  }

  @override
  void deactivate() {
    super.deactivate();
    providerContainer.read(clientStateProvider).removeListener(_handleClientStateChanges);
  }

  @override
  void didUpdateWidget(ClassMetaEnumPropertiesViewProperties oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.id != widget.data.id ||
        oldWidget.data.filePathRegex != widget.data.filePathRegex ||
        oldWidget.data.filePathRegexExclude != widget.data.filePathRegexExclude ||
        oldWidget.data.fileContentRegexInclude != widget.data.fileContentRegexInclude ||
        oldWidget.data.fileContentRegexExclude != widget.data.fileContentRegexExclude ||
        oldWidget.data.enumNameFromRegex != widget.data.enumNameFromRegex ||
        oldWidget.data.pathValueFromRegex != widget.data.pathValueFromRegex) {
      _initControllers();
    }
  }

  @override
  void dispose() {
    _filePathRegexController.dispose();
    _filePathRegexExcludeController.dispose();
    _fileContentRegexIncludeController.dispose();
    _fileContentRegexExcludeController.dispose();
    _enumNameFromRegexController.dispose();
    _pathValueFromRegexController.dispose();
    super.dispose();
  }

  void _initControllers() {
    _filePathRegexController.text = widget.data.filePathRegex;
    _filePathRegexExcludeController.text = widget.data.filePathRegexExclude;
    _fileContentRegexIncludeController.text = widget.data.fileContentRegexInclude;
    _fileContentRegexExcludeController.text = widget.data.fileContentRegexExclude;
    _enumNameFromRegexController.text = widget.data.enumNameFromRegex;
    _pathValueFromRegexController.text = widget.data.pathValueFromRegex;
  }

  void _handleClientStateChanges([bool toSetState = true]) {
    values = widget.data.values.toList();
    if (toSetState) {
      setState(() {
        _initControllers();
        providerContainer.read(enumValueWidthRatioProvider).setValue(widget.data.valueColumnWidth, true);
      });
    } else {
      _initControllers();
    }
  }

  bool _isRegExpPatternValid(String text, {required bool isMandatory}) {
    if (text.isEmpty) return !isMandatory;
    try {
      RegExp(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isPlaceholderTemplateValid(String text, {required bool isMandatory}) {
    if (text.isEmpty) return !isMandatory;
    final filePathRegex = _filePathRegexController.text;
    try {
      RegExp(filePathRegex);
      final groupCount = Utils.countCapturingGroups(filePathRegex);
      final matches = RegExp(r'\{(\d+)\}').allMatches(text);
      if (isMandatory && matches.isEmpty) return false;
      for (final match in matches) {
        final groupIndex = int.tryParse(match.group(1) ?? '');
        if (groupIndex == null || groupIndex < 0 || groupIndex > groupCount) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isEnumNameFromRegexValid() {
    return _isPlaceholderTemplateValid(_enumNameFromRegexController.text, isMandatory: true);
  }

  bool _isPathValueFromRegexValid() {
    return _isPlaceholderTemplateValid(_pathValueFromRegexController.text, isMandatory: false);
  }

  bool _validateLocalSettings() {
    return Utils.validateAutoByFileSettings(
      _filePathRegexController.text,
      _enumNameFromRegexController.text,
      _pathValueFromRegexController.text,
      _filePathRegexExcludeController.text,
      _fileContentRegexIncludeController.text,
      _fileContentRegexExcludeController.text,
    );
  }

  bool _validateDbSettings() {
    return Utils.validateAutoByFileSettings(
      widget.data.filePathRegex,
      widget.data.enumNameFromRegex,
      widget.data.pathValueFromRegex,
      widget.data.filePathRegexExclude,
      widget.data.fileContentRegexInclude,
      widget.data.fileContentRegexExclude,
    );
  }

  bool _hasAnyChanges() {
    return _filePathRegexController.text != widget.data.filePathRegex ||
        _filePathRegexExcludeController.text != widget.data.filePathRegexExclude ||
        _fileContentRegexIncludeController.text != widget.data.fileContentRegexInclude ||
        _fileContentRegexExcludeController.text != widget.data.fileContentRegexExclude ||
        _enumNameFromRegexController.text != widget.data.enumNameFromRegex ||
        _pathValueFromRegexController.text != widget.data.pathValueFromRegex;
  }

  void _saveSettings() {
    if (!_validateLocalSettings()) return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditEnumFileSettings.values(
            entityId: widget.data.id,
            filePathRegex: _filePathRegexController.text,
            filePathRegexExclude: _filePathRegexExcludeController.text,
            fileContentRegexInclude: _fileContentRegexIncludeController.text,
            fileContentRegexExclude: _fileContentRegexExcludeController.text,
            enumNameFromRegex: _enumNameFromRegexController.text,
            pathValueFromRegex: _pathValueFromRegexController.text,
          ),
        );
  }

  @override
  Widget build(context) {
    return Consumer(
      builder: (context, ref, child) {
        final clientState = providerContainer.read(clientStateProvider).state.version;
        final idInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
          MetaValueCoordinates(classId: widget.data.id),
          ref.watch(clientFindStateProvider).state,
          ref.watch(clientNavigationServiceProvider).state,
        );

        return ClassMetaPropertiesContainer(
          children: [
            PropertyStringView(
              key: ValueKey(widget.data.id),
              title: Loc.get.classMetaPropertyId,
              value: widget.data.id,
              canBeEmpty: false,
              saveCallback: (v) => DbCmdEditMetaEntityId.values(entityId: widget.data.id, newValue: v),
              inputFormatters: Config.filterId,
              inputDecoration: idInputDecoration,
              showFindIcon: ref.watch(clientViewModeStateProvider).state.actionsMode,
            ),
            kStyle.kPropertiesVerticalDivider,
            PropertyStringView(
              key: ValueKey(widget.data.description),
              title: Loc.get.classMetaPropertyDescription,
              value: widget.data.description,
              defaultValue: Config.newEnumDescription,
              saveCallback: (v) => DbCmdEditMetaEntityDescription.values(entityId: widget.data.id, newValue: v),
              multiline: true,
            ),
            kStyle.kPropertiesVerticalDivider,
            Container(
              color: kColorBlueMetaPropertiesGroup,
              width: 9999,
              child: Padding(
                padding: EdgeInsets.only(left: 5 * kScale, top: 5 * kScale, bottom: 5 * kScale),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Theme(
                        data: kStyle.kReorderableListTheme,
                        child: ScrollConfiguration(
                          behavior: kScrollNoScroll,
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: !widget.data.autoByFile,
                            shrinkWrap: true,
                            itemCount: values.length,
                            onReorder: _handleValuesReorder,
                            header: Padding(
                              padding: EdgeInsets.only(left: 10 * kScale),
                              child: PropertyTitle(
                                title: Loc.get.enumsListTitle,
                              ),
                            ),
                            itemBuilder: (context, index) {
                              return EnumValueView(
                                key: ValueKey('${values[index].hashCode}_${values[index].id}_$clientState'),
                                entity: widget.data,
                                data: values[index],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (!widget.data.autoByFile)
                      AddNewEnumValueButton(
                        onClick: _handleAddNewValue,
                      ),
                  ],
                ),
              ),
            ),
            kStyle.kPropertiesVerticalDivider,
            Container(
              color: kColorBlueMetaPropertiesGroup,
              width: 9999,
              padding: EdgeInsets.symmetric(horizontal: 10 * kScale, vertical: 10 * kScale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PropertyTitle(
                    title: Loc.get.autoByFileSettings,
                  ),
                  kStyle.kPropertiesVerticalDivider,
                  TooltipWrapper(
                    message: Loc.get.autoByFileTooltip,
                    child: SizedBox(
                      height: 30 * kScale,
                      child: Row(
                        children: [
                          kStyle.wrapCheckbox(
                            Checkbox(
                              value: widget.data.autoByFile,
                              onChanged: (val) {
                                providerContainer.read(clientOwnCommandsStateProvider).addCommand(
                                      DbCmdEditEnumFileSettings.values(
                                        entityId: widget.data.id,
                                        autoByFile: val ?? false,
                                      ),
                                    );
                              },
                            ),
                          ),
                          Text(
                            Loc.get.autoByFile,
                            style: kStyle.kTextExtraSmallPropertyHeader,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.data.autoByFile) ...[
                    SizedBox(height: 2 * kScale),
                    Row(
                      children: [
                        TooltipWrapper(
                          message: Loc.get.autoByFileSettingsTooltip,
                          child: IconButtonTransparent(
                            size: 35 * kScale,
                            onClick: () {
                              setState(() {
                                _showSettings = !_showSettings;
                              });
                            },
                            icon: Icon(
                              FontAwesomeIcons.gear,
                              color: _showSettings ? kColorAccentBlue : Colors.white,
                              size: 20 * kScale,
                            ),
                          ),
                        ),
                        SizedBox(width: 10 * kScale),
                        TooltipWrapper(
                          message: Loc.get.runTooltip,
                          child: IconButtonTransparent(
                            size: 35 * kScale,
                            enabled: !_showSettings && _validateDbSettings(),
                            onClick: () {
                              providerContainer.read(clientOwnCommandsStateProvider).addCommand(
                                    DbCmdGenerateEnumValuesFromFiles.values(
                                      entityId: widget.data.id,
                                    ),
                                  );
                            },
                            icon: Icon(
                              FontAwesomeIcons.play,
                              color: (_showSettings || !_validateDbSettings())
                                  ? Colors.white.withOpacity(0.3)
                                  : kColorAccentGreen,
                              size: 20 * kScale,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.data.autoByFile && _showSettings) ...[
                    kStyle.kPropertiesVerticalDivider,
                    TooltipWrapper(
                      message: Loc.get.filePathRegexTooltip,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: kStyle.kInputTextStyleProperties.copyWith(
                                fillColor: _isRegExpPatternValid(_filePathRegexController.text, isMandatory: true) ? null : kColorAccentRed.withOpacity(0.15),
                                focusColor: _isRegExpPatternValid(_filePathRegexController.text, isMandatory: true) ? null : kColorAccentRed.withOpacity(0.15),
                                hoverColor: _isRegExpPatternValid(_filePathRegexController.text, isMandatory: true) ? null : kColorAccentRed.withOpacity(0.15),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      Loc.get.filePathRegex,
                                      style: kStyle.kTextSmall,
                                    ),
                                    Text(
                                      ' *',
                                      style: kStyle.kTextSmall.copyWith(color: kColorAccentRed, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              controller: _filePathRegexController,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    kStyle.kPropertiesVerticalDivider,
                    TooltipWrapper(
                      message: Loc.get.filePathRegexExcludeTooltip,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: kStyle.kInputTextStyleProperties.copyWith(
                                fillColor: _isRegExpPatternValid(_filePathRegexExcludeController.text, isMandatory: false) ? null : kColorAccentRed.withOpacity(0.15),
                                focusColor: _isRegExpPatternValid(_filePathRegexExcludeController.text, isMandatory: false) ? null : kColorAccentRed.withOpacity(0.15),
                                hoverColor: _isRegExpPatternValid(_filePathRegexExcludeController.text, isMandatory: false) ? null : kColorAccentRed.withOpacity(0.15),
                                labelText: Loc.get.filePathRegexExclude,
                              ),
                              controller: _filePathRegexExcludeController,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    kStyle.kPropertiesVerticalDivider,
                    TooltipWrapper(
                      message: Loc.get.fileContentRegexIncludeTooltip,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: kStyle.kInputTextStyleProperties.copyWith(
                                fillColor: _isRegExpPatternValid(_fileContentRegexIncludeController.text, isMandatory: false) ? null : kColorAccentRed.withOpacity(0.15),
                                focusColor: _isRegExpPatternValid(_fileContentRegexIncludeController.text, isMandatory: false) ? null : kColorAccentRed.withOpacity(0.15),
                                hoverColor: _isRegExpPatternValid(_fileContentRegexIncludeController.text, isMandatory: false) ? null : kColorAccentRed.withOpacity(0.15),
                                labelText: Loc.get.fileContentRegexInclude,
                              ),
                              controller: _fileContentRegexIncludeController,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    kStyle.kPropertiesVerticalDivider,
                    TooltipWrapper(
                      message: Loc.get.fileContentRegexExcludeTooltip,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: kStyle.kInputTextStyleProperties.copyWith(
                                fillColor: _isRegExpPatternValid(_fileContentRegexExcludeController.text, isMandatory: false) ? null : kColorAccentRed.withOpacity(0.15),
                                focusColor: _isRegExpPatternValid(_fileContentRegexExcludeController.text, isMandatory: false) ? null : kColorAccentRed.withOpacity(0.15),
                                hoverColor: _isRegExpPatternValid(_fileContentRegexExcludeController.text, isMandatory: false) ? null : kColorAccentRed.withOpacity(0.15),
                                labelText: Loc.get.fileContentRegexExclude,
                              ),
                              controller: _fileContentRegexExcludeController,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    kStyle.kPropertiesVerticalDivider,
                    TooltipWrapper(
                      message: Loc.get.enumNameFromRegexTooltip,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: kStyle.kInputTextStyleProperties.copyWith(
                                fillColor: _isEnumNameFromRegexValid() ? null : kColorAccentRed.withOpacity(0.15),
                                focusColor: _isEnumNameFromRegexValid() ? null : kColorAccentRed.withOpacity(0.15),
                                hoverColor: _isEnumNameFromRegexValid() ? null : kColorAccentRed.withOpacity(0.15),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      Loc.get.enumNameFromRegex,
                                      style: kStyle.kTextSmall,
                                    ),
                                    Text(
                                      ' *',
                                      style: kStyle.kTextSmall.copyWith(color: kColorAccentRed, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              controller: _enumNameFromRegexController,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    kStyle.kPropertiesVerticalDivider,
                    TooltipWrapper(
                      message: Loc.get.pathValueFromRegexTooltip,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: kStyle.kInputTextStyleProperties.copyWith(
                                fillColor: _isPathValueFromRegexValid() ? null : kColorAccentRed.withOpacity(0.15),
                                focusColor: _isPathValueFromRegexValid() ? null : kColorAccentRed.withOpacity(0.15),
                                hoverColor: _isPathValueFromRegexValid() ? null : kColorAccentRed.withOpacity(0.15),
                                labelText: Loc.get.pathValueFromRegex,
                              ),
                              controller: _pathValueFromRegexController,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_hasAnyChanges()) ...[
                      kStyle.kPropertiesVerticalDivider,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButtonTransparent(
                            size: 35 * kScale,
                            enabled: _validateLocalSettings(),
                            onClick: () {
                              _saveSettings();
                            },
                            icon: Icon(
                              FontAwesomeIcons.check,
                              color: !_validateLocalSettings()
                                  ? kColorAccentGreen.withOpacity(0.3)
                                  : kColorAccentGreen,
                              size: 20 * kScale,
                            ),
                          ),
                          IconButtonTransparent(
                            size: 35 * kScale,
                            onClick: () {
                              setState(() {
                                _initControllers();
                              });
                            },
                            icon: Icon(
                              FontAwesomeIcons.xmark,
                              color: kColorAccentRed,
                              size: 27 * kScale,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleValuesReorder(int oldIndex, int newIndex) {
    if (widget.data.autoByFile) return;
    if (oldIndex == newIndex || oldIndex == newIndex - 1) //
      return;

    providerContainer
        .read(clientOwnCommandsStateProvider)
        .addCommand(DbCmdReorderEnum.values(entityId: widget.data.id, indexFrom: oldIndex, indexTo: newIndex));

    setState(() {
      values.insert(newIndex, values[oldIndex]);
      final indexesAfterInserting = Utils.getModifiedIndexesAfterReordering(oldIndex, newIndex);
      values.removeAt(indexesAfterInserting.oldValue!);
    });
  }

  void _handleAddNewValue() {
    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdAddEnumValue.values(
            entityId: widget.data.id,
            index: widget.data.values.length,
            value: DbModelUtils.getRandomId(),
          ),
        );
  }
}
