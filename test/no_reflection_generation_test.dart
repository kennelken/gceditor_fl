import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/generator_csharp.dart';
import 'package:gceditor/model/db/generator_java.dart';
import 'package:gceditor/server/generators/generator_csharp_runner.dart';
import 'package:gceditor/server/generators/generator_java_runner.dart';
import 'package:gceditor/server/generators/generators_job.dart';

void main() {
  test('C# and Java generators generate code without reflection', () async {
    final tempDir = Directory.systemTemp.createTempSync('gceditor_no_reflection_test');
    try {
      final dbModel = DbModel();

      // Interface
      final iface = ClassMetaEntity()
        ..id = 'Character'
        ..classType = ClassType.interface;
      dbModel.classes.add(iface);

      // Base class
      final baseClass = ClassMetaEntity()
        ..id = 'Unit'
        ..classType = ClassType.referenceType
        ..interfaces = ['Character'];
      dbModel.classes.add(baseClass);

      // Derived class
      final heroClass = ClassMetaEntity()
        ..id = 'Hero'
        ..classType = ClassType.referenceType
        ..parent = 'Unit';
      dbModel.classes.add(heroClass);

      // Value type (struct)
      final structClass = ClassMetaEntity()
        ..id = 'StatMod'
        ..classType = ClassType.valueType;
      dbModel.classes.add(structClass);

      // Enum
      final enumEntity = ClassMetaEntityEnum()
        ..id = 'Element'
        ..values = [
          EnumValue()..id = 'Fire',
          EnumValue()..id = 'Water',
        ];
      dbModel.classes.add(enumEntity);

      // Table
      final table = TableMetaEntity()
        ..id = 'heroes'
        ..classId = 'Hero';
      dbModel.tables.add(table);

      dbModel.cache.invalidate();

      final additionalInfo = GeneratorAdditionalInformation(date: '2026-10-03', user: 'TestUser');

      // Test C#
      final csharpGen = GeneratorCsharp()
        ..prefix = 'Game'
        ..prefixInterface = 'I'
        ..postfix = 'Data'
        ..namespace = 'Game.Config'
        ..fileName = 'GameRootData'
        ..fileExtension = 'cs';

      final csharpRunner = GeneratorCsharpRunner();
      final csResult = await csharpRunner.execute(tempDir.path, dbModel, csharpGen, additionalInfo);
      expect(csResult.success, isTrue, reason: csResult.error);

      final csFile = File('${tempDir.path}/GameRootData.cs');
      expect(csFile.existsSync(), isTrue);
      final csCode = csFile.readAsStringSync();

      // Check that NO reflection is used in C#
      expect(csCode.contains('Activator.CreateInstance'), isFalse);
      expect(csCode.contains('GetMethod("TrimExcess"'), isFalse);
      expect(csCode.contains('GetParentTypesIncludingCurrent'), isFalse);
      expect(csCode.contains('.GetType().IsValueType'), isFalse);
      expect(csCode.contains('item.GetType()'), isFalse);
      expect(csCode.contains('System.Reflection'), isFalse);

      // Check positive constructs in C#
      expect(csCode.contains('bool IsValueType { get; }'), isTrue);
      expect(csCode.contains('IReadOnlyList<Type> ParentTypes { get; }'), isTrue);
      expect(csCode.contains('public override IReadOnlyList<Type> ParentTypes => _parentTypes;'), isTrue);
      expect(csCode.contains('public readonly IReadOnlyList<Type> ParentTypes => _parentTypes;'), isTrue);
      expect(csCode.contains('FastListFactory.TrimExcess(list);'), isTrue);
      expect(csCode.contains('kvp.Value.IsValueType'), isTrue);
      expect(csCode.contains('default: throw new ArgumentException(\$"Unexpected class {list?.GetType().FullName}");'), isTrue);
      expect(
        csCode.contains(
          '                "IIdentifiable" => (object)new List<IIdentifiable>(),\n'
          '                _ => throw new ArgumentException(\$"Unknown type {type.FullName}")',
        ),
        isTrue,
      );
      expect(
        csCode.contains(
          '                case List<IIdentifiable> l: l.TrimExcess(); break;\n'
          '                default: throw new ArgumentException(\$"Unexpected class {list?.GetType().FullName}");\n'
          '            }',
        ),
        isTrue,
      );

      final dotnetCheck = await Process.run('which', ['dotnet']);
      if (dotnetCheck.exitCode == 0) {
        const csproj = '''<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>disable</Nullable>
    <ImplicitUsings>disable</ImplicitUsings>
  </PropertyGroup>
</Project>''';
        File('${tempDir.path}/TestLib.csproj').writeAsStringSync(csproj);
        final buildResult = await Process.run('dotnet', ['build', '${tempDir.path}/TestLib.csproj']);
        expect(buildResult.exitCode, 0, reason: 'dotnet build output: \n${buildResult.stdout}\n${buildResult.stderr}');
      }

      // Test Java
      final javaGen = GeneratorJava()
        ..prefix = 'Game'
        ..prefixInterface = 'I'
        ..postfix = 'Data'
        ..namespace = 'game.config'
        ..fileName = 'GameRootData'
        ..fileExtension = 'java';

      final javaRunner = GeneratorJavaRunner();
      final javaResult = await javaRunner.execute(tempDir.path, dbModel, javaGen, additionalInfo);
      expect(javaResult.success, isTrue, reason: javaResult.error);

      final javaFile = File('${tempDir.path}/GameRootData.java');
      expect(javaFile.existsSync(), isTrue);
      final javaCode = javaFile.readAsStringSync();

      // Check that NO reflection is used in Java
      expect(javaCode.contains('java.lang.reflect'), isFalse);
      expect(javaCode.contains('InvocationTargetException'), isFalse);
      expect(javaCode.contains('NoSuchMethodException'), isFalse);
      expect(javaCode.contains('InstantiationException'), isFalse);
      expect(javaCode.contains('IllegalAccessException'), isFalse);
      expect(javaCode.contains('ArrayList.class.getConstructor()'), isFalse);
      expect(javaCode.contains('newInstance()'), isFalse);
      expect(javaCode.contains('GetParentTypesIncludingCurrent'), isFalse);
      expect(javaCode.contains('HashMap<Type,'), isFalse);

      // Check positive constructs in Java
      expect(javaCode.contains('List<Class<?>> getParentTypes();'), isTrue);
      expect(javaCode.contains('public List<Class<?>> getParentTypes() { return _parentTypes; }'), isTrue);
      expect(javaCode.contains('HashMap<Class<?>, Object> AllItemsByType;'), isTrue);
      expect(javaCode.contains('item.getParentTypes().contains(itemClass)'), isTrue);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
