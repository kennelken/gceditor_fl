import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/delete_button.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_view.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_cmd/db_cmd_delete_data_row.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_table_row_id.dart';
import 'package:gceditor/model/db_cmd/db_cmd_resize_column.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/pinned_items_state.dart';
import 'package:gceditor/model/state/service/client_data_selection_state.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';

import '../../../consts/loc.dart';

double? _initialWidth;

class DataTableRowIdView extends ConsumerWidget {
  final TableMetaEntity table;
  final DataTableRow? row;
  final int index;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool isPinnedItem;
  late final DataTableValueCoordinates? coordinates;

  DataTableRowIdView({
    Key? key,
    required this.table,
    required this.row,
    required this.index,
    required this.isPinnedItem,
    required this.coordinates,
  }) : super(key: key) {
    _controller = TextEditingController(text: row?.id ?? '');
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  Widget build(context, ref) {
    final model = clientModel;
    final height = DbModelUtils.getTableRowsHeight(model, table: table);

    ref.watch(columnSizeChangedProvider);
    final width = DbModelUtils.getTableIdsColumnWidth(table);

    return Container(
      decoration: DbModelUtils.getDataTableIdBoxDecoration(
        coordinates,
        ref.watch(clientFindStateProvider).state,
        ref.watch(clientNavigationServiceProvider).state,
      ),
      width: width,
      height: height,
      child: _getBody(ref),
    );
  }

  Widget _getBody(WidgetRef ref) {
    if (row == null) {
      return Row(
        children: [
          const Expanded(child: SizedBox()),
          _getDraggableDivider(),
        ],
      );
    }

    final selectionState = ref.watch(clientDataSelectionStateProvider).state;
    final isSelected = selectionState.selectionTable == table && selectionState.selectedItems.contains(index);

    return Material(
      color: isSelected ? kColorSelectedDataTableId : kColorTransparent,
      child: InkWell(
        onTap: _handleClick,
        child: Row(
          children: [
            Flexible(
              flex: 0,
              child: Padding(
                padding: EdgeInsets.only(left: 6 * kScale),
                child: Text(
                  '$index.',
                  style: kStyle.kTextExtraSmallInactive,
                ),
              ),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: kScrollNoScroll,
                child: TextField(
                  controller: _controller,
                  inputFormatters: Config.filterId,
                  focusNode: _focusNode,
                  decoration: kStyle.kInputTextStylePropertiesTableRowId,
                ),
              ),
            ),
            if (ref.watch(clientViewModeStateProvider).state.actionsMode) ...[
              if (!isPinnedItem)
                SizedBox(
                  width: 16 * kScale,
                  child: DeleteButton(
                    onAction: _handleDelete,
                    size: 14 * kScale,
                    color: kColorPrimaryLight,
                    tooltipText: Loc.get.deleteTableItemTooltip,
                  ),
                ),
              TooltipWrapper(
                message: Loc.get.findReferencesTooltip,
                child: IconButtonTransparent(
                  size: 22 * kScale,
                  icon: Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    color: kColorPrimaryLight,
                    size: 12 * kScale,
                  ),
                  onClick: _handleFindClick,
                ),
              ),
              if (!isPinnedItem)
                TooltipWrapper(
                  message: Loc.get.pinItemTooltip,
                  child: IconButtonTransparent(
                    size: 22 * kScale,
                    icon: Icon(
                      FontAwesomeIcons.mapPin,
                      color: kColorPrimaryLight,
                      size: 12 * kScale,
                    ),
                    onClick: () => _handlePinClick(row!),
                  ),
                ),
              if (isPinnedItem)
                TooltipWrapper(
                  message: Loc.get.unpinItemTooltip,
                  child: IconButtonTransparent(
                    size: 22 * kScale,
                    icon: Icon(
                      FontAwesomeIcons.xmark,
                      color: kColorPrimaryLight,
                      size: 12 * kScale,
                    ),
                    onClick: () => _handleUnpinClick(row!),
                  ),
                ),
            ],
            if (!isPinnedItem) //
              SizedBox(width: 22 * kScale),
            _getDraggableDivider(),
          ],
        ),
      ),
    );
  }

  Widget _getDraggableDivider() {
    return MouseRegion(
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
    );
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      DbModelUtils.selectAllIfDefaultId(_controller);
      return;
    }

    if (_controller.text == row!.id) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditTableRowId.values(
            tableId: table.id,
            newId: _controller.text,
            oldId: row!.id,
          ),
        );
  }

  void _handleDelete() {
    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdDeleteDataRow.values(
            tableId: table.id,
            rowId: row!.id,
          ),
        );
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx == 0.0) //
      return;

    DbModelUtils.setIdsColumnWidth(table, deltaWidth: details.delta.dx);
    providerContainer.read(columnSizeChangedProvider).dispatchEvent();
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _initialWidth = DbModelUtils.getTableIdsColumnWidth(table, false);
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_initialWidth != null && _initialWidth != DbModelUtils.getTableIdsColumnWidth(table, false)) {
      providerContainer.read(clientOwnCommandsStateProvider).addCommand(
            DbCmdResizeColumn.values(
              tableId: table.id,
              toResizeIds: true,
              width: DbModelUtils.getTableIdsColumnWidth(table, false),
              oldWidth: _initialWidth!,
            ),
          );
    }

    _initialWidth = null;
  }

  void _handleFindClick() {
    providerContainer.read(clientFindStateProvider).findUsage(clientModel, row!.id);
  }

  void _handlePinClick(DataTableRow item) {
    providerContainer.read(pinnedItemsStateProvider).addItem(clientModel, item);
  }

  void _handleUnpinClick(DataTableRow item) {
    providerContainer.read(pinnedItemsStateProvider).removeItem(clientModel, item);
  }

  void _handleClick() {
    providerContainer.read(clientDataSelectionStateProvider).select(table, index);
  }
}
