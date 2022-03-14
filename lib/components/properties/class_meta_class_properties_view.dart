import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/properties/primitives/add_new_enum_value_button.dart';
import 'package:gceditor/components/properties/primitives/class_field_value_view.dart';
import 'package:gceditor/components/properties/primitives/class_meta_properties_container.dart';
import 'package:gceditor/components/properties/primitives/drop_down_selector.dart';
import 'package:gceditor/components/properties/primitives/property_bool_view.dart';
import 'package:gceditor/components/properties/primitives/property_string_view.dart';
import 'package:gceditor/components/properties/primitives/property_title.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_class_field.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_class_interface.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_class.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_meta_entity_description.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_meta_entity_id.dart';
import 'package:gceditor/model/db_cmd/db_cmd_reorder_class_field.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/db_model_factory.dart';
import 'package:gceditor/model/state/enum_wrapper.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';

import 'primitives/property_class_interface.dart';

class ClassMetaClassPropertiesViewProperties extends StatefulWidget {
  final ClassMetaEntity data;

  const ClassMetaClassPropertiesViewProperties({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<ClassMetaClassPropertiesViewProperties> createState() => _ClassMetaClassPropertiesViewPropertiesState();
}

class _ClassMetaClassPropertiesViewPropertiesState extends State<ClassMetaClassPropertiesViewProperties> {
  late List<ClassMetaFieldDescription> _columns;
  late List<ClassMetaEntity?> _interfaces;

  @override
  void initState() {
    super.initState();
    providerContainer.read(clientStateProvider).addListener(_handleClientStateChanges);
    _handleClientStateChanges(false);
  }

  @override
  void deactivate() {
    super.deactivate();
    providerContainer.read(clientStateProvider).removeListener(_handleClientStateChanges);
  }

  void _handleClientStateChanges([bool toSetState = true]) {
    _columns = widget.data.fields.toList();
    _interfaces = widget.data.interfaces.map((i) => clientModel.cache.getClass<ClassMetaEntity>(i)).toList();

    if (toSetState) //
      setState(() {});
  }

  @override
  Widget build(context) {
    return Consumer(
      builder: (context, watch, child) {
        final model = clientModel;
        final classTypes = DbModelUtils.allowedClassTypes.map((e) => EnumWrapper(e)).toList();

        final idInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
          MetaValueCoordinates(classId: widget.data.id),
          watch(clientFindStateProvider).state,
          watch(clientNavigationServiceProvider).state,
        );

        final parentInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
          MetaValueCoordinates(classId: widget.data.id, parentClass: widget.data.parent ?? ''),
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
              defaultValue: Config.newClassDescription,
              saveCallback: (v) => DbCmdEditMetaEntityDescription.values(entityId: widget.data.id, newValue: v),
              multiline: true,
            ),
            kStyle.kPropertiesVerticalDivider,
            DropDownSelector<EnumWrapper<ClassType>>(
              label: Loc.get.classType,
              items: classTypes,
              selectedItem: classTypes.firstWhereOrNull((e) => e.value == widget.data.classType),
              isEnabled: (e) => true,
              onValueChanged: _handleClassTypeChange,
              addNull: false,
            ),
            if (widget.data.classType != ClassType.interface) ...[
              kStyle.kPropertiesVerticalDivider,
              DropDownSelector<ClassMetaEntity>(
                label: Loc.get.parentClass,
                items: model.cache.allClasses.where((element) => element.classType != ClassType.interface).toList(),
                selectedItem: model.cache.getClass(widget.data.parent),
                isEnabled: (e) =>
                    e != widget.data &&
                    !model.cache.getParentClasses(e).contains(widget.data) &&
                    e.classType == ClassType.referenceType &&
                    widget.data.classType == ClassType.referenceType,
                onValueChanged: _handleParentClassChange,
                inputDecoration: parentInputDecoration,
              ),
            ],
            kStyle.kPropertiesVerticalDivider,
            PropertyBoolView(
              title: Loc.get.exportElementsList,
              value: widget.data.exportList ?? false,
              saveCallback: _handleExportListChanged,
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
                        child: ReorderableListView.builder(
                          scrollController: ScrollController(),
                          shrinkWrap: true,
                          itemCount: _columns.length,
                          onReorder: _handleColumnsReorder,
                          header: Padding(
                            padding: EdgeInsets.only(left: 10 * kScale),
                            child: PropertyTitle(
                              title: Loc.get.classFieldsListTitle,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            return ClassFieldValueView(
                              key: ObjectKey(_columns[index]),
                              entity: widget.data,
                              data: _columns[index],
                            );
                          },
                        ),
                      ),
                    ),
                    AddNewEnumValueButton(
                      onClick: _handleAddNewColumn,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.data.classType != ClassType.valueType) ...[
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
                          child: ReorderableListView.builder(
                            scrollController: ScrollController(),
                            shrinkWrap: true,
                            itemCount: _interfaces.length,
                            onReorder: _handleInterfaceReorder,
                            header: Padding(
                              padding: EdgeInsets.only(left: 10 * kScale),
                              child: PropertyTitle(
                                title: Loc.get.interfacesListTitle,
                              ),
                            ),
                            itemBuilder: (context, index) {
                              return PropertyClassInterface(
                                key: ValueKey(index),
                                entity: widget.data,
                                interface: _interfaces[index],
                                index: index,
                              );
                            },
                          ),
                        ),
                      ),
                      AddNewEnumValueButton(
                        onClick: _handleAddNewInterface,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _handleColumnsReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) //
      return;

    providerContainer
        .read(clientOwnCommandsStateProvider)
        .addCommand(DbCmdReorderClassField.values(entityId: widget.data.id, indexFrom: oldIndex, indexTo: newIndex));

    setState(() {
      _columns.insert(newIndex, _columns[oldIndex]);
      final indexesAfterInserting = Utils.getModifiedIndexesAfterReordering(oldIndex, newIndex);
      _columns.removeAt(indexesAfterInserting.oldValue!);
    });
  }

  void _handleAddNewColumn() {
    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdAddClassField.values(
            entityId: widget.data.id,
            index: widget.data.fields.length,
            field: DbModelFactory.fieldInt(DbModelUtils.getRandomId())..description = Config.newFieldDescription,
          ),
        );
  }

  void _handleParentClassChange(ClassMetaEntity? value) {
    if (value?.id == widget.data.parent) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditClass.values(
            entityId: widget.data.id,
            editParentClassId: true,
            parentClassId: value?.id,
          ),
        );
  }

  void _handleClassTypeChange(EnumWrapper<ClassType>? value) {
    if (value!.value == widget.data.classType) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditClass.values(
            entityId: widget.data.id,
            classType: value.value,
          ),
        );
  }

  BaseDbCmd _handleExportListChanged(bool value) {
    return DbCmdEditClass.values(
      entityId: widget.data.id,
      exportList: value,
    );
  }

  void _handleInterfaceReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) //
      return;

/*     providerContainer
        .read(clientOwnCommandsStateProvider)
        .addCommand(DbCmdReorderClassField.values(entityId: widget.data.id, indexFrom: oldIndex, indexTo: newIndex));

    setState(() {
      _columns.insert(newIndex, _columns[oldIndex]);
      final indexesAfterInserting = Utils.getModifiedIndexesAfterReordering(oldIndex, newIndex);
      _columns.removeAt(indexesAfterInserting.oldValue!);
    }); */
  }

  void _handleAddNewInterface() {
    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdAddClassInterface.values(
            entityId: widget.data.id,
            index: widget.data.interfaces.length,
            interfaceId: null,
          ),
        );
  }
}
