import 'package:flutter/material.dart';
import 'package:gceditor/components/table/data_table/data_table_ids_view.dart';
import 'package:gceditor/components/table/data_table/data_table_rows_view.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_navigation_history_state.dart';
import 'package:gceditor/model/state/pinned_items_state.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class DataTableBodyView extends StatefulWidget {
  final TableMetaEntity table;
  final ScrollController horizontalScrollController;
  final List<PinnedItemInfo>? pinnedItems;

  const DataTableBodyView({
    super.key,
    required this.table,
    required this.horizontalScrollController,
    this.pinnedItems,
  });

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

    _rowsControllerVertical.addListener(_onScroll);
    widget.horizontalScrollController.addListener(_onScroll);

    _restoreScrollPosition();
  }

  @override
  void didUpdateWidget(covariant DataTableBodyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.horizontalScrollController != widget.horizontalScrollController) {
      oldWidget.horizontalScrollController.removeListener(_onScroll);
      widget.horizontalScrollController.addListener(_onScroll);
    }
    if (oldWidget.table.id != widget.table.id) {
      _saveScrollPosition(oldWidget.table.id);
      _restoreScrollPosition();
    }
  }

  @override
  void dispose() {
    _saveScrollPosition(widget.table.id);
    _rowsControllerVertical.removeListener(_onScroll);
    widget.horizontalScrollController.removeListener(_onScroll);
    _idsControllerVertical.dispose();
    _rowsControllerVertical.dispose();
    super.dispose();
  }

  void _onScroll() {
    _saveScrollPosition(widget.table.id);
  }

  void _saveScrollPosition(String tableId) {
    if (_rowsControllerVertical.hasClients && widget.horizontalScrollController.hasClients) {
      providerContainer.read(clientNavigationHistoryStateProvider).updateCurrentScrollPosition(
            tableId,
            Offset(widget.horizontalScrollController.offset, _rowsControllerVertical.offset),
          );
    }
  }

  void _restoreScrollPosition() {
    if (widget.pinnedItems != null) //
      return;

    final navigationData = providerContainer.read(clientNavigationServiceProvider).state.navigationData;
    if (navigationData != null) //
      return;

    final historyNotifier = providerContainer.read(clientNavigationHistoryStateProvider.notifier);
    var savedOffset = historyNotifier.consumePendingHistoryScrollRestore(widget.table.id);
    savedOffset ??= historyNotifier.getTableScrollPosition(widget.table.id);

    if (savedOffset == null) //
      return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) //
        return;

      if (_rowsControllerVertical.hasClients) {
        final maxY = _rowsControllerVertical.position.maxScrollExtent;
        final targetY = savedOffset!.dy.clamp(0.0, maxY);
        _rowsControllerVertical.jumpTo(targetY);
      }

      if (widget.horizontalScrollController.hasClients) {
        final maxX = widget.horizontalScrollController.position.maxScrollExtent;
        final targetX = savedOffset!.dx.clamp(0.0, maxX);
        widget.horizontalScrollController.jumpTo(targetX);
      }
    });
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
