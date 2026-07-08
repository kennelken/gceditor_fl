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

  DbCmdGenerateEnumValuesFromFiles.values({
    String? id,
    required this.entityId,
    this.newValues,
    this.oldValues,
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
    return DbCmdGenerateEnumValuesFromFiles.values(
      entityId: entityId,
      newValues: oldValues,
    );
  }

  static List<EnumValue> scan(DbModel dbModel, ClassMetaEntityEnum entity) {
    final projectFile = providerContainer.read(appStateProvider).state.projectFile;
    if (projectFile == null) return [];
    final projectDir = projectFile.parent;
    if (!projectDir.existsSync()) return [];

    final regexText = entity.filePathRegex;
    if (regexText.isEmpty) return [];

    RegExp regExp;
    try {
      regExp = RegExp(regexText);
    } catch (e) {
      return [];
    }

    RegExp? regExpExclude;
    final regexExcludeText = entity.filePathRegexExclude;
    if (regexExcludeText.isNotEmpty) {
      try {
        regExpExclude = RegExp(regexExcludeText);
      } catch (e) {
        // ignore
      }
    }

    RegExp? contentRegExpInclude;
    final contentRegexIncludeText = entity.fileContentRegexInclude;
    if (contentRegexIncludeText.isNotEmpty) {
      try {
        contentRegExpInclude = RegExp(contentRegexIncludeText);
      } catch (e) {
        // ignore
      }
    }

    RegExp? contentRegExpExclude;
    final contentRegexExcludeText = entity.fileContentRegexExclude;
    if (contentRegexExcludeText.isNotEmpty) {
      try {
        contentRegExpExclude = RegExp(contentRegexExcludeText);
      } catch (e) {
        // ignore
      }
    }

    final files = _getAllFiles(projectDir);
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

        var pathValue = entity.pathValueFromRegex;
        if (pathValue.isEmpty) {
          pathValue = '{0}';
        }
        pathValue = _replaceGroups(pathValue, match);

        if (enumName.isNotEmpty && seen.add(enumName)) {
          final val = EnumValue()
            ..id = enumName
            ..description = pathValue;
          results.add(val);
        }
      }
    }

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
      'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch', 'char', 'checked', 'class', 'const',
      'continue', 'decimal', 'default', 'delegate', 'do', 'double', 'else', 'enum', 'event', 'explicit',
      'extern', 'false', 'finally', 'fixed', 'float', 'for', 'foreach', 'goto', 'if', 'implicit', 'in', 'int',
      'interface', 'internal', 'is', 'lock', 'long', 'namespace', 'new', 'null', 'object', 'operator', 'out',
      'override', 'params', 'private', 'protected', 'public', 'readonly', 'ref', 'return', 'sbyte', 'sealed',
      'short', 'sizeof', 'stackalloc', 'static', 'string', 'struct', 'switch', 'this', 'throw', 'true', 'try',
      'typeof', 'uint', 'ulong', 'unchecked', 'unsafe', 'ushort', 'using', 'virtual', 'void', 'volatile', 'while',
      'assert', 'boolean', 'extends', 'final', 'implements', 'import', 'instanceof', 'native', 'package',
      'strictfp', 'super', 'synchronized', 'transient', 'exports', 'module', 'requires'
    };
    if (keywords.contains(sanitized)) {
      sanitized = '_$sanitized';
    }
    
    return sanitized;
  }

  static List<File> _getAllFiles(Directory dir) {
    final files = <File>[];
    try {
      final List<FileSystemEntity> entities = dir.listSync(recursive: true, followLinks: false);
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
}
