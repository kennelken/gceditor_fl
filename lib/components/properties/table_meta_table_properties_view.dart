import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/properties/primitives/class_meta_properties_container.dart';
import 'package:gceditor/components/properties/primitives/drop_down_selector.dart';
import 'package:gceditor/components/properties/primitives/property_bool_view.dart';
import 'package:gceditor/components/properties/primitives/property_string_view.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_meta_entity_description.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_meta_entity_id.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_table.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';

class TableMetaTablePropertiesViewProperties extends ConsumerWidget {
  final TableMetaEntity data;

  const TableMetaTablePropertiesViewProperties({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(context, watch) {
    final model = watch(clientStateProvider).state.model;
    final idInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
      MetaValueCoordinates(tableId: data.id),
      watch(clientFindStateProvider).state,
      watch(clientNavigationServiceProvider).state,
    );

    final parentInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
      MetaValueCoordinates(tableId: data.id, parentClass: data.classId.isEmpty ? null : data.classId),
      watch(clientFindStateProvider).state,
      watch(clientNavigationServiceProvider).state,
    );

    return ClassMetaPropertiesContainer(
      children: [
        PropertyStringView(
          key: ValueKey(data.id),
          title: Loc.get.classMetaPropertyId,
          value: data.id,
          canBeEmpty: false,
          saveCallback: (v) => DbCmdEditMetaEntityId.values(entityId: data.id, newValue: v),
          inputFormatters: Config.filterId,
          inputDecoration: idInputDecoration,
        ),
        kStyle.kPropertiesVerticalDivider,
        PropertyStringView(
          key: ValueKey(data.description),
          title: Loc.get.classMetaPropertyDescription,
          value: data.description,
          defaultValue: Config.newTableDescription,
          saveCallback: (v) => DbCmdEditMetaEntityDescription.values(entityId: data.id, newValue: v),
          multiline: true,
        ),
        kStyle.kPropertiesVerticalDivider,
        DropDownSelector<ClassMetaEntity>(
          label: Loc.get.parentClass,
          items: model.cache.allClasses.where((e) => e.classType != ClassType.interface).toList(),
          selectedItem: model.cache.getClass(data.classId),
          isEnabled: (e) => e.id != data.classId,
          onValueChanged: _handleClassChange,
          addNull: false,
          inputDecoration: parentInputDecoration,
        ),
        kStyle.kPropertiesVerticalDivider,
        PropertyStringView(
          title: Loc.get.rowHeightMultiplier,
          value: data.rowHeightMultiplier?.toString() ?? '1',
          inputFormatters: Config.filterCellTypeFloat,
          saveCallback: _handleRowHeightChanged,
        ),
        kStyle.kPropertiesVerticalDivider,
        TooltipWrapper(
          message: Loc.get.generateTableItemsTooltip,
          child: PropertyBoolView(
            title: Loc.get.exportElementsList,
            value: data.exportList ?? false,
            saveCallback: _handleExportListChanged,
          ),
        ),
      ],
    );
  }

  void _handleClassChange(ClassMetaEntity? classEntity) {
    if (classEntity?.id == data.classId) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditTable.values(
            entityId: data.id,
            classId: classEntity!.id,
          ),
        );
  }

  BaseDbCmd _handleExportListChanged(bool value) {
    return DbCmdEditTable.values(
      entityId: data.id,
      exportList: value,
    );
  }

  BaseDbCmd _handleRowHeightChanged(String newValue) {
    var parsedValue = double.tryParse(newValue);
    parsedValue ??= data.rowHeightMultiplier ?? 1;
    parsedValue = parsedValue.clamp(Config.minRowHeightMultiplier, Config.maxRowHeightMultiplier);

    return DbCmdEditTable.values(
      entityId: data.id,
      rowHeightMultiplier: parsedValue,
    );
  }
}
