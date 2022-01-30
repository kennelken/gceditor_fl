// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';

final clientNavigationServiceProvider = ChangeNotifierProvider((ref) => ClientNavigationServiceStateNotifier(ClientNavigationService()));

class ClientNavigationService {
  NavigationData? navigationData;
  NavigationData? longLastingNavigationData;
  FindResultItem? longLastingFindResult;
}

class ClientNavigationServiceStateNotifier extends ChangeNotifier {
  final ClientNavigationService state;

  ClientNavigationServiceStateNotifier(this.state);

  void focusOn(NavigationData data, {FindResultItem? findResultItem}) async {
    final model = clientModel;
    state.navigationData = data;
    state.longLastingNavigationData = data;
    state.longLastingFindResult = findResultItem;

    if (data.tableId != null && data.fieldId != null) {
      providerContainer.read(tableSelectionStateProvider).setSelectedTable(table: model.cache.getTable(data.tableId), id: data.tableId);
    } else if (data.tableId != null) {
      providerContainer.read(tableSelectionStateProvider).setSelectedEntity(entity: model.cache.getTable(data.tableId), id: data.tableId);
    } else if (data.classId != null && data.fieldId != null && findResultItem?.metaItem?.fieldValueType != null) {
      final classEntity = model.cache.getClass<ClassMetaEntity>(data.classId);
      providerContainer.read(tableSelectionStateProvider).setSelectedField(field: model.cache.getField(data.fieldId!, classEntity), id: data.fieldId);
    } else if (data.classId != null) {
      providerContainer.read(tableSelectionStateProvider).setSelectedEntity(entity: model.cache.getClass(data.classId!), id: data.classId);
    } else {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Unexpected focusOn argument'));
      return;
    }

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    clear();
  }

  void clear() {
    state.navigationData = null;
    notifyListeners();
  }
}

class NavigationData {
  String? tableId;
  String? classId;
  String? fieldId;
  int? rowIndex;

  NavigationData.toTable({required String tableId, required String? fieldId, required int rowIndex}) {
    this.tableId = tableId;
    this.fieldId = fieldId;
    this.rowIndex = rowIndex;
  }

  NavigationData.toClassProperties({required String classId}) {
    this.classId = classId;
  }

  NavigationData.toTableProperties({required String tableId}) {
    this.tableId = tableId;
  }

  NavigationData.toFieldProperties({required String classId, required String fieldId}) {
    this.classId = classId;
    this.fieldId = fieldId;
  }

  bool fitsFindResult(FindResultItem? findResult) {
    if (findResult == null) //
      return false;

    if (findResult.tableItem != null && rowIndex != null) {
      return findResult.tableItem!.tableId == tableId && //
          findResult.tableItem!.fieldId == fieldId &&
          findResult.tableItem!.rowIndex == rowIndex;
    }

    return false;
  }

  bool fitsProblem(DbModelProblem? problem) {
    if (problem == null) //
      return false;

    return problem.rowIndex == rowIndex && //
        problem.tableId == tableId &&
        problem.fieldId == fieldId;
  }
}
