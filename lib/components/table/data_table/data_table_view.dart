import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/table/data_table/data_table_head_view.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

import 'data_table_body_view.dart';

class DataTableView extends StatefulWidget {
  const DataTableView({
    Key? key,
  }) : super(key: key);

  @override
  State<DataTableView> createState() => _DataTableViewState();
}

class _DataTableViewState extends State<DataTableView> {
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
    return Consumer(
      builder: (context, ref, child) {
        final table = ref.watch(tableSelectionStateProvider).state.selectedTable;
        ref.watch(styleStateProvider);
        ref.watch(clientStateProvider);
        ref.watch(columnSizeChangedProvider);

        if (table == null || table.classId.isEmpty) {
          return Expanded(
            child: Center(
              child: Text(
                table == null ? Loc.get.noTableSelected : Loc.get.tableHasNoClass,
                style: kStyle.kTextBigger,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DataTableHeadView(
                scrollController: _headControllerHorizontal,
                table: table,
              ),
              Expanded(
                child: DataTableBodyView(
                  table: table,
                  horizontalScrollController: _bodyControllerHorizontal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
