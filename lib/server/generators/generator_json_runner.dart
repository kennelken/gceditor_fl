import 'dart:convert';

import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/generator_json.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/server/generators/json/generator_json_item_list.dart';
import 'package:gceditor/server/generators/json/generator_json_root.dart';

import 'generators_job.dart';
import 'json/generator_json_item.dart';

class GeneratorJsonRunner extends BaseGeneratorRunner<GeneratorJson> with OutputFolderSaver, FilesComparer {
  @override
  Future<GeneratorResult> execute(String outputFolder, DbModel model, GeneratorJson data, GeneratorAdditionalInformation additionalInfo) async {
    final result = GeneratorJsonRoot();
    result.date = additionalInfo.date;
    result.user = additionalInfo.user;

    try {
      for (final table in model.cache.allDataTables) {
        var listEntries = result.classes[table.classId];
        if (listEntries == null) {
          listEntries = GeneratorJsonItemList();
          result.classes[table.classId] = listEntries;
        }

        for (final row in table.rows) {
          final rowData = <String, dynamic>{};
          listEntries.items.add(
            GeneratorJsonItem()
              ..values = rowData
              ..id = row.id,
          );

          final allFields = model.cache.getAllFieldsByClassId(table.classId);
          if (allFields == null) //
            continue;

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
            } else {
              rowData[field.id] = row.values[i];
            }
          }
        }
      }

      final resultJson = JsonEncoder.withIndent(data.indentation).convert(result.toJson());

      final previousResult = await readFromFile(
        outputFolder: outputFolder,
        fileName: data.fileName,
        fileExtension: data.fileExtension,
      );

      if (!resultChanged(resultJson, previousResult, '"classes": {')) //
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
}
