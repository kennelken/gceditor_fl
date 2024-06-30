import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_view.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';

import '../../../model/state/client_find_state.dart';
import '../../../model/state/client_problems_state.dart';
import '../../../model/state/db_model_extensions.dart';
import '../../../model/state/service/client_navigation_service.dart';
import '../../../model/state/style_state.dart';

class DataTableCellBoolView extends ConsumerWidget {
  final DataTableValueCoordinates coordinates;

  final ClassFieldDescriptionDataInfo fieldType;
  final dynamic value;
  final ValueChanged<dynamic> onValueChanged;

  const DataTableCellBoolView({
    super.key,
    required this.coordinates,
    required this.fieldType,
    required this.value,
    required this.onValueChanged,
  });

  @override
  Widget build(context, ref) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 9999,
        color: DbModelUtils.getDataCellColor(
          coordinates,
          ref.watch(clientProblemsStateProvider).state,
          ref.watch(clientFindStateProvider).state,
          ref.watch(clientNavigationServiceProvider).state,
        ),
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
