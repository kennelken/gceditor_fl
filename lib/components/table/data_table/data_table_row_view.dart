import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_view.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/service/client_data_selection_state.dart';

class DataTableRowView extends StatelessWidget {
  final TableMetaEntity table;
  final DataTableRow row;
  final int index;

  const DataTableRowView({
    Key? key,
    required this.table,
    required this.row,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, watch, child) {
        final selectionState = watch(clientDataSelectionStateProvider).state;
        final isSelected = selectionState.selectionTable == table && selectionState.selectedItems.contains(index);

        return Material(
          color: isSelected ? kColorSelectedDataTable : kColorTransparent,
          child: InkWell(
            onTap: _handleClick,
            child: Row(
              children: _getCells(),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _getCells() {
    final classEntity = clientModel.cache.getClass<ClassMetaEntity>(table.classId)!;
    final columns = clientModel.cache.getAllFields(classEntity);

    final result = <Widget>[];

    for (var i = 0; i < columns.length; i++) {
      result.add(
        DataTableCellView(
          key: ValueKey('${table.id}_${row.id}_${i}_${columns[i].getFieldsUniqueId()}'),
          table: table,
          index: i,
          row: row,
        ),
      );
    }
    return result;
  }

  void _handleClick() {
    providerContainer.read(clientDataSelectionStateProvider).select(table, index);
  }
}
