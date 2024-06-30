import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/class_meta_properties_container.dart';
import 'package:gceditor/components/properties/primitives/drop_down_selector.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/properties/primitives/info_button.dart';
import 'package:gceditor/components/properties/primitives/property_bool_view.dart';
import 'package:gceditor/components/properties/primitives/property_string_view.dart';
import 'package:gceditor/components/properties/primitives/text_button_transparent.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_class_field.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/enum_wrapper.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';

import '../tooltip_wrapper.dart';

class ClassMetaClassFieldPropertiesViewProperties extends StatefulWidget {
  final ClassMetaFieldDescription data;

  const ClassMetaClassFieldPropertiesViewProperties({
    super.key,
    required this.data,
  });

  @override
  State<ClassMetaClassFieldPropertiesViewProperties> createState() => _ClassMetaClassFieldPropertiesViewPropertiesState();
}

class _ClassMetaClassFieldPropertiesViewPropertiesState extends State<ClassMetaClassFieldPropertiesViewProperties> {
  late ClassFieldType type;
  late String? typeRefId;

  late ClassFieldType? keyType;
  late String? keyTypeRefId;

  late ClassFieldType? valueType;
  late String? valueTypeRefId;

  late TextEditingController defaultValueController;

  @override
  void initState() {
    super.initState();

    defaultValueController = TextEditingController();
    defaultValueController.addListener(() => setState(() {}));
    providerContainer.read(clientStateProvider).addListener(_handleClientStateChanges);
    _restoreValuesFromModel();
  }

  @override
  void deactivate() {
    super.deactivate();
    providerContainer.read(clientStateProvider).removeListener(_handleClientStateChanges);
  }

  void _handleClientStateChanges() {
    setState(_restoreValuesFromModel);
  }

  @override
  Widget build(context) {
    return Consumer(
      builder: (context, ref, child) {
        final classEntity = clientModel.cache.getFieldOwner(widget.data);

        final idInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
          MetaValueCoordinates(classId: classEntity!.id, fieldId: widget.data.id),
          ref.watch(clientFindStateProvider).state,
          ref.watch(clientNavigationServiceProvider).state,
        );

        final model = clientModel;
        final entity = model.cache.getFieldOwner(widget.data);
        if (entity == null) //
          return const SizedBox();

        final classFieldTypes = DbModelUtils.sortedFieldTypes.map((e) => EnumWrapper(e)).toList();
        final simpleClassFieldTypes = classFieldTypes.where((e) => e.value.isSimple()).toList();
        final multiValueFieldTypes = classFieldTypes.where((e) => e.value == ClassFieldType.reference).toList();

        final allClasses = [...model.cache.allEnums, ...model.cache.allClasses];
        final allNonAbstractClasses = model.cache.allNonAbstractClasses;

        return ClassMetaPropertiesContainer(children: [
          PropertyStringView(
            key: ValueKey(widget.data.id),
            title: Loc.get.classMetaPropertyId,
            value: widget.data.id,
            canBeEmpty: false,
            saveCallback: (v) => DbCmdEditClassField.values(entityId: entity.id, fieldId: widget.data.id, newId: v),
            inputFormatters: Config.filterId,
            inputDecoration: idInputDecoration,
            showFindIcon: ref.watch(clientViewModeStateProvider).state.actionsMode,
          ),
          kStyle.kPropertiesVerticalDivider,
          PropertyStringView(
            key: ValueKey(widget.data.description),
            title: Loc.get.classMetaPropertyDescription,
            value: widget.data.description,
            defaultValue: Config.newFieldDescription,
            saveCallback: (v) => DbCmdEditClassField.values(entityId: entity.id, fieldId: widget.data.id, newDescription: v),
            multiline: true,
          ),
          Row(
            children: [
              Text(Loc.get.fieldOwnerClass, style: kStyle.kTextExtraSmall),
              const SizedBox(
                width: 5,
              ),
              Flexible(
                fit: FlexFit.loose,
                child: TextButtonTransparent(
                  onClick: _handleParentClassClick,
                  child: Text(
                    entity.id,
                    style: kStyle.kTextExtraSmallSelected,
                    maxLines: 1,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          kStyle.kPropertiesVerticalDivider,
          TooltipWrapper(
            message: Loc.get.exportFieldTooltip,
            child: PropertyBoolView(
              title: Loc.get.exportFieldTitle,
              value: widget.data.toExport,
              saveCallback: _handleToExportChanged,
            ),
          ),
          if (type.isSimple()) ...[
            TooltipWrapper(
              message: Loc.get.isUniqueValueTooltip,
              child: PropertyBoolView(
                title: Loc.get.isUniqueValueTitle,
                value: widget.data.isUniqueValue,
                saveCallback: _handleIsUniqueValueChanged,
              ),
            ),
            kStyle.kPropertiesVerticalDivider
          ],
          Container(
            padding: EdgeInsets.symmetric(vertical: 10 * kScale, horizontal: 5 * kScale),
            color: kColorBlueMetaPropertiesGroup,
            child: Column(
              children: [
                Row(
                  children: [
                    if (!_needClassSelector(type)) ...[
                      Expanded(child: _getTypeDropDownSelector(classFieldTypes))
                    ] else ...[
                      SizedBox(
                        width: 150 * kScale,
                        child: _getTypeDropDownSelector(classFieldTypes),
                      ),
                      _getHorizontalDivider(),
                      Expanded(
                        child: Builder(builder: (context) {
                          final idInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
                            MetaValueCoordinates(
                              classId: classEntity.id,
                              fieldId: widget.data.id,
                              fieldValueType: FindResultFieldDefinitionValueType.simple,
                            ),
                            ref.watch(clientFindStateProvider).state,
                            ref.watch(clientNavigationServiceProvider).state,
                          );

                          return _getReferenceClassSelector(
                            classes: allClasses,
                            selectedItem: model.cache.getClass(typeRefId),
                            onValueSelected: _handleTypeRefSelected,
                            inputDecoration: idInputDecoration,
                          );
                        }),
                      ),
                    ],
                  ],
                ),
                if (type.hasKeyType()) ...[
                  kStyle.kPropertiesVerticalDivider,
                  Row(
                    children: [
                      if (!_needClassSelector(keyType)) ...[
                        Expanded(child: _getKeyTypeDropDownSelector(simpleClassFieldTypes))
                      ] else ...[
                        SizedBox(
                          width: 150 * kScale,
                          child: _getKeyTypeDropDownSelector(simpleClassFieldTypes),
                        ),
                        _getHorizontalDivider(),
                        Expanded(
                          child: Builder(builder: (context) {
                            final idInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
                              MetaValueCoordinates(
                                classId: classEntity.id,
                                fieldId: widget.data.id,
                                fieldValueType: FindResultFieldDefinitionValueType.key,
                              ),
                              ref.watch(clientFindStateProvider).state,
                              ref.watch(clientNavigationServiceProvider).state,
                            );

                            return _getReferenceClassSelector(
                              classes: allClasses,
                              selectedItem: model.cache.getClass(keyTypeRefId),
                              onValueSelected: _handleKeyTypeRefSelected,
                              inputDecoration: idInputDecoration,
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ],
                if (type.hasValueType()) ...[
                  kStyle.kPropertiesVerticalDivider,
                  Row(
                    children: [
                      if (!_needClassSelector(valueType)) ...[
                        Expanded(child: _getValueTypeDropDownSelector(simpleClassFieldTypes))
                      ] else ...[
                        SizedBox(
                          width: 150 * kScale,
                          child: _getValueTypeDropDownSelector(simpleClassFieldTypes),
                        ),
                        _getHorizontalDivider(),
                        Expanded(
                          child: Builder(builder: (context) {
                            final idInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
                              MetaValueCoordinates(
                                classId: classEntity.id,
                                fieldId: widget.data.id,
                                fieldValueType: FindResultFieldDefinitionValueType.value,
                              ),
                              ref.watch(clientFindStateProvider).state,
                              ref.watch(clientNavigationServiceProvider).state,
                            );

                            return _getReferenceClassSelector(
                              classes: allClasses,
                              selectedItem: model.cache.getClass(valueTypeRefId),
                              onValueSelected: _handleValueTypeRefSelected,
                              inputDecoration: idInputDecoration,
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ],
                if (type.hasMultiValueType()) ...[
                  kStyle.kPropertiesVerticalDivider,
                  Row(
                    children: [
                      SizedBox(
                        width: 150 * kScale,
                        child: _getValueTypeDropDownSelector(multiValueFieldTypes),
                      ),
                      _getHorizontalDivider(),
                      Expanded(
                        child: Builder(builder: (context) {
                          final idInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
                            MetaValueCoordinates(
                              classId: classEntity.id,
                              fieldId: widget.data.id,
                              fieldValueType: FindResultFieldDefinitionValueType.value,
                            ),
                            ref.watch(clientFindStateProvider).state,
                            ref.watch(clientNavigationServiceProvider).state,
                          );

                          return _getReferenceClassSelector(
                            classes: allNonAbstractClasses,
                            selectedItem: model.cache.getClass(valueTypeRefId),
                            onValueSelected: _handleValueTypeRefSelected,
                            inputDecoration: idInputDecoration,
                          );
                        }),
                      ),
                    ],
                  ),
                ],
                kStyle.kPropertiesVerticalDivider,
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: defaultValueController,
                        decoration: kStyle.kInputTextStyleProperties.copyWith(labelText: Loc.get.defaultValueTitle),
                      ),
                    ),
                    _getHorizontalDivider(),
                    _getHorizontalDivider(),
                    InfoButton(
                      text: Loc.get.defaultFieldInfo,
                    ),
                  ],
                ),
                if (_hasAnyChanges()) ...[
                  kStyle.kPropertiesVerticalDivider,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButtonTransparent(
                        size: 35 * kScale,
                        onClick: _applyTypes,
                        icon: Icon(
                          FontAwesomeIcons.check,
                          color: kColorAccentGreen,
                          size: 20 * kScale,
                        ),
                      ),
                      IconButtonTransparent(
                        size: 35 * kScale,
                        onClick: _revertTypes,
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
            ),
          ),
          kStyle.kPropertiesVerticalDivider,
        ]);
      },
    );
  }

  SizedBox _getHorizontalDivider() => const SizedBox(width: 3);

  DropDownSelector<ClassMeta> _getReferenceClassSelector({
    required List<ClassMeta> classes,
    ClassMeta? selectedItem,
    required ValueChanged<ClassMeta?> onValueSelected,
    required InputDecoration inputDecoration,
  }) {
    return DropDownSelector<ClassMeta>(
      label: Loc.get.classReference,
      items: classes,
      selectedItem: selectedItem,
      isEnabled: (e) => true,
      onValueChanged: onValueSelected,
      addNull: false,
      inputDecoration: inputDecoration,
    );
  }

  DropDownSelector<EnumWrapper<ClassFieldType>> _getValueTypeDropDownSelector(List<EnumWrapper<ClassFieldType>> classFieldTypes) {
    return DropDownSelector<EnumWrapper<ClassFieldType>>(
      label: Loc.get.fieldValueType,
      items: classFieldTypes,
      selectedItem: classFieldTypes.firstWhereOrNull((e) => e.value == valueType),
      isEnabled: (e) => true,
      onValueChanged: _handleValueTypeChange,
      addNull: false,
    );
  }

  DropDownSelector<EnumWrapper<ClassFieldType>> _getKeyTypeDropDownSelector(List<EnumWrapper<ClassFieldType>> classFieldTypes) {
    return DropDownSelector<EnumWrapper<ClassFieldType>>(
      label: Loc.get.fieldKeyType,
      items: classFieldTypes,
      selectedItem: classFieldTypes.firstWhereOrNull((e) => e.value == keyType),
      isEnabled: (e) => true,
      onValueChanged: _handleKeyTypeChange,
      addNull: false,
    );
  }

  DropDownSelector<EnumWrapper<ClassFieldType>> _getTypeDropDownSelector(List<EnumWrapper<ClassFieldType>> classFieldTypes) {
    return DropDownSelector<EnumWrapper<ClassFieldType>>(
      label: Loc.get.fieldType,
      items: classFieldTypes,
      selectedItem: classFieldTypes.firstWhereOrNull((e) => e.value == type),
      isEnabled: (e) => true,
      onValueChanged: _handleTypeChange,
      addNull: false,
    );
  }

  BaseDbCmd _handleIsUniqueValueChanged(bool newValue) {
    final entity = clientModel.cache.getFieldOwner(widget.data)!;

    return DbCmdEditClassField.values(entityId: entity.id, fieldId: widget.data.id, newIsUniqueValue: newValue);
  }

  BaseDbCmd _handleToExportChanged(bool newValue) {
    final entity = clientModel.cache.getFieldOwner(widget.data)!;

    return DbCmdEditClassField.values(entityId: entity.id, fieldId: widget.data.id, newToExportValue: newValue);
  }

  void _handleTypeChange(EnumWrapper<ClassFieldType>? value) {
    setState(() {
      defaultValueController.text = '';
      type = value!.value;

      if (type.hasMultiValueType()) {
        valueType = ClassFieldType.reference;
      }
    });
  }

  void _handleKeyTypeChange(EnumWrapper<ClassFieldType>? value) {
    setState(() {
      defaultValueController.text = '';
      keyType = value!.value;
    });
  }

  void _handleValueTypeChange(EnumWrapper<ClassFieldType>? value) {
    setState(() {
      defaultValueController.text = '';
      valueType = value!.value;
    });
  }

  bool _needClassSelector(ClassFieldType? type) {
    return type == ClassFieldType.reference;
  }

  void _handleTypeRefSelected(ClassMeta? value) {
    defaultValueController.text = '';
    setState(() {
      typeRefId = value!.id;
    });
  }

  void _handleKeyTypeRefSelected(ClassMeta? value) {
    setState(() {
      defaultValueController.text = '';
      keyTypeRefId = value!.id;
    });
  }

  void _handleValueTypeRefSelected(ClassMeta? value) {
    setState(() {
      defaultValueController.text = '';
      valueTypeRefId = value!.id;
    });
  }

  bool _hasAnyChanges() {
    if (type != widget.data.typeInfo.type || typeRefId != widget.data.typeInfo.classId) //
      return true;

    if (type.hasKeyType()) {
      if (keyType != widget.data.keyTypeInfo?.type || keyTypeRefId != widget.data.keyTypeInfo?.classId) //
        return true;
    }

    if (type.hasValueType()) {
      if (valueType != widget.data.valueTypeInfo?.type || valueTypeRefId != widget.data.valueTypeInfo?.classId) //
        return true;
    }

    if (type.hasMultiValueType()) {
      if (valueType != widget.data.valueTypeInfo?.type || valueTypeRefId != widget.data.valueTypeInfo?.classId) //
        return true;
    }

    if (defaultValueController.text != widget.data.defaultValue) {
      return true;
    }

    return false;
  }

  void _applyTypes() {
    final entity = clientModel.cache.getFieldOwner(widget.data)!;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditClassField.values(
            entityId: entity.id,
            fieldId: widget.data.id,
            newType: ClassFieldDescriptionDataInfo.fromData(
              type: type,
              classId: typeRefId,
            ),
            newKeyType: keyType == null
                ? null
                : ClassFieldDescriptionDataInfo.fromData(
                    type: keyType!,
                    classId: keyTypeRefId,
                  ),
            newValueType: valueType == null
                ? null
                : ClassFieldDescriptionDataInfo.fromData(
                    type: valueType!,
                    classId: valueTypeRefId,
                  ),
            newDefaultValue: defaultValueController.text == widget.data.defaultValue ? null : defaultValueController.text,
          ),
        );
  }

  void _revertTypes() {
    setState(() {
      _restoreValuesFromModel();
    });
  }

  void _restoreValuesFromModel() {
    type = widget.data.typeInfo.type;
    typeRefId = widget.data.typeInfo.classId;

    keyType = widget.data.keyTypeInfo?.type;
    keyTypeRefId = widget.data.keyTypeInfo?.classId;

    valueType = widget.data.valueTypeInfo?.type;
    valueTypeRefId = widget.data.valueTypeInfo?.classId;

    defaultValueController.text = widget.data.defaultValue;
  }

  void _handleParentClassClick() {
    providerContainer.read(clientNavigationServiceProvider).focusOn(
          NavigationData.toClassProperties(classId: clientModel.cache.getFieldOwner(widget.data)!.id),
        );
  }
}
