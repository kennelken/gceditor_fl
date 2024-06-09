import 'package:flutter/material.dart';
import 'package:gceditor/components/table/data_table/data_table_body_view.dart';
import 'package:gceditor/components/table/data_table/data_table_head_view.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/state/pinned_items_state.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class PinnedPanelItem extends StatefulWidget {
  final TableMetaEntity table;
  final List<PinnedItemInfo> pinnedItems;

  const PinnedPanelItem({
    super.key,
    required this.table,
    required this.pinnedItems,
  });

  @override
  State<PinnedPanelItem> createState() => _PinnedPanelItemState();
}

class _PinnedPanelItemState extends State<PinnedPanelItem> {
  late final LinkedScrollControllerGroup _controllersHorizontal;
  late final ScrollController _headControllerHorizontal;
  late final ScrollController _bodyControllerHorizontal;

  @override
  void initState() {
    super.initState();
    _controllersHorizontal = LinkedScrollControllerGroup();
    _headControllerHorizontal = _controllersHorizontal.addAndGet();
    _bodyControllerHorizontal = _controllersHorizontal.addAndGet();
  }

  @override
  void dispose() {
    super.dispose();
    _headControllerHorizontal.dispose();
    _bodyControllerHorizontal.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DataTableHeadView(
          table: widget.table,
          scrollController: _headControllerHorizontal,
        ),
        Flexible(
          child: DataTableBodyView(
            table: widget.table,
            horizontalScrollController: _bodyControllerHorizontal,
            pinnedItems: widget.pinnedItems,
          ),
        ),
      ],
    );
  }
}
