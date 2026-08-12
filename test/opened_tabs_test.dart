import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/state/client_navigation_history_state.dart';
import 'package:gceditor/model/state/client_opened_tabs_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';

void main() {
  test('clientOpenedTabsStateProvider manages open tabs correctly', () {
    final container = ProviderContainer();
    final dbModel = DbModel();

    final table1 = TableMetaEntity()..id = 'table_a';
    final table2 = TableMetaEntity()..id = 'table_b';
    final table3 = TableMetaEntity()..id = 'table_c';

    dbModel.tables.addAll([table1, table2, table3]);
    dbModel.cache.invalidate();

    container.read(clientStateProvider.notifier).state.model = dbModel;

    final tabsNotifier = container.read(clientOpenedTabsStateProvider.notifier);
    final selectionNotifier = container.read(tableSelectionStateProvider.notifier);

    expect(tabsNotifier.state.openedTableIds, isEmpty);
    expect(tabsNotifier.state.activeTableId, isNull);

    // Select table 1 -> tab opens and becomes active
    selectionNotifier.setSelectedEntity(entity: table1);
    expect(tabsNotifier.state.openedTableIds, equals(['table_a']));
    expect(tabsNotifier.state.activeTableId, equals('table_a'));

    // Select table 2 -> second tab opens and becomes active
    selectionNotifier.setSelectedEntity(entity: table2);
    expect(tabsNotifier.state.openedTableIds, equals(['table_a', 'table_b']));
    expect(tabsNotifier.state.activeTableId, equals('table_b'));

    // Re-select table 1 -> active tab switches to table 1 without duplicating tab
    selectionNotifier.setSelectedEntity(entity: table1);
    expect(tabsNotifier.state.openedTableIds, equals(['table_a', 'table_b']));
    expect(tabsNotifier.state.activeTableId, equals('table_a'));

    // Close table 1 -> active tab becomes table 2
    tabsNotifier.closeTable('table_a');
    expect(tabsNotifier.state.openedTableIds, equals(['table_b']));
    expect(tabsNotifier.state.activeTableId, equals('table_b'));
    expect(selectionNotifier.state.selectedTable?.id, equals('table_b'));

    // Close table 2 -> no tabs left
    tabsNotifier.closeTable('table_b');
    expect(tabsNotifier.state.openedTableIds, isEmpty);
    expect(tabsNotifier.state.activeTableId, isNull);
    expect(selectionNotifier.state.selectedTable, isNull);
  });

  test('scroll positions are stored and restored per table', () {
    final container = ProviderContainer();
    final historyNotifier = container.read(clientNavigationHistoryStateProvider.notifier);

    historyNotifier.updateCurrentScrollPosition('table_a', const Offset(10.0, 100.0));
    historyNotifier.updateCurrentScrollPosition('table_b', const Offset(25.0, 250.0));

    expect(historyNotifier.getTableScrollPosition('table_a'), equals(const Offset(10.0, 100.0)));
    expect(historyNotifier.getTableScrollPosition('table_b'), equals(const Offset(25.0, 250.0)));
  });

  test('closing active tab switches active tab to neighbor', () {
    final container = ProviderContainer();
    final dbModel = DbModel();
    final table1 = TableMetaEntity()..id = 't1';
    final table2 = TableMetaEntity()..id = 't2';
    dbModel.tables.addAll([table1, table2]);
    dbModel.cache.invalidate();
    container.read(clientStateProvider.notifier).state.model = dbModel;

    final tabsNotifier = container.read(clientOpenedTabsStateProvider.notifier);
    final selectionNotifier = container.read(tableSelectionStateProvider.notifier);

    selectionNotifier.setSelectedEntity(entity: table1);
    selectionNotifier.setSelectedEntity(entity: table2);
    expect(tabsNotifier.state.activeTableId, equals('t2'));

    final activeId = tabsNotifier.state.activeTableId;
    if (activeId != null) {
      tabsNotifier.closeTable(activeId);
    }

    expect(tabsNotifier.state.openedTableIds, equals(['t1']));
    expect(tabsNotifier.state.activeTableId, equals('t1'));
    expect(selectionNotifier.state.selectedTable?.id, equals('t1'));
  });

  test('deleting a table removes its tab automatically', () {
    final container = ProviderContainer();
    final dbModel = DbModel();
    final table1 = TableMetaEntity()..id = 't1';
    final table2 = TableMetaEntity()..id = 't2';
    dbModel.tables.addAll([table1, table2]);
    dbModel.cache.invalidate();
    container.read(clientStateProvider.notifier).state.model = dbModel;

    final tabsNotifier = container.read(clientOpenedTabsStateProvider.notifier);
    final selectionNotifier = container.read(tableSelectionStateProvider.notifier);

    selectionNotifier.setSelectedEntity(entity: table1);
    selectionNotifier.setSelectedEntity(entity: table2);
    expect(tabsNotifier.state.openedTableIds, equals(['t1', 't2']));
    expect(tabsNotifier.state.activeTableId, equals('t2'));

    // Remove t2 from dbModel and notify clientState
    dbModel.tables.remove(table2);
    dbModel.cache.invalidate();
    container.read(clientStateProvider.notifier).incrementVersion();

    expect(tabsNotifier.state.openedTableIds, equals(['t1']));
    expect(tabsNotifier.state.activeTableId, equals('t1'));
    expect(selectionNotifier.state.selectedTable?.id, equals('t1'));
  });
}
