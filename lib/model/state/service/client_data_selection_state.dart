import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';
import 'package:gceditor/utils/selection_list_controller.dart';

import '../client_view_mode_state.dart';
import '../db_model_extensions.dart';

final clientDataSelectionStateProvider = ChangeNotifierProvider((ref) {
  final notifier = ClientDataSelectionStateNotifier(ClientDataSelectionState());
  ref.read(clientRestoredProvider).addListener(() {
    notifier.clear(true);
  });
  ref.read(tableSelectionStateProvider).addListener(() {
    notifier.clear(false);
    notifier.updateVisibility(false);
  });
  return notifier;
});

class ClientDataSelectionState {
  SelectionListController selectionListController = SelectionListController();
  TableMetaEntity? selectionTable;

  List<String>? externalCopiedColumns;
  List<List<String>>? externalCopiedItems;

  List<DataTableRow>? copiedItems;
  TableMetaEntity? copiedItemsTable;
  bool cut = false;

  Set<int> get selectedItems => selectionListController.selectedItems;
  bool visible = false;
}

class ClientDataSelectionStateNotifier extends ChangeNotifier {
  static const idColumnName = '%id%';
  static const csvDelimiter = '\t';
  static const rowsDelimiter = '\n';

  ClientDataSelectionState state;

  ClientDataSelectionStateNotifier(this.state);

  void clear(bool full) {
    state.selectionListController.reset();
    state.selectionTable = null;
    state.visible = false;

    if (full) {
      state.copiedItems = null;
      state.copiedItemsTable = null;
      state.cut = false;

      state.externalCopiedColumns = null;
      state.externalCopiedItems = null;
    }
    notifyListeners();
  }

  void select(TableMetaEntity table, int index) {
    if (table != state.selectionTable) {
      clear(false);
    }

    final viewModeState = providerContainer.read(clientViewModeStateProvider).state;

    state.selectionTable = table;
    state.selectionListController.selectItem(index, viewModeState.controlKey, viewModeState.shiftKey);
    updateVisibility(true);
    notifyListeners();
  }

  void selectMany(TableMetaEntity table, Iterable<int> indices) {
    if (table != state.selectionTable) {
      clear(false);
    }

    state.selectionTable = table;
    for (var index in indices) {
      state.selectionListController.selectItem(index, true, false);
    }
    updateVisibility(true);
    notifyListeners();
  }

  void updateVisibility(bool silent) {
    state.visible = providerContainer.read(tableSelectionStateProvider).state.selectedTable != null;
    state.visible &= state.selectionTable?.id != null && //
            state.selectionTable?.id == providerContainer.read(tableSelectionStateProvider).state.selectedTable?.id &&
            state.selectedItems.isNotEmpty ||
        (state.copiedItems?.length ?? 0) > 0 ||
        (state.externalCopiedItems?.length ?? 0) > 0;

    if (!silent) //
      notifyListeners();
  }

  void copySelected({
    required bool cut,
  }) {
    if (state.selectedItems.isEmpty) //
      return;

    state.cut = cut;

    state.externalCopiedColumns = null;
    state.externalCopiedItems = null;

    state.copiedItemsTable = state.selectionTable;
    state.copiedItems = state.selectionTable!.rows //
        .asMap()
        .entries
        .where((kvp) => state.selectedItems.contains(kvp.key))
        .map((kvp) => kvp.value)
        .toList();

    updateVisibility(true);
    notifyListeners();

    final allField = clientModel.cache.getAllFieldsById(state.selectionTable!.classId)!;
    final columnNames = [idColumnName, ...allField.map((e) => e.id)].join(csvDelimiter);

    final rows = state.copiedItems!.map(
      (e) => DbModelUtils.encodeDataRowCell(e).join(csvDelimiter),
    );
    final clipboardCsv = [columnNames, ...rows].join('\n');

    Clipboard.setData(ClipboardData(text: clipboardCsv));
  }

  void copyExternal({
    required List<String> columns,
    required List<List<String>> values,
  }) {
    state.cut = false;

    state.externalCopiedColumns = columns;
    state.externalCopiedItems = values;

    state.copiedItemsTable = null;
    state.copiedItems = null;

    updateVisibility(true);
    notifyListeners();
  }
}
