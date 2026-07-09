import 'dart:convert';

import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/generator_json.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/server/generators/json/generator_json_root.dart';
import 'package:sort_json/utils/json_sorter.dart';

import 'generators_job.dart';

class GeneratorJsonRunner extends BaseGeneratorRunner<GeneratorJson> with OutputFolderSaver, FilesComparer {
  @override
  Future<GeneratorResult> execute(String outputFolder, DbModel model, GeneratorJson data, GeneratorAdditionalInformation additionalInfo) async {
    final result = GeneratorJsonRoot();
    result.generationDate = additionalInfo.date;
    result.generationUser = additionalInfo.user;

    final pathByEnumMap = <String, Map<String, String>>{};
    for (final enumEntity in model.cache.allEnums) {
      if (enumEntity.autoByFile) {
        final enumValuesMap = <String, String>{};
        for (final value in enumEntity.values) {
          enumValuesMap[value.id] = value.description;
        }
        pathByEnumMap[enumEntity.id] = enumValuesMap;
      }
    }
    if (pathByEnumMap.isNotEmpty) {
      result.pathByEnum = pathByEnumMap;
    }

    try {
      for (final table in model.cache.allDataTables) {
        final items = <Map<String, dynamic>>[];

        for (final row in table.rows) {
          final rowData = <String, dynamic>{};

          final allFields = model.cache.getAllFieldsByClassId(table.classId);
          if (allFields != null) {
            for (var i = 0; i < allFields.length; i++) {
              final field = allFields[i];

              if (field.typeInfo.type.hasMultiValueType()) {
                final listRows = row.values[i].listInlineCellValues()!;
                final columns = DbModelUtils.getListInlineColumns(model, field.valueTypeInfo!)!;

                final outInlineRows = <Map<String, dynamic>>[];
                rowData[field.id] = outInlineRows;

                for (var i = 0; i < listRows.length; i++) {
                  final inlineRow = <String, dynamic>{};
                  outInlineRows.add(inlineRow);
                  for (var j = 0; j < columns.length; j++) {
                    inlineRow[columns[j].id] = listRows[i].values![j];
                  }
                }
              } else if (field.typeInfo.type.hasKeyType()) {
                final dictRows = row.values[i].dictionaryCellValues();
                if (dictRows != null) {
                  final mapData = <String, dynamic>{};
                  for (final item in dictRows) {
                    if (item.key != null) {
                      mapData[item.key.toString()] = item.value;
                    }
                  }
                  rowData[field.id] = mapData;
                } else {
                  rowData[field.id] = {};
                }
              } else {
                rowData[field.id] = _convertToSimpleFormat(field.typeInfo.type, row.values[i].simpleValue);
              }
            }
          }

          items.add({'id': row.id, ...rowData});
        }

        result.tables[table.id] = items;
      }

      final prioritizedKeys = ['id'];
      final encoded = JsonEncoder.withIndent(data.indentation).convert(result.toJson());
      final decoded = jsonDecode(encoded); // need to convert to array/object for the package to correctly sort keys
      final sortedJson = JsonSorter.sortJson(decoded, prioritized: prioritizedKeys);
      final resultJson = JsonEncoder.withIndent(data.indentation).convert(sortedJson);

      final previousResult = await readFromFile(
        outputFolder: outputFolder,
        fileName: data.fileName,
        fileExtension: data.fileExtension,
      );

      final tablesChanged = resultChanged(resultJson, previousResult, '"tables": {');
      final pathByEnumChanged = resultChanged(resultJson, previousResult, '"pathByEnum": {');

      if (!tablesChanged && !pathByEnumChanged) //
        return GeneratorResult.success();

      final saveError = await saveToFile(
        outputFolder: outputFolder,
        fileName: data.fileName,
        fileExtension: data.fileExtension,
        data: resultJson,
      );

      if (saveError != null) //
        return GeneratorResult.error(saveError);
      // ignore: unused_catch_stack
    } catch (e, callstack) {
      return GeneratorResult.error(e.toString());
    }

    return GeneratorResult.success();
  }

  dynamic _convertToSimpleFormat(ClassFieldType type, dynamic value) {
    if (value is! String) return value;

    switch (type) {
      case ClassFieldType.date:
        final date = DbModelUtils.parseDate(value);
        return date?.millisecondsSinceEpoch;
      case ClassFieldType.duration:
        final duration = DbModelUtils.parseDuration(value);
        return duration?.inMilliseconds;
      case ClassFieldType.vector2:
        final v = DbModelUtils.parseVector2(value);
        return v != null ? '${v.x};${v.y}' : value;
      case ClassFieldType.vector2Int:
        final v = DbModelUtils.parseVector2Int(value);
        return v != null ? '${v.x};${v.y}' : value;
      case ClassFieldType.vector3:
        final v = DbModelUtils.parseVector3(value);
        return v != null ? '${v.x};${v.y};${v.z}' : value;
      case ClassFieldType.vector3Int:
        final v = DbModelUtils.parseVector3Int(value);
        return v != null ? '${v.x};${v.y};${v.z}' : value;
      case ClassFieldType.vector4:
        final v = DbModelUtils.parseVector4(value);
        return v != null ? '${v.x};${v.y};${v.z};${v.w}' : value;
      case ClassFieldType.vector4Int:
        final v = DbModelUtils.parseVector4Int(value);
        return v != null ? '${v.x};${v.y};${v.z};${v.w}' : value;
      case ClassFieldType.rectangle:
        final v = DbModelUtils.parseRectangle(value);
        return v != null ? '${v.x};${v.y};${v.width};${v.height}' : value;
      case ClassFieldType.rectangleInt:
        final v = DbModelUtils.parseRectangleInt(value);
        return v != null ? '${v.x};${v.y};${v.width};${v.height}' : value;
      default:
        return value;
    }
  }
}
