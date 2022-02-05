import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:darq/darq.dart';
import 'package:flutter/foundation.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/main.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/generator_csharp.dart';
import 'package:gceditor/model/db/generator_json.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/server/generators/generator_csharp_runner.dart';
import 'package:gceditor/server/generators/generator_json_runner.dart';
import 'package:path/path.dart' as path;

class GeneratorsJob {
  Future<List<GeneratorResult>> start(DbModel model, String user) async {
    final results = <GeneratorResult>[];

    final generators = model.settings.generators;
    if (generators!.isEmpty) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'generators list is empty'));
      return results;
    }

    final modelJson = jsonEncode(model.toJson());

    final allTasks = <Future>[];
    var numErrors = 0;
    final numGenerators = generators.length;

    final outputFolder = providerContainer.read(appStateProvider).state.output!;

    for (var i = 0; i < generators.length; i++) {
      final generatorType = generators[i].$type;

      final task = computer.compute(
        _executeGenerator,
        param: Tuple4(modelJson, i, outputFolder.path, user), // optional
      );

      allTasks.add(task);

      task.then(
        (result) {
          results.add(result);
          if (!result.success) {
            numErrors++;
            providerContainer
                .read(logStateProvider)
                .addMessage(LogEntry(LogLevel.error, 'Generator "${describeEnum(generatorType!)}" failed with error: "${result.error}"'));
          } else {
            providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, 'Generator "${describeEnum(generatorType!)}" finished'));
          }
        },
      );
    }

    await Future.wait(allTasks);
    providerContainer
        .read(logStateProvider)
        .addMessage(LogEntry(LogLevel.warning, 'All $numGenerators generators finished. Errors count: $numErrors'));
    return results;
  }
}

Future<GeneratorResult> _executeGenerator(Tuple4<String, int, String, String> params) async {
  final modelJson = params.item0;
  final generatorIndex = params.item1;
  final outputFolder = params.item2;
  final user = params.item3;

  final model = DbModel.fromJson(jsonDecode(modelJson));
  final generatorData = model.settings.generators![generatorIndex];

  final additionalInfo = GeneratorAdditionalInformation(
    date: '${kDateTimeFormat.format(DateTime.now().toUtc())} UTC',
    user: user,
  );

  final generatorType = generatorData.$type!;
  switch (generatorType) {
    case GeneratorType.undefined:
      return GeneratorResult.error('Unexpected generator type "${describeEnum(generatorData.$type!)}"');

    case GeneratorType.json:
      return await GeneratorJsonRunner().execute(outputFolder, model, generatorData as GeneratorJson, additionalInfo);

    case GeneratorType.csharp:
      return await GeneratorCsharpRunner().execute(outputFolder, model, generatorData as GeneratorCsharp, additionalInfo);
  }
}

class GeneratorResult {
  String? error;
  bool success = false;

  GeneratorResult.success() {
    success = true;
  }

  GeneratorResult.error(this.error) {
    success = false;
  }
}

abstract class BaseGeneratorRunner<T extends BaseGenerator> {
  Future<GeneratorResult> execute(String outputFolder, DbModel model, T data, GeneratorAdditionalInformation additionalInfo);
}

class GeneratorAdditionalInformation {
  String date = '';
  String user = '';

  GeneratorAdditionalInformation({
    required this.date,
    required this.user,
  });
}

mixin OutputFolderSaver {
  Future<String?> saveToFile({required String outputFolder, required String fileName, required String fileExtension, required String data}) async {
    try {
      final file = _getFile(outputFolder: outputFolder, fileName: fileName, fileExtension: fileExtension);

      if (!await file.exists()) {
        file.create(recursive: true);
      }

      await file.writeAsString(data);
      // ignore: unused_catch_stack
    } catch (e, callstack) {
      return e.toString();
    }

    return null;
  }

  Future<String?> readFromFile({required String outputFolder, required String fileName, required String fileExtension}) async {
    try {
      final file = _getFile(outputFolder: outputFolder, fileName: fileName, fileExtension: fileExtension);
      if (!await file.exists()) return null;

      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  File _getFile({required String outputFolder, required String fileName, required String fileExtension}) {
    final fullPath = path.join(outputFolder, '$fileName.$fileExtension');
    final file = File(fullPath);
    return file;
  }
}

mixin FilesComparer {
  bool resultChanged(String newResult, String? oldResult, String payloadBeginning) {
    if (oldResult == null) //
      return true;

    final payloadStartOldResult = oldResult.indexOf(payloadBeginning);
    final payloadStartNewResult = newResult.indexOf(payloadBeginning);

    final hashOld = _getHash(oldResult, payloadStartOldResult);
    final hashNew = _getHash(newResult, payloadStartNewResult);

    return hashOld != hashNew;
  }

  String _getHash(String input, int startingFrom) {
    return md5.convert(utf8.encode(input.substring(startingFrom).replaceAll(Config.newLinePattern, Config.newLineSymbol))).toString();
  }
}
