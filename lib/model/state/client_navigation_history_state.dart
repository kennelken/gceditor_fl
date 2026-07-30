import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';

final clientNavigationHistoryStateProvider = ChangeNotifierProvider((ref) {
  final notifier = ClientNavigationHistoryStateNotifier(ClientNavigationHistoryState());

  ref.read(tableSelectionStateProvider).addListener(() {
    final selectionState = ref.read(tableSelectionStateProvider).state;
    notifier.onSelectionChanged(
      tableId: selectionState.selectedTableId,
      entityId: selectionState.selectedId,
      fieldId: selectionState.selectedFieldId,
    );
  });

  DbModel? oldModel;
  ref.read(clientStateProvider).addListener(() {
    final newModel = ref.read(clientStateProvider).state.model;
    if (oldModel != newModel) {
      notifier.clear();
      oldModel = newModel;
    }
  });

  return notifier;
});

class NavigationHistoryEntry {
  final String? tableId;
  final String? entityId;
  final String? fieldId;
  Offset? scrollPosition;

  NavigationHistoryEntry({
    this.tableId,
    this.entityId,
    this.fieldId,
    this.scrollPosition,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationHistoryEntry &&
          runtimeType == other.runtimeType &&
          tableId == other.tableId &&
          entityId == other.entityId &&
          fieldId == other.fieldId;

  @override
  int get hashCode => Object.hash(tableId, entityId, fieldId);
}

class ClientNavigationHistoryState {
  final List<NavigationHistoryEntry> history = [];
  int currentIndex = -1;
  final Map<String, Offset> tableScrollPositions = {};

  String? pendingHistoryScrollTableId;
  Offset? pendingHistoryScrollRestore;

  bool get canGoBack => currentIndex > 0;
  bool get canGoForward => history.isNotEmpty && currentIndex < history.length - 1;
}

class ClientNavigationHistoryStateNotifier extends ChangeNotifier {
  final ClientNavigationHistoryState state;
  bool _isNavigatingHistory = false;

  ClientNavigationHistoryStateNotifier(this.state);

  bool get canGoBack => state.canGoBack;
  bool get canGoForward => state.canGoForward;

  void updateCurrentScrollPosition(String tableId, Offset offset) {
    state.tableScrollPositions[tableId] = offset;
    if (state.currentIndex >= 0 && state.currentIndex < state.history.length) {
      final currentEntry = state.history[state.currentIndex];
      if (currentEntry.tableId == tableId) {
        currentEntry.scrollPosition = offset;
      }
    }
  }

  Offset? getTableScrollPosition(String tableId) {
    return state.tableScrollPositions[tableId];
  }

  Offset? consumePendingHistoryScrollRestore(String tableId) {
    if (state.pendingHistoryScrollTableId == tableId && state.pendingHistoryScrollRestore != null) {
      final offset = state.pendingHistoryScrollRestore;
      state.pendingHistoryScrollRestore = null;
      state.pendingHistoryScrollTableId = null;
      return offset;
    }
    return null;
  }

  void onSelectionChanged({
    required String? tableId,
    required String? entityId,
    required String? fieldId,
  }) {
    if (_isNavigatingHistory) //
      return;

    if (tableId == null && entityId == null && fieldId == null) //
      return;

    if (state.currentIndex >= 0 && state.currentIndex < state.history.length) {
      final prevEntry = state.history[state.currentIndex];
      if (prevEntry.tableId != null && state.tableScrollPositions.containsKey(prevEntry.tableId)) {
        prevEntry.scrollPosition = state.tableScrollPositions[prevEntry.tableId];
      }
    }

    Offset? currentScroll;
    if (tableId != null) {
      currentScroll = state.tableScrollPositions[tableId];
    }

    final newEntry = NavigationHistoryEntry(
      tableId: tableId,
      entityId: entityId,
      fieldId: fieldId,
      scrollPosition: currentScroll,
    );

    if (state.history.isNotEmpty && state.currentIndex >= 0 && state.currentIndex < state.history.length) {
      if (state.history[state.currentIndex] == newEntry) //
        return;
    }

    if (state.currentIndex >= 0 && state.currentIndex < state.history.length - 1) {
      state.history.length = state.currentIndex + 1;
    }

    state.history.add(newEntry);
    state.currentIndex = state.history.length - 1;

    if (state.history.length > 100) {
      state.history.removeAt(0);
      state.currentIndex--;
    }

    notifyListeners();
  }

  void goBack() {
    if (!canGoBack) //
      return;

    _saveCurrentStepScroll();
    state.currentIndex--;
    final targetEntry = state.history[state.currentIndex];
    state.pendingHistoryScrollTableId = targetEntry.tableId;
    state.pendingHistoryScrollRestore = targetEntry.scrollPosition;

    _applyHistoryEntry(targetEntry);
    notifyListeners();
  }

  void goForward() {
    if (!canGoForward) //
      return;

    _saveCurrentStepScroll();
    state.currentIndex++;
    final targetEntry = state.history[state.currentIndex];
    state.pendingHistoryScrollTableId = targetEntry.tableId;
    state.pendingHistoryScrollRestore = targetEntry.scrollPosition;

    _applyHistoryEntry(targetEntry);
    notifyListeners();
  }

  void _saveCurrentStepScroll() {
    if (state.currentIndex >= 0 && state.currentIndex < state.history.length) {
      final currentEntry = state.history[state.currentIndex];
      if (currentEntry.tableId != null && state.tableScrollPositions.containsKey(currentEntry.tableId)) {
        currentEntry.scrollPosition = state.tableScrollPositions[currentEntry.tableId];
      }
    }
  }

  void _applyHistoryEntry(NavigationHistoryEntry entry) {
    _isNavigatingHistory = true;
    try {
      final model = providerContainer.read(clientStateProvider).state.model;
      final selectionNotifier = providerContainer.read(tableSelectionStateProvider);

      TableMetaEntity? table;
      if (entry.tableId != null) {
        table = model.cache.getTable(entry.tableId!);
      }

      selectionNotifier.setSelectedTable(table: table, id: entry.tableId);

      if (entry.entityId != null) {
        final entity = model.cache.getEntity(entry.entityId!);
        selectionNotifier.setSelectedEntity(entity: entity, id: entry.entityId);

        if (entity is ClassMetaEntity && entry.fieldId != null) {
          final field = model.cache.getField(entry.fieldId!, entity);
          selectionNotifier.setSelectedField(field: field, id: entry.fieldId);
        } else {
          selectionNotifier.setSelectedField(field: null, id: null);
        }
      } else {
        selectionNotifier.deselectAllButTable(silent: true);
        selectionNotifier.setSelectedField(field: null, id: null);
      }
    } finally {
      _isNavigatingHistory = false;
    }
  }

  void clear() {
    state.history.clear();
    state.currentIndex = -1;
    state.tableScrollPositions.clear();
    state.pendingHistoryScrollTableId = null;
    state.pendingHistoryScrollRestore = null;
    notifyListeners();
  }
}
