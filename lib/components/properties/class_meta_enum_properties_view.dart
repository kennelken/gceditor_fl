import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/properties/primitives/add_new_enum_value_button.dart';
import 'package:gceditor/components/properties/primitives/class_meta_properties_container.dart';
import 'package:gceditor/components/properties/primitives/enum_value_view.dart';
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

  void _handleClientStateChanges([bool toSetState = true]) {
    values = widget.data.values.toList();
    if (toSetState)
      setState(
        () => providerContainer.read(enumValueWidthRatioProvider).setValue(widget.data.valueColumnWidth, true),
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
                          style: kStyle.kTextRegular.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (widget.data.autoByFile) ...[
                    kStyle.kPropertiesVerticalDivider,
                    TooltipWrapper(
                      message: Loc.get.filePathRegexTooltip,
                      child: PropertyStringView(
                        key: ValueKey('${widget.data.id}_filePathRegex'),
                        title: Loc.get.filePathRegex,
                        value: widget.data.filePathRegex,
                        saveCallback: (v) => DbCmdEditEnumFileSettings.values(
                          entityId: widget.data.id,
                          filePathRegex: v,
                        ),
                      ),
                    ),
                    kStyle.kPropertiesVerticalDivider,
                    TooltipWrapper(
                      message: Loc.get.filePathRegexExcludeTooltip,
                      child: PropertyStringView(
                        key: ValueKey('${widget.data.id}_filePathRegexExclude'),
                        title: Loc.get.filePathRegexExclude,
                        value: widget.data.filePathRegexExclude,
                        saveCallback: (v) => DbCmdEditEnumFileSettings.values(
                          entityId: widget.data.id,
                          filePathRegexExclude: v,
                        ),
                      ),
                    ),
                    kStyle.kPropertiesVerticalDivider,
                    TooltipWrapper(
                      message: Loc.get.fileContentRegexIncludeTooltip,
                      child: PropertyStringView(
                        key: ValueKey('${widget.data.id}_fileContentRegexInclude'),
                        title: Loc.get.fileContentRegexInclude,
                        value: widget.data.fileContentRegexInclude,
                        saveCallback: (v) => DbCmdEditEnumFileSettings.values(
                          entityId: widget.data.id,
                          fileContentRegexInclude: v,
                        ),
                      ),
                    ),
                    kStyle.kPropertiesVerticalDivider,
                    TooltipWrapper(
                      message: Loc.get.fileContentRegexExcludeTooltip,
                      child: PropertyStringView(
                        key: ValueKey('${widget.data.id}_fileContentRegexExclude'),
                        title: Loc.get.fileContentRegexExclude,
                        value: widget.data.fileContentRegexExclude,
                        saveCallback: (v) => DbCmdEditEnumFileSettings.values(
                          entityId: widget.data.id,
                          fileContentRegexExclude: v,
                        ),
                      ),
                    ),
                    kStyle.kPropertiesVerticalDivider,
                    TooltipWrapper(
                      message: Loc.get.enumNameFromRegexTooltip,
                      child: PropertyStringView(
                        key: ValueKey('${widget.data.id}_enumNameFromRegex'),
                        title: Loc.get.enumNameFromRegex,
                        value: widget.data.enumNameFromRegex,
                        saveCallback: (v) => DbCmdEditEnumFileSettings.values(
                          entityId: widget.data.id,
                          enumNameFromRegex: v,
                        ),
                      ),
                    ),
                    kStyle.kPropertiesVerticalDivider,
                    TooltipWrapper(
                      message: Loc.get.pathValueFromRegexTooltip,
                      child: PropertyStringView(
                        key: ValueKey('${widget.data.id}_pathValueFromRegex'),
                        title: Loc.get.pathValueFromRegex,
                        value: widget.data.pathValueFromRegex,
                        saveCallback: (v) => DbCmdEditEnumFileSettings.values(
                          entityId: widget.data.id,
                          pathValueFromRegex: v,
                        ),
                      ),
                    ),
                    kStyle.kPropertiesVerticalDivider,
                    Row(
                      children: [
                        TooltipWrapper(
                          message: Loc.get.runTooltip,
                          child: ElevatedButton(
                            style: kButtonBlue.copyWith(
                              padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20 * kScale, vertical: 10 * kScale)),
                            ),
                            onPressed: () {
                              providerContainer.read(clientOwnCommandsStateProvider).addCommand(
                                    DbCmdGenerateEnumValuesFromFiles.values(
                                      entityId: widget.data.id,
                                    ),
                                  );
                            },
                            child: Text(
                              Loc.get.run,
                              style: kStyle.kTextRegular.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(width: 20 * kScale),
                        TooltipWrapper(
                          message: Loc.get.autoTooltip,
                          child: Row(
                            children: [
                              kStyle.wrapCheckbox(
                                Checkbox(
                                  value: widget.data.autoByFileAutoRefresh,
                                  onChanged: (val) {
                                    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
                                          DbCmdEditEnumFileSettings.values(
                                            entityId: widget.data.id,
                                            autoByFileAutoRefresh: val ?? false,
                                          ),
                                        );
                                  },
                                ),
                              ),
                              Text(
                                Loc.get.auto,
                                style: kStyle.kTextRegular,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
