import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:gceditor/components/table/data_table_header.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_view.dart';
import 'package:gceditor/components/table/primitives/data_table_row_id_view.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_cmd/db_cmd_reorder_data_row.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/pinned_items_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';

class DataTableIdsView extends StatefulWidget {
  final TableMetaEntity table;
  final ScrollController scrollController;
  final List<PinnedItemInfo>? pinnedItems;

  const DataTableIdsView({
    Key? key,
    required this.scrollController,
    required this.table,
    this.pinnedItems,
  }) : super(key: key);

  @override
  State<DataTableIdsView> createState() => _DataTableIdsViewState();
}

class _DataTableIdsViewState extends State<DataTableIdsView> {
  late List<DataTableRow> _rows;

  @override
  void initState() {
    super.initState();
    _updateList(false);
    providerContainer.read(clientRestoredProvider).addListener(_handleClientRestored);
    providerContainer.read(scrollDataTableProvider).addListener(_handleScrollDataTable);
  }

  @override
  void deactivate() {
    super.deactivate();
    providerContainer.read(clientRestoredProvider).removeListener(_handleClientRestored);
    providerContainer.read(scrollDataTableProvider).removeListener(_handleScrollDataTable);
  }

  void _handleClientRestored() {
    _updateList(true);
  }

  void _updateList(bool toSetState) {
    _rows = widget.table.rows.toList();

    if (toSetState) //
      setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _rows = widget.pinnedItems?.map((e) => e.row).toList() ?? widget.table.rows.toList();
    final indexes =
        widget.pinnedItems != null ? widget.pinnedItems!.map((e) => e.index).toList() : IntRange(0, widget.table.rows.length - 1).toList();

    final itemExtent = DbModelUtils.getTableRowsHeight(clientModel, table: widget.table);
    final height = widget.pinnedItems != null ? widget.pinnedItems!.length * itemExtent : null;

    return SizedBox(
      width: DbModelUtils.getTableIdsColumnWidth(widget.table),
      child: SizedBox(
        height: height,
        child: ScrollConfiguration(
            behavior: kScrollDraggable, // TODO! get rid of a phantom horizontal scroll
            child: Theme(
              data: kStyle.kReorderableListTheme,
              child: ReorderableListView.builder(
                buildDefaultDragHandles: widget.pinnedItems == null,
                scrollDirection: Axis.vertical,
                itemCount: _rows.length,
                scrollController: widget.scrollController,
                onReorder: _handleReorder,
                itemBuilder: (context, index) {
                  return DataTableRowIdView(
                    key: ValueKey(index),
                    table: widget.table,
                    row: _rows[index],
                    index: indexes[index],
                    isPinnedItem: widget.pinnedItems != null,
                    coordinates: DataTableValueCoordinates(table: widget.table, field: null, rowIndex: indexes[index]),
                  );
                },
              ),
            )),
      ),
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    _rows = Utils.copyAndReorder(_rows, oldIndex, newIndex);

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdReorderDataRow.values(
            tableId: widget.table.id,
            indexFrom: oldIndex,
            indexTo: newIndex,
          ),
        );
  }

  void _handleScrollDataTable() {
    final rowHeight = DbModelUtils.getTableRowsHeight(clientModel, table: widget.table);
    final index = providerContainer.read(scrollDataTableProvider).value + 10;

    widget.scrollController.animateTo(
      index * rowHeight,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }
}
