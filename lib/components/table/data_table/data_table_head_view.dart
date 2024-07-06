import 'package:flutter/material.dart';
import 'package:gceditor/components/table/primitives/data_table_column_head_view.dart';
import 'package:gceditor/components/table/primitives/data_table_row_id_view.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/style_state.dart';

class DataTableHeadView extends StatelessWidget {
  final TableMetaEntity table;
  final ScrollController scrollController;

  const DataTableHeadView({
    super.key,
    required this.table,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final classEntity = clientModel.cache.getClass<ClassMetaEntity>(table.classId);
    final columns = clientModel.cache.getAllFields(classEntity!);

    return SizedBox(
      height: kStyle.kDataTableRowHeight,
      child: Row(
        children: [
          DataTableRowIdView(
            table: table,
            row: null,
            index: 0,
            isPinnedItem: false,
            coordinates: null,
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: kScrollDraggable,
              child: Scrollbar(
                scrollbarOrientation: ScrollbarOrientation.bottom,
                controller: scrollController,
                child: ListView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  children: _getColumnItems(columns),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getColumnItems(List<ClassMetaFieldDescription> columns) {
    final result = <Widget>[];

    for (var i = 0; i < columns.length; i++) {
      result.add(
        DataTableColumnHeadView(
          coordinates: MetaValueCoordinates(
            classId: table.classId,
            fieldId: columns[i].id,
          ),
          table: table,
          field: columns[i],
          index: i,
        ),
      );
    }
    return result;
  }
}
