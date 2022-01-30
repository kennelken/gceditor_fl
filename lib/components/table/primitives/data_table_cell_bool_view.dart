import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_view.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/state/style_state.dart';

class DataTableCellBoolView extends ConsumerWidget {
  final DataTableValueCoordinates coordinates;

  final ClassFieldDescriptionDataInfo fieldType;
  final dynamic value;
  final ValueChanged<dynamic> onValueChanged;

  const DataTableCellBoolView({
    Key? key,
    required this.coordinates,
    required this.fieldType,
    required this.value,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  Widget build(context, watch) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 9999,
        color: kColorTransparent,
        child: FittedBox(
          alignment: Alignment.center,
          fit: BoxFit.scaleDown,
          child: kStyle.wrapCheckbox(
            Checkbox(
              value: value == 1,
              onChanged: _handleValueChanged,
            ),
          ),
        ),
      ),
    );
  }

  void _handleValueChanged(bool? value) {
    final newValue = value ?? false;
    if (newValue == this.value) //
      return;
    onValueChanged(newValue ? 1 : 0);
  }
}
