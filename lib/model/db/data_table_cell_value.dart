import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/data_table_cell_dictionary_item.dart';

import 'db_model_shared.dart';

class DataTableCellValue {
  dynamic simpleValue;
  List<dynamic>? listCellValues;
  List<DataTableCellDictionaryItem>? dictionaryCellValues;

  DataTableCellValue();

  DataTableCellValue.simple(dynamic value) {
    simpleValue = value;
  }

  DataTableCellValue.list(List<dynamic> value) {
    listCellValues = value;
  }

  DataTableCellValue.dictionary(List<DataTableCellDictionaryItem> value) {
    dictionaryCellValues = value;
  }

  DataTableCellValue copy() {
    return DataTableCellValue()
      ..simpleValue = simpleValue
      ..listCellValues = listCellValues?.toList()
      ..dictionaryCellValues = dictionaryCellValues?.map((e) => e.copy()).toList();
  }

  factory DataTableCellValue.fromJson(dynamic json) {
    final result = DataTableCellValue();

    result.simpleValue = json;
    if (json is List<dynamic>) {
      result.listCellValues = json;
      if (json.isEmpty || json[0] is Map<String, dynamic>) {
        result.dictionaryCellValues = json.map((e) => DataTableCellDictionaryItem.fromJson(e)).toList();
      }
    }
    return result;
  }

  dynamic toJson() {
    if (dictionaryCellValues != null) {
      return dictionaryCellValues!.map((e) => e.toJson()).toList();
    } else if (listCellValues != null) {
      return listCellValues!.toList();
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
        dictionaryCellValues = null;
        break;

      case ClassFieldType.list:
      case ClassFieldType.set:
        dictionaryCellValues = null;
        simpleValue = null;
        break;

      case ClassFieldType.dictionary:
        listCellValues = null;
        simpleValue = null;
        break;
    }
  }

  static dynamic toJsonSt(DataTableCellValue obj) {
    return obj.toJson();
  }

  static DataTableCellValue fromJsonSt(dynamic obj) {
    return DataTableCellValue.fromJson(obj);
  }
}
