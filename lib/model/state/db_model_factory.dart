import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/class_meta_group.dart';
import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_settings.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/db/generator_csharp.dart';
import 'package:gceditor/model/db/generator_json.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db/table_meta_group.dart';

class DbModelFactory {
  DbModel createDefaultDbModel() {
    final result = DbModel();

    // classes

    final enumFruitType = ClassMetaEntityEnum()
      ..id = 'FruitType'
      ..description = 'all fruit types here'
      ..values = [
        EnumValue()
          ..id = 'Apple'
          ..description = 'fruit is apple',
        EnumValue()
          ..id = 'Orange'
          ..description = 'fruit is orange',
      ];

    final foodClass = ClassMetaEntity()
      ..id = 'Food'
      ..description = 'food class description'
      ..fields = [
        fieldText('Recipe', defaultValue: ''),
      ];

    final fruitClass = ClassMetaEntity()
      ..id = 'Fruit'
      ..parent = foodClass.id
      ..description = 'fruit class description'
      ..fields = [
        fieldRefEnum('FruitType', enumFruitType.id, defaultValue: 'Apple'),
      ];

    final classesGroup = ClassMetaGroup()
      ..id = 'Classes'
      ..description = 'root folder for classes'
      ..entries = [foodClass, fruitClass];

    final enumsGroup = ClassMetaGroup()
      ..id = 'Enums'
      ..description = 'root folder for enums'
      ..entries = [enumFruitType];

    result.classes.addAll([
      classesGroup,
      enumsGroup,
    ]);

    // values

    final italianFood = TableMetaEntity()
      ..id = 'ItalianFood'
      ..description = 'table for italian food'
      ..classId = 'Food'
      ..rows = [
        DataTableRow()
          ..id = 'Pizza'
          ..values = [
            DataTableCellValue.simple('some pizza recipe'),
          ],
        DataTableRow()
          ..id = 'Pasta'
          ..values = [
            DataTableCellValue.simple('some pasta recipe'),
          ],
      ];

    final fruits = TableMetaEntity()
      ..id = 'Fruits'
      ..description = 'table for fruits'
      ..classId = 'Fruit'
      ..rows = [
        DataTableRow()
          ..id = 'RedApple'
          ..values = [
            DataTableCellValue.simple('N/A'),
            DataTableCellValue.simple('Apple'),
          ],
        DataTableRow()
          ..id = 'NavelOrange'
          ..values = [
            DataTableCellValue.simple('N/A'),
            DataTableCellValue.simple('Orange'),
          ]
      ];

    final foodGroup = TableMetaGroup()
      ..id = 'FoodRoot'
      ..description = 'root folder for food'
      ..entries = [italianFood, fruits];

    result.tables.addAll([
      foodGroup,
    ]);

    result.settings = DbModelSettings()
      ..timeZone = 0.0
      ..generators = [
        generator(GeneratorType.json),
        generator(GeneratorType.csharp),
      ];

    return result;
  }

  static ClassMetaFieldDescription fieldString(String id, {String? defaultValue}) {
    return ClassMetaFieldDescription()
      ..id = id
      ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.string)
      ..defaultValue = defaultValue ?? '';
  }

  static ClassMetaFieldDescription fieldText(String id, {String? defaultValue}) {
    return ClassMetaFieldDescription()
      ..id = id
      ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.text)
      ..defaultValue = defaultValue ?? '';
  }

  static ClassMetaFieldDescription fieldInt(String id, {int? defaultValue}) {
    return ClassMetaFieldDescription()
      ..id = id
      ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.int)
      ..defaultValue = defaultValue?.toString() ?? '0';
  }

  static ClassMetaFieldDescription fieldFloat(String id, {double? defaultValue}) {
    return ClassMetaFieldDescription()
      ..id = id
      ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.float)
      ..defaultValue = defaultValue?.toString() ?? '0';
  }

  static ClassMetaFieldDescription fieldRefClass(String id, String classId, {String? defaultValue}) {
    return ClassMetaFieldDescription()
      ..id = id
      ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.reference, classId: classId)
      ..defaultValue = defaultValue ?? '';
  }

  static ClassMetaFieldDescription fieldRefEnum(String id, String enumId, {String? defaultValue}) {
    return ClassMetaFieldDescription()
      ..id = id
      ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.reference, classId: enumId)
      ..defaultValue = defaultValue ?? '';
  }

  static ClassMetaFieldDescription fieldRefList(String id, String classId, {List<String>? defaultValue}) {
    return ClassMetaFieldDescription()
      ..id = id
      ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.list)
      ..valueTypeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.reference, classId: classId)
      ..defaultValue = jsonEncode(defaultValue);
  }

  static ClassMetaFieldDescription fieldRefSet(String id, String classId, {List<String>? defaultValue}) {
    return ClassMetaFieldDescription()
      ..id = id
      ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.set)
      ..valueTypeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.reference, classId: classId)
      ..defaultValue = jsonEncode(defaultValue);
  }

  static ClassMetaFieldDescription fieldDictStringInt(String id, {Map<String, int>? defaultValue}) {
    return ClassMetaFieldDescription()
      ..id = id
      ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.dictionary)
      ..keyTypeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.string)
      ..valueTypeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.int)
      ..defaultValue = jsonEncode(defaultValue);
  }

  static BaseGenerator generator(GeneratorType generatorType) {
    switch (generatorType) {
      case GeneratorType.undefined:
        throw Exception('Unexpected generator type "${describeEnum(generatorType)}"');

      case GeneratorType.json:
        return GeneratorJson()
          ..fileName = Config.defaultGeneratorName
          ..fileExtension = Config.defaultGeneratorJsonFileExtension
          ..indentation = Config.defaultGeneratorJsonIndentation;

      case GeneratorType.csharp:
        return GeneratorCsharp()
          ..fileName = Config.defaultGeneratorName
          ..fileExtension = Config.defaultGeneratorCsharpFileExtension
          ..namespace = Config.defaultGeneratorCsharpNamespace
          ..prefix = Config.defaultGeneratorCsharpPrefix
          ..prefixInterface = Config.defaultGeneratorCsharpPrefixInterface
          ..postfix = Config.defaultGeneratorCsharpPostfix;
    }
  }
}
