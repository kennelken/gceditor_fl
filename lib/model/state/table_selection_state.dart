import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/log_state.dart';

final tableSelectionStateProvider = ChangeNotifierProvider((ref) {
  final notifier = TableSelectionStateNotifier(TableSelectionState());
  ref.read(clientStateProvider).addListener(
    () {
      final model = ref.read(clientStateProvider).state.model;

      if (notifier.state.selectedEntity == null && notifier.state.selectedId != null) {
        notifier.state.selectedEntity = model.cache.getEntity(notifier.state.selectedId!);
        notifier.setSelectedEntity(id: notifier.state.selectedId, entity: notifier.state.selectedEntity);
      }
      if (notifier.state.selectedField == null && notifier.state.selectedFieldId != null) {
        if (notifier.state.selectedEntity is ClassMetaEntity) {
          notifier.state.selectedField = model.cache.getField(notifier.state.selectedFieldId!, notifier.state.selectedEntity as ClassMetaEntity);
          notifier.setSelectedEntity(id: notifier.state.selectedFieldId, entity: notifier.state.selectedField);
        }
      }
      if (notifier.state.selectedTable == null && notifier.state.selectedTableId != null) {
        notifier.state.selectedTable = model.cache.getTable(notifier.state.selectedTableId!);
        notifier.setSelectedTable(id: notifier.state.selectedTableId, table: notifier.state.selectedTable);
      }

      if (notifier.state.selectedTable != null) {
        if (model.cache.getTable(notifier.state.selectedTable!.id) == null) //
          notifier.setSelectedTable(table: null, id: null);
      }
      if (notifier.state.selectedEntity != null) {
        if (model.cache.getClass(notifier.state.selectedEntity!.id) == null && model.cache.getTable(notifier.state.selectedEntity!.id) == null) //
          notifier.setSelectedEntity(entity: null, id: null);
      }
      if (notifier.state.selectedField != null) {
        if (!(model.cache.allClasses.any((c) => c.fields.any((f) => f.id == notifier.state.selectedField!.id)))) //
          notifier.setSelectedField(field: null, id: null);
      }
    },
  );
  return notifier;
});

class TableSelectionState {
  String? selectedId;
  IIdentifiable? selectedEntity;

  String? selectedFieldId;
  ClassMetaFieldDescription? selectedField;

  TableMetaEntity? selectedTable;
  String? selectedTableId;

  TableSelectionState();

  bool canBeDeselected() => selectedId != null || selectedEntity != null || selectedFieldId != null || selectedField != null;
}

class TableSelectionStateNotifier extends ChangeNotifier {
  late TableSelectionState state;
  TableSelectionStateNotifier(this.state);

  void setSelectedEntity({IIdentifiable? entity, String? id}) {
    deselectAllButTable(silent: true);

    if (entity != null && id != null && entity.id != id) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Conflicting selection state specified'));
    }

    if (entity != null) {
      state.selectedEntity = entity;
      state.selectedId = entity.id;

      if (entity is TableMetaEntity) {
        setSelectedTable(table: entity);
      }
    } else {
      state.selectedEntity = null;
      state.selectedId = id;
    }
    notifyListeners();
  }

  void setSelectedField({ClassMetaFieldDescription? field, String? id}) {
    if (field != null && id != null && field.id != id) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Conflicting selection state specified'));
    }

    if (field != null) {
      state.selectedField = field;
      state.selectedFieldId = field.id;
    } else {
      state.selectedField = null;
      state.selectedFieldId = id;
    }
    notifyListeners();
  }

  void setSelectedTable({TableMetaEntity? table, String? id}) {
    if (table != null && id != null && table.id != id) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Conflicting selection state specified'));
    }

    if (table != null) {
      state.selectedTable = table;
      state.selectedTableId = table.id;
    } else {
      state.selectedTable = null;
      state.selectedTableId = id;
    }

    notifyListeners();
  }

  void deselectAllButTable({bool silent = false}) {
    state.selectedId = null;
    state.selectedEntity = null;
    state.selectedField = null;
    state.selectedFieldId = null;

    if (!silent) //
      notifyListeners();
  }
}
