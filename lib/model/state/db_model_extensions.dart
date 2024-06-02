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

import '../db/data_table_cell_multivalue_item.dart';
import 'custom_data_classes.dart';
import 'service/client_navigation_service.dart';

final dateFormatter = DateFormat('yyyy.MM.dd HH:mm');

extension ClassFieldTypeExtensions on ClassFieldType {
  bool isList() {
    return hasKeyType() || hasValueType() || hasMultiValueType();
  }

  bool isEssential() {
    return isList() ||
        this == ClassFieldType.bool ||
        this == ClassFieldType.int ||
        this == ClassFieldType.long ||
        this == ClassFieldType.float ||
        this == ClassFieldType.double ||
        this == ClassFieldType.string ||
        this == ClassFieldType.text ||
        this == ClassFieldType.duration ||
        this == ClassFieldType.date;
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

  bool hasMultiValueType() {
    //TODO! @sergey test
    return this == ClassFieldType.listInline;
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
    _sortedFieldTypes ??= ClassFieldType.values
        .where((e) => e != ClassFieldType.undefined)
        .orderBy((e) => e.isEssential() ? 0 : 1)
        .thenBy((e) => e.isList() ? 1 : 0)
        .toList();
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
    final milliSeconds = match.namedGroup('ms');

    try {
      result = Duration(
        days: days == null ? 0 : int.parse(days),
        hours: hours == null ? 0 : int.parse(hours),
        minutes: minutes == null ? 0 : int.parse(minutes),
        seconds: seconds == null ? 0 : int.parse(seconds),
        milliseconds: milliSeconds == null ? 0 : int.parse(milliSeconds),
      );
    } catch (e, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
      return null;
    }

    return result;
  }

  static Vector2? parseVector2(String value) {
    Vector2? result;

    final match = Config.vector2FormatRegex.firstMatch(value);
    if (match == null) //
      return result;

    final x = match.namedGroup('x');
    final y = match.namedGroup('y');

    try {
      result = Vector2(
        x == null ? 0 : double.parse(x),
        y == null ? 0 : double.parse(y),
      );
    } catch (e, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
      return null;
    }

    return result;
  }

  static Vector2Int? parseVector2Int(String value) {
    Vector2Int? result;

    final match = Config.vector2IntFormatRegex.firstMatch(value);
    if (match == null) //
      return result;

    final x = match.namedGroup('x');
    final y = match.namedGroup('y');

    try {
      result = Vector2Int(
        x == null ? 0 : int.parse(x),
        y == null ? 0 : int.parse(y),
      );
    } catch (e, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
      return null;
    }

    return result;
  }

  static Vector3? parseVector3(String value) {
    Vector3? result;

    final match = Config.vector3FormatRegex.firstMatch(value);
    if (match == null) //
      return result;

    final x = match.namedGroup('x');
    final y = match.namedGroup('y');
    final z = match.namedGroup('z');

    try {
      result = Vector3(
        x == null ? 0 : double.parse(x),
        y == null ? 0 : double.parse(y),
        z == null ? 0 : double.parse(z),
      );
    } catch (e, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
      return null;
    }

    return result;
  }

  static Vector3Int? parseVector3Int(String value) {
    Vector3Int? result;

    final match = Config.vector3IntFormatRegex.firstMatch(value);
    if (match == null) //
      return result;

    final x = match.namedGroup('x');
    final y = match.namedGroup('y');
    final z = match.namedGroup('z');

    try {
      result = Vector3Int(
        x == null ? 0 : int.parse(x),
        y == null ? 0 : int.parse(y),
        z == null ? 0 : int.parse(z),
      );
    } catch (e, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
      return null;
    }

    return result;
  }

  static Vector4? parseVector4(String value) {
    Vector4? result;

    final match = Config.vector4FormatRegex.firstMatch(value);
    if (match == null) //
      return result;

    final x = match.namedGroup('x');
    final y = match.namedGroup('y');
    final z = match.namedGroup('z');
    final w = match.namedGroup('w');

    try {
      result = Vector4(
        x == null ? 0 : double.parse(x),
        y == null ? 0 : double.parse(y),
        z == null ? 0 : double.parse(z),
        w == null ? 0 : double.parse(w),
      );
    } catch (e, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
      return null;
    }

    return result;
  }

  static Vector4Int? parseVector4Int(String value) {
    Vector4Int? result;

    final match = Config.vector4IntFormatRegex.firstMatch(value);
    if (match == null) //
      return result;

    final x = match.namedGroup('x');
    final y = match.namedGroup('y');
    final z = match.namedGroup('z');
    final w = match.namedGroup('w');

    try {
      result = Vector4Int(
        x == null ? 0 : int.parse(x),
        y == null ? 0 : int.parse(y),
        z == null ? 0 : int.parse(z),
        w == null ? 0 : int.parse(w),
      );
    } catch (e, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
      return null;
    }

    return result;
  }

  static Rectangle? parseRectangle(String value) {
    Rectangle? result;

    final match = Config.rectangleFormatRegex.firstMatch(value);
    if (match == null) //
      return result;

    final x = match.namedGroup('x');
    final y = match.namedGroup('y');
    final w = match.namedGroup('w');
    final h = match.namedGroup('h');

    try {
      result = Rectangle(
        x == null ? 0 : double.parse(x),
        y == null ? 0 : double.parse(y),
        w == null ? 0 : double.parse(w),
        h == null ? 0 : double.parse(h),
      );
    } catch (e, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
      return null;
    }

    return result;
  }

  static RectangleInt? parseRectangleInt(String value) {
    RectangleInt? result;

    final match = Config.rectangleIntFormatRegex.firstMatch(value);
    if (match == null) //
      return result;

    final x = match.namedGroup('x');
    final y = match.namedGroup('y');
    final w = match.namedGroup('w');
    final h = match.namedGroup('h');

    try {
      result = RectangleInt(
        x == null ? 0 : int.parse(x),
        y == null ? 0 : int.parse(y),
        w == null ? 0 : int.parse(w),
        h == null ? 0 : int.parse(h),
      );
    } catch (e, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Error: $e\nclasstack: $callstack'));
      return null;
    }

    return result;
  }

  static DataTableCellValue parseDefaultValueByFieldOrDefault(DbModel model, ClassMetaFieldDescription field, String value) {
    return parseDefaultValueByField(model, field, value) ?? getDefaultValue(field.typeInfo.type);
  }

  static DataTableCellValue? parseDefaultValueByField(DbModel model, ClassMetaFieldDescription field, String value, {bool silent = false}) {
    return parseDefaultValue(
      model,
      field.typeInfo,
      field.keyTypeInfo,
      field.valueTypeInfo,
      value,
      silent: silent,
    );
  }

  static DataTableCellValue? parseDefaultValue(
    DbModel model,
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

      case ClassFieldType.vector2:
        return DataTableCellValue.simple(simpleValueToText(parseVector2(value)));

      case ClassFieldType.vector2Int:
        return DataTableCellValue.simple(simpleValueToText(parseVector2Int(value)));

      case ClassFieldType.vector3:
        return DataTableCellValue.simple(simpleValueToText(parseVector3(value)));

      case ClassFieldType.vector3Int:
        return DataTableCellValue.simple(simpleValueToText(parseVector3Int(value)));

      case ClassFieldType.vector4:
        return DataTableCellValue.simple(simpleValueToText(parseVector4(value)));

      case ClassFieldType.vector4Int:
        return DataTableCellValue.simple(simpleValueToText(parseVector4Int(value)));

      case ClassFieldType.rectangle:
        return DataTableCellValue.simple(simpleValueToText(parseRectangle(value)));

      case ClassFieldType.rectangleInt:
        return DataTableCellValue.simple(simpleValueToText(parseRectangleInt(value)));

      case ClassFieldType.list:
      case ClassFieldType.set:
        try {
          final list = jsonDecode(value) ?? [];
          final valuesList = list
              .map(
                (e) => parseDefaultValue(model, valueType!, null, null, e.toString())?.simpleValue,
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
          final list = jsonDecode(value) ?? [];
          final valuesList = list
              .map(
                (v) => DataTableCellDictionaryItem.values(
                  key: parseDefaultValue(model, keyType!, null, null, v[0])?.simpleValue,
                  value: parseDefaultValue(model, valueType!, null, null, v[1])?.simpleValue,
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

      case ClassFieldType.listInline: //TODO! @sergey test
        try {
          final listMulti = jsonDecode(value) ?? [];

          final valuesList = listMulti
              .map(
                (e) => getListMultiColumnsWithValues(model, valueType!, e)!
                    .map((p) => parseDefaultValue(model, p.$1.typeInfo, null, null, p.$2))
                    .toList(),
              )
              .toList();

          if (valuesList.any((e) => e == null)) //
            return null;

          final resultList = DataTableCellValue.listMulti(valuesList);
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
    return '_${const Uuid().v4().replaceAll('-', '_').substring(0, 23)}';
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
    DbModel model,
    List<DataTableRow> from,
    List<ClassMetaFieldDescription> fieldsFrom,
    List<ClassMetaFieldDescription> fieldsTo,
  ) {
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

    final defaultValues = parseDefaultValues(model, fieldsTo);

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

  static bool validateValue(DbModel model, ClassMetaFieldDescription field, DataTableCellValue value) {
    switch (field.typeInfo.type) {
      case ClassFieldType.list:
      case ClassFieldType.set:
        return value.listCellValues != null && //
            value.listCellValues!.every((e) => validateSimpleValue(field.valueTypeInfo!.type, e));

      case ClassFieldType.dictionary:
        final dictionaryValues = value.dictionaryCellValues();
        return dictionaryValues != null &&
            dictionaryValues.length == value.listCellValues?.length &&
            dictionaryValues.every(
              (e) => validateSimpleValue(field.keyTypeInfo!.type, e.key) && validateSimpleValue(field.valueTypeInfo!.type, e.value),
            );

      case ClassFieldType.listInline: //TODO! @sergey test
        final multiValues = value.listMultiCellValues();
        return multiValues != null &&
            multiValues.length == value.listCellValues?.length &&
            multiValues.every(
              (e) => getListMultiColumnsWithValues(model, field.valueTypeInfo!, e.values)! //
                  .every((p) => validateSimpleValue(p.$1.typeInfo.type, p.$2)),
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

      case ClassFieldType.vector2:
        return value is String && parseVector2(value) != null;
      case ClassFieldType.vector2Int:
        return value is String && parseVector2Int(value) != null;
      case ClassFieldType.vector3:
        return value is String && parseVector3(value) != null;
      case ClassFieldType.vector3Int:
        return value is String && parseVector3Int(value) != null;
      case ClassFieldType.vector4:
        return value is String && parseVector4(value) != null;
      case ClassFieldType.vector4Int:
        return value is String && parseVector4Int(value) != null;
      case ClassFieldType.rectangle:
        return value is String && parseRectangle(value) != null;
      case ClassFieldType.rectangleInt:
        return value is String && parseRectangleInt(value) != null;

      case ClassFieldType.list:
      case ClassFieldType.listInline:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        return false;
    }
  }

  static Map<ClassMetaFieldDescription, DataTableCellValue> parseDefaultValues(DbModel model, List<ClassMetaFieldDescription> list) {
    final result = <ClassMetaFieldDescription, DataTableCellValue>{};
    for (var field in list) {
      result[field] = parseDefaultValueByField(model, field, field.defaultValue) ?? getDefaultValue(field.typeInfo.type);
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
      case ClassFieldType.listInline:
        return DataTableCellValue.listMulti([]);

      case ClassFieldType.date:
        return DataTableCellValue.simple(simpleValueToText(Config.defaultDateTime));
      case ClassFieldType.duration:
        return DataTableCellValue.simple(simpleValueToText(Duration.zero));

      case ClassFieldType.vector2:
        return DataTableCellValue.simple(simpleValueToText(Vector2(0, 0)));
      case ClassFieldType.vector2Int:
        return DataTableCellValue.simple(simpleValueToText(Vector2Int(0, 0)));
      case ClassFieldType.vector3:
        return DataTableCellValue.simple(simpleValueToText(Vector3(0, 0, 0)));
      case ClassFieldType.vector3Int:
        return DataTableCellValue.simple(simpleValueToText(Vector3Int(0, 0, 0)));
      case ClassFieldType.vector4:
        return DataTableCellValue.simple(simpleValueToText(Vector4(0, 0, 0, 0)));
      case ClassFieldType.vector4Int:
        return DataTableCellValue.simple(simpleValueToText(Vector4Int(0, 0, 0, 0)));
      case ClassFieldType.rectangle:
        return DataTableCellValue.simple(simpleValueToText(Rectangle(0, 0, 0, 0)));
      case ClassFieldType.rectangleInt:
        return DataTableCellValue.simple(simpleValueToText(RectangleInt(0, 0, 0, 0)));
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
      case ClassFieldType.listInline:
        return 430 * scale;
      case ClassFieldType.set:
        return 250 * scale;
      case ClassFieldType.dictionary:
        return 430 * scale;

      case ClassFieldType.date:
        return 200 * scale;
      case ClassFieldType.duration:
        return 200 * scale;

      case ClassFieldType.vector2:
        return 200 * scale;
      case ClassFieldType.vector2Int:
        return 150 * scale;
      case ClassFieldType.vector3:
        return 250 * scale;
      case ClassFieldType.vector3Int:
        return 200 * scale;
      case ClassFieldType.vector4:
        return 250 * scale;
      case ClassFieldType.vector4Int:
        return 200 * scale;
      case ClassFieldType.rectangle:
        return 250 * scale;
      case ClassFieldType.rectangleInt:
        return 200 * scale;
    }
  }

  static List<double> getTableInnerCellsFlex(DbModel model, TableMetaEntity table, ClassMetaFieldDescription field) {
    if (table.columnInnerCellFlex.containsKey(field.id)) {
      return table.columnInnerCellFlex[field.id]!;
    }

    final columnsCount = DbModelUtils.getInnerCellsCount(model, field)!;
    return List<double>.generate(columnsCount, (_) => 1.0 / columnsCount);
  }

  static List<double> setInnerCellColumnFlex(DbModel model, TableMetaEntity table, ClassMetaFieldDescription field,
      {List<double>? flex, List<double>? deltaRatio}) {
    //TODO! @sergey test
    var result = getTableInnerCellsFlex(model, table, field);
    if (flex != null) {
      result = flex;
    } else if (deltaRatio != null) {
      result = getTableInnerCellsFlex(model, table, field).select((e, i) => e + deltaRatio[i]).toList();
    } else {
      throw Exception('At least on of the following should be specified: "ratio", "deltaRatio"');
    }

    final sum = result.fold(0.0, (v, e) => v + e);
    result = result.map((e) => e / sum).toList();

    final indexesToNormalize = <int>{};
    var sumOfNormalizableValues = 0.0;
    var sumOfFixedValues = 0.0;
    for (var i = 0; i < result.length; i++) {
      if (result[i] <= Config.minInnerCellFlex) {
        result[i] = Config.minInnerCellFlex;
        sumOfFixedValues += result[i];
      } else {
        indexesToNormalize.add(i);
        sumOfNormalizableValues += result[i];
      }
    }

    if (indexesToNormalize.length != result.length && sumOfNormalizableValues > 0) {
      final normalizingCoeff = (1 - sumOfFixedValues) / sumOfNormalizableValues;

      for (var i = 0; i < result.length; i++) {
        if (!indexesToNormalize.contains(i)) //
          continue;

        result[i] = result[i] * normalizingCoeff;
      }
    }

    table.columnInnerCellFlex[field.id] = result;
    return result;
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
    final allColumns = model.cache.getAllFieldsByClassId(table.classId);
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
    final allFields = model.cache.getAllFieldsByClassId(table.classId);
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
    final allFields = model.cache.getAllFieldsByClassId(table.classId);
    if (allFields != null) {
      for (var i = 0; i < allFields.length; i++) {
        final field = allFields[i];
        if (fields.contains(allFields[i])) {
          for (var j = 0; j < table.rows.length; j++) {
            final currentValue = table.rows[j].values[i];
            table.rows[j].values[i] =
                validateAndConvertValueIfRequired(model, currentValue, field) ?? parseDefaultValueByFieldOrDefault(model, field, field.defaultValue);
          }
        }
      }
    }
  }

  static DataTableCellValue? validateAndConvertValueIfRequired(DbModel model, DataTableCellValue value, ClassMetaFieldDescription field) {
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
      case ClassFieldType.vector2:
      case ClassFieldType.vector2Int:
      case ClassFieldType.vector3:
      case ClassFieldType.vector3Int:
      case ClassFieldType.vector4:
      case ClassFieldType.vector4Int:
      case ClassFieldType.rectangle:
      case ClassFieldType.rectangleInt:
        final convertedSimpleValue = convertSimpleValueIfPossible(value.simpleValue, field.typeInfo.type);
        return convertedSimpleValue == null ? null : DataTableCellValue.simple(convertedSimpleValue);

      case ClassFieldType.list:
      case ClassFieldType.set:
        if (validateValue(model, field, value)) //
          return value;
        if (value.listCellValues == null) //
          return null;
        final resultList = value.listCellValues!
            .map(
              (e) => convertSimpleValueIfPossible(e, field.valueTypeInfo!.type) ?? (getDefaultValue(field.valueTypeInfo!.type)).simpleValue,
            )
            .toList();
        return DataTableCellValue.list(resultList);

      case ClassFieldType.listInline: //TODO! @sergey test
        if (validateValue(model, field, value)) //
          return value;
        final listMultiValues = value.listMultiCellValues();
        if (listMultiValues == null) //
          return null;

        final resultList = listMultiValues
            .map(
              (e) => DataTableCellMultiValueItem.values(
                values: getListMultiColumnsWithValues(model, field.valueTypeInfo!, e.values)!
                    .map(
                      (ev) => convertSimpleValueIfPossible(ev.$1, field.keyTypeInfo!.type) ?? (getDefaultValue(field.keyTypeInfo!.type)).simpleValue,
                    )
                    .toList(),
              ),
            )
            .toList();
        return DataTableCellValue.listMulti(resultList);

      case ClassFieldType.dictionary:
        if (validateValue(model, field, value)) //
          return value;
        final dictionaryValues = value.dictionaryCellValues();
        if (dictionaryValues == null) //
          return null;
        final resultList = dictionaryValues
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
      case ClassFieldType.vector2:
      case ClassFieldType.vector2Int:
      case ClassFieldType.vector3:
      case ClassFieldType.vector3Int:
      case ClassFieldType.vector4:
      case ClassFieldType.vector4Int:
      case ClassFieldType.rectangle:
      case ClassFieldType.rectangleInt:
        return null;

      case ClassFieldType.undefined:
      case ClassFieldType.list:
      case ClassFieldType.listInline:
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
      final allFields = model.cache.getAllFieldsByClassId(currentTable.classId);
      if (allFields == null) //
        continue;

      for (var i = 0; i < allFields.length; i++) {
        final field = allFields[i];
        for (var j = 0; j < currentTable.rows.length; j++) {
          _editTableRowReferenceValue(
            model,
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
      final allFields = model.cache.getAllFieldsByClassId(currentTable.classId);
      if (allFields == null) //
        continue;

      for (var i = 0; i < allFields.length; i++) {
        final field = allFields[i];
        for (var j = 0; j < currentTable.rows.length; j++) {
          _editTableRowReferenceValue(
            model,
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
    DbModel model,
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
      case ClassFieldType.vector2:
      case ClassFieldType.vector2Int:
      case ClassFieldType.vector3:
      case ClassFieldType.vector3Int:
      case ClassFieldType.vector4:
      case ClassFieldType.vector4Int:
      case ClassFieldType.rectangle:
      case ClassFieldType.rectangleInt:
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

      case ClassFieldType.listInline: //TODO! @sergey test
        final list = values[index].listMultiCellValues();
        if (list != null) {
          final columns = getListMultiColumns(model, field.valueTypeInfo!)!;
          for (var j = 0; j < columns.length; j++) {
            final column = columns[j];
            if (column.typeInfo.type == ClassFieldType.reference && isSuitableClass(column.typeInfo.classId)) {
              for (var i = 0; i < list.length; i++) {
                if (list[i].values![j] == whatReplace) //
                  list[i].values![j] = replaceTo;
              }
            }
          }
        }
        break;

      case ClassFieldType.dictionary:
        final list = values[index].dictionaryCellValues();
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
    final aDictionaryValues = a.dictionaryCellValues();
    final bDictionaryValues = b.dictionaryCellValues();
    if ((aDictionaryValues == null) != (bDictionaryValues == null)) //
      return false;
    if (aDictionaryValues != null) {
      if (aDictionaryValues.length != bDictionaryValues!.length) //
        return false;
      for (var i = 0; i < aDictionaryValues.length; i++) {
        if (aDictionaryValues[i].key != bDictionaryValues[i].key) //
          return false;
        if (aDictionaryValues[i].value != bDictionaryValues[i].value) //
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
    if (value is Vector2) return _vector2ToString(value);
    if (value is Vector2Int) return _vector2IntToString(value);
    if (value is Vector3) return _vector3ToString(value);
    if (value is Vector3Int) return _vector3IntToString(value);
    if (value is Vector4) return _vector4ToString(value);
    if (value is Vector4Int) return _vector4IntToString(value);
    if (value is Rectangle) return _rectangleToString(value);
    if (value is RectangleInt) return _rectangleIntToString(value);
    return null;
  }

  static String _durationToString(Duration duration) {
    final days = duration.inDays;
    final hours = (duration - Duration(days: days)).inHours;
    final minutes = (duration - Duration(days: days, hours: hours)).inMinutes;
    final seconds = (duration - Duration(days: days, hours: hours, minutes: minutes)).inSeconds;
    final milliSeconds = (duration - Duration(days: days, hours: hours, minutes: minutes, seconds: seconds)).inMilliseconds;

    final result = <String>[];
    if (days != 0) {
      result.add('${days}d');
    }
    if (hours != 0) {
      result.add('${hours}h');
    }
    if (minutes != 0) {
      result.add('${minutes}m');
    }
    if (seconds != 0) {
      result.add('${seconds}s');
    }
    if (milliSeconds != 0) {
      result.add('${milliSeconds}ms');
    }
    if (result.isEmpty) {
      return '0s';
    }
    return result.join(' ');
  }

  static String _vector2ToString(Vector2 value) {
    return 'x:${value.x} y:${value.y}';
  }

  static String _vector2IntToString(Vector2Int value) {
    return 'x:${value.x} y:${value.y}';
  }

  static String _vector3ToString(Vector3 value) {
    return 'x:${value.x} y:${value.y} z:${value.z}';
  }

  static String _vector3IntToString(Vector3Int value) {
    return 'x:${value.x} y:${value.y} z:${value.z}';
  }

  static String _vector4ToString(Vector4 value) {
    return 'x:${value.x} y:${value.y} z:${value.z} w:${value.w}';
  }

  static String _vector4IntToString(Vector4Int value) {
    return 'x:${value.x} y:${value.y} z:${value.z} w:${value.w}';
  }

  static String _rectangleToString(Rectangle value) {
    return 'x:${value.x} y:${value.y} w:${value.width} h:${value.height}';
  }

  static String _rectangleIntToString(RectangleInt value) {
    return 'x:${value.x} y:${value.y} w:${value.width} h:${value.height}';
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
    final allFields = model.cache.getAllFieldsByClassId(table.classId);
    if (allFields == null) //
      return;

    var allStoredFields = table.columWidth.keys.toList();
    for (var fieldId in allStoredFields) {
      if (!allFields.any((e) => e.id == fieldId)) //
        table.columWidth.remove(fieldId);
    }

    allStoredFields = table.columnInnerCellFlex.keys.toList();
    for (var fieldId in allStoredFields) {
      if (!allFields.any((e) => e.id == fieldId)) //
        table.columnInnerCellFlex.remove(fieldId);
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
        if (table.columnInnerCellFlex.containsKey(oldId)) {
          table.columnInnerCellFlex[newId] = table.columnInnerCellFlex[oldId]!;
          table.columnInnerCellFlex.remove(oldId);
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
    final allFields = model.cache.getAllFieldsByClassId(coordinates.table.classId)!;
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
    required DbModel model,
    required String tableId,
    required String rowId,
    DataTableRow? tableRowValues,
  }) {
    final table = model.cache.getTable(tableId) as TableMetaEntity;
    final allFields = model.cache.getAllFieldsByClassId(table.classId) ?? [];

    final newRow = DataTableRow()
      ..id = rowId
      ..values = tableRowValues?.values ?? <DataTableCellValue>[];

    for (var i = 0; i < allFields.length; i++) {
      if (i >= newRow.values.length) //
        newRow.values.add(DbModelUtils.parseDefaultValueByFieldOrDefault(model, allFields[i], allFields[i].defaultValue));
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
              final dictionaryValues = e.dictionaryCellValues();
              if (dictionaryValues != null) //
                return jsonEncode(dictionaryValues.map((e) => [e.key, e.value]).toList());
              final listMultiValues = e.listMultiCellValues();
              if (listMultiValues != null) //
                return jsonEncode(listMultiValues.map((e) => e.values).toList());
              return e.simpleValue;
            },
          ),
        )
        .toList();
  }

  static DataTableRow decodeDataRowCell(
    DbModel model,
    List<dynamic> rowData,
    List<String> columns,
    Map<String, ClassMetaFieldDescription?> columnsData,
  ) {
    final result = DataTableRow()
      ..id = rowData[0]
      ..values = rowData.skip(1).select((e, i) {
        final columnData = columnsData[columns[i]];
        if (columnData == null) //
          return DataTableCellValue.simple(e.toString());

        return DbModelUtils.parseDefaultValueByFieldOrDefault(model, columnData, e?.toString() ?? '');
      }).toList();
    return result;
  }

  static DbCmdResult validateDataByColumns(DbModel model, Map<String, List<DataTableColumn>>? dataColumnsByTable) {
    if (dataColumnsByTable == null) //
      return DbCmdResult.success();

    for (var tableId in dataColumnsByTable.keys) {
      final table = model.cache.getTable(tableId);
      if (table == null) //
        return DbCmdResult.fail('Entity with id "$tableId" does not exist');

      if (table is! TableMetaEntity) //
        return DbCmdResult.fail('Entity with id "$tableId" is not a table');

      if (dataColumnsByTable[tableId]!.any((e) => e.values.length != table.rows.length)) //
        return DbCmdResult.fail('invalid rows count for table "$tableId"');
    }
    return DbCmdResult.success();
  }

  static void specifyDataCellValues(DbModel model) {
    for (final table in model.cache.allDataTables) {
      if (table.classId.isEmpty) //
        return;

      final fields = model.cache.getAllFieldsByClassId(table.classId);
      if (fields == null) {
        throw Exception("Could not find columns for class '${table.classId}'");
      }

      for (final row in table.rows) {
        for (var i = 0; i < row.values.length; i++) {
          row.values[i].specifyType(fields[i]);
        }
      }
    }
  }

  static List<ClassMetaFieldDescription>? getListMultiColumns(DbModel model, ClassFieldDescriptionDataInfo valueType) {
    return model.cache.getAllFieldsByClassId(valueType.classId!)!;
  }

  static List<(ClassMetaFieldDescription, T)>? getListMultiColumnsWithValues<T>(
      DbModel model, ClassFieldDescriptionDataInfo description, List<T>? values) {
    final columns = getListMultiColumns(model, description);
    if (columns?.length != values?.length) {
      throw Exception('Columns and values number mismatch: columns=${columns?.length}, values=${values?.length}');
    }

    var index = 0;
    return columns!.map((e) => (e, values![index++])).toList();
  }

  static int? getInnerCellsCount(DbModel dbModel, ClassMetaFieldDescription field) {
    switch (field.typeInfo.type) {
      case ClassFieldType.dictionary:
        return 2;
      case ClassFieldType.listInline:
        final columns = DbModelUtils.getListMultiColumns(dbModel, field.valueTypeInfo!)!;
        return columns.length;
      default:
        return null;
    }
  }

  static List<ClassMetaFieldDescription> getFieldsUsingInlineClass(DbModel dbModel, ClassMetaEntity classEntity) {
    final allFields = dbModel.cache.allClasses
        .selectMany((c, _) =>
            dbModel.cache.getAllFields(c).where((f) => f.typeInfo.type == ClassFieldType.listInline && f.valueTypeInfo?.classId == classEntity.id))
        .toList();
    return allFields;
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
