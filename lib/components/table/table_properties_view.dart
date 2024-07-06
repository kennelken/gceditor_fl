import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/class_meta_class_field_properties_view.dart';
import 'package:gceditor/components/properties/class_meta_class_properties_view.dart';
import 'package:gceditor/components/properties/class_meta_enum_properties_view.dart';
import 'package:gceditor/components/properties/class_meta_group_properties_view.dart';
import 'package:gceditor/components/properties/primitives/delete_button.dart';
import 'package:gceditor/components/properties/table_meta_group_properties_view.dart';
import 'package:gceditor/components/properties/table_meta_table_properties_view.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/class_meta_group.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db/table_meta_group.dart';
import 'package:gceditor/model/db_cmd/db_cmd_delete_class.dart';
import 'package:gceditor/model/db_cmd/db_cmd_delete_table.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/settings_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';
import 'package:gceditor/utils/lazy_cache.dart';
import 'package:nil/nil.dart';

LazyCache<Type, List<Color>> _colorsByType = LazyCache<Type, List<Color>>(_getColor);

class TablePropertiesView extends ConsumerWidget {
  const TablePropertiesView({super.key});

  @override
  Widget build(context, ref) {
    ref.watch(clientStateProvider);
    ref.watch(styleStateProvider);

    IIdentifiable? selectedEntity = ref.watch(tableSelectionStateProvider).state.selectedField;
    selectedEntity ??= ref.watch(tableSelectionStateProvider).state.selectedEntity;

    if (selectedEntity == null) //
      return const SizedBox();

    final selectedClassName = _getSelectedEntityLabel(selectedEntity);
    final width = ref.watch(settingsStateProvider).state.propertiesWidth;

    final colors = _colorsByType.get(selectedEntity.runtimeType)!;

    return SizedBox(
      width: width,
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onHorizontalDragUpdate: _handleDrag,
              child: Container(
                width: kDividerLineWidth,
                color: kColorPrimary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: colors[0],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: kStyle.kTableTopRowHeight,
                    color: colors[1],
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(kStyle.kLabelPadding),
                            child: Text(
                              selectedClassName,
                              textAlign: TextAlign.left,
                              softWrap: false,
                              style: kStyle.kTextSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (_isDeleteButtonVisible(selectedEntity) && ref.watch(clientViewModeStateProvider).state.actionsMode) //
                          DeleteButton(
                            onAction: () => _deleteEntity(selectedEntity!.id),
                            tooltipText: _getDeleteTooltip(selectedEntity),
                          ),
                        SizedBox(
                          width: 30 * kScale,
                          child: TooltipWrapper(
                            message: Loc.get.closeTooltip,
                            child: MaterialButton(
                              onPressed: () => _handleBackButton(selectedEntity),
                              child: Icon(
                                FontAwesomeIcons.xmark,
                                color: kColorPrimaryLight,
                                size: 20 * kScale,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 5 * kScale),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _getPropertySelectionWidget(selectedEntity),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteEntity(String selectedId) {
    final entity = providerContainer.read(clientStateProvider).state.model.cache.getEntity(selectedId);
    var added = false;
    if (entity is ClassMeta) {
      added = providerContainer.read(clientOwnCommandsStateProvider).addCommand(
            DbCmdDeleteClass.values(
              entityId: entity.id,
            ),
          );
    } else {
      added = providerContainer.read(clientOwnCommandsStateProvider).addCommand(
            DbCmdDeleteTable.values(
              entityId: entity?.id ?? selectedId,
            ),
          );
    }

    if (added) //
      providerContainer.read(tableSelectionStateProvider).setSelectedEntity();
  }

  void _handleDrag(DragUpdateDetails details) {
    final width = providerContainer.read(settingsStateProvider).state.propertiesWidth;
    final newWidth = max(Config.minColumnWidth, width - details.delta.dx);
    providerContainer.read(settingsStateProvider).setPropertiesWidth(newWidth);
  }

  String _getSelectedEntityLabel(IIdentifiable? selectedObject) {
    if (selectedObject == null) return '';

    var result = '';
    if (selectedObject is ClassMetaGroup) {
      result = Loc.get.typeClassGroup;
    } else if (selectedObject is ClassMetaEntity) {
      result = Loc.get.typeClass;
    } else if (selectedObject is ClassMetaEntityEnum) {
      result = Loc.get.typeEnum;
    } else if (selectedObject is TableMetaGroup) {
      result = Loc.get.typeTableGroup;
    } else if (selectedObject is TableMetaEntity) {
      result = Loc.get.typeTableEntry;
    } else if (selectedObject is ClassMetaFieldDescription) {
      result = Loc.get.typeClassField;
    }
    result += ': ${selectedObject.id}';

    return result;
  }

  String _getDeleteTooltip(IIdentifiable? selectedObject) {
    if (selectedObject == null) return '';

    var result = '';
    if (selectedObject is ClassMetaGroup) {
      result = Loc.get.deleteGroupTooltip;
    } else if (selectedObject is ClassMetaEntity) {
      result = Loc.get.deleteClassTooltip;
    } else if (selectedObject is ClassMetaEntityEnum) {
      result = Loc.get.deleteEnumTooltip;
    } else if (selectedObject is TableMetaGroup) {
      result = Loc.get.deleteGroupTooltip;
    } else if (selectedObject is TableMetaEntity) {
      result = Loc.get.deleteTableTooltip;
    } else if (selectedObject is ClassMetaFieldDescription) {
      result = Loc.get.deleteFieldTooltip;
    }

    return result;
  }

  Widget _getPropertySelectionWidget(IIdentifiable? selectedItem) {
    if (selectedItem is ClassMetaGroup) {
      return ClassMetaGroupPropertiesViewProperties(
        data: selectedItem,
        key: ObjectKey(selectedItem),
      );
    }
    if (selectedItem is ClassMetaEntity) {
      return ClassMetaClassPropertiesViewProperties(data: selectedItem, key: ObjectKey(selectedItem));
    }
    if (selectedItem is ClassMetaEntityEnum) {
      return ClassMetaEnumPropertiesViewProperties(data: selectedItem, key: ObjectKey(selectedItem));
    }
    if (selectedItem is TableMetaGroup) {
      return TableMetaGroupPropertiesViewProperties(data: selectedItem, key: ObjectKey(selectedItem));
    }
    if (selectedItem is TableMetaEntity) {
      return TableMetaTablePropertiesViewProperties(data: selectedItem, key: ObjectKey(selectedItem));
    }
    if (selectedItem is ClassMetaFieldDescription) {
      return ClassMetaClassFieldPropertiesViewProperties(data: selectedItem, key: ObjectKey(selectedItem));
    }
    return nil;
  }

  bool _isDeleteButtonVisible(IIdentifiable? selectedItem) {
    return selectedItem != null && selectedItem is! ClassMetaFieldDescription;
  }

  void _handleBackButton(IIdentifiable? selectedItem) {
    if (selectedItem is ClassMetaFieldDescription) {
      providerContainer.read(tableSelectionStateProvider).setSelectedField();
    } else {
      providerContainer.read(tableSelectionStateProvider).setSelectedEntity();
    }
  }
}

List<Color>? _getColor(Type type) {
  switch (type) {
    case ClassMetaFieldDescription _:
      return [kColorAccentBlue2, kColorAccentBlue3];
  }
  return [kColorAccentBlue2, kColorAccentBlue3];
}
