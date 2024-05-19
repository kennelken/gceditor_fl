import 'dart:core';

import 'package:collection/collection.dart';
import 'package:darq/darq.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_copypaste.g.dart';

@JsonSerializable()
class DbCmdCopyPaste extends BaseDbCmd {
  String? fromTableId;
  String? toTableId;

  List<int>? fromIndices;
  List<int>? toIndices;

  List<List<dynamic>>? fromValues; // for undo delete and paste from external source (length N + 1 (extra itrem for ID))
  List<String>? fromColumns; // for undo delete and paste from external source (length N)

  List<String>? idSuffixes; // for paste to make new unique ids

  // for undoing cut command
  List<List<dynamic>>? restoreValues;
  List<String>? restoreColumns;
  String? restoreTableId;
  List<int>? restoreIndices;

  bool? replace;
  bool? delete;
  bool? cut;
  bool? after;

  DbCmdCopyPaste.values({
    String? id,
    required this.fromTableId,
    required this.toTableId,
    required this.fromIndices,
    required this.toIndices,
    this.replace,
    this.delete,
    this.cut,
    this.fromValues,
    this.fromColumns,
    this.restoreValues,
    this.restoreColumns,
    this.restoreTableId,
    this.restoreIndices,
  }) : super.withId(id) {
    $type = DbCmdType.copypaste;
  }

  DbCmdCopyPaste prepareCommand(DbModel dbModel) {
    final fromTable = dbModel.cache.getTable<TableMetaEntity>(fromTableId);

    if (toIndices != null) {
      toIndices = toIndices!.orderBy((i) => i).toList();
    }
    if (fromIndices != null && fromTableId != null) {
      final fromtable = dbModel.cache.getTable<TableMetaEntity>(fromTableId);
      if (fromtable != null) {
        fromIndices = fromIndices!.orderBy((e) => e).toList();
      }
    }

    if (delete != true && cut != true && replace != true) {
      idSuffixes = <String>[];

      if (fromIndices != null) {
        for (final rowIndex in fromIndices!) {
          final row = fromTable!.rows[rowIndex];
          idSuffixes!.add(dbModel.cache.getTableByRowId(row.id) != null ? DbModelUtils.getRandomId() : '');
        }
      }

      if (fromValues != null) {
        for (var row in fromValues!) {
          if (row.isNotEmpty) {
            idSuffixes!.add(dbModel.cache.getTableByRowId(row[0]) != null ? DbModelUtils.getRandomId() : '');
          }
        }
      }
    }

    return this;
  }

  DbCmdCopyPaste();

  factory DbCmdCopyPaste.fromJson(Map<String, dynamic> json) => _$DbCmdCopyPasteFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdCopyPasteToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final fromTable = dbModel.cache.getTable<TableMetaEntity>(fromTableId);
    final columnsFrom = fromColumns ?? dbModel.cache.getAllFieldsByClassId(fromTable?.classId ?? '')?.map((element) => element.id).toList() ?? [];

    final toTable = dbModel.cache.getTable<TableMetaEntity>(toTableId);

    if (delete == true) {
      final excludeItems = fromIndices!.map((e) => fromTable!.rows[e]).toSet();
      fromTable!.rows = fromTable.rows.where((e) => !excludeItems.contains(e)).toList();
      return DbCmdResult.success();
    }

    final toColumns = dbModel.cache.getAllFieldsByClassId(toTable!.classId)!.map((e) => e.id).toList();
    final fromValues = this.fromValues != null //
        ? createRowsData(this.fromValues, fromColumns!, toTable, dbModel)!
        : fromIndices!.map((e) => fromTable!.rows[e]).toList();

    if (replace == true) {
      final toValues = toIndices!.map((e) => toTable.rows[e]).toList();

      DbModelUtils.stealValues(
        columnsFrom: columnsFrom,
        columnsTo: toColumns,
        dataFrom: fromValues,
        dataTo: toValues,
      );

      if (restoreColumns != null) {
        insertDataRows(
          dbModel,
          restoreTableId!,
          restoreIndices!,
          createRowsData(restoreValues, restoreColumns!, dbModel.cache.getTable<TableMetaEntity>(id)!, dbModel)!,
          null,
          restoreColumns!,
        );
      }
    } else // paste
    {
      insertDataRows(
        dbModel,
        toTableId!,
        toIndices!,
        fromValues,
        idSuffixes,
        columnsFrom,
      );
    }

    if (cut == true) {
      final excludeItems = fromIndices!.map((e) => fromTable!.rows[e]).toSet();
      fromTable!.rows = fromTable.rows.where((e) => !excludeItems.contains(e)).toList();
    }

    return DbCmdResult.success();
  }

  List<DataTableRow> insertDataRows(
    DbModel dbModel,
    String toTableId,
    List<int> toIndices,
    List<DataTableRow> fromValues,
    List<String>? idsSuffixes,
    List<String> columnsFrom,
  ) {
    final toTable = dbModel.cache.getTable<TableMetaEntity>(toTableId)!;
    final toColumns = dbModel.cache.getAllFieldsByClassId(toTable.classId)!.map((e) => e.id).toList();

    final toValues = <DataTableRow>[];
    for (var i = 0; i < toIndices.length; i++) {
      final newRow = DbModelUtils.buildNewRow(model: dbModel, tableId: toTableId, rowId: fromValues[i].id + (idSuffixes?[i] ?? ''));

      toValues.add(newRow);
      toTable.rows.insert(
        toIndices[i],
        newRow,
      );
    }

    DbModelUtils.stealValues(
      columnsFrom: columnsFrom,
      columnsTo: toColumns,
      dataFrom: fromValues,
      dataTo: toValues,
    );

    return toValues;
  }

  List<DataTableRow>? createRowsData(List<List<dynamic>>? values, List<String> columns, TableMetaEntity table, DbModel dbModel) {
    if (values == null) //
      return null;

    final tableColumns = dbModel.cache.getAllFieldsByClassId(table.classId)!;
    final columnsData = {for (var columnId in columns) columnId: tableColumns.firstWhereOrNull((ei) => ei.id == columnId)};
    final result = values.map((e) => DbModelUtils.decodeDataRowCell(dbModel, e, columns, columnsData)).toList();
    return result;
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final fromTable = dbModel.cache.getTable<TableMetaEntity>(fromTableId);
    final toTable = dbModel.cache.getTable<TableMetaEntity>(toTableId);

    final fromValues = fromIndices?.map((e) => fromTable!.rows[e]).toList();

    final isPasteMode = replace == true || cut == true || after == true || delete != true;
    if (isPasteMode && delete == true) //
      return DbCmdResult.fail('Ambiguous operation');

    if (cut == true && fromTableId == toTableId) //
      return DbCmdResult.fail('Cut operations inside a table are not supported');

    if (replace == true) {
      if (fromIndices == null && this.fromValues == null) //
        return DbCmdResult.fail('From values are not specified');
      if (toIndices == null) //
        return DbCmdResult.fail('To indexes are not specified');
      if ((fromIndices?.length ?? this.fromValues!.length) != toIndices!.length) //
        return DbCmdResult.fail('Rows count should be equal for replace');
    }

    if (cut == true && replace == true) {
      final toValues = toIndices?.map((e) => toTable!.rows[e]).toList();
      if (fromValues!.any((e) => toValues!.any((element) => element.id == e.id))) //
        return DbCmdResult.fail('Values should not intersect in Cut & Replace mode');
    }

    if (delete == true) {
      if (fromTable == null) //
        return DbCmdResult.fail('Table with id "$fromTableId" does not exist');
    }

    if (fromIndices?.isNotEmpty ?? false) {
      if (fromTable != null && fromIndices!.any((e) => e <= -1 || e >= fromTable.rows.length))
        return DbCmdResult.fail('fromIndices has out of allowed range values');
    }

    if ((toIndices?.isNotEmpty ?? false)) {
      if (toTable == null) //
        return DbCmdResult.fail('toTable is not specified');
      if (replace == true && toIndices!.any((e) => e < 0 || e >= toTable.rows.length))
        return DbCmdResult.fail('toTable does not contain some of the specified values');
      for (var index in toIndices!) {
        if (index <= -1 || index >= toTable.rows.length + toIndices!.length) //
          return DbCmdResult.fail('index "$index" is out of allowed range');
        if (toIndices!.fold<int>(0, (value, element) => value + (element == index ? 1 : 0)) > 1) //
          return DbCmdResult.fail('index "$index" is specified more then once');
      }
    }

    if (cut != true && delete != true && replace != true) {
      if (idSuffixes == null && (fromIndices?.length ?? 0) > 0) //
        return DbCmdResult.fail('idSuffixes is expected to be specified');
    }

    if (idSuffixes != null) {
      if (idSuffixes!.length != toIndices!.length) //
        return DbCmdResult.fail('idSuffixes length "${idSuffixes!.length}" should be equal to fromIndices length "${toIndices!.length}"');
    }

    if (cut == true) {
      if ((fromIndices?.length ?? 0) <= 0) //
        return DbCmdResult.fail('fromIndices can not be empty for cut command');
      if (fromTableId?.isEmpty ?? true) //
        return DbCmdResult.fail('fromTableId can not be empty for cut command');
    }

    if (delete != true) {
      if ((this.fromValues?.length ?? 0) <= 0 && (fromIndices?.length ?? 0) <= 0) //
        return DbCmdResult.fail('At least one of fromValues or fromIndices should be not empty');

      if (cut != true && (this.fromValues?.length ?? 0) > 0 && (fromIndices?.length ?? 0) > 0) //
        return DbCmdResult.fail('One of fromValues or fromIndices should be empty');

      if ((this.fromValues?.length ?? 0) > 0) {
        if (fromColumns == null) //
          return DbCmdResult.fail('fromColumns must be specified');

        for (var value in this.fromValues!) {
          if (value.isEmpty) //
            return DbCmdResult.fail('fromValues entry should at least contain one value (id)');
        }
        if (this.fromValues!.any((element) => element.length != fromColumns!.length + 1)) //
          return DbCmdResult.fail('fromValues length is invalid');
      }

      final fromLength = fromIndices != null ? fromValues!.length : this.fromValues!.length;
      if (fromLength != toIndices?.length) //
        return DbCmdResult.fail('fromValues length should be equal to toIndexes length');
    }

    if (restoreIndices != null || restoreTableId != null || restoreValues != null || restoreColumns != null) {
      if (replace != true) //
        return DbCmdResult.fail('Replace mode is expected to be enabled when the replace parameters are specified');
      if (cut == true) //
        return DbCmdResult.fail('Cut mode is expected to be diabled when the replace parameters are specified');
      if (restoreTableId == null) //
        return DbCmdResult.fail('restoreTableId is expected to be not null when the replace parameters are specified');
      if ((restoreIndices?.length ?? 0) <= 0) //
        return DbCmdResult.fail('restoreIndices is expected to be not null when the replace parameters are specified');
      if ((restoreValues?.length ?? 0) <= 0) //
        return DbCmdResult.fail('restoreValues is expected to be not null when the replace parameters are specified');
      if ((restoreColumns?.length ?? 0) <= 0) //
        return DbCmdResult.fail('restoreColumns is expected to be not null when the replace parameters are specified');
      if (restoreValues!.length != restoreIndices!.length) //
        return DbCmdResult.fail('restoreValues.length "${restoreValues!.length}" is not equal to restoreIndices.length "${restoreIndices!.length}"');
      if (restoreValues!.any((element) => element.length != restoreColumns!.length + 1)) //
        return DbCmdResult.fail('lenght of some item of restoreValues is not equal to (restoreColumns.length + 1) "${restoreColumns!.length + 1}"');
    }

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final fromTable = dbModel.cache.getTable<TableMetaEntity>(fromTableId);
    final toTable = dbModel.cache.getTable<TableMetaEntity>(toTableId);
    final fromColumns = this.fromColumns ?? dbModel.cache.getAllFieldsByClassId(fromTable?.classId ?? '')?.map((e) => e.id).toList();
    final toColumns = dbModel.cache.getAllFieldsByClassId(toTable?.classId ?? '')?.map((e) => e.id).toList();
    final commonColumnsList = fromColumns != null && toColumns != null ? toColumns.where((element) => fromColumns.contains(element)).toList() : null;
    final commonColumns = commonColumnsList?.toSet();
    final commonColumnsIndexesInFrom = commonColumns?.map((e) => fromColumns!.indexOf(e)).toSet();

    if (delete == true) {
      return DbCmdCopyPaste.values(
        fromTableId: null,
        fromIndices: null,
        toTableId: fromTableId,
        fromColumns: fromColumns,
        fromValues: fromIndices!.map((e) => DbModelUtils.encodeDataRowCell(fromTable!.rows[e])).toList(),
        toIndices: fromIndices,
      );
    }

    if (replace == true) {
      return DbCmdCopyPaste.values(
        fromTableId: null,
        toTableId: toTableId,
        fromColumns: commonColumnsList,
        fromValues:
            toIndices!.map((e) => DbModelUtils.encodeDataRowCell(toTable!.rows[e], includeColumnsIndexes: commonColumnsIndexesInFrom)).toList(),
        fromIndices: null,
        toIndices: toIndices,
        replace: true,
        restoreValues: cut != true ? null : fromIndices!.map((e) => DbModelUtils.encodeDataRowCell(fromTable!.rows[e])).toList(),
        restoreIndices: cut != true ? null : fromIndices,
        restoreTableId: cut != true ? null : fromTableId,
        restoreColumns: cut != true ? null : dbModel.cache.getAllFieldsByClassId(fromTable!.classId)!.map((e) => e.id).toList(),
      );
    }

    if (cut == true) {
      return DbCmdCopyPaste.values(
        fromTableId: toTableId,
        toTableId: fromTableId,
        fromIndices: toIndices,
        toIndices: fromIndices,
        fromValues: fromIndices!.map((e) => DbModelUtils.encodeDataRowCell(fromTable!.rows[e])).toList(),
        fromColumns: dbModel.cache.getAllFieldsByClassId(fromTable!.classId)!.map((e) => e.id).toList(),
        cut: true,
      );
    }

    return DbCmdCopyPaste.values(
      fromTableId: toTableId,
      toTableId: null,
      fromIndices: toIndices,
      toIndices: null,
      delete: true,
    );
  }
}
