import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';

final clientOpenedTabsStateProvider = ChangeNotifierProvider((ref) {
  final notifier = ClientOpenedTabsStateNotifier(ClientOpenedTabsState(), ref);

  ref.read(tableSelectionStateProvider).addListener(() {
    final selectedTable = ref.read(tableSelectionStateProvider).state.selectedTable;
    if (selectedTable != null) {
      notifier.openTable(selectedTable.id);
    }
  });

  ref.read(clientStateProvider).addListener(() {
    notifier.validateTabs();
  });

  return notifier;
});

class ClientOpenedTabsState {
  final List<String> openedTableIds = [];
  String? activeTableId;
}

class ClientOpenedTabsStateNotifier extends ChangeNotifier {
  final ClientOpenedTabsState state;
  final Ref _ref;

  ClientOpenedTabsStateNotifier(this.state, this._ref);

  void openTable(String tableId) {
    if (!state.openedTableIds.contains(tableId)) {
      state.openedTableIds.add(tableId);
    }
    state.activeTableId = tableId;
    notifyListeners();
  }

  void closeTable(String tableId) {
    final index = state.openedTableIds.indexOf(tableId);
    if (index == -1) //
      return;

    state.openedTableIds.removeAt(index);

    if (state.activeTableId == tableId) {
      if (state.openedTableIds.isNotEmpty) {
        final nextIndex = index.clamp(0, state.openedTableIds.length - 1);
        final nextTableId = state.openedTableIds[nextIndex];
        state.activeTableId = nextTableId;
        final model = _ref.read(clientStateProvider).state.model;
        final table = model.cache.getTable(nextTableId);
        _ref.read(tableSelectionStateProvider).setSelectedEntity(entity: table);
      } else {
        state.activeTableId = null;
        _ref.read(tableSelectionStateProvider).setSelectedTable(table: null, id: null);
        _ref.read(tableSelectionStateProvider).setSelectedEntity(entity: null, id: null);
      }
    } else {
      notifyListeners();
    }
  }

  void validateTabs() {
    final model = _ref.read(clientStateProvider).state.model;
    state.openedTableIds.removeWhere((tableId) => model.cache.getTable(tableId) == null);

    if (state.activeTableId != null && model.cache.getTable(state.activeTableId!) == null) {
      state.activeTableId = state.openedTableIds.isNotEmpty ? state.openedTableIds.last : null;
      if (state.activeTableId != null) {
        final table = model.cache.getTable(state.activeTableId!);
        _ref.read(tableSelectionStateProvider).setSelectedEntity(entity: table);
      } else {
        _ref.read(tableSelectionStateProvider).setSelectedTable(table: null, id: null);
        _ref.read(tableSelectionStateProvider).setSelectedEntity(entity: null, id: null);
      }
    } else {
      notifyListeners();
    }
  }

  void clear() {
    state.openedTableIds.clear();
    state.activeTableId = null;
    notifyListeners();
  }
}
