import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/properties/primitives/add_new_enum_value_button.dart';
import 'package:gceditor/components/properties/primitives/class_meta_properties_container.dart';
import 'package:gceditor/components/properties/primitives/enum_value_view.dart';
import 'package:gceditor/components/properties/primitives/property_string_view.dart';
import 'package:gceditor/components/properties/primitives/property_title.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_enum_value.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_meta_entity_description.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_meta_entity_id.dart';
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
    Key? key,
    required this.data,
  }) : super(key: key);

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
      builder: (context, watch, child) {
        final clientState = providerContainer.read(clientStateProvider).state.version;
        final idInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
          MetaValueCoordinates(classId: widget.data.id),
          watch(clientFindStateProvider).state,
          watch(clientNavigationServiceProvider).state,
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
              showFindIcon: watch(clientViewModeStateProvider).state.actionsMode,
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
                        data: kStyle.kReordableListTheme,
                        child: ScrollConfiguration(
                          behavior: kScrollNoScroll,
                          child: ReorderableListView.builder(
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
                    AddNewEnumValueButton(
                      onClick: _handleAddNewValue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleValuesReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) //
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
