import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/properties/primitives/text_button_transparent.dart';
import 'package:gceditor/components/table/context_menu_button.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_data_row.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';
import 'package:gceditor/utils/value_change_notifier.dart';

var scrollDataTableProvider = ChangeNotifierProvider((_) => ValueChangeNotifier(-1));

class DataTableHeader extends ConsumerWidget {
  const DataTableHeader({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(context, watch) {
    watch(clientStateProvider);
    final selectedTable = watch(tableSelectionStateProvider).state.selectedTable;
    final selectedTableClass = selectedTable == null ? null : clientModel.cache.getClass<ClassMetaEntity>(selectedTable.classId);
    final hasSelection = selectedTable != null;
    watch(styleStateProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (!hasSelection) ...[
          Text(
            Loc.get.noTableSelected,
            style: kStyle.kTextSmall,
            maxLines: 1,
            overflow: TextOverflow.clip,
          )
        ],
        if (hasSelection) ...[
          TooltipWrapper(
            message: selectedTable!.description,
            child: TextButtonTransparent(
              onClick: () => _handleTableClick(selectedTable),
              child: Text(
                selectedTable.id,
                style: selectedTable == watch(tableSelectionStateProvider).state.selectedEntity
                    ? kStyle.kTextExtraSmallSelected
                    : kStyle.kTextExtraSmall,
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
          ..._getClasses(
            selectedTable,
            selectedTableClass,
            watch(tableSelectionStateProvider).state.selectedEntity,
          ),
          SizedBox(width: 15 * kScale),
          Expanded(
            child: Text(
              _getSizeText(selectedTable),
              style: kStyle.kTextExtraSmallInactive,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
          SizedBox(
            width: 33 * kScale,
            height: 33 * kScale,
            child: IconButtonTransparent(
              icon: const IconPlus(),
              onClick: _handleAddNewRow,
            ),
          ),
        ]
      ],
    );
  }

  String _getSizeText(TableMetaEntity? selectedTable) {
    final classEntity = clientModel.cache.getClass(selectedTable?.classId) as ClassMetaEntity?;
    final allFields = classEntity == null ? [] : clientModel.cache.getAllFields(classEntity);

    return selectedTable == null //
        ? ''
        : Loc.get.selectedTableSize(selectedTable.rows.length, allFields.length);
  }

  void _handleTableClick(TableMetaEntity table) {
    if (providerContainer.read(tableSelectionStateProvider).state.selectedEntity == table) {
      providerContainer.read(tableSelectionStateProvider).deselectAllButTable();
    } else {
      providerContainer.read(tableSelectionStateProvider).setSelectedEntity(entity: table);
    }
  }

  void _handleClassClick(ClassMetaEntity classEntity) {
    if (providerContainer.read(tableSelectionStateProvider).state.selectedEntity == classEntity) {
      providerContainer.read(tableSelectionStateProvider).deselectAllButTable();
    } else {
      providerContainer.read(tableSelectionStateProvider).setSelectedEntity(entity: classEntity);
    }
  }

  List<Widget> _getClasses(TableMetaEntity table, ClassMetaEntity? classEntity, IIdentifiable? selectedEntity) {
    final result = <Widget>[];
    if (classEntity == null) //
      return result;

    final parentClasses = clientModel.cache.getParentClasses(classEntity);
    final selfAndParents = [...parentClasses, classEntity];

    for (var i = 0; i < selfAndParents.length; i++) {
      final parentClass = selfAndParents[i];
      final interfaces = clientModel.cache.getParentInterfaces(parentClass);
      if (interfaces.isNotEmpty) {
        selfAndParents.insertAll(i, interfaces);
        i += interfaces.length;
      }
    }

    for (var i = 0; i < selfAndParents.length; i++) {
      final currentClass = selfAndParents[i];
      result.add(
        Text(
          i == 0 ? ':' : '>',
          style: kStyle.kTextExtraSmallInactive,
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
      );
      result.add(
        TooltipWrapper(
          message: currentClass.description,
          child: TextButtonTransparent(
            onClick: () => _handleClassClick(currentClass),
            child: Text(
              currentClass.id,
              style: currentClass == selectedEntity ? kStyle.kTextExtraSmallSelected : kStyle.kTextExtraSmall,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
        ),
      );
    }

    return result;
  }

  void _handleAddNewRow() {
    final selectedTable = providerContainer.read(tableSelectionStateProvider).state.selectedTable!;
    final index = selectedTable.rows.length;

    if (selectedTable.classId.isEmpty) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdAddDataRow.values(
            tableId: selectedTable.id,
            rowId: DbModelUtils.getRandomId(),
            index: index,
          ),
          onSuccess: () => providerContainer.read(scrollDataTableProvider).setValue(index),
        );
  }
}
