import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/generator_csharp.dart';
import 'package:gceditor/model/db_cmd/db_cmd_generate_enum_values_from_files.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_enum_file_settings.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/server/generators/generator_csharp_runner.dart';
import 'package:gceditor/server/generators/generators_job.dart';
import 'package:gceditor/utils/utils.dart';

void main() {
  test('Enum auto generation from files works correctly', () {
    final tempDir = Directory.systemTemp.createTempSync('gceditor_test');
    File('${tempDir.path}/Assets/Prefabs/Player.prefab').createSync(recursive: true);
    File('${tempDir.path}/Assets/Prefabs/Monster.prefab').createSync(recursive: true);
    File('${tempDir.path}/Assets/Prefabs/Items/Sword.prefab').createSync(recursive: true);
    File('${tempDir.path}/Assets/Prefabs/ignore_me.txt').createSync(recursive: true);

    try {
      final projectFile = File('${tempDir.path}/project.json');
      providerContainer.read(appStateProvider).state.projectFile = projectFile;

      final dbModel = DbModel();
      final entity = ClassMetaEntityEnum()
        ..id = 'BuildingPresentationType'
        ..filePathRegex = r'Assets/Prefabs/(.*)\.prefab'
        ..enumNameFromRegex = '{1}'
        ..pathValueFromRegex = '{0}';

      final results = DbCmdGenerateEnumValuesFromFiles.scan(dbModel, entity);

      expect(results.length, 3);
      
      final playerVal = results.firstWhere((e) => e.id == 'Player');
      expect(playerVal.description, 'Assets/Prefabs/Player.prefab');

      final monsterVal = results.firstWhere((e) => e.id == 'Monster');
      expect(monsterVal.description, 'Assets/Prefabs/Monster.prefab');

      final swordVal = results.firstWhere((e) => e.id == 'Items_Sword');
      expect(swordVal.description, 'Assets/Prefabs/Items/Sword.prefab');
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Enum auto generation from files respects exclusion regex', () {
    final tempDir = Directory.systemTemp.createTempSync('gceditor_test');
    File('${tempDir.path}/Assets/Prefabs/Player.prefab').createSync(recursive: true);
    File('${tempDir.path}/Assets/Prefabs/Monster.prefab').createSync(recursive: true);
    File('${tempDir.path}/Assets/Prefabs/Items/Sword.prefab').createSync(recursive: true);

    try {
      final projectFile = File('${tempDir.path}/project.json');
      providerContainer.read(appStateProvider).state.projectFile = projectFile;

      final dbModel = DbModel();
      final entity = ClassMetaEntityEnum()
        ..id = 'BuildingPresentationType'
        ..filePathRegex = r'Assets/Prefabs/(.*)\.prefab'
        ..filePathRegexExclude = r'Items/.*'
        ..enumNameFromRegex = '{1}'
        ..pathValueFromRegex = '{0}';

      final results = DbCmdGenerateEnumValuesFromFiles.scan(dbModel, entity);

      expect(results.length, 2);
      expect(results.any((e) => e.id == 'Player'), isTrue);
      expect(results.any((e) => e.id == 'Monster'), isTrue);
      expect(results.any((e) => e.id == 'Items_Sword'), isFalse);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Enum auto generation from files respects content regex matching and keyword/digit sanitization', () {
    final tempDir = Directory.systemTemp.createTempSync('gceditor_test');
    final file1 = File('${tempDir.path}/Assets/Prefabs/123Player.prefab')..createSync(recursive: true);
    file1.writeAsStringSync('Type: Hero\nStatus: Active');

    final file2 = File('${tempDir.path}/Assets/Prefabs/class.prefab')..createSync(recursive: true);
    file2.writeAsStringSync('Type: Hero\nStatus: Deprecated');

    final file3 = File('${tempDir.path}/Assets/Prefabs/Monster.prefab')..createSync(recursive: true);
    file3.writeAsStringSync('Type: Enemy\nStatus: Active');

    try {
      final projectFile = File('${tempDir.path}/project.json');
      providerContainer.read(appStateProvider).state.projectFile = projectFile;

      final dbModel = DbModel();
      final entity = ClassMetaEntityEnum()
        ..id = 'BuildingPresentationType'
        ..filePathRegex = r'Assets/Prefabs/(.*)\.prefab'
        ..fileContentRegexInclude = r'Status: Active'
        ..fileContentRegexExclude = r'Type: Enemy'
        ..enumNameFromRegex = '{1}'
        ..pathValueFromRegex = '{0}';

      final results = DbCmdGenerateEnumValuesFromFiles.scan(dbModel, entity);

      // Should only include 123Player (since class has Status: Deprecated, Monster is Type: Enemy).
      expect(results.length, 1);
      
      // 123Player starts with a digit, so it should be prefixed with an underscore -> _123Player
      expect(results[0].id, '_123Player');
      expect(results[0].description, 'Assets/Prefabs/123Player.prefab');

      // Test manual keyword prefixing logic directly
      expect(DbCmdGenerateEnumValuesFromFiles.sanitizeIdentifier('class'), '_class');
      expect(DbCmdGenerateEnumValuesFromFiles.sanitizeIdentifier('A'), 'A_');
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('C# generator generates correct static path overloads and extension class', () async {
    final tempDir = Directory.systemTemp.createTempSync('gceditor_test');
    try {
      final dbModel = DbModel();
      
      final entity = ClassMetaEntityEnum()
        ..id = 'BuildingPresentationType'
        ..autoByFile = true
        ..filePathRegex = r'Assets/Prefabs/(.*)\.prefab'
        ..enumNameFromRegex = '{1}'
        ..pathValueFromRegex = '{0}';
      entity.values = [
        EnumValue()..id = 'Player'..description = 'Assets/Prefabs/Player.prefab',
        EnumValue()..id = 'Monster'..description = 'Assets/Prefabs/Monster.prefab',
      ];
      dbModel.classes.add(entity);
      dbModel.cache.invalidate();

      final generator = GeneratorCsharp()
        ..prefix = 'MyPrefix'
        ..postfix = 'MyPostfix'
        ..namespace = 'MyNamespace'
        ..fileName = 'MyPrefixRootMyPostfix'
        ..fileExtension = 'cs';

      final runner = GeneratorCsharpRunner();
      final genResult = await runner.execute(
        tempDir.path,
        dbModel,
        generator,
        GeneratorAdditionalInformation(date: '2026-07-08', user: 'TestUser'),
      );
      expect(genResult.success, isTrue, reason: genResult.error);

      final file = File('${tempDir.path}/MyPrefixRootMyPostfix.cs');
      expect(file.existsSync(), isTrue);
      final generatedCode = file.readAsStringSync();

      expect(generatedCode.contains('public static string GetPathByEnum(MyPrefixBuildingPresentationTypeMyPostfix value)'), isTrue);
      expect(generatedCode.contains('public static string GetEnumPath(MyPrefixBuildingPresentationTypeMyPostfix value) => GetPathByEnum(value);'), isTrue);

      expect(generatedCode.contains('public static class MyPrefixExtensionsMyPostfix'), isTrue);
      expect(generatedCode.contains('public static string Path(this MyPrefixBuildingPresentationTypeMyPostfix value)'), isTrue);
      expect(generatedCode.contains('return MyPrefixRootMyPostfix.GetEnumPath(value);'), isTrue);
      expect(generatedCode.contains('public static class ListExtensions'), isFalse);
      expect(generatedCode.contains('public static class IClonableExtensions'), isFalse);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Utils capturing group count and settings validation works correctly', () {
    // 1. Capturing group count
    expect(Utils.countCapturingGroups(r'Assets/Prefabs/(.*)\.prefab'), equals(1));
    expect(Utils.countCapturingGroups(r'Assets/Prefabs/Player\.prefab'), equals(0));
    expect(Utils.countCapturingGroups(r'Assets/Prefabs/(?:ignored)/(.*)\.prefab'), equals(1));
    expect(Utils.countCapturingGroups(r'Assets/Prefabs/(\d+)/(\w+)\.prefab'), equals(2));
    expect(Utils.countCapturingGroups(r'Assets/Prefabs/(?<name>\w+)\.prefab'), equals(1));
    expect(Utils.countCapturingGroups(r'Assets/Prefabs/\((\w+)\)\.prefab'), equals(1));
    expect(Utils.countCapturingGroups(r'Assets/Prefabs/\\(\w+)\.prefab'), equals(1));
    expect(Utils.countCapturingGroups(r'Assets/Prefabs/\(\w+\)\.prefab'), equals(0)); // escaped parentheses

    // 2. Settings validation
    // Empty settings
    expect(Utils.validateAutoByFileSettings('', ''), isFalse);
    expect(Utils.validateAutoByFileSettings('abc', ''), isFalse);
    expect(Utils.validateAutoByFileSettings('', 'abc'), isFalse);

    // Invalid regex syntax
    expect(Utils.validateAutoByFileSettings('[a-z', '{1}'), isFalse);

    // Missing {N} placeholder
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', 'value'), isFalse);

    // Out-of-bounds group index
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{2}'), isFalse);

    // Valid group index
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{1}'), isTrue);
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{0}'), isTrue);
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(\d+)/(\w+)\.prefab', 'Item_{2}'), isTrue);

    // 3. Optional pathValueFromRegex validation
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{1}', '{2}'), isFalse); // path out of bounds
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{1}', '{1}'), isTrue); // path valid
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{1}', '{0}'), isTrue); // path valid
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{1}', ''), isTrue); // path empty (optional)

    // 4. Optional filePathRegexExclude validation
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{1}', '', '[a-z'), isFalse); // invalid exclude regex syntax
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{1}', '', 'Player'), isTrue); // valid exclude regex
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{1}', '', ''), isTrue); // empty exclude regex (optional)
  });

  test('DbCmdEditEnumFileSettings execution and undo works correctly', () {
    final dbModel = DbModel();
    final entity = ClassMetaEntityEnum()
      ..id = 'MyEnum'
      ..filePathRegex = 'old_regex'
      ..filePathRegexExclude = 'old_exclude'
      ..enumNameFromRegex = 'old_name'
      ..pathValueFromRegex = 'old_path'
      ..autoByFileAutoRefresh = false;
    dbModel.classes.add(entity);
    dbModel.cache.invalidate();

    final cmd = DbCmdEditEnumFileSettings.values(
      entityId: 'MyEnum',
      filePathRegex: 'new_regex',
      filePathRegexExclude: 'new_exclude',
      enumNameFromRegex: 'new_name',
      pathValueFromRegex: 'new_path',
      autoByFileAutoRefresh: true,
    );

    // Create undo command BEFORE executing the original command, as done in ClientOwnCommandsStateNotifier
    final undoCmd = cmd.createUndoCmd(dbModel);

    // Verify undo command contains the old values
    expect(undoCmd, isA<DbCmdEditEnumFileSettings>());
    final undoEdit = undoCmd as DbCmdEditEnumFileSettings;
    expect(undoEdit.filePathRegex, equals('old_regex'));
    expect(undoEdit.filePathRegexExclude, equals('old_exclude'));
    expect(undoEdit.enumNameFromRegex, equals('old_name'));
    expect(undoEdit.pathValueFromRegex, equals('old_path'));
    expect(undoEdit.autoByFileAutoRefresh, equals(false));

    // Execute the original command
    final result = cmd.execute(dbModel);
    expect(result.success, isTrue);

    // Verify fields updated in db
    expect(entity.filePathRegex, equals('new_regex'));
    expect(entity.filePathRegexExclude, equals('new_exclude'));
    expect(entity.enumNameFromRegex, equals('new_name'));
    expect(entity.pathValueFromRegex, equals('new_path'));
    expect(entity.autoByFileAutoRefresh, equals(true));

    // Execute the undo command
    final undoResult = undoCmd.execute(dbModel);
    expect(undoResult.success, isTrue);

    // Verify fields reverted
    expect(entity.filePathRegex, equals('old_regex'));
    expect(entity.filePathRegexExclude, equals('old_exclude'));
    expect(entity.enumNameFromRegex, equals('old_name'));
    expect(entity.pathValueFromRegex, equals('old_path'));
    expect(entity.autoByFileAutoRefresh, equals(false));
  });
}
