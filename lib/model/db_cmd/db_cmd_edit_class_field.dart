import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

import '../db/data_table_cell_multivalue_item.dart';
import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_edit_class_field.g.dart';

@JsonSerializable()
class DbCmdEditClassField extends BaseDbCmd {
  late String entityId;
  late String fieldId;
  late Map<String, Map<int, List<List<dynamic>>>>? listInlineValuesByTableColumn;
  String? newId;
  String? newDescription;
  bool? newIsUniqueValue;
  bool? newToExportValue;

  ClassFieldDescriptionDataInfo? newType;
  ClassFieldDescriptionDataInfo? newKeyType;
  ClassFieldDescriptionDataInfo? newValueType;
  String? newDefaultValue;

  Map<String, List<DataTableColumn>>? valuesByTable;

  DbCmdEditClassField.values({
    String? id,
    required this.entityId,
    required this.fieldId,
    this.newId,
    this.newDescription,
    this.newIsUniqueValue,
    this.newToExportValue,
    this.newType,
    this.newKeyType,
    this.newValueType,
    this.newDefaultValue,
    this.valuesByTable,
    this.listInlineValuesByTableColumn,
  }) : super.withId(id) {
    $type = DbCmdType.editClassField;
  }

  DbCmdEditClassField();

  factory DbCmdEditClassField.fromJson(Map<String, dynamic> json) => _$DbCmdEditClassFieldFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdEditClassFieldToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId) as ClassMetaEntity;
    final field = dbModel.cache.getField(fieldId, entity)!;

    if (newId != null) {
      final oldId = field.id;
      field.id = newId!;
      DbModelUtils.updateFieldIdReferences(dbModel, entity, newId!, oldId);
    }

    if (newDescription != null) //
      field.description = newDescription!;

    if (newIsUniqueValue != null) //
      field.isUniqueValue = newIsUniqueValue!;

    if (newToExportValue != null) //
      field.toExport = newToExportValue!;

    var defaultValue = newDefaultValue;
    if (newType != null) {
      field.typeInfo = newType!;
      field.keyTypeInfo = newKeyType;
      field.valueTypeInfo = newValueType;

      defaultValue ??= field.defaultValue;
      dbModel.cache.invalidate();
    }

    if (defaultValue != null) {
      field.defaultValue = defaultValue;

      final allTables = dbModel.cache.allDataTables;
      for (final table in allTables) {
        DbModelUtils.makeDefaultIfRequired(dbModel, table, {field});
      }
    }

    if (valuesByTable != null) {
      DbModelUtils.applyManyDataColumns(dbModel, valuesByTable!);
    }

    dbModel.cache.invalidate();

    final fieldsUsingInline = DbModelUtils.getFieldsUsingInlineClass(dbModel, entity);
    for (var fieldUsingInline in fieldsUsingInline) {
      for (var table in dbModel.cache.allDataTables) {
        final fields = dbModel.cache.getAllFieldsByClassId(table.classId)!;
        final columnIndex = fields.indexOf(fieldUsingInline);
        if (columnIndex <= -1) //
          continue;

        final listInlineField = fields[columnIndex];
        final inlineColumns = DbModelUtils.getListMultiColumns(dbModel, listInlineField.valueTypeInfo!);
        final inlineColumnIndex = inlineColumns!.indexOf(field);

        for (var i = 0; i < table.rows.length; i++) {
          final row = table.rows[i];
          final cellValues = row.values[columnIndex].listCellValues!;
          for (var j = 0; j < cellValues.length; j++) {
            final cellValue = cellValues[j];
            final value = listInlineValuesByTableColumn?[(table.id)]?[inlineColumnIndex]?[i][j] ??
                DbModelUtils.convertSimpleValueIfPossible(
                    (cellValue as DataTableCellMultiValueItem).values![inlineColumnIndex], field.typeInfo.type) ??
                dbModel.cache.getDefaultValue(field).simpleValue;
            (cellValue as DataTableCellMultiValueItem).values![inlineColumnIndex] = value;
          }
        }
      }
    }

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId);
    if (entity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (entity is! ClassMetaEntity) //
      return DbCmdResult.fail('Entity with id "$entityId" is not a class');

    final field = dbModel.cache.getField(fieldId, entity);
    if (field == null) //
      return DbCmdResult.fail('Field with id "$fieldId" does not exist');

    final fieldOwner = dbModel.cache.getFieldOwner(field);
    if (fieldOwner == null) //
      return DbCmdResult.fail('Field with id "$fieldId" does not belong to any class');

    if (newId != null) {
      if (!DbModelUtils.validateId(newId!)) //
        return DbCmdResult.fail('Id "$newId" is invalid. Valid format: "${Config.idFormatRegex.pattern}"');

      final subclasses = dbModel.cache.getImplementingClasses(fieldOwner);
      for (var subClass in [fieldOwner, ...subclasses]) {
        if (dbModel.cache.getAllFields(subClass).any((e) => e.id == newId)) //
          return DbCmdResult.fail('Field with id "$newId" already exists in class "${subClass.id}"');
      }
    }

    var defaultValue = newDefaultValue;

    if (newType != null) {
      if (newType!.type == ClassFieldType.undefined) //
        return DbCmdResult.fail('Key type is not specified');

      if (newType!.type == ClassFieldType.reference && newType!.classId == null) //
        return DbCmdResult.fail('Class reference is not specified');

      defaultValue ??= field.defaultValue;

      //TODO! @sergey test
      if (!newType!.type.isSimple()) {
        final allClassesUsingField = dbModel.cache.allClasses //
            .where((e) => dbModel.cache.getAllFieldsByClassId(e.id)!.any((f) => f == field))
            .map((e) => e.id)
            .toSet();
        if (dbModel.cache.allClasses.any(
          (e) => dbModel.cache
              .getAllFields(e)
              .any((f) => f.typeInfo.type == ClassFieldType.listInline && allClassesUsingField.contains(f.valueTypeInfo!.classId)),
        )) {
          return DbCmdResult.fail('The field can not have a complex type because it is used in a multiValue list');
        }
      }

      if (newType!.type.hasKeyType()) {
        if (newKeyType == null || newKeyType!.type == ClassFieldType.undefined) //
          return DbCmdResult.fail('Key type is not specified');

        if (newKeyType!.type == ClassFieldType.reference && newKeyType!.classId == null) //
          return DbCmdResult.fail('Class reference is not specified');

        if (!newKeyType!.type.isSimple()) //
          return DbCmdResult.fail('Specified type is not simple');
      }

      if (newType!.type.hasValueType()) {
        if (newValueType == null || newValueType!.type == ClassFieldType.undefined) //
          return DbCmdResult.fail('Value type is not specified');

        if (newValueType!.type == ClassFieldType.reference && newValueType!.classId == null) //
          return DbCmdResult.fail('Class reference is not specified');

        if (!newValueType!.type.isSimple()) //
          return DbCmdResult.fail('Specified type is not simple');
      }

      if (newType!.type.hasMultiValueType()) {
        //TODO! @sergey test
        if (newValueType == null || newValueType!.type == ClassFieldType.undefined) //
          return DbCmdResult.fail('Value type is not specified');

        if (newValueType!.type == ClassFieldType.reference && newValueType!.classId == null) //
          return DbCmdResult.fail('Class reference is not specified');

        if (newValueType!.type != ClassFieldType.reference) //
          return DbCmdResult.fail('Specified type must be a reference');

        final newValueClass = dbModel.cache.getClass(newValueType!.classId)!;
        if (newValueClass is! ClassMetaEntity) return DbCmdResult.fail('Specified type must be a class');

        final valueClassType = newValueClass.classType;
        if (valueClassType != ClassType.referenceType && valueClassType != ClassType.valueType) //
          return DbCmdResult.fail('Specified type must be a non abstract class');

        final newColumns = DbModelUtils.getListMultiColumns(dbModel, newValueType!)!;
        for (var column in newColumns) {
          if (!column.typeInfo.type.isSimple()) //
            return DbCmdResult.fail('Specified type contains a column that is not simple');
        }
      }
    }

    if (defaultValue?.isNotEmpty ?? false) {
      final type = newType ?? field.typeInfo;
      final keyType = newType != null ? newKeyType : field.keyTypeInfo;
      final valueType = newType != null ? newValueType : field.valueTypeInfo;

      if (DbModelUtils.parseDefaultValue(dbModel, type, keyType, valueType, defaultValue!) == null) //
        return DbCmdResult.fail('Incorrect default value');
    }

    final validateDataColumnsResult = DbModelUtils.validateDataByColumns(dbModel, valuesByTable);
    if (!validateDataColumnsResult.success) //
      return validateDataColumnsResult;

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId) as ClassMetaEntity;
    final field = dbModel.cache.getField(fieldId, entity)!;

    Map<String, List<DataTableColumn>>? valuesByTable;
    if (newType != null || newKeyType != null || newValueType != null || newDefaultValue != null) {
      valuesByTable = {};
      for (var table in dbModel.cache.allDataTables) {
        final dataColumns = DbModelUtils.getDataColumns(dbModel, table, columns: [field]);
        if (dataColumns.isNotEmpty) {
          valuesByTable[table.id] = dataColumns;
        }
      }
    }

    final listInlineValuesByTableColumn = <String, Map<int, List<List<dynamic>>>>{};
    final fieldsUsingInline = DbModelUtils.getFieldsUsingInlineClass(dbModel, entity);
    for (var fieldUsingInline in fieldsUsingInline) {
      for (var table in dbModel.cache.allDataTables) {
        final fields = dbModel.cache.getAllFieldsByClassId(table.classId)!;
        final columnIndex = fields.indexOf(fieldUsingInline);
        if (columnIndex <= -1) //
          continue;

        final listInlineField = fields[columnIndex];
        final inlineColumns = DbModelUtils.getListMultiColumns(dbModel, listInlineField.valueTypeInfo!);
        final inlineColumnIndex = inlineColumns!.indexOf(field);

        listInlineValuesByTableColumn.addIfMissing(table.id, (_) => {});
        listInlineValuesByTableColumn[table.id]!.addIfMissing(inlineColumnIndex, (_) => []);

        for (var i = 0; i < table.rows.length; i++) {
          final row = table.rows[i];
          final cellValues = row.values[columnIndex].listCellValues!;

          listInlineValuesByTableColumn[table.id]![inlineColumnIndex]!.add([]);
          for (var j = 0; j < cellValues.length; j++) {
            final cellValue = cellValues[j];
            listInlineValuesByTableColumn[table.id]![inlineColumnIndex]![i]
                .add((cellValue as DataTableCellMultiValueItem).values![inlineColumnIndex]);
          }
        }
      }
    }

    return DbCmdEditClassField.values(
      entityId: entityId,
      fieldId: newId ?? fieldId,
      newId: newId != null ? fieldId : null,
      newDescription: newDescription != null ? field.description : null,
      newIsUniqueValue: newIsUniqueValue != null ? field.isUniqueValue : null,
      newToExportValue: newToExportValue != null ? field.toExport : null,
      newType: newType != null ? ClassFieldDescriptionDataInfo.fromJson(field.typeInfo.toJson().clone()) : null,
      newKeyType:
          newKeyType != null && field.keyTypeInfo != null ? ClassFieldDescriptionDataInfo.fromJson(field.keyTypeInfo!.toJson().clone()) : null,
      newValueType:
          newValueType != null && field.valueTypeInfo != null ? ClassFieldDescriptionDataInfo.fromJson(field.valueTypeInfo!.toJson().clone()) : null,
      newDefaultValue: newDefaultValue != null ? field.defaultValue : null,
      valuesByTable: valuesByTable,
      listInlineValuesByTableColumn: listInlineValuesByTableColumn,
    );
  }
}
