import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gceditor/components/properties/primitives/drop_down_selector.dart';
import 'package:gceditor/components/settings/generators_item_view.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/main.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/db/generator_gdscript.dart';
import 'package:gceditor/model/db/generator_rust.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/db_model_factory.dart';
import 'package:gceditor/model/state/string_wrapper.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/server/generators/generator_gdscript_runner.dart';
import 'package:gceditor/server/generators/generator_rust_runner.dart';
import 'package:gceditor/server/generators/generators_job.dart';

void main() {
  test('Newly created GDScript and Rust generators have correct default settings', () {
    final gd = DbModelFactory.generator(GeneratorType.gdscript) as GeneratorGdscript;
    expect(gd.fileName, 'ModelRoot');
    expect(gd.fileExtension, 'gd');
    expect(gd.prefix, 'Model');
    expect(gd.postfix, '');
    expect(gd.$type, GeneratorType.gdscript);

    final rust = DbModelFactory.generator(GeneratorType.rust) as GeneratorRust;
    expect(rust.fileName, 'ModelRoot');
    expect(rust.fileExtension, 'rs');
    expect(rust.prefix, 'Model');
    expect(rust.postfix, '');
    expect(rust.geometryClasses, 'bevy_math');
    expect(rust.jsonSerializer, 'serde');
    expect(rust.$type, GeneratorType.rust);

    expect(Config.generatorRustGeometryClassesList, contains('bevy_math'));
    expect(Config.generatorRustJsonSerializerList, contains('serde'));
  });

  test('GDScript generator produces valid Godot 4 code', () async {
    final tempDir = Directory.systemTemp.createTempSync('gceditor_gdscript_test');
    try {
      final dbModel = DbModel();

      final enumEntity = ClassMetaEntityEnum()
        ..id = 'Element'
        ..values = [
          EnumValue()..id = 'Fire',
          EnumValue()..id = 'Water',
        ];
      dbModel.classes.add(enumEntity);

      final structClass = ClassMetaEntity()
        ..id = 'StatMod'
        ..classType = ClassType.valueType
        ..fields = [
          ClassMetaFieldDescription()
            ..id = 'amount'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.int),
        ];
      dbModel.classes.add(structClass);

      final heroClass = ClassMetaEntity()
        ..id = 'Hero'
        ..classType = ClassType.referenceType
        ..fields = [
          ClassMetaFieldDescription()
            ..id = 'level'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.int),
          ClassMetaFieldDescription()
            ..id = 'name'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.string),
          ClassMetaFieldDescription()
            ..id = 'pos'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.vector2),
          ClassMetaFieldDescription()
            ..id = 'color'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.color),
          ClassMetaFieldDescription()
            ..id = 'element'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.reference, classId: 'Element'),
          ClassMetaFieldDescription()
            ..id = 'target'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.reference, classId: 'Hero'),
          ClassMetaFieldDescription()
            ..id = 'scores'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.list)
            ..valueTypeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.int),
          ClassMetaFieldDescription()
            ..id = 'modifiers'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.listInline)
            ..valueTypeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.reference, classId: 'StatMod'),
        ];
      dbModel.classes.add(heroClass);

      final table = TableMetaEntity()
        ..id = 'heroes'
        ..classId = 'Hero';
      dbModel.tables.add(table);
      dbModel.cache.invalidate();

      final gdGen = GeneratorGdscript()
        ..prefix = 'Model'
        ..postfix = ''
        ..fileName = 'ModelRoot'
        ..fileExtension = 'gd';

      final additionalInfo = GeneratorAdditionalInformation(date: '2026-10-04', user: 'TestUser');
      final runner = GeneratorGdscriptRunner();
      final result = await runner.execute(tempDir.path, dbModel, gdGen, additionalInfo);
      expect(result.success, isTrue, reason: result.error);

      final file = File('${tempDir.path}/ModelRoot.gd');
      expect(file.existsSync(), isTrue);
      final code = file.readAsStringSync();

      expect(code.contains('class_name ModelRoot extends RefCounted'), isTrue);
      expect(code.contains('class ModelHero extends BaseModelItem:'), isTrue);
      expect(code.contains('class ModelStatMod extends BaseModelItem:'), isTrue);
      expect(code.contains('func is_value_type() -> bool:'), isTrue);
      expect(code.contains('var level: int = 0'), isTrue);
      expect(code.contains('var name: String = ""'), isTrue);
      expect(code.contains('var pos: Vector2 = Vector2.ZERO'), isTrue);
      expect(code.contains('var color: Color = Color(0, 0, 0, 1)'), isTrue);
      expect(code.contains('var target: RefCounted = null'), isTrue);
      expect(code.contains('func clone() -> ModelHero:'), isTrue);
      expect(code.contains('static func parse(json_text: String'), isTrue);
      expect(code.contains('JSON.parse_string(json_text)'), isTrue);
      expect(code.contains('func get_hero(id: String) -> ModelHero:'), isTrue);
      expect(code.contains('class ParserContext extends RefCounted:'), isTrue);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Rust generator produces valid Rust code with bevy_math and serde', () async {
    final tempDir = Directory.systemTemp.createTempSync('gceditor_rust_test');
    try {
      final dbModel = DbModel();

      final enumEntity = ClassMetaEntityEnum()
        ..id = 'Element'
        ..values = [
          EnumValue()..id = 'Fire',
          EnumValue()..id = 'Water',
        ];
      dbModel.classes.add(enumEntity);

      final structClass = ClassMetaEntity()
        ..id = 'StatMod'
        ..classType = ClassType.valueType
        ..fields = [
          ClassMetaFieldDescription()
            ..id = 'amount'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.int),
        ];
      dbModel.classes.add(structClass);

      final heroClass = ClassMetaEntity()
        ..id = 'Hero'
        ..classType = ClassType.referenceType
        ..fields = [
          ClassMetaFieldDescription()
            ..id = 'level'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.int),
          ClassMetaFieldDescription()
            ..id = 'name'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.string),
          ClassMetaFieldDescription()
            ..id = 'pos'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.vector2),
          ClassMetaFieldDescription()
            ..id = 'element'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.reference, classId: 'Element'),
          ClassMetaFieldDescription()
            ..id = 'target'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.reference, classId: 'Hero'),
          ClassMetaFieldDescription()
            ..id = 'scores'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.list)
            ..valueTypeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.int),
          ClassMetaFieldDescription()
            ..id = 'modifiers'
            ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.listInline)
            ..valueTypeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.reference, classId: 'StatMod'),
        ];
      dbModel.classes.add(heroClass);

      final table = TableMetaEntity()
        ..id = 'heroes'
        ..classId = 'Hero';
      dbModel.tables.add(table);
      dbModel.cache.invalidate();

      final rustGen = GeneratorRust()
        ..prefix = 'Model'
        ..postfix = ''
        ..fileName = 'model_root'
        ..fileExtension = 'rs'
        ..geometryClasses = 'bevy_math'
        ..jsonSerializer = 'serde';

      final additionalInfo = GeneratorAdditionalInformation(date: '2026-10-04', user: 'TestUser');
      final runner = GeneratorRustRunner();
      final result = await runner.execute(tempDir.path, dbModel, rustGen, additionalInfo);
      expect(result.success, isTrue, reason: result.error);

      final file = File('${tempDir.path}/model_root.rs');
      expect(file.existsSync(), isTrue);
      final code = file.readAsStringSync();

      expect(code.contains('use bevy_math::{IVec2, IVec3, IVec4, IRect, Rect, Vec2, Vec3, Vec4};'), isTrue);
      expect(code.contains('use serde::{Deserialize, Serialize};'), isTrue);
      expect(code.contains('pub struct ModelHero {'), isTrue);
      expect(code.contains('pub struct ModelStatMod {'), isTrue);
      expect(code.contains('pub target: Option<String>'), isTrue);
      expect(code.contains('pub pos: Vec2'), isTrue);
      expect(code.contains('pub fn target<\'a>(&self, root: &\'a ModelRoot) -> Option<&\'a ModelHero>'), isTrue);
      expect(code.contains('pub trait ModelModelItem: Sized'), isTrue);
      expect(code.contains('impl ModelModelItem for ModelHero'), isTrue);
      expect(code.contains('pub fn get<T: ModelModelItem>(&self, id: &str) -> Option<&T>'), isTrue);
      expect(code.contains('pub fn parse(json_text: &str) -> Result<Self, String>'), isTrue);
      expect(code.contains('pub struct ParserContext'), isTrue);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Problems list reports errors and warnings for Godot and Rust generator restrictions', () {
    final dbModel = DbModel();

    // 1. Interface
    final iface = ClassMetaEntity()
      ..id = 'Character'
      ..classType = ClassType.interface;
    dbModel.classes.add(iface);

    // 2. Base class
    final baseClass = ClassMetaEntity()
      ..id = 'Unit'
      ..classType = ClassType.referenceType;
    dbModel.classes.add(baseClass);

    // 3. Class implementing interface and with inheritance
    final derived = ClassMetaEntity()
      ..id = 'Hero'
      ..parent = 'Unit'
      ..interfaces = ['Character']
      ..classType = ClassType.referenceType;
    dbModel.classes.add(derived);

    // 3. Value type
    final valueType = ClassMetaEntity()
      ..id = 'StatMod'
      ..classType = ClassType.valueType;
    dbModel.classes.add(valueType);

    dbModel.cache.invalidate();

    // When only C# generator is present, no generator errors/warnings should be generated
    dbModel.settings.generators = [
      DbModelFactory.generator(GeneratorType.csharp),
    ];
    var problems = computeProblems(jsonEncode(dbModel.toJson()));
    expect(problems.any((p) => p.type == ProblemType.unsupportedInheritance), isFalse);
    expect(problems.any((p) => p.type == ProblemType.unsupportedInterface), isFalse);
    expect(problems.any((p) => p.type == ProblemType.unsupportedValueType), isFalse);
    expect(problems.any((p) => p.type == ProblemType.unsupportedReferenceType), isFalse);

    // When Godot generator is added:
    dbModel.settings.generators = [
      DbModelFactory.generator(GeneratorType.gdscript),
    ];
    problems = computeProblems(jsonEncode(dbModel.toJson()));

    // Inheritance is supported in GDScript, so no unsupportedInheritance error
    final godotInhErrors = problems.where((p) => p.type == ProblemType.unsupportedInheritance);
    expect(godotInhErrors.isEmpty, isTrue);

    // Interface should be an ERROR
    final godotIfaceErrors = problems.where((p) => p.type == ProblemType.unsupportedInterface);
    expect(godotIfaceErrors.isNotEmpty, isTrue);
    expect(godotIfaceErrors.every((p) => p.severity == ProblemSeverity.error), isTrue);
    expect(godotIfaceErrors.every((p) => p.details == 'GDScript'), isTrue);
    expect(godotIfaceErrors.first.getDescription(), contains('GDScript'));

    // Value types should be a WARNING (will be replaced with RefCounted)
    final godotValueTypeWarnings = problems.where((p) => p.type == ProblemType.unsupportedValueType);
    expect(godotValueTypeWarnings.isNotEmpty, isTrue);
    expect(godotValueTypeWarnings.first.severity, ProblemSeverity.warning);
    expect(godotValueTypeWarnings.first.classId, 'StatMod');
    expect(godotValueTypeWarnings.first.details, 'GDScript');
    expect(godotValueTypeWarnings.first.getDescription(), contains('GDScript'));

    // When Rust generator is added:
    dbModel.settings.generators = [
      DbModelFactory.generator(GeneratorType.rust),
    ];
    problems = computeProblems(jsonEncode(dbModel.toJson()));

    // Inheritance should be an ERROR in Rust
    final rustInhErrors = problems.where((p) => p.type == ProblemType.unsupportedInheritance);
    expect(rustInhErrors.isNotEmpty, isTrue);
    expect(rustInhErrors.first.severity, ProblemSeverity.error);
    expect(rustInhErrors.first.classId, 'Hero');
    expect(rustInhErrors.first.details, 'Rust');
    expect(rustInhErrors.first.getDescription(), contains('Rust'));

    // Interface should be an ERROR
    final rustIfaceErrors = problems.where((p) => p.type == ProblemType.unsupportedInterface);
    expect(rustIfaceErrors.isNotEmpty, isTrue);
    expect(rustIfaceErrors.every((p) => p.severity == ProblemSeverity.error), isTrue);
    expect(rustIfaceErrors.every((p) => p.details == 'Rust'), isTrue);
    expect(rustIfaceErrors.first.getDescription(), contains('Rust'));

    // Reference types should be a WARNING (will be replaced with struct)
    final rustRefTypeWarnings = problems.where((p) => p.type == ProblemType.unsupportedReferenceType);
    expect(rustRefTypeWarnings.isNotEmpty, isTrue);
    expect(rustRefTypeWarnings.every((p) => p.severity == ProblemSeverity.warning), isTrue);
    expect(rustRefTypeWarnings.every((p) => p.details == 'Rust'), isTrue);
    expect(rustRefTypeWarnings.first.getDescription(), contains('Rust'));
    expect(rustRefTypeWarnings.map((p) => p.classId).toSet(), containsAll(['Hero', 'Unit']));

    // When both Godot and Rust generators are present:
    dbModel.settings.generators = [
      DbModelFactory.generator(GeneratorType.gdscript),
      DbModelFactory.generator(GeneratorType.rust),
    ];
    problems = computeProblems(jsonEncode(dbModel.toJson()));
    final allInhErrors = problems.where((p) => p.type == ProblemType.unsupportedInheritance).toList();
    expect(allInhErrors.length, 1);
    expect(allInhErrors.first.details, 'Rust');
  });

  testWidgets('GeneratorsItemView renders Rust generator dropdowns matching item height', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    providerContainer.read(styleStateProvider).init();
    final rust = DbModelFactory.generator(GeneratorType.rust) as GeneratorRust;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providerContainer,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 1200,
                child: GeneratorsItemView(
                  generator: rust,
                  index: 0,
                  onChange: (_) {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dropDowns = find.byType(DropDownSelector<StringWrapper>);
    expect(dropDowns, findsNWidgets(2));

    expect(find.text('bevy_math'), findsOneWidget);
    expect(find.text('serde'), findsOneWidget);

    for (final element in dropDowns.evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(size.height, GeneratorsItemView.itemHeight);
    }

    final iconButtons = find.byType(IconButton);
    expect(iconButtons, findsNWidgets(2));
    for (final element in iconButtons.evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(size.width, lessThanOrEqualTo(20.0 * 0.85 + 0.1));
    }
  });
}
