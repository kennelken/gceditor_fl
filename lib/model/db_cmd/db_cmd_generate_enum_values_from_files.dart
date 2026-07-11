import 'dart:io';

import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/db_cmd/db_cmd_result.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;

import 'base_db_cmd.dart';

part 'db_cmd_generate_enum_values_from_files.g.dart';

@JsonSerializable()
class DbCmdGenerateEnumValuesFromFiles extends BaseDbCmd {
  late String entityId;
  List<EnumValue>? newValues;
  List<EnumValue>? oldValues;
  int? filesFound;
  int? valuesAdded;
  bool silent = false;

  DbCmdGenerateEnumValuesFromFiles.values({
    String? id,
    required this.entityId,
    this.newValues,
    this.oldValues,
    this.silent = false,
  }) : super.withId(id) {
    $type = DbCmdType.generateEnumValuesFromFiles;
  }

  DbCmdGenerateEnumValuesFromFiles();

  factory DbCmdGenerateEnumValuesFromFiles.fromJson(Map<String, dynamic> json) => _$DbCmdGenerateEnumValuesFromFilesFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdGenerateEnumValuesFromFilesToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId) as ClassMetaEntityEnum;

    oldValues = entity.values.map((e) => EnumValue.fromJson(e.toJson())).toList();

    if (newValues == null) {
      final scanned = scan(dbModel, entity);
      newValues = scanned;
    }

    filesFound = newValues!.length;
    final oldIds = oldValues!.map((e) => e.id).toSet();
    valuesAdded = newValues!.where((e) => !oldIds.contains(e.id)).length;

    entity.values = newValues!;
    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId);
    if (entity == null) {
      return DbCmdResult.fail('Entity "$entityId" not found');
    }
    if (entity is! ClassMetaEntityEnum) {
      return DbCmdResult.fail('Entity "$entityId" is not an enum');
    }
    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final entity = dbModel.cache.getClass(entityId) as ClassMetaEntityEnum;
    final previousValues = entity.values.map((e) => EnumValue.fromJson(e.toJson())).toList();
    return DbCmdGenerateEnumValuesFromFiles.values(
      entityId: entityId,
      newValues: previousValues,
    );
  }

  static List<EnumValue> scan(DbModel dbModel, ClassMetaEntityEnum entity) {
    final projectFile = providerContainer.read(appStateProvider).state.projectFile;
    if (projectFile == null) return [];
    final projectDir = projectFile.parent;
    if (!projectDir.existsSync()) return [];

    final appFilesPath = dbModel.settings.appFilesPath;
    if (appFilesPath.trim().isEmpty) return [];
    final paths = appFilesPath.split(RegExp(r'[;,]')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (paths.isEmpty) return [];

    final excludeRegexText = dbModel.settings.appFilesPathExcludeRegex;
    RegExp? excludeRegExp;
    if (excludeRegexText.isNotEmpty) {
      try {
        excludeRegExp = RegExp(excludeRegexText);
      } catch (_) {}
    }

    final files = <File>[];
    final seenFilePaths = <String>{};
    var anyDirectoryExists = false;
    for (final p in paths) {
      final scanDirPath = path.normalize(path.absolute(path.join(projectDir.path, p)));
      final scanDir = Directory(scanDirPath);
      if (scanDir.existsSync()) {
        anyDirectoryExists = true;
        for (final file in _getAllFiles(scanDir)) {
          final relativePath = path.relative(file.path, from: projectDir.path);
          final normalizedPath = relativePath.replaceAll('\\', '/');
          if (excludeRegExp != null && excludeRegExp.hasMatch(normalizedPath)) {
            continue;
          }
          final absPath = path.absolute(file.path);
          if (seenFilePaths.add(absPath)) {
            files.add(file);
          }
        }
      }
    }
    if (!anyDirectoryExists) return [];

    final regexText = entity.filePathRegex;
    if (regexText.isEmpty) return [];

    RegExp regExp;
    try {
      regExp = RegExp(regexText);
    } catch (e) {
      return [];
    }

    final regExpExclude = _tryParseRegExp(entity.filePathRegexExclude);
    final contentRegExpInclude = _tryParseRegExp(entity.fileContentRegexInclude);
    final contentRegExpExclude = _tryParseRegExp(entity.fileContentRegexExclude);

    final results = <EnumValue>[];
    final seen = <String>{};

    for (final file in files) {
      final relativePath = path.relative(file.path, from: projectDir.path);
      final normalizedPath = relativePath.replaceAll('\\', '/');

      if (regExpExclude != null && regExpExclude.hasMatch(normalizedPath)) {
        continue;
      }

      final match = regExp.firstMatch(normalizedPath);
      if (match != null) {
        if (contentRegExpInclude != null || contentRegExpExclude != null) {
          try {
            final content = file.readAsStringSync();
            if (contentRegExpInclude != null && !contentRegExpInclude.hasMatch(content)) {
              continue;
            }
            if (contentRegExpExclude != null && contentRegExpExclude.hasMatch(content)) {
              continue;
            }
          } catch (e) {
            continue;
          }
        }

        var enumName = entity.enumNameFromRegex;
        if (enumName.isEmpty) {
          enumName = '{1}';
        }
        enumName = _replaceGroups(enumName, match);
        enumName = sanitizeIdentifier(enumName);

        var pathValue = '';
        final pathValueFromRegex = entity.pathValueFromRegex;
        if (pathValueFromRegex.isNotEmpty) {
          pathValue = _replaceGroups(pathValueFromRegex, match);
        }

        if (enumName.isNotEmpty) {
          var uniqueName = enumName;
          if (!seen.add(uniqueName)) {
            var suffix = 1;
            while (!seen.add('${enumName}_$suffix')) {
              suffix++;
            }
            uniqueName = '${enumName}_$suffix';
          }
          final val = EnumValue()
            ..id = uniqueName
            ..description = pathValue
            ..fullPath = normalizedPath;
          results.add(val);
        }
      }
    }

    results.sort((a, b) => a.id.compareTo(b.id));
    results.insert(
        0,
        EnumValue()
          ..id = 'Undefined'
          ..description = '');
    return results;
  }

  static String sanitizeIdentifier(String name) {
    if (name.isEmpty) return 'Invalid';

    // Replace any character not in [a-zA-Z0-9_] with '_'
    var sanitized = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    // If it starts with a digit, prepend '_'
    if (RegExp(r'^[0-9]').hasMatch(sanitized)) {
      sanitized = '_$sanitized';
    }

    // Ensure length >= 2
    if (sanitized.length < 2) {
      sanitized = '${sanitized}_';
    }

    const keywords = {
      'abstract',
      'as',
      'base',
      'bool',
      'break',
      'byte',
      'case',
      'catch',
      'char',
      'checked',
      'class',
      'const',
      'continue',
      'decimal',
      'default',
      'delegate',
      'do',
      'double',
      'else',
      'enum',
      'event',
      'explicit',
      'extern',
      'false',
      'finally',
      'fixed',
      'float',
      'for',
      'foreach',
      'goto',
      'if',
      'implicit',
      'in',
      'int',
      'interface',
      'internal',
      'is',
      'lock',
      'long',
      'namespace',
      'new',
      'null',
      'object',
      'operator',
      'out',
      'override',
      'params',
      'private',
      'protected',
      'public',
      'readonly',
      'ref',
      'return',
      'sbyte',
      'sealed',
      'short',
      'sizeof',
      'stackalloc',
      'static',
      'string',
      'struct',
      'switch',
      'this',
      'throw',
      'true',
      'try',
      'typeof',
      'uint',
      'ulong',
      'unchecked',
      'unsafe',
      'ushort',
      'using',
      'virtual',
      'void',
      'volatile',
      'while',
      'assert',
      'boolean',
      'extends',
      'final',
      'implements',
      'import',
      'instanceof',
      'native',
      'package',
      'strictfp',
      'super',
      'synchronized',
      'transient',
      'exports',
      'module',
      'requires'
    };
    if (keywords.contains(sanitized)) {
      sanitized = '_$sanitized';
    }

    return sanitized;
  }

  static List<File> _getAllFiles(Directory dir) {
    final files = <File>[];
    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          files.add(entity);
        }
      }
    } catch (e) {
      // ignore
    }
    return files;
  }

  static String _replaceGroups(String template, RegExpMatch match) {
    var result = template;
    for (var i = 0; i <= match.groupCount; i++) {
      final groupVal = match.group(i) ?? '';
      result = result.replaceAll('{$i}', groupVal);
    }
    return result;
  }

  static RegExp? _tryParseRegExp(String pattern) {
    if (pattern.isEmpty) return null;
    try {
      return RegExp(pattern);
    } catch (_) {
      return null;
    }
  }
}
