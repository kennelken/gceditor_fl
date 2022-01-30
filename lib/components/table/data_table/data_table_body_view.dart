import 'package:flutter/material.dart';
import 'package:gceditor/components/table/data_table/data_table_ids_view.dart';
import 'package:gceditor/components/table/data_table/data_table_rows_view.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/state/pinned_items_state.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class DataTableBodyView extends StatefulWidget {
  final TableMetaEntity table;
  final ScrollController horizontalScrollController;
  final List<PinnedItemInfo>? pinnedItems;

  const DataTableBodyView({
    Key? key,
    required this.table,
    required this.horizontalScrollController,
    this.pinnedItems,
  }) : super(key: key);

  @override
  State<DataTableBodyView> createState() => _DataTableBodyViewState();
}

class _DataTableBodyViewState extends State<DataTableBodyView> {
  late final LinkedScrollControllerGroup _verticalControllers;
  late final ScrollController _idsControllerVertical;
  late final ScrollController _rowsControllerVertical;

  @override
  void initState() {
    super.initState();
    _verticalControllers = LinkedScrollControllerGroup();
    _idsControllerVertical = _verticalControllers.addAndGet();
    _rowsControllerVertical = _verticalControllers.addAndGet();
  }

  @override
  void dispose() {
    _idsControllerVertical.dispose();
    _rowsControllerVertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DataTableIdsView(
          table: widget.table,
          scrollController: _idsControllerVertical,
          pinnedItems: widget.pinnedItems,
        ),
        Expanded(
          child: DataTableRowsView(
            table: widget.table,
            scrollControllerHorizontal: widget.horizontalScrollController,
            scrollControllerVertical: _rowsControllerVertical,
            pinnedItems: widget.pinnedItems,
          ),
        ),
      ],
    );
  }
}
