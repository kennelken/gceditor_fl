import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/data_table_cell_dictionary_item.dart';
import 'package:gceditor/utils/utils.dart';

import 'data_table_cell_list_inline_item.dart';
import 'db_model_shared.dart';

class DataTableCellValue {
  dynamic simpleValue;
  List<dynamic>? listCellValues;
  List<DataTableCellDictionaryItem>? dictionaryCellValues() => listCellValues == null
      ? null
      : List<DataTableCellDictionaryItem>.unmodifiable(
          (listCellValues?.isNotEmpty ?? false) && listCellValues![0] is DataTableCellDictionaryItem
              ? List.from(listCellValues!.map((e) => e as DataTableCellDictionaryItem))
              : List<DataTableCellDictionaryItem>.empty(),
        );

  List<DataTableCellListInlineItem>? listInlineCellValues() => listCellValues == null
      ? null
      : List<DataTableCellListInlineItem>.unmodifiable(
          (listCellValues?.isNotEmpty ?? false) && listCellValues![0] is DataTableCellListInlineItem
              ? List.from(listCellValues!.map((e) => e as DataTableCellListInlineItem))
              : List<DataTableCellListInlineItem>.empty(),
        );

  DataTableCellValue();

  DataTableCellValue.simple(dynamic value) {
    simpleValue = value;
  }

  DataTableCellValue.list(List<dynamic> value) {
    listCellValues = value;
  }

  DataTableCellValue.dictionary(List<DataTableCellDictionaryItem> value) {
    listCellValues = value;
  }

  DataTableCellValue.listInline(List<DataTableCellListInlineItem> value) {
    listCellValues = value;
  }

  DataTableCellValue copy() {
    return DataTableCellValue()
      ..simpleValue = simpleValue
      ..listCellValues = listCellValues != null //
          ? List.from(listCellValues!
              .map((e) => ((e as Object?)?.safeAs<DataTableCellDictionaryItem>()?.copy() ?? e?.safeAs<DataTableCellListInlineItem>()?.copy() ?? e)))
          : null;
  }

  factory DataTableCellValue.fromJson(dynamic json) {
    final result = DataTableCellValue();

    result.simpleValue = json;
    if (json is List<dynamic>) {
      result.listCellValues = json;
      final jsonMap = json.isNotEmpty ? json[0] : null;
      if (jsonMap is Map<String, dynamic>) {
        if (jsonMap.containsKey('vs')) {
          result.listCellValues = List.from(json.map((e) => DataTableCellListInlineItem.fromJson(e)));
        } else {
          result.listCellValues = List.from(json.map((e) => DataTableCellDictionaryItem.fromJson(e)));
        }
      }
    }
    return result;
  }

  dynamic toJson() {
    if (listCellValues?.isNotEmpty ?? false) {
      if (listCellValues![0] is DataTableCellDictionaryItem) {
        return listCellValues!.map((e) => (e as DataTableCellDictionaryItem).toJson()).toList();
      }
      if (listCellValues![0] is DataTableCellListInlineItem) {
        return listCellValues!.map((e) => (e as DataTableCellListInlineItem).toJson()).toList();
      }
      return listCellValues!.toList();
    }
    if (listCellValues != null) {
      return [];
    }
    return simpleValue;
  }

  void specifyType(ClassMetaFieldDescription? field) {
    if (field == null) //
      return;

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
        listCellValues = null;
        break;

      case ClassFieldType.list:
      case ClassFieldType.listInline:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        simpleValue = null;
        break;
    }
  }
}
