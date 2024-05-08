import 'package:flutter/material.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_bool_view.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_color_view.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_dictionary_view.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_reference_view.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_table_cell_value.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/style_state.dart';

import 'data_table_cell_list_view.dart';
import 'data_table_cell_text_view.dart';

typedef DataTableSimpleCellFactory = Widget Function({
  Key? key,
  required DataTableValueCoordinates coordinates,
  required ClassFieldDescriptionDataInfo fieldInfo,
  required ValueChanged<dynamic> onValueChanged,
  required dynamic value,
  dynamic defaultValue,
});

class DataTableCellView extends StatelessWidget {
  final TableMetaEntity table;
  final DataTableRow row;
  final int index;

  const DataTableCellView({
    Key? key,
    required this.table,
    required this.row,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = clientModel;
    final classEntity = model.cache.getClass<ClassMetaEntity>(table.classId);
    final columns = model.cache.getAllFields(classEntity!);
    final field = columns[index];
    final width = DbModelUtils.getTableColumnWidth(table, field);
    final height = DbModelUtils.getTableRowsHeight(model, table: table);

    return Container(
      decoration: kStyle.kDataTableCellBoxDecoration,
      width: width,
      height: height,
      child: _getCellImplementation(),
    );
  }

  Widget _getCellImplementation() {
    final model = clientModel;
    final allFields = model.cache.getAllFieldsById(table.classId)!;
    final clientStateVersion = providerContainer.read(clientStateProvider).state.version;

    final field = allFields[index];
    final coordinates = DataTableValueCoordinates(
      table: table,
      field: field,
      rowIndex: table.rows.indexOf(row),
    );

    switch (field.typeInfo.type) {
      case ClassFieldType.undefined:
        return const SizedBox();

      case ClassFieldType.bool:
      case ClassFieldType.int:
      case ClassFieldType.long:
      case ClassFieldType.float:
      case ClassFieldType.double:
      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.date:
      case ClassFieldType.duration:
      case ClassFieldType.reference:
      case ClassFieldType.color:
      case ClassFieldType.vector2:
      case ClassFieldType.vector2Int:
      case ClassFieldType.vector3:
      case ClassFieldType.vector3Int:
      case ClassFieldType.vector4:
      case ClassFieldType.vector4Int:
      case ClassFieldType.rectangle:
      case ClassFieldType.rectangleInt:
        return _getSimpleCellImplementation(
          key: ValueKey('${table.id}_${row.id}_${index}_${clientStateVersion}_${row.values[index].simpleValue}'),
          coordinates: coordinates,
          fieldInfo: field.typeInfo,
          value: row.values[index].simpleValue,
          defaultValue: model.cache.getDefaultValue(field),
          onValueChanged: (v) => _saveValue(DataTableCellValue.simple(v)),
        );

      case ClassFieldType.list:
      case ClassFieldType.set:
        return DataTableCellListView(
          key: ValueKey('${table.id}_${row.id}_${index}_$clientStateVersion'),
          coordinates: coordinates,
          value: row.values[index],
          fieldType: field.typeInfo,
          valueFieldType: field.valueTypeInfo!,
          onValueChanged: _saveValue,
          cellFactory: _getSimpleCellImplementation,
        );

      case ClassFieldType.listMulti: //TODO! @sergey
        return DataTableCellListView(
          key: ValueKey('${table.id}_${row.id}_${index}_$clientStateVersion'),
          coordinates: coordinates,
          value: row.values[index],
          fieldType: field.typeInfo,
          valueFieldType: field.valueTypeInfo!,
          onValueChanged: _saveValue,
          cellFactory: _getSimpleCellImplementation,
        );

      case ClassFieldType.dictionary:
        return DataTableCellDictionaryView(
          key: ValueKey('${table.id}_${row.id}_${index}_$clientStateVersion'),
          coordinates: coordinates,
          table: table,
          field: field,
          value: row.values[index],
          fieldType: field.typeInfo,
          valueFieldType: field.valueTypeInfo!,
          keyFieldType: field.keyTypeInfo!,
          onValueChanged: _saveValue,
          cellFactory: _getSimpleCellImplementation,
        );
    }
  }

  Widget _getSimpleCellImplementation({
    Key? key,
    required DataTableValueCoordinates coordinates,
    required ClassFieldDescriptionDataInfo fieldInfo,
    required dynamic value,
    dynamic defaultValue,
    required ValueChanged<dynamic> onValueChanged,
  }) {
    switch (fieldInfo.type) {
      case ClassFieldType.undefined:
        return SizedBox(
          key: key,
        );

      case ClassFieldType.bool:
        return DataTableCellBoolView(
          key: key,
          coordinates: coordinates,
          value: value,
          fieldType: fieldInfo,
          onValueChanged: onValueChanged,
        );

      case ClassFieldType.int:
      case ClassFieldType.long:
      case ClassFieldType.float:
      case ClassFieldType.double:
      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.date:
      case ClassFieldType.duration:
      case ClassFieldType.vector2:
      case ClassFieldType.vector2Int:
      case ClassFieldType.vector3:
      case ClassFieldType.vector3Int:
      case ClassFieldType.vector4:
      case ClassFieldType.vector4Int:
      case ClassFieldType.rectangle:
      case ClassFieldType.rectangleInt:
        return DataTableCellTextView(
          key: key,
          coordinates: coordinates,
          value: value,
          defaultValue: defaultValue,
          fieldType: fieldInfo,
          onValueChanged: onValueChanged,
        );

      case ClassFieldType.reference:
        return DataTableCellReferenceView(
          key: key,
          coordinates: coordinates,
          value: value,
          fieldType: fieldInfo,
          onValueChanged: onValueChanged,
        );

      case ClassFieldType.color:
        return DataTableCellColorView(
          key: key,
          coordinates: coordinates,
          value: value,
          onValueChanged: onValueChanged,
        );

      case ClassFieldType.list:
      case ClassFieldType.listMulti:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        throw Exception('Unexpected type "${fieldInfo.type}"');
    }
  }

  void _saveValue(DataTableCellValue value) {
    final allFields = clientModel.cache.getAllFieldsById(table.classId)!;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditTableCellValue.values(
            tableId: table.id,
            fieldId: allFields[index].id,
            rowId: row.id,
            value: value.copy(),
          ),
        );
  }
}

class DataTableValueCoordinates {
  TableMetaEntity table;
  ClassMetaFieldDescription? field;
  int rowIndex;
  int? innerListRowIndex;
  int? innerListColumnIndex;

  DataTableValueCoordinates({
    required this.table,
    required this.field,
    required this.rowIndex,
    this.innerListRowIndex,
    this.innerListColumnIndex,
  });

  bool fitsProblem(DbModelProblem problem) {
    return table.id == problem.tableId &&
        field?.id == problem.fieldId &&
        rowIndex == problem.rowIndex &&
        innerListRowIndex == problem.innerListRowIndex &&
        innerListColumnIndex == problem.innerListColumnIndex;
  }

  bool fitsFindResult(FindResultItemTableItem? item) {
    return item != null &&
        table.id == item.tableId &&
        field?.id == item.fieldId &&
        rowIndex == item.rowIndex &&
        innerListRowIndex == item.innerListRowIndex &&
        innerListColumnIndex == item.innerListColumnIndex;
  }

  DataTableValueCoordinates copyWith({
    TableMetaEntity? table,
    ClassMetaFieldDescription? field,
    int? rowIndex,
    int? innerListRowIndex,
    int? innerListColumnIndex,
  }) {
    return DataTableValueCoordinates(
      table: table ?? this.table,
      field: field ?? this.field,
      rowIndex: rowIndex ?? this.rowIndex,
      innerListRowIndex: innerListRowIndex ?? this.innerListRowIndex,
      innerListColumnIndex: innerListColumnIndex ?? this.innerListColumnIndex,
    );
  }
}
