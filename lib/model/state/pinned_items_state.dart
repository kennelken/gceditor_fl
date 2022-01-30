import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/utils/utils.dart';

final pinnedItemsStateProvider = ChangeNotifierProvider((ref) {
  final notifier = PinnedItemsStateNotifier(PinnedItemsState());
  ref.read(clientRestoredProvider).addListener(() {
    notifier.removeDeletedItemsIfRequired(clientModel);
  });
  return notifier;
});

class PinnedItemsState {
  List<TableMetaEntity> tables = [];
  Map<TableMetaEntity, List<PinnedItemInfo>> items = {};
}

class PinnedItemsStateNotifier extends ChangeNotifier {
  final PinnedItemsState state;

  PinnedItemsStateNotifier(this.state);

  void addItem(DbModel model, DataTableRow row) {
    final table = model.cache.getTableByRowId(row.id)!;

    const indexTo = 0;

    var indexFrom = state.tables.indexOf(table);
    if (indexFrom > -1) {
      state.tables.insert(indexTo, table);
      final newIndexes = Utils.getModifiedIndexesAfterReordering(indexFrom, indexTo);
      state.tables.removeAt(newIndexes.oldValue!);
    } else {
      state.tables.insert(indexTo, table);
      state.items[table] = [];
    }

    indexFrom = state.items[table]!.indexWhere((e) => e.row == row);
    if (indexFrom > -1) {
      state.items[table]!.insert(indexTo, state.items[table]![indexFrom]);
      final newIndexes = Utils.getModifiedIndexesAfterReordering(indexFrom, indexTo);
      state.items[table]!.removeAt(newIndexes.oldValue!);
    } else {
      state.items[table]!.insert(
        indexTo,
        PinnedItemInfo(
          table: table,
          row: row,
          index: table.rows.indexOf(row),
        ),
      );
    }

    notifyListeners();
  }

  void removeItem(DbModel model, DataTableRow row, {TableMetaEntity? specificTable, bool? silent}) {
    final table = specificTable ?? model.cache.getTableByRowId(row.id)!;

    if (!state.tables.contains(table)) //
      return;

    final index = state.items[table]!.indexWhere((e) => e.row == row);
    if (index <= -1) //
      return;

    state.items[table]!.removeAt(index);
    if (state.items[table]!.isEmpty) {
      state.items.remove(table);
      state.tables.remove(table);
    }

    if (silent != true) //
      notifyListeners();
  }

  void clear() {
    state.items.clear();
    state.tables.clear();
    notifyListeners();
  }

  void removeDeletedItemsIfRequired(DbModel model) {
    var changed = false;

    for (var i = state.tables.length - 1; i >= 0; i--) {
      final items = state.items[state.tables[i]]!;
      for (var j = items.length - 1; j >= 0; j--) {
        if (model.cache.getTableRow(items[j].row.id)?.row != items[j].row) {
          removeItem(model, items[j].row, specificTable: state.tables[i], silent: true);
          changed = true;
        }
      }
    }
    if (changed) //
      notifyListeners();
  }
}

class PinnedItemInfo {
  TableMetaEntity table;
  DataTableRow row;
  int index;

  PinnedItemInfo({
    required this.table,
    required this.row,
    required this.index,
  });
}
