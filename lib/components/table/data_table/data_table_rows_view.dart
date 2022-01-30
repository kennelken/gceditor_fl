import 'package:flutter/material.dart';
import 'package:gceditor/components/table/data_table/data_table_row_view.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/pinned_items_state.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';

class DataTableRowsView extends StatelessWidget {
  final TableMetaEntity table;
  final ScrollController scrollControllerHorizontal;
  final ScrollController scrollControllerVertical;
  final List<PinnedItemInfo>? pinnedItems;

  const DataTableRowsView({
    Key? key,
    required this.table,
    required this.scrollControllerHorizontal,
    required this.scrollControllerVertical,
    this.pinnedItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = DbModelUtils.getTableWidth(clientModel, table, false);

    if (pinnedItems == null) //
      _navigateToSelectedItem(context);

    final rows = pinnedItems?.map((e) => e.row).toList() ?? table.rows;
    final itemExtent = DbModelUtils.getTableRowsHeight(clientModel, table: table);
    final height = pinnedItems != null ? pinnedItems!.length * itemExtent : null;

    return ScrollConfiguration(
      behavior: kScrollDraggableNoScrollBar,
      child: SingleChildScrollView(
        controller: scrollControllerHorizontal,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          height: height,
          child: ScrollConfiguration(
            behavior: kScrollDraggableNoScrollBar,
            child: ListView.builder(
              itemExtent: itemExtent,
              controller: scrollControllerVertical,
              itemCount: rows.length,
              itemBuilder: (context, index) {
                return DataTableRowView(
                  table: table,
                  row: rows[index],
                  index: index,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSelectedItem(BuildContext context) async {
    final navigationData = providerContainer.read(clientNavigationServiceProvider).state.navigationData;
    if (navigationData == null) //
      return;

    for (var i = 0; i < 5; i++) {
      if (!scrollControllerVertical.hasClients || !scrollControllerHorizontal.hasClients) //
        await Future.delayed(const Duration(milliseconds: 20));
    }

    if (navigationData.tableId == table.id && navigationData.rowIndex != null) {
      final rowHeight = DbModelUtils.getTableRowsHeight(clientModel, table: table);
      scrollControllerVertical.animateTo(
        rowHeight * navigationData.rowIndex!,
        duration: kScrollListDuration,
        curve: Curves.easeInOut,
      );

      scrollControllerHorizontal.animateTo(
        navigationData.fieldId == null ? 0 : DbModelUtils.getTableWidth(clientModel, table, false, upToFieldId: navigationData.fieldId),
        duration: kScrollListDuration,
        curve: Curves.easeInOut,
      );
    }

    providerContainer.read(clientNavigationServiceProvider).state.navigationData = null;
  }
}
