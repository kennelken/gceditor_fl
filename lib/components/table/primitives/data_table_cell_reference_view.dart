import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/drop_down_selector.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_view.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/pinned_items_state.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';

class DataTableCellReferenceView extends ConsumerWidget {
  final DataTableValueCoordinates coordinates;

  final ClassFieldDescriptionDataInfo fieldType;
  final dynamic value;
  final ValueChanged<dynamic> onValueChanged;

  const DataTableCellReferenceView({
    super.key,
    required this.coordinates,
    required this.fieldType,
    required this.value,
    required this.onValueChanged,
  });

  @override
  Widget build(context, ref) {
    final model = clientModel;
    final classEntity = model.cache.getClass(fieldType.classId)!;

    final items = _getItems();
    final selectedItem = items.firstWhereOrNull((i) => i.id == value);

    var nullValueLabel = value?.toString() ?? Loc.get.nullValue;
    if (nullValueLabel == '') //
      nullValueLabel = Loc.get.nullValue;

    final actionsMode = ref.watch(clientViewModeStateProvider).state.actionsMode;

    final showOpenButtons = ref.watch(appStateProvider).state.appMode == AppMode.standalone &&
        classEntity is ClassMetaEntityEnum &&
        classEntity.autoByFile &&
        selectedItem is EnumValue &&
        selectedItem.fullPath != null &&
        selectedItem.fullPath!.isNotEmpty;

    final absolutePath = showOpenButtons
        ? Utils.getAbsolutePath(ref.watch(appStateProvider).state.projectFile, selectedItem.fullPath)
        : null;

    final double rightPadding;
    if (showOpenButtons) {
      rightPadding = (actionsMode ? 75 : 45) * kScale;
    } else {
      rightPadding = (actionsMode ? 35 : 0) * kScale;
    }

    String? Function()? tooltipMessageBuilder;
    String? imagePath;
    if (selectedItem != null) {
      if (selectedItem is EnumValue && selectedItem.fullPath != null && selectedItem.fullPath!.isNotEmpty) {
        imagePath = Utils.getAbsolutePath(ref.watch(appStateProvider).state.projectFile, selectedItem.fullPath);
      }
      tooltipMessageBuilder = () {
        if (selectedItem is DataTableRow) {
          final table = model.cache.allDataTables.firstWhereOrNull((t) => t.rows.contains(selectedItem));
          if (table != null) {
            final jsonMap = DbModelUtils.rowToJson(model, table, selectedItem);
            return const JsonEncoder.withIndent('  ').convert(jsonMap);
          }
        } else {
          try {
            final jsonMap = (selectedItem as dynamic).toJson();
            return const JsonEncoder.withIndent('  ').convert(jsonMap);
          } catch (_) {
            return selectedItem.id;
          }
        }
        return null;
      };
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Stack(
        children: [
          TooltipWrapper(
            messageBuilder: tooltipMessageBuilder,
            imagePath: imagePath,
            child: DropDownSelector<IIdentifiable>(
              label: '',
              items: items,
              onValueChanged: _handleValueChanged,
              selectedItem: selectedItem,
              addNull: classEntity is ClassMetaEntity,
              isEnabled: (_) => true,
              showTooltip: false,
              inputDecoration: DbModelUtils.getDataCellInputDecoration(
                coordinates,
                ref.watch(clientProblemsStateProvider).state,
                ref.watch(clientFindStateProvider).state,
                ref.watch(clientNavigationServiceProvider).state,
              ).copyWith(contentPadding: EdgeInsets.only(left: 5 * kScale, right: rightPadding)),
              nullValueLabel: null /* nullValueLabel */, //
            ),
          ),
          if (actionsMode || showOpenButtons) ...[
            SizedBox(
              height: kStyle.kTableTopRowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (actionsMode)
                    IconButtonTransparent(
                      size: 22 * kScale,
                      icon: Icon(
                        FontAwesomeIcons.magnifyingGlass,
                        color: kColorPrimaryLight,
                        size: 12 * kScale,
                      ),
                      onClick: _handleFindClick,
                    ),
                  if (showOpenButtons) ...[
                    TooltipWrapper(
                      message: absolutePath ?? selectedItem.fullPath!,
                      imagePath: absolutePath,
                      child: IconButtonTransparent(
                        size: 22 * kScale,
                        icon: Icon(
                          FontAwesomeIcons.folderOpen,
                          color: kColorPrimaryLight,
                          size: 12 * kScale,
                        ),
                        onClick: () => Utils.showInExplorer(absolutePath),
                      ),
                    ),
                    TooltipWrapper(
                      message: absolutePath ?? selectedItem.fullPath!,
                      imagePath: absolutePath,
                      child: IconButtonTransparent(
                        size: 22 * kScale,
                        icon: Icon(
                          FontAwesomeIcons.arrowUpRightFromSquare,
                          color: kColorPrimaryLight,
                          size: 12 * kScale,
                        ),
                        onClick: () => Utils.openFile(absolutePath),
                      ),
                    ),
                  ],
                  if (actionsMode && selectedItem is DataTableRow)
                    IconButtonTransparent(
                      size: 22 * kScale,
                      icon: Icon(
                        FontAwesomeIcons.mapPin,
                        color: kColorPrimaryLight,
                        size: 12 * kScale,
                      ),
                      onClick: () => _handlePinClick(selectedItem),
                    ),
                  SizedBox(width: 30 * kScale),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<IIdentifiable> _getItems() {
    final model = clientModel;
    final classEntity = model.cache.getClass(fieldType.classId)!;

    return model.cache.getAvailableValues(classEntity) ?? [];
  }

  void _handleValueChanged(IIdentifiable? value) {
    final newValue = value?.id ?? '';
    if (newValue == this.value) //
      return;
    onValueChanged(newValue);
  }

  void _handleFindClick() {
    providerContainer.read(clientFindStateProvider).findUsage(clientModel, value ?? 'null');
  }

  void _handlePinClick(IIdentifiable? selectedItem) {
    if (selectedItem is! DataTableRow) //
      return;

    providerContainer.read(pinnedItemsStateProvider).addItem(clientModel, selectedItem);
  }
}
