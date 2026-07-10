import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gceditor/client/client_app.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/generator_csharp.dart';
import 'package:gceditor/model/db/generator_java.dart';
import 'package:gceditor/model/db_cmd/db_cmd_generate_enum_values_from_files.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_enum_file_settings.dart';
import 'package:gceditor/model/db_network/authentication_data.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/auth_list_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/server/generators/generator_csharp_runner.dart';
import 'package:gceditor/server/generators/generator_java_runner.dart';
import 'package:gceditor/server/generators/generators_job.dart';
import 'package:gceditor/server/server_app.dart';
import 'package:gceditor/utils/utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

      expect(results.length, 4);
      expect(results[0].id, 'Undefined');
      expect(results[0].description, '');
      
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

      expect(results.length, 3);
      expect(results[0].id, 'Undefined');
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

      // Should only include Undefined + 123Player (since class has Status: Deprecated, Monster is Type: Enemy).
      expect(results.length, 2);
      
      expect(results[0].id, 'Undefined');
      // 123Player starts with a digit, so it should be prefixed with an underscore -> _123Player
      expect(results[1].id, '_123Player');
      expect(results[1].description, 'Assets/Prefabs/123Player.prefab');

      // Test manual keyword prefixing logic directly
      expect(DbCmdGenerateEnumValuesFromFiles.sanitizeIdentifier('class'), '_class');
      expect(DbCmdGenerateEnumValuesFromFiles.sanitizeIdentifier('A'), 'A_');
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Enum auto generation adds incremental suffix for duplicate names and sorts results', () {
    final tempDir = Directory.systemTemp.createTempSync('gceditor_test_dup');
    // Create files that will produce duplicate enum names via the regex
    // Using subdirectories: A/Player.prefab, B/Player.prefab, C/Player.prefab, A/Zombie.prefab
    File('${tempDir.path}/Assets/A/Player.prefab').createSync(recursive: true);
    File('${tempDir.path}/Assets/B/Player.prefab').createSync(recursive: true);
    File('${tempDir.path}/Assets/C/Player.prefab').createSync(recursive: true);
    File('${tempDir.path}/Assets/A/Zombie.prefab').createSync(recursive: true);

    try {
      final projectFile = File('${tempDir.path}/project.json');
      providerContainer.read(appStateProvider).state.projectFile = projectFile;

      final dbModel = DbModel();
      final entity = ClassMetaEntityEnum()
        ..id = 'TestEnum'
        // Only captures the filename, not the directory, so A/Player and B/Player both become "Player"
        ..filePathRegex = r'Assets/[^/]+/([^/]+)\.prefab'
        ..enumNameFromRegex = '{1}'
        ..pathValueFromRegex = '{0}';

      final results = DbCmdGenerateEnumValuesFromFiles.scan(dbModel, entity);

      expect(results.length, 5);

      // Should have Undefined first, then Player, Player_1, Player_2, Zombie — sorted alphabetically
      final names = results.map((e) => e.id).toList();
      expect(names, ['Undefined', 'Player', 'Player_1', 'Player_2', 'Zombie']);

      // Verify remaining results (after Undefined) are sorted
      for (var i = 2; i < results.length; i++) {
        expect(results[i].id.compareTo(results[i - 1].id) >= 0, isTrue);
      }
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('C# generator generates correct dynamic path overloads and extension class', () async {
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

      expect(generatedCode.contains('public string GetPathByEnum(MyPrefixBuildingPresentationTypeMyPostfix value)'), isTrue);
      expect(generatedCode.contains('public Dictionary<string, Dictionary<string, string>> PathByEnum { get; set; }'), isTrue);
      expect(generatedCode.contains('public static MyPrefixRootMyPostfix Instance { get; private set; }'), isTrue);

      expect(generatedCode.contains('public static class MyPrefixExtensionsMyPostfix'), isTrue);
      expect(generatedCode.contains('public static string Path(this MyPrefixBuildingPresentationTypeMyPostfix value, MyPrefixRootMyPostfix root = null)'), isTrue);
      expect(generatedCode.contains('return (root ?? MyPrefixRootMyPostfix.Instance)?.GetPathByEnum(value) ?? "";'), isTrue);
      expect(generatedCode.contains('public static class ListExtensions'), isFalse);
      expect(generatedCode.contains('public static class IClonableExtensions'), isFalse);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Java generator generates correct dynamic path overloads', () async {
    final tempDir = Directory.systemTemp.createTempSync('gceditor_test_java');
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

      final generator = GeneratorJava()
        ..prefix = 'MyPrefix'
        ..postfix = 'MyPostfix'
        ..namespace = 'MyNamespace'
        ..fileName = 'MyPrefixRootMyPostfix'
        ..fileExtension = 'java';

      final runner = GeneratorJavaRunner();
      final genResult = await runner.execute(
        tempDir.path,
        dbModel,
        generator,
        GeneratorAdditionalInformation(date: '2026-07-08', user: 'TestUser'),
      );
      expect(genResult.success, isTrue, reason: genResult.error);

      final file = File('${tempDir.path}/MyPrefixRootMyPostfix.java');
      expect(file.existsSync(), isTrue);
      final generatedCode = file.readAsStringSync();

      expect(generatedCode.contains('public String GetPathByEnum(MyPrefixBuildingPresentationTypeMyPostfix value)'), isTrue);
      expect(generatedCode.contains('public HashMap<String, HashMap<String, String>> PathByEnum;'), isTrue);
      expect(generatedCode.contains('public HashMap<String, HashMap<String, String>> pathByEnum;'), isTrue);
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
    // 5. Optional fileContentRegexInclude / fileContentRegexExclude validation
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{1}', '', '', '[a-z'), isFalse);
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{1}', '', '', 'Status: Active'), isTrue);
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{1}', '', '', '', '[a-z'), isFalse);
    expect(Utils.validateAutoByFileSettings(r'Assets/Prefabs/(.*)\.prefab', '{1}', '', '', '', 'Type: Enemy'), isTrue);
  });

  test('DbCmdEditEnumFileSettings execution and undo works correctly', () {
    final dbModel = DbModel();
    final entity = ClassMetaEntityEnum()
      ..id = 'MyEnum'
      ..filePathRegex = 'old_regex'
      ..filePathRegexExclude = 'old_exclude'
      ..enumNameFromRegex = 'old_name'
      ..pathValueFromRegex = 'old_path';
    dbModel.classes.add(entity);
    dbModel.cache.invalidate();

    final cmd = DbCmdEditEnumFileSettings.values(
      entityId: 'MyEnum',
      filePathRegex: 'new_regex',
      filePathRegexExclude: 'new_exclude',
      enumNameFromRegex: 'new_name',
      pathValueFromRegex: 'new_path',
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

    // Execute the original command
    final result = cmd.execute(dbModel);
    expect(result.success, isTrue);

    // Verify fields updated in db
    expect(entity.filePathRegex, equals('new_regex'));
    expect(entity.filePathRegexExclude, equals('new_exclude'));
    expect(entity.enumNameFromRegex, equals('new_name'));
    expect(entity.pathValueFromRegex, equals('new_path'));

    // Execute the undo command
    final undoResult = undoCmd.execute(dbModel);
    expect(undoResult.success, isTrue);

    // Verify fields reverted
    expect(entity.filePathRegex, equals('old_regex'));
    expect(entity.filePathRegexExclude, equals('old_exclude'));
    expect(entity.enumNameFromRegex, equals('old_name'));
    expect(entity.pathValueFromRegex, equals('old_path'));
  });

  test('DbCmdGenerateEnumValuesFromFiles execution and undo works correctly', () {
    final dbModel = DbModel();
    final entity = ClassMetaEntityEnum()
      ..id = 'MyEnum'
      ..values = [
        EnumValue()..id = 'Val1'..description = 'Desc1',
        EnumValue()..id = 'Val2'..description = 'Desc2',
      ];
    dbModel.classes.add(entity);
    dbModel.cache.invalidate();

    final cmd = DbCmdGenerateEnumValuesFromFiles.values(
      entityId: 'MyEnum',
      newValues: [
        EnumValue()..id = 'Val3'..description = 'Desc3',
      ],
    );

    // Create undo command BEFORE executing the original command, as done in ClientOwnCommandsStateNotifier
    final undoCmd = cmd.createUndoCmd(dbModel);

    // Verify undo command contains the old values
    expect(undoCmd, isA<DbCmdGenerateEnumValuesFromFiles>());
    final undoGenerate = undoCmd as DbCmdGenerateEnumValuesFromFiles;
    expect(undoGenerate.newValues!.length, equals(2));
    expect(undoGenerate.newValues![0].id, equals('Val1'));
    expect(undoGenerate.newValues![1].id, equals('Val2'));

    // Execute the original command
    final result = cmd.execute(dbModel);
    expect(result.success, isTrue);

    // Verify fields updated in db
    expect(entity.values.length, equals(1));
    expect(entity.values[0].id, equals('Val3'));

    // Execute the undo command
    final undoResult = undoCmd.execute(dbModel);
    expect(undoResult.success, isTrue);

    // Verify fields reverted
    expect(entity.values.length, equals(2));
    expect(entity.values[0].id, equals('Val1'));
    expect(entity.values[1].id, equals('Val2'));
  });

  test('Enum auto generation respects appFilesPath setting', () {
    final tempDir = Directory.systemTemp.createTempSync('gceditor_test');
    
    // Create folders
    final appFilesFolder = Directory('${tempDir.path}/Src/Prefabs')..createSync(recursive: true);
    final outsideFolder = Directory('${tempDir.path}/Outside/Prefabs')..createSync(recursive: true);
    
    // Create files
    File('${appFilesFolder.path}/Player.prefab').createSync();
    File('${outsideFolder.path}/Monster.prefab').createSync();

    try {
      final projectFile = File('${tempDir.path}/project.json');
      providerContainer.read(appStateProvider).state.projectFile = projectFile;

      final dbModel = DbModel();
      dbModel.settings.appFilesPath = './Src'; // Restrict to Src

      final entity = ClassMetaEntityEnum()
        ..id = 'Prefabs'
        ..autoByFile = true
        ..filePathRegex = r'Src/Prefabs/(.*)\.prefab'
        ..enumNameFromRegex = '{1}';
      
      dbModel.classes.add(entity);
      dbModel.cache.invalidate();

      // 1. Scan with valid App files path
      final results = DbCmdGenerateEnumValuesFromFiles.scan(dbModel, entity);
      expect(results.length, equals(2));
      expect(results[0].id, equals('Undefined'));
      expect(results[1].id, equals('Player'));
      expect(results[1].description, equals('Src/Prefabs/Player.prefab')); // relative path computed from project root

      // 2. Scan with invalid App files path (non-existent)
      dbModel.settings.appFilesPath = './NonExistentDir';
      final emptyResults = DbCmdGenerateEnumValuesFromFiles.scan(dbModel, entity);
      expect(emptyResults, isEmpty);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('loopback test of enum auto generation triggered from client', () async {
    final tempDir = Directory.systemTemp.createTempSync('gceditor_integration_test');
    
    try {
      // 1. Create a dummy project.json
      final projectFile = File('${tempDir.path}/project.json');
      final dbModel = DbModel();
      
      // Configure settings
      dbModel.settings.appFilesPath = './Src';
      dbModel.settings.autoGenerateEnumValues = true;
      
      // Add enum entity
      final entity = ClassMetaEntityEnum()
        ..id = 'MyScannedEnum'
        ..autoByFile = true
        ..filePathRegex = r'Src/Prefabs/(.*)\.prefab'
        ..enumNameFromRegex = '{1}';
      dbModel.classes.add(entity);
      
      projectFile.writeAsStringSync(Config.fileJsonOptions.convert(dbModel.toJson()));

      // 2. Create folders and files to scan
      final appFilesFolder = Directory('${tempDir.path}/Src/Prefabs')..createSync(recursive: true);
      File('${appFilesFolder.path}/Player.prefab').createSync();
      File('${appFilesFolder.path}/Monster.prefab').createSync();

      // Initialize mock auth
      final authFile = File('${tempDir.path}/auth.json');
      authFile.writeAsStringSync('{"users": {"admin": {"login": "admin", "secret": "admin12345678", "salt": "salt"}}}');
      providerContainer.read(authListStateProvider).setPath(authFile.path);

      // 3. Start ServerApp
      final serverApp = ServerApp(
        port: 12346,
        projectFile: projectFile,
      );
      final initErr = await serverApp.init();
      if (initErr != null) {
        fail('Failed to start server: $initErr');
      }

      // 4. Initialize Client App
      final authData = AuthenticationData()
        ..login = 'admin'
        ..secret = 'admin12345678'
        ..password = 'admin12345678';
      final clientApp = ClientApp(
        ipAddress: 'localhost',
        port: 12346,
        authData: authData,
      );
      
      // Set projectFile on client too
      providerContainer.read(appStateProvider).state.projectFile = projectFile;
      
      final clientInitErr = await clientApp.init();
      if (clientInitErr != null) {
        fail('Failed to start client: $clientInitErr');
      }

      // Print initial client state
      final clientEnumValues = (providerContainer.read(clientStateProvider).state.model.classes.first as ClassMetaEntityEnum).values;
      expect(clientEnumValues, isEmpty);

      // 5. Trigger run generators request on client
      await clientApp.requestRunGenerators();

      // Wait a short time for everything to settle
      await Future.delayed(const Duration(milliseconds: 1000));

      // 6. Check client model enum values
      final updatedModel = providerContainer.read(clientStateProvider).state.model;
      final updatedEnum = updatedModel.classes.first as ClassMetaEntityEnum;
      expect(updatedEnum.values.length, equals(3));
      expect(updatedEnum.values[0].id, equals('Undefined'));
      expect(updatedEnum.values[1].id, equals('Monster'));
      expect(updatedEnum.values[2].id, equals('Player'));

    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
