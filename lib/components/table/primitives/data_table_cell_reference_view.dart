import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/drop_down_selector.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_view.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/pinned_items_state.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';

class DataTableCellReferenceView extends ConsumerWidget {
  final DataTableValueCoordinates coordinates;

  final ClassFieldDescriptionDataInfo fieldType;
  final dynamic value;
  final ValueChanged<dynamic> onValueChanged;

  const DataTableCellReferenceView({
    Key? key,
    required this.coordinates,
    required this.fieldType,
    required this.value,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  Widget build(context, watch) {
    final model = clientModel;
    final classEntity = model.cache.getClass(fieldType.classId)!;

    final items = _getItems();
    final selectedItem = items.firstWhereOrNull((i) => i.id == value);

    var nullValueLabel = value?.toString() ?? Loc.get.nullValue;
    if (nullValueLabel == '') //
      nullValueLabel = Loc.get.nullValue;

    final actionsMode = watch(clientViewModeStateProvider).state.actionsMode;

    return Align(
      alignment: Alignment.topCenter,
      child: Stack(
        children: [
          DropDownSelector<IIdentifiable>(
            label: '',
            items: items,
            onValueChanged: _handleValueChanged,
            selectedItem: selectedItem,
            addNull: classEntity is ClassMetaEntity,
            isEnabled: (_) => true,
            inputDecoration: DbModelUtils.getDataCellInputDecoration(
              coordinates,
              watch(clientProblemsStateProvider).state,
              watch(clientFindStateProvider).state,
              watch(clientNavigationServiceProvider).state,
            ).copyWith(contentPadding: EdgeInsets.only(left: 5 * kScale, right: (actionsMode ? 35 : 0) * kScale)),
            nullValueLabel: null /* nullValueLabel */, //
          ),
          if (actionsMode) ...[
            SizedBox(
              height: kStyle.kTableTopRowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButtonTransparent(
                    size: 22 * kScale,
                    icon: Icon(
                      FontAwesomeIcons.search,
                      color: kColorPrimaryLight,
                      size: 12 * kScale,
                    ),
                    onClick: _handleFindClick,
                  ),
                  if (selectedItem is DataTableRow)
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
