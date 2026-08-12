// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
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
  Timer? _clearTimer;

  ClientNavigationServiceStateNotifier(this.state);

  void focusOn(NavigationData data, {FindResultItem? findResultItem}) async {
    final model = clientModel;
    _clearTimer?.cancel();
    state.navigationData = data;
    state.longLastingNavigationData = data;
    state.longLastingFindResult = findResultItem;

    if (data.tableId != null) {
      final table = model.cache.getTable<TableMetaEntity>(data.tableId);
      providerContainer.read(tableSelectionStateProvider).setSelectedTable(table: table, id: data.tableId);
      if (data.fieldId == null && data.rowIndex == null) {
        providerContainer.read(tableSelectionStateProvider).setSelectedEntity(entity: table, id: data.tableId);
      }
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

    _clearTimer = Timer(const Duration(milliseconds: 500), () {
      clear();
    });
  }

  bool canJumpToDefinition(DbModel model, IIdentifiable? item, {ClassMeta? classEntity, String? valueId}) {
    final id = item?.id ?? valueId;
    if (id == null || id.isEmpty) return false;

    if (item is DataTableRow) {
      final table = model.cache.getTableByRowId(item.id);
      return table != null && table.rows.any((r) => r.id == item.id);
    }

    if (item is EnumValue) {
      final enumEntity = classEntity is ClassMetaEntityEnum
          ? classEntity
          : model.cache.allEnums.firstWhereOrNull((e) => e.values.any((v) => v.id == item.id || v == item));
      return enumEntity != null;
    }

    if (item is ClassMeta) {
      return model.cache.getClass(item.id) != null;
    }

    if (item is TableMeta) {
      return model.cache.getTable(item.id) != null;
    }

    if (item is ClassMetaFieldDescription) {
      return model.cache.getFieldOwner(item) != null;
    }

    // Try finding by string id in cache
    final table = model.cache.getTableByRowId(id);
    if (table != null && table.rows.any((r) => r.id == id)) {
      return true;
    }

    if (classEntity is ClassMetaEntityEnum) {
      return true;
    }

    final cls = model.cache.getClass(id);
    if (cls != null) return true;

    final tbl = model.cache.getTable(id);
    if (tbl != null) return true;

    return false;
  }

  bool jumpToDefinition(DbModel model, IIdentifiable? item, {ClassMeta? classEntity, String? valueId}) {
    final id = item?.id ?? valueId;
    if (id == null || id.isEmpty) return false;

    if (item is DataTableRow) {
      final table = model.cache.getTableByRowId(item.id);
      if (table != null) {
        final rowIndex = table.rows.indexWhere((r) => r.id == item.id);
        if (rowIndex != -1) {
          focusOn(NavigationData.toTable(tableId: table.id, fieldId: null, rowIndex: rowIndex));
          return true;
        }
      }
    }

    if (item is EnumValue) {
      final enumEntity = classEntity is ClassMetaEntityEnum
          ? classEntity
          : model.cache.allEnums.firstWhereOrNull((e) => e.values.any((v) => v.id == item.id || v == item));
      if (enumEntity != null) {
        focusOn(NavigationData.toClassProperties(classId: enumEntity.id, enumValueId: item.id));
        return true;
      }
    }

    if (item is ClassMeta) {
      focusOn(NavigationData.toClassProperties(classId: item.id));
      return true;
    }

    if (item is TableMeta) {
      focusOn(NavigationData.toTableProperties(tableId: item.id));
      return true;
    }

    if (item is ClassMetaFieldDescription) {
      final ownerClass = model.cache.getFieldOwner(item);
      if (ownerClass != null) {
        focusOn(NavigationData.toFieldProperties(classId: ownerClass.id, fieldId: item.id));
        return true;
      }
    }

    // Fallback search by string id
    final table = model.cache.getTableByRowId(id);
    if (table != null) {
      final rowIndex = table.rows.indexWhere((r) => r.id == id);
      if (rowIndex != -1) {
        focusOn(NavigationData.toTable(tableId: table.id, fieldId: null, rowIndex: rowIndex));
        return true;
      }
    }

    if (classEntity is ClassMetaEntityEnum) {
      focusOn(NavigationData.toClassProperties(classId: classEntity.id, enumValueId: id));
      return true;
    }

    final cls = model.cache.getClass(id);
    if (cls != null) {
      focusOn(NavigationData.toClassProperties(classId: cls.id));
      return true;
    }

    final tbl = model.cache.getTable(id);
    if (tbl != null) {
      focusOn(NavigationData.toTableProperties(tableId: tbl.id));
      return true;
    }

    return false;
  }

  void clear() {
    _clearTimer?.cancel();
    state.navigationData = null;
    notifyListeners();
  }
}

class NavigationData {
  String? tableId;
  String? classId;
  String? fieldId;
  int? rowIndex;
  String? enumValueId;

  NavigationData.toTable({required String tableId, required String? fieldId, required int rowIndex}) {
    this.tableId = tableId;
    this.fieldId = fieldId;
    this.rowIndex = rowIndex;
  }

  NavigationData.toClassProperties({required String classId, this.enumValueId}) {
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
