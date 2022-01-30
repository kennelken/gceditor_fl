import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_edit_table.g.dart';

@JsonSerializable()
class DbCmdEditTable extends BaseDbCmd {
  late final String entityId;
  late final String? classId;
  late final bool? exportList;
  late final double? rowHeightMultiplier;

  List<DataTableColumn>? dataColumns;

  DbCmdEditTable.values({
    String? id,
    required this.entityId,
    this.classId,
    this.dataColumns,
    this.exportList,
    this.rowHeightMultiplier,
  }) : super.withId(id) {
    $type = DbCmdType.editTable;
  }

  DbCmdEditTable();

  factory DbCmdEditTable.fromJson(Map<String, dynamic> json) => _$DbCmdEditTableFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdEditTableToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final table = dbModel.cache.getTable(entityId)! as TableMetaEntity;

    final commandArgValues = dataColumns == null ? <String, DataTableColumn>{} : {for (var c in dataColumns!) c.id: c};
    final currentRowIds = DbModelUtils.getRowIds(table);

    if (classId != null) {
      final currentValues = DbModelUtils.getDataColumnsMap(dbModel, table);

      table.classId = classId!;
      table.rows = [];
      dbModel.cache.invalidate();

      for (var i = 0; i < currentRowIds.length; i++) {
        final row = DataTableRow()..id = currentRowIds[i];
        table.rows.add(row);

        final allColumns = dbModel.cache.getAllFieldsById(table.classId);

        if (allColumns != null) {
          for (var j = 0; j < allColumns.length; j++) {
            final column = allColumns[j];
            row.values.add(commandArgValues[column.id]?.values[i] ??
                currentValues[column.id]?.values[i] ??
                DbModelUtils.parseDefaultValueByFieldOrDefault(column, column.defaultValue));
          }
        }
      }
    }

    if (exportList != null) {
      table.exportList = exportList!;
    }

    if (rowHeightMultiplier != null) {
      table.rowHeightMultiplier = rowHeightMultiplier;
    }

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final table = dbModel.cache.getTable(entityId);
    if (table == null) //
      return DbCmdResult.fail('Table with id "$entityId" does not exist');

    if (table is! TableMetaEntity) //
      return DbCmdResult.fail('Table with id "$entityId" is not a class');

    var newClass = dbModel.cache.getClass(table.classId) as ClassMetaEntity?;
    if (classId != null) {
      final classEntity = dbModel.cache.getClass(classId);

      if (classEntity == null) //
        return DbCmdResult.fail('Class with id "$classId" does not exist');

      if (classEntity is! ClassMetaEntity) //
        return DbCmdResult.fail('Entity with id "$classId" is not a class');

      newClass = classEntity;
    }

    if (dataColumns != null) {
      final allFields = dbModel.cache.getAllFields(newClass!).map((f) => f.id).toSet();
      for (var dataColumn in dataColumns!) {
        if (!allFields.contains(dataColumn.id)) //
          return DbCmdResult.fail('dataColumn id "${dataColumn.id}" is not found in table "${newClass.id}"');

        if (dataColumn.values.length != table.rows.length) //
          return DbCmdResult.fail('dataColumn size is incorrect ($dataColumn != ${table.rows.length})');
      }
    }

    if (rowHeightMultiplier != null) {
      if (rowHeightMultiplier! < Config.minRowHeightMultiplier || rowHeightMultiplier! > Config.maxRowHeightMultiplier) //
        return DbCmdResult.fail(
          'rowHeightMultiplier is out of the allowed value interval [${Config.minRowHeightMultiplier}, ${Config.maxRowHeightMultiplier}]',
        );
    }

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final table = dbModel.cache.getTable(entityId) as TableMetaEntity;

    final columnsToSave = <ClassMetaFieldDescription>[];
    if (classId != table.classId) {
      final oldFields =
          table.classId.isEmpty ? <ClassMetaFieldDescription>[] : dbModel.cache.getAllFields(dbModel.cache.getClass<ClassMetaEntity>(table.classId)!);
      final newFields = classId == null || classId!.isEmpty
          ? <ClassMetaFieldDescription>[]
          : dbModel.cache.getAllFields(dbModel.cache.getClass<ClassMetaEntity>(classId)!);

      columnsToSave.addAll(oldFields.where((e) => !newFields.contains(e)));
    }

    final currentValues = (dataColumns != null || classId != null) && table.classId.isNotEmpty
        ? DbModelUtils.getDataColumns(dbModel, table, columns: columnsToSave)
        : null;

    return DbCmdEditTable.values(
      entityId: entityId,
      classId: classId == null ? null : table.classId,
      dataColumns: currentValues,
      exportList: exportList != null ? (table.exportList == true) : null,
      rowHeightMultiplier: rowHeightMultiplier != null ? (table.rowHeightMultiplier ?? 1.0) : null,
    );
  }
}
