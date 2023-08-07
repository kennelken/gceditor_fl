import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/text_button_transparent.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_cmd/db_cmd_resize_column.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';

import '../../../consts/loc.dart';
import '../../../main.dart';
import '../../../model/state/client_view_mode_state.dart';
import '../../properties/primitives/icon_button_transparent.dart';
import '../../tooltip_wrapper.dart';
import '../fill_value_view.dart';

double? _initialWidth;

class DataTableColumnHeadView extends ConsumerWidget {
  final TableMetaEntity table;
  final ClassMetaFieldDescription field;
  final int index;
  final MetaValueCoordinates coordinates;

  const DataTableColumnHeadView({
    Key? key,
    required this.table,
    required this.field,
    required this.index,
    required this.coordinates,
  }) : super(key: key);

  @override
  Widget build(context, ref) {
    final width = DbModelUtils.getTableColumnWidth(table, field);
    final actionsMode = ref.watch(clientViewModeStateProvider).state.actionsMode;

    final decoration = kStyle.kDataTableHeadBoxDecorationNoRight.copyWith(
      color: DbModelUtils.getMetaFieldColor(
        coordinates,
        ref.watch(clientFindStateProvider).state,
        ref.watch(clientNavigationServiceProvider).state,
        kStyle.kDataTableHeadBoxDecorationNoRight.color!,
      ),
    );

    return Container(
      decoration: decoration,
      width: width,
      height: kStyle.kDataTableRowHeight,
      child: Row(
        children: [
          Expanded(
            child: TooltipWrapper(
              message: field.description,
              child: TextButtonTransparent(
                onClick: _handleFieldClick,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 0,
                      child: Text(
                        '$index.',
                        style: kStyle.kTextExtraSmallInactive,
                      ),
                    ),
                    SizedBox(width: 7 * kScale),
                    Flexible(
                      child: Text(
                        field.id,
                        style: ref.watch(tableSelectionStateProvider).state.selectedField == field
                            ? kStyle.kTextExtraSmallSelected
                            : kStyle.kTextExtraSmall,
                        maxLines: 1,
                      ),
                    ),
                    if (actionsMode) ...[
                      const SizedBox(width: 10),
                      TooltipWrapper(
                        message: Loc.get.buttonFillColumnTooltip,
                        child: IconButtonTransparent(
                          onClick: () => _openFillColumnDialog(index),
                          icon: Icon(
                            FontAwesomeIcons.fillDrip,
                            size: 12.0 * kScale,
                            color: kColorAccentBlue,
                          ),
                          size: 25 * kScale,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onHorizontalDragUpdate: _handleHorizontalDragUpdate,
              onHorizontalDragEnd: _handleHorizontalDragEnd,
              onHorizontalDragStart: _handleHorizontalDragStart,
              child: Container(
                width: kDividerLineWidth,
                color: kColorDataTableLine,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _handleFieldClick() {
    final selectedField = providerContainer.read(tableSelectionStateProvider).state.selectedField;

    providerContainer.read(tableSelectionStateProvider).setSelectedField(field: selectedField == field ? null : field);
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx == 0.0) //
      return;

    DbModelUtils.setColumnWidth(table, field, deltaWidth: details.delta.dx);
    providerContainer.read(columnSizeChangedProvider).dispatchEvent();
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _initialWidth = DbModelUtils.getTableColumnWidth(table, field, false);
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_initialWidth != null && _initialWidth != DbModelUtils.getTableColumnWidth(table, field, false)) {
      providerContainer.read(clientOwnCommandsStateProvider).addCommand(
            DbCmdResizeColumn.values(
              tableId: table.id,
              fieldId: field.id,
              width: DbModelUtils.getTableColumnWidth(table, field, false),
              oldWidth: _initialWidth!,
            ),
          );
    }

    _initialWidth = null;
  }

  void _openFillColumnDialog(int index) {
    showDialog(
      context: popupContext!,
      barrierColor: kColorTransparent,
      builder: (context) {
        return Dialog(
          child: FillValueView(
            field: field,
            table: table,
          ),
        );
      },
    );
  }
}
