import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:darq/darq.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_view.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/data_table_cell_dictionary_item.dart';
import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_cmd/db_cmd_result.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'service/client_navigation_service.dart';

final dateFormatter = DateFormat('yyyy.MM.dd HH:mm');

extension ClassFieldTypeExtensions on ClassFieldType {
  bool isList() {
    return hasKeyType() || hasValueType();
  }

  bool isSimple() {
    return !isList() && this != ClassFieldType.text;
  }

  bool hasKeyType() {
    return this == ClassFieldType.dictionary;
  }

  bool hasValueType() {
    return this == ClassFieldType.dictionary || this == ClassFieldType.list || this == ClassFieldType.set;
  }
}

extension ClassMetaFieldDescriptionExtensions on ClassMetaFieldDescription {
  int getFieldsUniqueId() {
    return hashCode ^ typeInfo.hashCode + (keyTypeInfo?.hashCode ?? 0) ^ (valueTypeInfo?.hashCode ?? 0);
  }
}

class DbModelUtils {
  static List<ClassFieldType>? _sortedFieldTypes;
  static List<ClassFieldType> get sortedFieldTypes {
    _sortedFieldTypes ??= ClassFieldType.values.where((e) => e != ClassFieldType.undefined).orderBy((e) => e.isList() ? 1 : 0).toList();
    return _sortedFieldTypes!;
  }

  static List<ClassType>? _allowedClassTypes;
  static List<ClassType> get allowedClassTypes {
    _allowedClassTypes ??= ClassType.values.where((e) => e != ClassType.undefined).toList();
    return _allowedClassTypes!;
  }

  static DateTime? parseDate(String value) {
    DateTime? result;

    final match = Config.dateFormatRegex.firstMatch(value);
    if (match == null) //
      return result;

    final year = match.namedGroup('y');
    final month = match.namedGroup('m');
    final day = match.namedGroup('d');
    final hour = match.namedGroup('hh');
    final minute = match.namedGroup('mm');
    final second = match.namedGroup('ss');

    try {
      result = DateTime(
        int.parse(year!),
        int.parse(month!),
        int.parse(day!),
        int.parse(hour!),
        int.parse(minute!),
        second == null ? 0 : int.parse(second),
      );
    } catch (e, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
      return null;
    }

    return result;
  }

  static Duration? parseDuration(String value) {
    Duration? result;

    final match = Config.durationFormatRegex.firstMatch(value);
    if (match == null) //
      return result;

    final days = match.namedGroup('d');
    final hours = match.namedGroup('h');
    final minutes = match.namedGroup('m');
    final seconds = match.namedGroup('s');

    try {
      result = Duration(
        days: days == null ? 0 : int.parse(days),
        hours: hours == null ? 0 : int.parse(hours),
        minutes: minutes == null ? 0 : int.parse(minutes),
        seconds: seconds == null ? 0 : int.parse(seconds),
      );
    } catch (e, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
      return null;
    }

    return result;
  }

  static DataTableCellValue parseDefaultValueByFieldOrDefault(ClassMetaFieldDescription field, String value) {
    return parseDefaultValueByField(field, value) ?? getDefaultValue(field.typeInfo.type);
  }

  static DataTableCellValue? parseDefaultValueByField(ClassMetaFieldDescription field, String value, {bool silent = false}) {
    return parseDefaultValue(
      field.typeInfo,
      field.keyTypeInfo,
      field.valueTypeInfo,
      value,
      silent: silent,
    );
  }

  static DataTableCellValue? parseDefaultValue(
    ClassFieldDescriptionDataInfo type,
    ClassFieldDescriptionDataInfo? keyType,
    ClassFieldDescriptionDataInfo? valueType,
    String value, {
    bool silent = false,
  }) {
    if (value.isEmpty) //
      return getDefaultValue(type.type);

    switch (type.type) {
      case ClassFieldType.undefined:
        return null;

      case ClassFieldType.bool:
        final result = Utils.tryParseBool(value);
        return result == null ? null : DataTableCellValue.simple(result == true ? 1 : 0);

      case ClassFieldType.int:
      case ClassFieldType.long:
        var result = int.tryParse(value);
        result ??= double.tryParse(value)?.toInt();
        return result == null ? null : DataTableCellValue.simple(result);

      case ClassFieldType.color:
        var result = int.tryParse(value);
        result ??= double.tryParse(value)?.toInt();
        return result == null || result > Config.colorMinValue || result > Config.colorMaxValue ? null : DataTableCellValue.simple(result);

      case ClassFieldType.float:
      case ClassFieldType.double:
        final result = double.tryParse(value);
        return result == null ? null : DataTableCellValue.simple(result);

      case ClassFieldType.string:
      case ClassFieldType.text:
        return DataTableCellValue.simple(value);

      case ClassFieldType.reference:
        if (!validateId(value)) //
          return null;
        return DataTableCellValue.simple(value);

      case ClassFieldType.date:
        return DataTableCellValue.simple(simpleValueToText(parseDate(value)));

      case ClassFieldType.duration:
        return DataTableCellValue.simple(simpleValueToText(parseDuration(value)));

      case ClassFieldType.list:
      case ClassFieldType.set:
        try {
          final list = jsonDecode(value) ?? [];
          final valuesList = list
              .map(
                (e) => parseDefaultValue(valueType!, null, null, e.toString())?.simpleValue,
              )
              .toList();

          if (valuesList.any((e) => e == null)) //
            return null;

          final resultList = DataTableCellValue.list(valuesList);
          return resultList;
        } catch (e, callstack) {
          if (!silent) //
            providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
          return null;
        }

      case ClassFieldType.dictionary:
        try {
          final map = jsonDecode(value) ?? [];
          final valuesList = map
              .map(
                (v) => DataTableCellDictionaryItem.values(
                  key: parseDefaultValue(keyType!, null, null, v[0])?.simpleValue,
                  value: parseDefaultValue(valueType!, null, null, v[1])?.simpleValue,
                ),
              )
              .toList();

          if (valuesList.any((e) => e.key == null || e.value == null)) //
            return null;

          final resultList = DataTableCellValue.dictionary(valuesList);
          return resultList;
        } catch (e, callstack) {
          if (!silent) //
            providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
          return null;
        }
    }
  }

  static bool validateId(String value) {
    return Config.idFormatRegex.hasMatch(value);
  }

  static String getRandomId() {
    return '_' + const Uuid().v4().replaceAll('-', '_').substring(0, 23);
  }

  static bool isDefaultId(String value) {
    return Config.defaultIdFormat.hasMatch(value);
  }

  static void selectAllIfDefaultId(TextEditingController controller) {
    if (isDefaultId(controller.text)) {
      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    }
  }

  static void selectAllIfDefault(TextEditingController controller, String? defaultValue) {
    if (controller.text == defaultValue) {
      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    }
  }

  static List<DataTableRow> copyValues(
      List<DataTableRow> from, List<ClassMetaFieldDescription> fieldsFrom, List<ClassMetaFieldDescription> fieldsTo) {
    final result = <DataTableRow>[];

    final indexInOldFields = <int?>[];

    for (var i = 0; i < fieldsTo.length; i++) {
      indexInOldFields.add(null);
      for (var j = 0; j < fieldsFrom.length; j++) {
        if (fieldsFrom[j].id == fieldsTo[i].id) {
          indexInOldFields[i] = j;
          break;
        }
      }
    }

    final defaultValues = parseDefaultValues(fieldsTo);

    for (var row in from) {
      final newRow = DataTableRow();
      newRow.id = row.id;

      for (var i = 0; i < fieldsTo.length; i++) {
        final value = indexInOldFields[i] != null ? row.values[indexInOldFields[i]!] : null;
        newRow.values.add(value ?? defaultValues[fieldsTo[i]]!);
      }

      result.add(newRow);
    }

    return result;
  }

  static bool validateValue(ClassMetaFieldDescription field, DataTableCellValue value) {
    switch (field.typeInfo.type) {
      case ClassFieldType.list:
      case ClassFieldType.set:
        return value.listCellValues != null && value.listCellValues!.every((e) => validateSimpleValue(field.valueTypeInfo!.type, e));

      case ClassFieldType.dictionary:
        return value.dictionaryCellValues != null &&
            value.dictionaryCellValues!.every(
              (e) => validateSimpleValue(field.keyTypeInfo!.type, e.key) && validateSimpleValue(field.valueTypeInfo!.type, e.value),
            );

      default:
        return validateSimpleValue(field.typeInfo.type, value.simpleValue);
    }
  }

  static bool validateSimpleValue(ClassFieldType type, dynamic value) {
    switch (type) {
      case ClassFieldType.undefined:
        return true;

      case ClassFieldType.bool:
        return value == 1 || value == 0;

      case ClassFieldType.int:
        return value is int && value >= Config.intMinValue && value <= Config.intMaxValue;
      case ClassFieldType.long:
        return value is int;
      case ClassFieldType.color:
        return value is int && value >= Config.colorMinValue && value <= Config.colorMaxValue;

      case ClassFieldType.float:
        return value is int || value is double && value >= Config.floatMinValue && value <= Config.floatMaxValue;
      case ClassFieldType.double:
        return value is int || value is double;

      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.reference:
        return value is String;

      case ClassFieldType.date:
        return value is String && parseDate(value) != null;

      case ClassFieldType.duration:
        return value is String && parseDuration(value) != null;

      case ClassFieldType.list:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        return false;
    }
  }

  static Map<ClassMetaFieldDescription, DataTableCellValue> parseDefaultValues(List<ClassMetaFieldDescription> list) {
    final result = <ClassMetaFieldDescription, DataTableCellValue>{};
    for (var field in list) {
      result[field] = parseDefaultValueByField(field, field.defaultValue) ?? getDefaultValue(field.typeInfo.type);
    }
    return result;
  }

  static DataTableCellValue getDefaultValue(ClassFieldType type) {
    switch (type) {
      case ClassFieldType.undefined:
        throw Exception('Unexpected type "$type"');

      case ClassFieldType.bool:
        return DataTableCellValue.simple(0);

      case ClassFieldType.int:
      case ClassFieldType.long:
        return DataTableCellValue.simple(0);
      case ClassFieldType.color:
        return DataTableCellValue.simple(Config.colorMaxValue);

      case ClassFieldType.float:
      case ClassFieldType.double:
        return DataTableCellValue.simple(0.0);

      case ClassFieldType.string:
      case ClassFieldType.text:
        return DataTableCellValue.simple('');

      case ClassFieldType.reference:
        return DataTableCellValue.simple('');

      case ClassFieldType.list:
      case ClassFieldType.set:
        return DataTableCellValue.list([]);
      case ClassFieldType.dictionary:
        return DataTableCellValue.dictionary([]);

      case ClassFieldType.date:
        return DataTableCellValue.simple(simpleValueToText(Config.defaultDateTime));

      case ClassFieldType.duration:
        return DataTableCellValue.simple(simpleValueToText(Duration.zero));
    }
  }

  static double getTableRowsHeight(
    DbModel model, {
    ClassMetaEntity? classEntity,
    required TableMetaEntity table,
  }) {
    final thisClass = model.cache.getClass(table.classId) as ClassMetaEntity?;
    return (model.cache.hasBigCells(thisClass) ? kStyle.kDataTableRowListHeight : kStyle.kDataTableRowHeight) * (table.rowHeightMultiplier ?? 1.0);
  }

  static double getTableIdsColumnWidth(TableMetaEntity table, [bool applyScale = true]) {
    final scale = applyScale ? kScale : 1.0;
    return (table.idsColumnWidth <= 0 ? 200 : table.idsColumnWidth.clamp(Config.minColumnWidth, 1000)) * scale;
  }

  static double getTableColumnWidth(TableMetaEntity table, ClassMetaFieldDescription field, [bool applyScale = true]) {
    final scale = applyScale ? kScale : 1.0;

    if (table.columWidth.containsKey(field.id)) //
      return max(Config.minColumnWidth, table.columWidth[field.id]!) * scale;

    switch (field.typeInfo.type) {
      case ClassFieldType.undefined:
        return Config.minColumnWidth;

      case ClassFieldType.bool:
      case ClassFieldType.color:
        return 130 * scale;

      case ClassFieldType.int:
      case ClassFieldType.long:
        return 150 * scale;

      case ClassFieldType.float:
      case ClassFieldType.double:
        return 200 * scale;

      case ClassFieldType.string:
      case ClassFieldType.text:
        return 200 * scale;

      case ClassFieldType.reference:
        return 250 * scale;

      case ClassFieldType.list:
        return 250 * scale;

      case ClassFieldType.set:
        return 250 * scale;

      case ClassFieldType.dictionary:
        return 430 * scale;

      case ClassFieldType.date:
        return 200 * scale;

      case ClassFieldType.duration:
        return 200 * scale;
    }
  }

  static double getTableKeyToValueRatio(TableMetaEntity table, ClassMetaFieldDescription field) {
    if (table.columnKeyToValueWidthRatio.containsKey(field.id)) //
      return table.columnKeyToValueWidthRatio[field.id]!.clamp(Config.minKeysToValuesRatio, 1 - Config.minKeysToValuesRatio);

    return Config.defaultKeysToValues;
  }

  static double getTableWidth(DbModel model, TableMetaEntity table, bool withIds, {String? upToFieldId}) {
    final classEntity = model.cache.getClass<ClassMetaEntity>(table.classId);
    if (classEntity == null) //
      return 0;

    var result = 0.0;
    for (final field in model.cache.getAllFields(classEntity)) {
      if (field.id == upToFieldId) //
        break;
      result += getTableColumnWidth(table, field);
    }

    if (withIds) //
      result += getTableIdsColumnWidth(table);

    return result;
  }

  static List<DataTableColumn> getDataColumns(
    DbModel model,
    TableMetaEntity table, {
    List<ClassMetaFieldDescription>? columns,
    List<String>? columnsIds,
    List<DataTableColumn>? prioritizedValues,
  }) {
    if (columns != null && columnsIds != null) //
      throw Exception('Only one of the following is allowed to be specified: fields, fieldIds');

    final result = <DataTableColumn>[];

    if (table.classId.isEmpty) //
      return result;

    final classEntity = model.cache.getClass<ClassMetaEntity>(table.classId)!;

    final allFields = model.cache.getAllFields(classEntity);
    var fieldsToSave = columns ?? allFields;
    if (columnsIds != null) //
      fieldsToSave = allFields.where((e) => columnsIds.contains(e.id)).toList();

    for (var field in fieldsToSave) {
      final fieldIndex = allFields.indexOf(field);
      if (fieldIndex <= -1) //
        continue;

      final values = <DataTableCellValue>[];
      result.add(DataTableColumn.data(field.id, values));

      for (var i = 0; i < table.rows.length; i++) {
        values.add(table.rows[i].values[fieldIndex].copy());
      }
    }

    if (prioritizedValues != null) {
      for (var prioritizedColumn in prioritizedValues) {
        result.removeWhere((element) => element.id == prioritizedColumn.id);
        result.add(prioritizedColumn);
      }
    }

    return result;
  }

  static Map<String, DataTableColumn> getDataColumnsMap(
    DbModel model,
    TableMetaEntity table, {
    List<ClassMetaFieldDescription>? columns,
    List<String>? columnsIds,
  }) {
    final list = getDataColumns(
      model,
      table,
      columns: columns,
      columnsIds: columnsIds,
    );

    return {for (var c in list) c.id: c};
  }

  static List<String> getRowIds(TableMetaEntity table) {
    return table.rows.map((e) => e.id).toList();
  }

  static void applyDataColumns(DbModel model, TableMetaEntity table, List<DataTableColumn>? columns) {
    final allColumns = model.cache.getAllFieldsById(table.classId);
    if (allColumns == null) //
      return;

    for (var i = 0; i < allColumns.length; i++) {
      final column = allColumns[i];

      final columnData = columns!.firstWhereOrNull((c) => c.id == column.id);
      if (columnData != null && columnData.values.length != table.rows.length)
        throw Exception('DataTableColumn length "${columnData.values.length}" is not equal to the table length "${table.rows.length}"');

      if (columnData != null) {
        for (var j = 0; j < table.rows.length; j++) {
          table.rows[j].values[i] = columnData.values[j];
        }
      }
    }
  }

  static void applyManyDataColumns(DbModel model, Map<String, List<DataTableColumn>> columnsByTable) {
    for (final tableId in columnsByTable.keys) {
      final table = model.cache.getTable<TableMetaEntity>(tableId)!;
      applyDataColumns(model, table, columnsByTable[tableId]!);
    }
  }

  static void insertDefaultValues(DbModel model, TableMetaEntity table, int columnIndex) {
    final allFields = model.cache.getAllFieldsById(table.classId);
    if (allFields == null) //
      return;

    final field = allFields[columnIndex];
    final defaultValue = model.cache.getDefaultValue(field);
    for (var i = 0; i < table.rows.length; i++) {
      table.rows[i].values.insert(columnIndex, defaultValue);
    }
  }

  static void deleteRowValuesAtColumn(TableMetaEntity table, int columnIndex) {
    for (var i = 0; i < table.rows.length; i++) {
      table.rows[i].values.removeAt(columnIndex);
    }
  }

  static void makeDefaultIfRequired(DbModel model, TableMetaEntity table, Set<ClassMetaFieldDescription> fields) {
    final allFields = model.cache.getAllFieldsById(table.classId);
    if (allFields != null) {
      for (var i = 0; i < allFields.length; i++) {
        final field = allFields[i];
        if (fields.contains(allFields[i])) {
          for (var j = 0; j < table.rows.length; j++) {
            final currentValue = table.rows[j].values[i];
            table.rows[j].values[i] =
                validateAndConvertValueIfRequired(currentValue, field) ?? parseDefaultValueByFieldOrDefault(field, field.defaultValue);
          }
        }
      }
    }
  }

  static DataTableCellValue? validateAndConvertValueIfRequired(DataTableCellValue value, ClassMetaFieldDescription field) {
    switch (field.typeInfo.type) {
      case ClassFieldType.undefined:
      case ClassFieldType.bool:
      case ClassFieldType.int:
      case ClassFieldType.long:
      case ClassFieldType.float:
      case ClassFieldType.double:
      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.reference:
      case ClassFieldType.color:
      case ClassFieldType.date:
      case ClassFieldType.duration:
        final convertedSimpleValue = convertSimpleValueIfPossible(value.simpleValue, field.typeInfo.type);
        return convertedSimpleValue == null ? null : DataTableCellValue.simple(convertedSimpleValue);

      case ClassFieldType.list:
      case ClassFieldType.set:
        if (validateValue(field, value)) //
          return value;
        if (value.listCellValues == null) //
          return null;
        final resultList = value.listCellValues!
            .map(
              (e) => convertSimpleValueIfPossible(e, field.valueTypeInfo!.type) ?? (getDefaultValue(field.valueTypeInfo!.type)).simpleValue,
            )
            .toList();
        return DataTableCellValue.list(resultList);

      case ClassFieldType.dictionary:
        if (validateValue(field, value)) //
          return value;
        if (value.dictionaryCellValues == null) //
          return null;
        final resultList = value.dictionaryCellValues!
            .map(
              (e) => DataTableCellDictionaryItem.values(
                key: convertSimpleValueIfPossible(e.key, field.keyTypeInfo!.type) ?? (getDefaultValue(field.keyTypeInfo!.type)).simpleValue,
                value: convertSimpleValueIfPossible(e.value, field.valueTypeInfo!.type) ?? (getDefaultValue(field.valueTypeInfo!.type)).simpleValue,
              ),
            )
            .toList();
        return DataTableCellValue.dictionary(resultList);
    }
  }

  static dynamic convertSimpleValueIfPossible(dynamic value, ClassFieldType type) {
    if (value == null) //
      return null;

    if (validateSimpleValue(type, value)) //
      return value;

    switch (type) {
      case ClassFieldType.bool:
        final parsedInt = int.tryParse(value.toString());
        if (parsedInt == 0 || parsedInt == 1) //
          return parsedInt;
        final parsedFloat = double.tryParse(value.toString());
        if (parsedFloat == 0.0 || parsedFloat == 1.0) //
          return parsedFloat?.toInt();
        return null;

      case ClassFieldType.int:
      case ClassFieldType.long:
        final parsedInt = int.tryParse(value.toString());
        if (parsedInt != null) //
          return parsedInt;
        final parsedFloat = double.tryParse(value.toString());
        return parsedFloat?.toInt();

      case ClassFieldType.color:
        final parsedValue = int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.toInt();
        return (parsedValue != null) && validateSimpleValue(type, parsedValue) ? parsedValue : null;

      case ClassFieldType.float:
      case ClassFieldType.double:
        final parsedFloat = double.tryParse(value.toString());
        return parsedFloat;

      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.reference:
        return value?.toString() ?? '';

      case ClassFieldType.date:
      case ClassFieldType.duration:
        return null;

      case ClassFieldType.undefined:
      case ClassFieldType.list:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        throw Exception('Unexpected type "${describeEnum(type)}"');
    }
  }

  static void editTableRowId(DbModel model, String currentValue, String newValue) {
    final tableRowData = model.cache.getTableRow(currentValue)!;
    tableRowData.row.id = newValue;

    final classEntity = model.cache.getClass(tableRowData.table.classId);
    if (classEntity == null) //
      return;

    final currentAndParentClasses = [classEntity.id, ...model.cache.getParentClasses(classEntity).map((e) => e.id)];

    for (final currentTable in model.cache.allDataTables) {
      final allFields = model.cache.getAllFieldsById(currentTable.classId);
      if (allFields == null) //
        continue;

      for (var i = 0; i < allFields.length; i++) {
        final field = allFields[i];
        for (var j = 0; j < currentTable.rows.length; j++) {
          _editTableRowReferenceValue(
            (classId) => currentAndParentClasses.contains(classId),
            field,
            currentTable.rows[j].values,
            i,
            currentValue,
            newValue,
            classEntity,
          );
        }
      }
    }
  }

  static void updateEnumReferences(DbModel model, String currentValue, String newValue, ClassMetaEntityEnum classEnum) {
    for (final currentTable in model.cache.allDataTables) {
      final allFields = model.cache.getAllFieldsById(currentTable.classId);
      if (allFields == null) //
        continue;

      for (var i = 0; i < allFields.length; i++) {
        final field = allFields[i];
        for (var j = 0; j < currentTable.rows.length; j++) {
          _editTableRowReferenceValue(
            (classId) => classId == classEnum.id,
            field,
            currentTable.rows[j].values,
            i,
            currentValue,
            newValue,
            classEnum,
          );
        }
      }
    }
  }

  static void _editTableRowReferenceValue(
    bool Function(String? classId) isSuitableClass,
    ClassMetaFieldDescription field,
    List<DataTableCellValue> values,
    int index,
    String whatReplace,
    String replaceTo,
    ClassMeta classEntity,
  ) {
    switch (field.typeInfo.type) {
      case ClassFieldType.undefined:
      case ClassFieldType.bool:
      case ClassFieldType.int:
      case ClassFieldType.long:
      case ClassFieldType.float:
      case ClassFieldType.double:
      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.date:
      case ClassFieldType.duration:
      case ClassFieldType.color:
        break;

      case ClassFieldType.reference:
        if (values[index].simpleValue == whatReplace && isSuitableClass(field.typeInfo.classId)) //
          values[index].simpleValue = replaceTo;
        break;

      case ClassFieldType.list:
      case ClassFieldType.set:
        final list = values[index].listCellValues;
        if (list != null) {
          if (field.valueTypeInfo!.type == ClassFieldType.reference && isSuitableClass(field.valueTypeInfo!.classId)) {
            for (var i = 0; i < list.length; i++) {
              if (list[i] == whatReplace) //
                list[i] = replaceTo;
            }
          }
        }
        break;

      case ClassFieldType.dictionary:
        final list = values[index].dictionaryCellValues;
        if (list != null) {
          if (field.keyTypeInfo!.type == ClassFieldType.reference && isSuitableClass(field.keyTypeInfo!.classId)) {
            for (var i = 0; i < list.length; i++) {
              if (list[i].key == whatReplace) //
                list[i].key = replaceTo;
            }
          }

          if (field.valueTypeInfo!.type == ClassFieldType.reference && isSuitableClass(field.valueTypeInfo!.classId)) {
            for (var i = 0; i < list.length; i++) {
              if (list[i].value == whatReplace) //
                list[i].value = replaceTo;
            }
          }
        }
        break;
    }
  }

  static bool valuesAreEqual(DataTableCellValue a, DataTableCellValue b) {
    if (a.simpleValue != b.simpleValue) return false;
    if (!listEquals(a.listCellValues, b.listCellValues)) return false;
    if ((a.dictionaryCellValues == null) != (b.dictionaryCellValues == null)) //
      return false;
    if (a.dictionaryCellValues != null) {
      if (a.dictionaryCellValues!.length != b.dictionaryCellValues!.length) //
        return false;
      for (var i = 0; i < a.dictionaryCellValues!.length; i++) {
        if (a.dictionaryCellValues![i].key != b.dictionaryCellValues![i].key) //
          return false;
        if (a.dictionaryCellValues![i].value != b.dictionaryCellValues![i].value) //
          return false;
      }
    }
    return true;
  }

  static bool simpleValuesAreEqual(dynamic a, dynamic b) {
    if (a is int && b is int || a is double && b is double || a is String && b is String) {
      return a == b;
    }
    if (a is List && b is List || a is Map && b is Map) {
      return simpleValueToText(a) == simpleValueToText(b);
    }
    if (a is Duration && b is Duration) {
      return a == b;
    }
    if (a is DateTime && b is DateTime) {
      return a == b;
    }
    return false;
  }

  static String? simpleValueToText(dynamic value) {
    if (value is int || value is double || value is String) return value.toString();
    if (value is DateTime) return dateFormatter.format(value);
    if (value is Duration) return _durationToString(value);
    return null;
  }

  static String _durationToString(Duration duration) {
    final days = duration.inDays;
    final hours = (duration - Duration(days: days)).inHours;
    final minutes = (duration - Duration(days: days, hours: hours)).inMinutes;
    final seconds = (duration - Duration(days: days, hours: hours, minutes: minutes)).inSeconds;

    return '${days}d ${hours}h ${minutes}m ${seconds}s';
  }

  static bool validateReferenceExists(DbModel model, ClassFieldDescriptionDataInfo field, String value) {
    if (field.type != ClassFieldType.reference) //
      return false;

    final classEntity = model.cache.getClass(field.classId);
    if (classEntity == null) //
      return false;

    if (value.isEmpty) //
      return classEntity is ClassMetaEntity;

    final availableValues = model.cache.getAvailableValues(classEntity);
    return availableValues?.any((e) => e.id == value) ?? false;
  }

  static List<TableMetaEntity> getAllTablesUsingClass(DbModel model, ClassMetaEntity classEntity) {
    final result = <TableMetaEntity>[];
    final currentClassAndSubclasses = [classEntity, ...model.cache.getImplementingClasses(classEntity)].map((e) => e.id).toSet();
    for (final table in model.cache.allDataTables) {
      if (currentClassAndSubclasses.contains(table.classId)) {
        result.add(table);
      }
    }

    return result;
  }

  static double setColumnWidth(TableMetaEntity table, ClassMetaFieldDescription field, {double? width, double? deltaWidth}) {
    var result = 0.0;

    if (width != null) {
      result = width;
    } else if (deltaWidth != null) {
      result = getTableColumnWidth(table, field, false) + deltaWidth;
    } else {
      throw Exception('At least on of the following should be specified: "width", "deltaWidth"');
    }

    table.columWidth[field.id] = result;
    return result;
  }

  static double setDictionaryColumnRatio(TableMetaEntity table, ClassMetaFieldDescription field, {double? ratio, double? deltaRatio}) {
    var result = getTableKeyToValueRatio(table, field);
    if (ratio != null) {
      result = ratio;
    } else if (deltaRatio != null) {
      result = getTableKeyToValueRatio(table, field) + deltaRatio;
    } else {
      throw Exception('At least on of the following should be specified: "ratio", "deltaRatio"');
    }

    result = result.clamp(Config.minKeysToValuesRatio, 1 - Config.minKeysToValuesRatio);
    table.columnKeyToValueWidthRatio[field.id] = result;
    return result;
  }

  static double setIdsColumnWidth(TableMetaEntity table, {double? width, double? deltaWidth}) {
    var result = 0.0;

    if (width != null) {
      result = width;
    } else if (deltaWidth != null) {
      result = getTableIdsColumnWidth(table, false) + deltaWidth;
    } else {
      throw Exception('At least on of the following should be specified: "width", "deltaWidth"');
    }

    table.idsColumnWidth = result;
    return result;
  }

  static void removeInvalidColumnWidth(DbModel model, TableMetaEntity table) {
    final allFields = model.cache.getAllFieldsById(table.classId);
    if (allFields == null) //
      return;

    var allStoredFields = table.columWidth.keys.toList();
    for (var fieldId in allStoredFields) {
      if (!allFields.any((e) => e.id == fieldId)) //
        table.columWidth.remove(fieldId);
    }

    allStoredFields = table.columnKeyToValueWidthRatio.keys.toList();
    for (var fieldId in allStoredFields) {
      if (!allFields.any((e) => e.id == fieldId)) //
        table.columnKeyToValueWidthRatio.remove(fieldId);
    }
  }

  static void updateFieldIdReferences(DbModel model, ClassMetaEntity entity, String newId, String oldId) {
    for (final table in model.cache.allDataTables) {
      final currentClass = model.cache.getClass(table.classId);
      if (currentClass == null) //
        continue;

      //final classAndParentClasses = [table.classId, ...model.cache.getParentClasses(currentClass)];
      if (entity.id == currentClass.id || model.cache.getParentClasses(currentClass).any((e) => e.id == entity.id)) {
        if (table.columWidth.containsKey(oldId)) {
          table.columWidth[newId] = table.columWidth[oldId]!;
          table.columWidth.remove(oldId);
        }
        if (table.columnKeyToValueWidthRatio.containsKey(oldId)) {
          table.columnKeyToValueWidthRatio[newId] = table.columnKeyToValueWidthRatio[oldId]!;
          table.columnKeyToValueWidthRatio.remove(oldId);
        }
      }
    }
  }

  static String? applyTimezone(String dateText, double timezone) {
    final date = parseDate(dateText);
    if (date == null) //
      return null;

    final newDate = simpleValueToText(date.add(Duration(minutes: (timezone * 60).toInt())))!;
    return newDate;
  }

  static DataTableCellValue? getValueByCoordinates(DbModel model, DataTableValueCoordinates coordinates) {
    final allFields = model.cache.getAllFieldsById(coordinates.table.classId)!;
    final fieldIndex = allFields.indexOf(coordinates.field!);
    final rows = coordinates.table.rows;
    final row = rows.length > coordinates.rowIndex ? rows[coordinates.rowIndex] : null;
    if (fieldIndex <= -1 || row == null) //
      return null;

    final value = coordinates.table.rows[coordinates.rowIndex].values[allFields.indexOf(coordinates.field!)];
    return value;
  }

  static Color getDataCellColor(
    DataTableValueCoordinates coordinates,
    ClientProblemsState clientProblems,
    ClientFindState findState,
    ClientNavigationService navigationService,
  ) {
    final problem = clientProblems.problems.firstWhereOrNull((e) => coordinates.fitsProblem(e));
    final findResult = !findState.visible ? null : findState.getResults()?.firstWhereOrNull((e) => coordinates.fitsFindResult(e.tableItem));
    final isSelected = (navigationService.longLastingNavigationData?.fitsFindResult(findResult) ?? false) ||
        (navigationService.longLastingNavigationData?.fitsProblem(problem) ?? false);

    return findResult?.color().withAlpha(isSelected ? kFindResultBackgroundAlphaSelected : kFindResultBackgroundAlpha) ??
        problem?.color ??
        kColorTransparent;
  }

  static InputDecoration getDataCellInputDecoration(
    DataTableValueCoordinates coordinates,
    ClientProblemsState clientProblems,
    ClientFindState findState,
    ClientNavigationService navigationService,
  ) {
    final problem = clientProblems.problems.firstWhereOrNull((e) => coordinates.fitsProblem(e));
    final findResult = !findState.visible ? null : findState.getResults()?.firstWhereOrNull((e) => coordinates.fitsFindResult(e.tableItem));
    final isSelected = (navigationService.longLastingNavigationData?.fitsFindResult(findResult) ?? false) ||
        (navigationService.longLastingNavigationData?.fitsProblem(problem) ?? false);

    return findResult?.inputDecoration(isSelected) ?? problem?.inputDecoration(isSelected) ?? kStyle.kInputTextStylePropertiesTransparent;
  }

  static InputDecoration getMetaFieldInputDecoration(
    MetaValueCoordinates coordinates,
    ClientFindState findState,
    ClientNavigationService navigationService, {
    InputDecoration? defaultInputDecoration,
    FindResultFieldDefinitionValueType? fieldValueType,
  }) {
    final findResult = !findState.visible ? null : findState.getResults()?.firstWhereOrNull((e) => coordinates.fitsFindResult(e.metaItem));
    final isSelected = coordinates.fitsFindResult(navigationService.longLastingFindResult?.metaItem);

    return findResult?.inputDecoration(isSelected) ?? defaultInputDecoration ?? kStyle.kInputTextStyleProperties;
  }

  static Color getMetaFieldColor(
    MetaValueCoordinates coordinates,
    ClientFindState findState,
    ClientNavigationService navigationService,
    Color color,
  ) {
    final findResult = !findState.visible ? null : findState.getResults()?.firstWhereOrNull((e) => coordinates.fitsFindResult(e.metaItem));
    final isSelected = coordinates.fitsFindResult(navigationService.longLastingFindResult?.metaItem);

    return findResult?.color().withAlpha(isSelected ? kFindResultBackgroundAlphaSelected : kFindResultBackgroundAlpha) ?? color;
  }

  static BoxDecoration getDataTableIdBoxDecoration(
    DataTableValueCoordinates? coordinates,
    ClientFindState findState,
    ClientNavigationService navigationService,
  ) {
    if (coordinates == null) //
      return kStyle.kDataTableEmptyIdBoxDecoration;
    final findResult = !findState.visible ? null : findState.getResults()?.firstWhereOrNull((e) => coordinates.fitsFindResult(e.tableItem));
    final isSelected = navigationService.longLastingNavigationData?.fitsFindResult(findResult) ?? false;

    return findResult?.boxDecoration(isSelected) ?? (kStyle.kDataTableIdBoxDecoration);
  }

  static DataTableRow buildNewRow({
    required DbModel dbModel,
    required String tableId,
    required String rowId,
    DataTableRow? tableRowValues,
  }) {
    final table = dbModel.cache.getTable(tableId) as TableMetaEntity;
    final allFields = dbModel.cache.getAllFieldsById(table.classId) ?? [];

    final newRow = DataTableRow()
      ..id = rowId
      ..values = tableRowValues?.values ?? <DataTableCellValue>[];

    for (var i = 0; i < allFields.length; i++) {
      if (i >= newRow.values.length) //
        newRow.values.add(DbModelUtils.parseDefaultValueByFieldOrDefault(allFields[i], allFields[i].defaultValue));
    }

    return newRow;
  }

  static void stealValues({
    required List<String> columnsFrom,
    required List<String> columnsTo,
    required List<DataTableRow> dataFrom,
    required List<DataTableRow> dataTo,
  }) {
    final fromColumnIndexByToColumnIndex = columnsTo.map((e) => columnsFrom.indexWhere((ei) => ei == e)).toList().asMap();

    for (var i = 0; i < dataTo.length; i++) {
      for (var j = 0; j < columnsTo.length; j++) {
        final indexFrom = fromColumnIndexByToColumnIndex[j];
        if ((indexFrom ?? -1) > -1) {
          dataTo[i].values[j] = dataFrom[i].values[indexFrom!];
        }
      }
    }
  }

  static List<dynamic> encodeDataRowCell(DataTableRow row, {Set<int>? includeColumnsIndexes}) {
    return [row.id as dynamic] //
        .concat(
          row.values.whereIndexed((index, element) => includeColumnsIndexes?.contains(index) ?? true).map(
            (e) {
              if (e.listCellValues != null) //
                return jsonEncode(e.listCellValues);
              if (e.dictionaryCellValues != null) //
                return jsonEncode(e.dictionaryCellValues!.map((e) => [e.key, e.value]).toList());
              return e.simpleValue;
            },
          ),
        )
        .toList();
  }

  static DataTableRow decodeDataRowCell(List<dynamic> rowData, List<String> columns, Map<String, ClassMetaFieldDescription?> columnsData) {
    final result = DataTableRow()
      ..id = rowData[0]
      ..values = rowData.skip(1).select((e, i) {
        final columnData = columnsData[columns[i]];
        if (columnData == null) //
          return DataTableCellValue.simple(e.toString());

        return DbModelUtils.parseDefaultValueByFieldOrDefault(columnData, e?.toString() ?? '');
      }).toList();
    return result;
  }

  static DbCmdResult validateDataByColumns(DbModel dbModel, Map<String, List<DataTableColumn>>? dataColumnsByTable) {
    if (dataColumnsByTable == null) //
      return DbCmdResult.success();

    for (var tableId in dataColumnsByTable.keys) {
      final table = dbModel.cache.getTable(tableId);
      if (table == null) //
        return DbCmdResult.fail('Entity with id "$tableId" does not exist');

      if (table is! TableMetaEntity) //
        return DbCmdResult.fail('Entity with id "$tableId" is not a table');

      if (dataColumnsByTable[tableId]!.any((e) => e.values.length != table.rows.length)) //
        return DbCmdResult.fail('invalid rows count for table "$tableId"');
    }
    return DbCmdResult.success();
  }
}

class MetaValueCoordinates {
  String? classId;
  String? tableId;
  String? enumId;
  String? fieldId;
  String? parentClass;
  FindResultFieldDefinitionValueType? fieldValueType;

  MetaValueCoordinates({
    this.classId,
    this.tableId,
    this.enumId,
    this.fieldId,
    this.parentClass,
    this.fieldValueType,
  });

  bool fitsFindResult(FindResultItemMetaItem? item) {
    if (item == null || //
        parentClass != item.parentClass ||
        fieldValueType != item.fieldValueType) return false;
    return (classId != null && classId == item.classId) && fieldId == item.fieldId && enumId == item.enumId || //
        (tableId != null && tableId == item.tableId);
  }
}
