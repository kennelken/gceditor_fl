// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:math';

import 'package:darq/darq.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/generator_csharp.dart';
import 'package:gceditor/utils/utils.dart';

import 'generators_job.dart';

class GeneratorCsharpRunner extends BaseGeneratorRunner<GeneratorCsharp> with OutputFolderSaver, FilesComparer {
  static final _newLineRegExp = RegExp(r'[\r\n]+');
  static const _indent = '    ';
  static const _defaultNewLine = '\n';
  static const _itemsListSuffix = 'ItemsList';

  static const _paramNamespaceStart = 'namespaceStart';
  static const _paramNamespaceEnd = 'namespaceEnd';

  static const _paramPrefix = 'prefix';
  static const _paramPrefixInterface = 'prefixInterface';
  static const _paramPostfix = 'postfix';
  static const _paramClasses = 'classes';
  static const _paramItemsLists = 'paramItemsLists';
  static const _paramDate = 'date';
  static const _paramUser = 'user';
  static const _paramJsonParser = 'json';

  static const _paramClass = 'class';
  static const _paramParentClass = 'parentClass';
  static const _paramParentInterfaces = 'parentInterfaces';
  static const _paramClassDescription = 'classDescription';
  static const _paramPropertiesBody = 'propertiesBody';
  static const _paramEnumBody = '_enumBody';
  static const _methodCloneBody = 'cloneBody';

  static const _paramListStructEquals = 'llistStructEquals';
  static const _paramListStructGetHashCode = 'listStructGetHashCode';
  static const _paramListStructEqEq = 'listStructEqEq';

  static const _paramPropertyAccessLevel = 'propertyAccessLevel';
  static const _paramPropertyType = 'propertyType';
  static const _paramPropertyName = 'propertyName';
  static const _paramPropertySummary = 'propertySummary';
  static const _paramCloneProperty = 'cloneProperty';

  static const _paramListInstantiate = 'listInstantiate';
  static const _paramClassName = 'className';
  static const _paramAssignValueListProperties = 'assignValueListProperties';
  static const _paramParseFunction = 'parseFunction';
  static const _paramAssignValueCases = 'assignValueCases';
  static const _paramMaxStructDepth = 'maxStructDepth';

  static const _paramItemsListPropertiesList = 'itemsListPropertiesBody';
  static const _paramItemsListConstructorList = 'itemsListConstructorBody';
  static const _paramEntryName = 'entryName';
  static const _paramMetaEntityType = 'metaEntityType';
  static const _paramListItemsListsAssignment = 'listItemsListsAssignment';
  static const _paramListItemsListsDeclarations = 'listItemsListsDeclarations';

  @override
  Future<GeneratorResult> execute(String outputFolder, DbModel model, GeneratorCsharp data, GeneratorAdditionalInformation additionalInfo) async {
    try {
      final result = _rootTemplate.format(
        {
          _paramNamespaceStart: _getNamespaceStart(data),
          _paramNamespaceEnd: _getNamespaceEnd(data),
          _paramDate: additionalInfo.date,
          _paramUser: additionalInfo.user,
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramClasses: _getClasses(model, data),
          _paramItemsLists: _getItemsLists(model, data),
          _paramJsonParser: _parserTemplate.format(
            {
              _paramPrefix: data.prefix,
              _paramPrefixInterface: data.prefixInterface,
              _paramPostfix: data.postfix,
              _paramListInstantiate: _getListInstantiate(model, data),
              _paramAssignValueCases: _getAssignValuesCases(model, data),
              _paramMaxStructDepth: _getMaxStructDepth(model, 3),
            },
          ),
          _paramListItemsListsAssignment: _getListItemsListAssignment(model, data),
          _paramListItemsListsDeclarations: _getListItemsListsDeclarations(model, data),
        },
      );

      final previousResult = await readFromFile(
        outputFolder: outputFolder,
        fileName: data.fileName,
        fileExtension: data.fileExtension,
      );

      if (!resultChanged(result, previousResult, '#pragma warning disable')) //
        return GeneratorResult.success();

      final saveError = await saveToFile(
        outputFolder: outputFolder,
        fileName: data.fileName,
        fileExtension: data.fileExtension,
        data: result,
      );

      if (saveError != null) //
        return GeneratorResult.error(saveError);
      // ignore: unused_catch_stack
    } catch (e, callstack) {
      return GeneratorResult.error(e.toString());
    }

    return GeneratorResult.success();
  }

  String _getNamespaceStart(GeneratorCsharp data) {
    if (data.namespace.isEmpty) //
      return '';
    return '''

namespace ${data.namespace}
{''';
  }

  String _getNamespaceEnd(GeneratorCsharp data) {
    if (data.namespace.isEmpty) //
      return '';
    return '\n}';
  }

  String _getClasses(DbModel model, GeneratorCsharp data) {
    final classesDefinitions = <String>[];

    for (var i = 0; i < model.cache.allEnums.length; i++) {
      final enumEntity = model.cache.allEnums[i];

      final enumDefinition = _enumTemplate.format(
        {
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramClass: enumEntity.id,
          _paramEnumBody: _getEnumValues(enumEntity),
          _paramClassDescription: _makeSummary(enumEntity.description.isNotEmpty ? enumEntity.description : '', 1),
        },
      );

      classesDefinitions.add(enumDefinition);
    }

    for (var i = 0; i < model.cache.allClasses.length; i++) {
      final classEntity = model.cache.allClasses[i];

      final classDefinition = _getClassTemplateByClassType(classEntity.classType).format(
        {
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramClass: classEntity.id,
          _paramParentClass: _getParentClass(classEntity, data),
          _paramParentInterfaces: _getParentInterfaces(classEntity, data),
          _paramClassDescription: _makeSummary(classEntity.description.isNotEmpty ? classEntity.description : '', 1),
          _paramPropertiesBody: _getClassProperties(model, data, classEntity),
          _methodCloneBody: _getCloneProperties(model, classEntity),
          _paramListStructGetHashCode: _getListStructGetHashCode(model, classEntity),
          _paramListStructEquals: _getListStructEquals(model, classEntity),
          _paramListStructEqEq: _getListStructEqEq(model, classEntity),
        },
      );

      classesDefinitions.add(classDefinition);
    }

    return classesDefinitions.join(_defaultNewLine * 2);
  }

  String _getItemsLists(DbModel model, GeneratorCsharp data) {
    final classesDefinitions = <String>[];

    for (var i = 0; i < model.cache.allClasses.length; i++) {
      final classEntity = model.cache.allClasses[i];
      if (classEntity.exportList != true) //
        continue;

      final thisAndParentClasses = model.cache.getImplementingClasses(classEntity).concat([classEntity]).map((e) => e.id).toSet();

      final allItems =
          model.cache.allDataTables.where((element) => thisAndParentClasses.contains(element.classId)).toMap((e) => MapEntry(e.classId, e.rows));

      final classDefinition = _classItemsListTemplate.format(
        {
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramClass: classEntity.id,
          _paramMetaEntityType: MetaEntityType.Class.name,
          _paramItemsListPropertiesList: allItems.entries
              .selectMany((kvp, _) => kvp.value.map((e) => _paramItemsListPropertyEntryTemplate.format({
                    _paramPrefix: data.prefix,
                    _paramPrefixInterface: data.prefixInterface,
                    _paramPostfix: data.postfix,
                    _paramClassName: kvp.key,
                    _paramEntryName: e.id,
                  })))
              .join(),
          _paramItemsListConstructorList: allItems.entries
              .selectMany((kvp, _) => kvp.value.map((e) => _paramItemsListConstructorEntryTemplate.format({
                    _paramPrefix: data.prefix,
                    _paramPrefixInterface: data.prefixInterface,
                    _paramPostfix: data.postfix,
                    _paramClassName: kvp.key,
                    _paramEntryName: e.id,
                  })))
              .join(),
        },
      );

      classesDefinitions.add(classDefinition);
    }

    for (var i = 0; i < model.cache.allDataTables.length; i++) {
      final tableEntity = model.cache.allDataTables[i];
      if (tableEntity.exportList != true) //
        continue;

      final classDefinition = _classItemsListTemplate.format(
        {
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramClass: tableEntity.id,
          _paramMetaEntityType: MetaEntityType.Table.name,
          _paramItemsListPropertiesList: tableEntity.rows
              .map((e) => _paramItemsListPropertyEntryTemplate.format({
                    _paramPrefix: data.prefix,
                    _paramPrefixInterface: data.prefixInterface,
                    _paramPostfix: data.postfix,
                    _paramClassName: tableEntity.classId,
                    _paramEntryName: e.id,
                  }))
              .join(),
          _paramItemsListConstructorList: tableEntity.rows
              .map((e) => _paramItemsListConstructorEntryTemplate.format({
                    _paramPrefix: data.prefix,
                    _paramPrefixInterface: data.prefixInterface,
                    _paramPostfix: data.postfix,
                    _paramClassName: tableEntity.classId,
                    _paramEntryName: e.id,
                  }))
              .join(),
        },
      );

      classesDefinitions.add(classDefinition);
    }

    return classesDefinitions.join(_defaultNewLine * 2);
  }

  String _getClassTemplateByClassType(ClassType classType) {
    switch (classType) {
      case ClassType.undefined:
      case ClassType.referenceType:
        return _classTemplate;

      case ClassType.valueType:
        return _structTemplate;

      case ClassType.interface:
        return _interfaceTemplate;
    }
  }

  String _getParentClass(ClassMetaEntity classEntity, GeneratorCsharp data) {
    switch (classEntity.classType) {
      case ClassType.referenceType:
        return ': ${classEntity.parent != null ? '${data.prefix}${classEntity.parent}${data.postfix}' : 'Base${data.prefix}Item${data.postfix}'},';

      case ClassType.undefined:
      case ClassType.valueType:
      case ClassType.interface:
        return '';
    }
  }

  String _getParentInterfaces(ClassMetaEntity classEntity, GeneratorCsharp data) {
    final interfaces = classEntity.interfaces //
        .where((e) => e != null)
        .map((e) => '${data.prefixInterface}$e${data.postfix}')
        .followedBy(classEntity.classType == ClassType.valueType ? [] : ['IIdentifiable'])
        .join(', ');

    if (interfaces.isEmpty) {
      return '';
    }

    switch (classEntity.classType) {
      case ClassType.referenceType:
      case ClassType.valueType:
        return ', $interfaces';

      case ClassType.undefined:
      case ClassType.interface:
        return ' : $interfaces';
    }
  }

  String _getClassProperties(DbModel model, GeneratorCsharp data, ClassMetaEntity classEntity) {
    final items = <String>[];

    final inheritedInterfaceFields = <ClassMetaFieldDescription>[];
    switch (classEntity.classType) {
      case ClassType.undefined:
      case ClassType.interface:
        break;

      case ClassType.referenceType:
      case ClassType.valueType:
        inheritedInterfaceFields.addAll(
          classEntity.interfaces //
              .where((e) => e != null)
              .selectMany((e, index) => model.cache.getAllFieldsByClassId(e!)!),
        );
        break;
    }

    final allFields = [...classEntity.fields, ...inheritedInterfaceFields];

    for (final field in allFields) {
      items.add(
        _classPropertyTemplate.format(
          {
            _paramPropertyAccessLevel: _getPropertyAccessLevel(classEntity, data),
            _paramPropertyType: _getPropertyType(field, data),
            _paramPropertyName: field.id,
            _paramPropertySummary: _makeWholeSummary(field.description, 2),
          },
        ),
      );
    }

    return items.join();
  }

  String _getCloneProperties(DbModel model, ClassMetaEntity classEntity) {
    final allFields = model.cache.getAllFields(classEntity);

    final items = <String>[];
    for (final field in allFields) {
      items.add(
        _copyRowTemplate.format(
          {
            _paramPropertyName: field.id,
            _paramCloneProperty: _getCloneProperty(field),
          },
        ),
      );
    }

    return items.join();
  }

  String _getEnumValues(ClassMetaEntityEnum enumEntity) {
    final allValues = enumEntity.values;

    final items = <String>[];
    for (final value in allValues) {
      items.add(
        _enumRowTemplate.format(
          {
            _paramPropertyName: value.id,
            _paramPropertySummary: _makeWholeSummary(value.description, 2),
          },
        ),
      );
    }

    return items.join();
  }

  String _getListStructGetHashCode(DbModel model, ClassMetaEntity classEntity) {
    final allFields = model.cache.getAllFields(classEntity);

    final items = <String>[];
    for (final field in allFields) {
      items.add(
        _structGetHashCodeTemplate.format(
          {
            _paramPropertyName: field.id,
          },
        ),
      );
    }

    return items.join();
  }

  String _getListStructEquals(DbModel model, ClassMetaEntity classEntity) {
    final allFields = model.cache.getAllFields(classEntity);

    final items = <String>[];
    for (final field in allFields) {
      items.add(
        _structEqualsTemplate.format(
          {
            _paramPropertyName: field.id,
          },
        ),
      );
    }

    return items.join();
  }

  String _getListStructEqEq(DbModel model, ClassMetaEntity classEntity) {
    final allFields = model.cache.getAllFields(classEntity);

    final items = <String>[];
    for (final field in allFields) {
      items.add(
        _structGetEqEqTemplate.format(
          {
            _paramPropertyName: field.id,
          },
        ),
      );
    }

    return items.join();
  }

  String _getPropertyAccessLevel(ClassMetaEntity classEntity, GeneratorCsharp data) {
    switch (classEntity.classType) {
      case ClassType.undefined:
      case ClassType.interface:
        return '';

      case ClassType.referenceType:
      case ClassType.valueType:
        return 'public ';
    }
  }

  String _getPropertyType(ClassMetaFieldDescription field, GeneratorCsharp data) {
    switch (field.typeInfo.type) {
      case ClassFieldType.bool:
      case ClassFieldType.int:
      case ClassFieldType.long:
      case ClassFieldType.float:
      case ClassFieldType.double:
      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.undefined:
      case ClassFieldType.reference:
      case ClassFieldType.date:
      case ClassFieldType.duration:
      case ClassFieldType.color:
      case ClassFieldType.vector2:
      case ClassFieldType.vector2Int:
      case ClassFieldType.vector3:
      case ClassFieldType.vector3Int:
      case ClassFieldType.vector4:
      case ClassFieldType.vector4Int:
      case ClassFieldType.rectangle:
      case ClassFieldType.rectangleInt:
        return _getSimplePropertyType(field.typeInfo, data);

      case ClassFieldType.list:
        return 'List<${_getSimplePropertyType(field.valueTypeInfo!, data)}>';

      case ClassFieldType.listInline:
        return 'List<${_getSimplePropertyType(field.valueTypeInfo!, data)}>';

      case ClassFieldType.set:
        return 'HashSet<${_getSimplePropertyType(field.valueTypeInfo!, data)}>';

      case ClassFieldType.dictionary:
        return 'Dictionary<${_getSimplePropertyType(field.keyTypeInfo!, data)}, ${_getSimplePropertyType(field.valueTypeInfo!, data)}>';
    }
  }

  String _getSimplePropertyType(ClassFieldDescriptionDataInfo type, GeneratorCsharp data) {
    switch (type.type) {
      case ClassFieldType.bool:
        return 'bool';

      case ClassFieldType.int:
        return 'int';

      case ClassFieldType.long:
        return 'long';

      case ClassFieldType.float:
        return 'float';

      case ClassFieldType.double:
        return 'double';

      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.undefined:
        return 'string';

      case ClassFieldType.reference:
        return '${data.prefix}${type.classId!}${data.postfix}';

      case ClassFieldType.list:
      case ClassFieldType.listInline:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        throw Exception('"${type.type.name}" is not a simple type');

      case ClassFieldType.date:
        return 'DateTime';

      case ClassFieldType.duration:
        return 'TimeSpan';

      case ClassFieldType.color:
        return 'Color';

      case ClassFieldType.vector2:
        return 'Vector2';

      case ClassFieldType.vector2Int:
        return 'Vector2Int';

      case ClassFieldType.vector3:
        return 'Vector3';

      case ClassFieldType.vector3Int:
        return 'Vector3Int';

      case ClassFieldType.vector4:
        return 'Vector4';

      case ClassFieldType.vector4Int:
        return 'Vector4Int';

      case ClassFieldType.rectangle:
        return 'Rectangle';

      case ClassFieldType.rectangleInt:
        return 'RectangleInt';
    }
  }

  String _makeSummary(String source, int indentDepth) {
    final lines = source.split(_newLineRegExp).map((e) => '${_indent * indentDepth}/// ${e.trim()}');
    return lines.join(_defaultNewLine);
  }

  String _makeWholeSummary(String summary, int indentDepth) {
    if (summary.isEmpty) return '';

    return '''

${_makeSummary('<summary>', indentDepth)}
${_makeSummary(summary, indentDepth)}
${_makeSummary('</summary>', indentDepth)}''';
  }

  String _getListInstantiate(DbModel model, GeneratorCsharp data) {
    final items = <String>[];
    for (final classEntity in model.cache.allClasses) {
      switch (classEntity.classType) {
        case ClassType.undefined:
        case ClassType.interface:
          break;

        case ClassType.referenceType:
        case ClassType.valueType:
          items.add(
            _getNewInstanceRowTemplate.format(
              {
                _paramClassName: classEntity.id,
                _paramPrefix: data.prefix,
                _paramPrefixInterface: data.prefixInterface,
                _paramPostfix: data.postfix,
              },
            ),
          );
          break;
      }
    }

    return items.join();
  }

  String _getAssignValuesCases(DbModel model, GeneratorCsharp data) {
    final items = <String>[];

    final allClassesSortedByDepth = model.cache.allClasses.orderByDescending((e) => model.cache.getParentClasses(e).length).toList();
    for (final classEntity in allClassesSortedByDepth) {
      switch (classEntity.classType) {
        case ClassType.undefined:
        case ClassType.interface:
          break;

        case ClassType.referenceType:
        case ClassType.valueType:
          items.add(
            _assignValueCaseTemplate.format(
              {
                _paramClassName: '${data.prefix}${classEntity.id}${data.postfix}',
                _paramAssignValueListProperties: _getAssignValueListProperties(model, data, classEntity),
              },
            ),
          );
          break;
      }
    }

    return items.join();
  }

  String _getAssignValueListProperties(DbModel model, GeneratorCsharp data, ClassMetaEntity classEntity) {
    final items = <String>[];
    for (final field in model.cache.getAllFields(classEntity)) {
      items.add(
        _assignValueRowTemplate.format(
          {
            _paramClassName: '${data.prefix}${classEntity.id}${data.postfix}',
            _paramPropertyName: field.id,
            _paramParseFunction: _getAssignValueFunction(model, data, classEntity, field).format({
              _paramPrefix: data.prefix,
              _paramPostfix: data.postfix,
            }),
          },
        ),
      );
    }

    return items.join();
  }

  String _getAssignValueFunction(DbModel model, GeneratorCsharp data, ClassMetaEntity classEntity, ClassMetaFieldDescription field) {
    final value = 'valuesById["${field.id}"]';

    switch (field.typeInfo.type) {
      case ClassFieldType.bool:
      case ClassFieldType.int:
      case ClassFieldType.long:
      case ClassFieldType.float:
      case ClassFieldType.double:
      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.undefined:
      case ClassFieldType.reference:
      case ClassFieldType.date:
      case ClassFieldType.duration:
      case ClassFieldType.color:
      case ClassFieldType.vector2:
      case ClassFieldType.vector2Int:
      case ClassFieldType.vector3:
      case ClassFieldType.vector3Int:
      case ClassFieldType.vector4:
      case ClassFieldType.vector4Int:
      case ClassFieldType.rectangle:
      case ClassFieldType.rectangleInt:
        return _getAssignSimpleValueFunction(model, data, field.typeInfo, value);

      case ClassFieldType.list:
        return 'ParseList(${value}, v => ${_getAssignSimpleValueFunction(model, data, field.valueTypeInfo!, 'v')}, emptyCollectionFactory)';

      case ClassFieldType.listInline:
        return 'ParseListInline(${value}, vs => AssignValues(GetNewInstance("${field.valueTypeInfo!.classId}", null, instance.Id), objectsByIds, vs, emptyCollectionFactory, onError) as {${_paramPrefix}}${field.valueTypeInfo!.classId}{${_paramPostfix}}, emptyCollectionFactory)';

      case ClassFieldType.set:
        return 'ParseHashSet(${value}, v => ${_getAssignSimpleValueFunction(model, data, field.valueTypeInfo!, 'v')}, emptyCollectionFactory)';

      case ClassFieldType.dictionary:
        return 'ParseDictionary(${value}, k => ${_getAssignSimpleValueFunction(model, data, field.keyTypeInfo!, 'k')}, v => ${_getAssignSimpleValueFunction(model, data, field.valueTypeInfo!, 'v')}, emptyCollectionFactory)';
    }
  }

  String _getAssignSimpleValueFunction(
    DbModel model,
    GeneratorCsharp data,
    ClassFieldDescriptionDataInfo type,
    String value,
  ) {
    switch (type.type) {
      case ClassFieldType.bool:
        return 'ParseBool(${value})';

      case ClassFieldType.int:
        return 'ParseInt(${value})';

      case ClassFieldType.long:
        return 'ParseLong(${value})';

      case ClassFieldType.float:
        return 'ParseFloat(${value})';

      case ClassFieldType.double:
        return 'ParseDouble(${value})';

      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.undefined:
        return 'ParseString(${value})';

      case ClassFieldType.reference:
        final classEntity = model.cache.getEntity(type.classId!);
        final genericType = '${data.prefix}${type.classId}${data.postfix}';
        if (classEntity is ClassMetaEntityEnum) //
          return 'ParseEnum<${genericType}>(${value})';
        return 'ParseReference<${genericType}>(${value}, objectsByIds)';

      case ClassFieldType.date:
        return 'ParseDate(${value})';

      case ClassFieldType.duration:
        return 'ParseDuration(${value})';

      case ClassFieldType.color:
        return 'ParseColor(${value})';

      case ClassFieldType.vector2:
        return 'ParseVector2(${value})';

      case ClassFieldType.vector2Int:
        return 'ParseVector2Int(${value})';

      case ClassFieldType.vector3:
        return 'ParseVector3(${value})';

      case ClassFieldType.vector3Int:
        return 'ParseVector3Int(${value})';

      case ClassFieldType.vector4:
        return 'ParseVector4(${value})';

      case ClassFieldType.vector4Int:
        return 'ParseVector4Int(${value})';

      case ClassFieldType.rectangle:
        return 'ParseRectangle(${value})';

      case ClassFieldType.rectangleInt:
        return 'ParseRectangleInt(${value})';

      case ClassFieldType.list:
      case ClassFieldType.listInline:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        throw Exception('Unexpected type "${type.type.name}"');
    }
  }

  String _getCloneProperty(ClassMetaFieldDescription field) {
    switch (field.typeInfo.type) {
      case ClassFieldType.undefined:
      case ClassFieldType.bool:
      case ClassFieldType.int:
      case ClassFieldType.long:
      case ClassFieldType.float:
      case ClassFieldType.double:
      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.date:
      case ClassFieldType.duration:
      case ClassFieldType.reference:
      case ClassFieldType.color:
      case ClassFieldType.vector2:
      case ClassFieldType.vector2Int:
      case ClassFieldType.vector3:
      case ClassFieldType.vector3Int:
      case ClassFieldType.vector4:
      case ClassFieldType.vector4Int:
      case ClassFieldType.rectangle:
      case ClassFieldType.rectangleInt:
        return '';

      case ClassFieldType.list:
      case ClassFieldType.listInline:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        return '.Clone()';
    }
  }

  String _getListItemsListAssignment(DbModel model, GeneratorCsharp data) {
    final classes = model.cache.allClasses.where((e) => e.exportList == true).map((e) => _listItemsListAssignmentRowTemplate.format({
          _paramClassName: e.id,
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramMetaEntityType: MetaEntityType.Class.name,
        }));

    final tables = model.cache.allDataTables.where((e) => e.exportList == true).map((e) => _listItemsListAssignmentRowTemplate.format({
          _paramClassName: e.id,
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramMetaEntityType: MetaEntityType.Table.name,
        }));

    return classes.concat(tables).join();
  }

  String _getListItemsListsDeclarations(DbModel model, GeneratorCsharp data) {
    final classes = model.cache.allClasses.where((e) => e.exportList == true).map((e) => _listItemsListDeclarationRowTemplate.format({
          _paramClassName: e.id,
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramMetaEntityType: MetaEntityType.Class.name,
        }));

    final tables = model.cache.allDataTables.where((e) => e.exportList == true).map((e) => _listItemsListDeclarationRowTemplate.format({
          _paramClassName: e.id,
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramMetaEntityType: MetaEntityType.Table.name,
        }));

    final result = classes.concat(tables).join();
    return '$result${result.isNotEmpty ? _defaultNewLine : ''}';
  }

  int _getMaxStructDepth(DbModel model, int maxAllowedDepth) {
    var depth = 0;
    for (var classEntry in model.cache.allClasses) {
      depth = max(depth, _getStructDepth(model, classEntry.id, 0, maxAllowedDepth));
    }
    return depth;
  }

  int _getStructDepth(DbModel model, String classId, int depth, int maxAllowedDepth) {
    if (depth >= maxAllowedDepth) return depth;

    final classEntity = model.cache.getEntity(classId);
    if (classEntity is ClassMetaEntity && classEntity.classType == ClassType.valueType) {
      depth++;
      final allFields = model.cache.getAllFieldsByClassId(classEntity.id);
      if (allFields != null) {
        final thisDepth = depth;
        for (final field in allFields) {
          if (field.typeInfo.classId != null) //
            depth = max(depth, _getStructDepth(model, field.typeInfo.classId!, thisDepth, maxAllowedDepth));
          if (field.keyTypeInfo?.classId != null) //
            depth = max(depth, _getStructDepth(model, field.keyTypeInfo!.classId!, thisDepth, maxAllowedDepth));
          if (field.valueTypeInfo?.classId != null) //
            depth = max(depth, _getStructDepth(model, field.valueTypeInfo!.classId!, thisDepth, maxAllowedDepth));
        }
      }
    }

    return depth;
  }

  final String _rootTemplate = //
      '''// This file was autogenerated via gceditor https://github.com/kennelken/gceditor_fl
// {${_paramDate}}
// by {${_paramUser}}
//
// Dependencies:
// When used in Unity, https://www.newtonsoft.com/json is required for this parser to work
//
// Usage:
// var config = {${_paramPrefix}}Root{${_paramPostfix}}Parser.Parse(JSON_TEXT_FILE_GENERATED_BY_GCEDITOR)
// Example:
// var config = {${_paramPrefix}}Root{${_paramPostfix}}Parser.Parse(_config.text)
// use 'config' as a source of config data

#pragma warning disable 0414, 0168, 0219, 1998, 0109, all
using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;

#if !UNITY_5_3_OR_NEWER
using System.Text.Json;
using System.Text.Json.Serialization;
#else
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
#endif

#if UNITY_5_3_OR_NEWER
using UnityEngine;
using Rectangle = UnityEngine.Rect;
using RectangleInt = UnityEngine.RectInt;
#elif GODOT4_0_OR_GREATER
using Godot;
using Rectangle = Godot.Rect2;
using RectangleInt = Godot.Rect2I;
using Vector2Int = Godot.Vector2I;
using Vector3Int = Godot.Vector3I;
using Vector4Int = Godot.Vector4I;
#else
using System.Drawing;
using System.Numerics;
using RectangleInt = System.Drawing.Rectangle;
using Rectangle = System.Drawing.RectangleF;
#endif

{${_paramNamespaceStart}}
#region Interfaces
    public interface ICloneable<out T>
    {
        T Clone();
    }

    public static class IClonableExtensions
    {
        public static List<T> Clone<T>(this IEnumerable<ICloneable<T>> source)
        {
            var result = new List<T>();
            foreach (var i in source)
                result.Add(i.Clone());
            return result;
        }
        public static List<T> Clone<T>(this IEnumerable<ICloneable<T>> source, Action<T> modify)
        {
            var result = new List<T>();
            foreach (var i in source)
            {
                var item = i.Clone();
                modify(item);
                result.Add(item);
            }
            return result;
        }
    }

    public interface IIdentifiable
    {
        string Id { get; }
    }
#endregion

#region Root
    /// <summary>
    /// Autogenerated via gceditor
    /// </summary>
    public partial class {${_paramPrefix}}Root{${_paramPostfix}}
    {
        public string CreatedBy;
        public string CreationTime;

        private EmptyCollectionFactory _emptyCollectionFactory;

        public Dictionary<string, IIdentifiable> AllItems { get; private set; }
        public Dictionary<Type, object> AllItemsByType { get; private set; }

        public ItemsLists Lists { get; private set; }

        public T Get<T>(string id) where T : IIdentifiable
        {
            if (AllItems.TryGetValue(id, out var item))
            {
                if (item is T value)
                    return value;

                throw new Exception(\$"Item with id='{id}' is not {typeof(T)}");
            }
            throw new Exception(\$"Could not find item with id '{id}'");
        }

        public List<T> Get<T>(IEnumerable<string> ids) where T : IIdentifiable
        {
            var result = new List<T>();
            foreach (var id in ids)
            {
                if (AllItems.TryGetValue(id, out var item))
                {
                    if (item is T value)
                    {
                        result.Add(value);
                    }
                    else
                    {
                        throw new Exception(\$"Item with id='{id}' is not {typeof(T)}");
                    }
                }
                else
                {
                    throw new Exception(\$"Could not find item with id '{id}'");
                }
            }
            return result;
        }

        public T GetOrDefault<T>(string id, T defaultValue = default) where T : IIdentifiable
        {
            if (AllItems.TryGetValue(id, out var item))
            {
                if (item is T value)
                    return value;

                throw new Exception(\$"Item with id='{id}' is not {typeof(T)}");
            }
            return defaultValue;
        }

        public List<T> GetOrDefault<T>(IEnumerable<string> ids) where T : IIdentifiable
        {
            var result = new List<T>();
            foreach (var id in ids)
            {
                if (AllItems.TryGetValue(id, out var item))
                {
                    if (item is T value)
                    {
                        result.Add(value);
                    }
                    else
                    {
                        throw new Exception(\$"Item with id='{id}' is not {typeof(T)}");
                    }
                }
            }
            return result;
        }

        public IReadOnlyList<T> GetAll<T>() where T : IIdentifiable
        {
            if (!AllItemsByType.TryGetValue(typeof(T), out var items))
            {
                items = _emptyCollectionFactory.List<T>();
                AllItemsByType[typeof(T)] = items;
            }
            return items as List<T>;
        }


        public IList GetAll(Type type)
        {
            if (!AllItemsByType.TryGetValue(type, out var items))
            {
                items = _emptyCollectionFactory.List(type);
                AllItemsByType[type] = items;
            }
            return items as IList;
        }

        /// <summary>
        /// Supposed to be called only once when the model is parsed
        /// </summary>
        public void Init(List<IIdentifiable> items)
        {
            _emptyCollectionFactory = new EmptyCollectionFactory();

            AllItems = new Dictionary<string, IIdentifiable>();
            AllItemsByType = new Dictionary<Type, object>();

            var typesCache = new Dictionary<Type, List<Type>>();
            foreach (var item in items)
            {
                AllItems[item.Id] = item;

                var types = GetParentTypesIncludingCurrent(item.GetType(), typesCache);
                foreach (var type in types)
                {
                    if (type == typeof(object))
                        continue;

                    if (!AllItemsByType.TryGetValue(type, out var listItemsByType))
                    {
                        listItemsByType = Activator.CreateInstance(typeof(List<>).MakeGenericType(type));
                        AllItemsByType.Add(type, listItemsByType);
                    }
                    (listItemsByType as IList).Add(item);
                }
            }

            Lists = new ItemsLists(AllItems);
        }

        private List<Type> GetParentTypesIncludingCurrent(Type type, Dictionary<Type, List<Type>> cache)
        {
            if (!cache.TryGetValue(type, out var result))
            {
                result = new List<Type>(type.GetInterfaces());

                var parent = type;
                while (parent != null)
                {
                    result.Add(parent);
                    parent = parent.BaseType;
                }

                cache[type] = result;
            }
            return result;
        }
    }

    public class ItemsLists
    {{${_paramListItemsListsDeclarations}}
        public ItemsLists(Dictionary<string, IIdentifiable> allItems)
        {{${_paramListItemsListsAssignment}}
        }
    }
#endregion

#region Classes definitions
    public abstract partial class Base{${_paramPrefix}}Item{${_paramPostfix}} : IIdentifiable
    {
        public string Id { get; set; }
        public bool IsGlobal { get; set; }

        public virtual void OnParsed({${_paramPrefix}}Root{${_paramPostfix}} root, CacheRoot cache) {}
    }

{${_paramClasses}}
#endregion

#region Items lists
{${_paramItemsLists}}
#endregion

#region Empty Collections
    internal class EmptyCollectionFactory
    {
        private Dictionary<Type, object> _lists = new Dictionary<Type, object>();
        public List<T> List<T>()
        {
            if (!_lists.TryGetValue(typeof(T), out var list))
            {
                list = new List<T>();
                _lists[typeof(T)] = list;
            }
            return list as List<T>;
        }

        public IList List(Type type)
        {
            if (!_lists.TryGetValue(type, out var list))
            {
                var genericListType = typeof(List<>);
                var concreteListType = genericListType.MakeGenericType(type);

                list = Activator.CreateInstance(concreteListType, Array.Empty<object>());
                _lists[type] = list;
            }
            return list as IList;
        }

        private Dictionary<Type, object> _hashsets = new Dictionary<Type, object>();
        public HashSet<T> HashSet<T>()
        {
            if (!_hashsets.TryGetValue(typeof(T), out var hashSet))
            {
                hashSet = new HashSet<T>();
                _hashsets[typeof(T)] = hashSet;
            }
            return hashSet as HashSet<T>;
        }

        private Dictionary<Type, Dictionary<Type, object>> _dictionaries = new Dictionary<Type, Dictionary<Type, object>>();
        public Dictionary<TKey, TValue> Dictionary<TKey, TValue>()
        {
            if (!_dictionaries.TryGetValue(typeof(TKey), out var dict))
            {
                dict = new Dictionary<Type, object>();
                _dictionaries[typeof(TKey)] = dict;
            }
            if (!dict.TryGetValue(typeof(TValue), out var dicts))
            {
                dicts = new Dictionary<TKey, TValue>();
                dict.Add(typeof(TValue), dicts);
            }
            return dicts as Dictionary<TKey, TValue>;
        }
    }
#endregion

#region Geometry classes
#if !GODOT4_0_OR_GREATER
    #if !UNITY_5_3_OR_NEWER
    public struct Vector2Int
    {
        public int X;
        public int Y;

        public Vector2Int(int x, int y)
        {
            X = x;
            Y = y;
        }
    }

    public struct Vector3Int
    {
        public int X;
        public int Y;
        public int Z;

        public Vector3Int(int x, int y, int z)
        {
            X = x;
            Y = y;
            Z = z;
        }
    }

    public struct RectInt
    {
        public Vector2Int Position;
        public Vector2Int Size;

        public RectInt(Vector2Int position, Vector2Int size)
        {
            Position = position;
            Size = size;
        }
    }
    #endif

    public struct Vector4Int
    {
        public int X;
        public int Y;
        public int Z;
        public int W;

        public Vector4Int(int x, int y, int z, int w)
        {
            X = x;
            Y = y;
            Z = z;
            W = w;
        }
    }
#endif
#endregion

{${_paramJsonParser}}
#pragma warning restore 0414, 0168, 0219, 1998, 0109, all{${_paramNamespaceEnd}}''';

  final String _enumTemplate = '''    /// <summary>
{${_paramClassDescription}}
    /// </summary>
    public enum {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}}
    {{${_paramEnumBody}}
    }''';

  final String _classTemplate = '''    /// <summary>
{${_paramClassDescription}}
    /// </summary>
    public partial class {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} {${_paramParentClass}} ICloneable<{${_paramPrefix}}{${_paramClass}}{${_paramPostfix}}>{${_paramParentInterfaces}}
    {{${_paramPropertiesBody}}

        /// <summary>
        /// Clone of the item. Warning: references to the model entities are not copied!
        /// </summary>
        public new {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} Clone()
        {
            {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} result = new {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}}
            {
                Id = Id,
                IsGlobal = IsGlobal,{${_methodCloneBody}}
            };
            CloneCustom(result);
            return result;
        }

        public override string ToString()
        {
            return \$"{{{${_paramPrefix}}{${_paramClass}}{${_paramPostfix}}}} {{Id: {Id}}}";
        }

        public override void OnParsed({${_paramPrefix}}Root{${_paramPostfix}} root, CacheRoot cache)
        {
            base.OnParsed(root, cache);
            OnParsedImplementation(root, cache);
        }

        partial void CloneCustom({${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} to);
        partial void OnParsedImplementation({${_paramPrefix}}Root{${_paramPostfix}} root, CacheRoot cache);
    }''';

  final String _interfaceTemplate = '''    /// <summary>
{${_paramClassDescription}}
    /// </summary>
    public partial interface {${_paramPrefixInterface}}{${_paramClass}}{${_paramPostfix}}{${_paramParentInterfaces}}
    {{${_paramPropertiesBody}}
    }''';

  final String _classItemsListTemplate =
      '''    public partial class {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}}{${_paramMetaEntityType}}${_itemsListSuffix}
    {{${_paramItemsListPropertiesList}}

        public {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}}{${_paramMetaEntityType}}${_itemsListSuffix}(Dictionary<string, IIdentifiable> allItems)
        {{${_paramItemsListConstructorList}}
        }
    }''';

  final String _paramItemsListPropertyEntryTemplate = '''

        public {${_paramPrefix}}{${_paramClassName}}{${_paramPostfix}} {${_paramEntryName}} { get; }''';
  final String _paramItemsListConstructorEntryTemplate = '''

            if (allItems.TryGetValue("{${_paramEntryName}}", out var {${_paramEntryName}}Value)) {${_paramEntryName}} = ({${_paramPrefix}}{${_paramClassName}}{${_paramPostfix}}){${_paramEntryName}}Value;''';

  final String _structTemplate = '''    /// <summary>
{${_paramClassDescription}}
    /// </summary>
    public partial struct {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} : IIdentifiable, ICloneable<{${_paramPrefix}}{${_paramClass}}{${_paramPostfix}}>{${_paramParentInterfaces}}
    {
        public string Id { get; set; }{${_paramPropertiesBody}}

        /// <summary>
        /// Deep clone of the item
        /// </summary>
        public {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} Clone()
        {
            return this;
        }

        public override bool Equals(object obj)
        {
            return obj is {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} other{${_paramListStructEquals}};
        }

        public override int GetHashCode()
        {
            return 0{${_paramListStructGetHashCode}};
        }

        public static bool operator ==({${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} a, {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} b)
        {
            return true{${_paramListStructEqEq}};
        }

        public static bool operator !=({${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} a, {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} b)
        {
            return !(a == b);
        }

        public override string ToString()
        {
            return \$"{{{${_paramPrefix}}{${_paramClass}}{${_paramPostfix}}}} {{Id: {Id}}}";
        }
    }''';

  final String _structEqualsTemplate = '''

                   && {${_paramPropertyName}} == other.{${_paramPropertyName}}''';
  final String _structGetHashCodeTemplate = '''

                   ^ {${_paramPropertyName}}.GetHashCode()''';
  final String _structGetEqEqTemplate = '''

                   && a.{${_paramPropertyName}} == b.{${_paramPropertyName}}''';

  final String _classPropertyTemplate = '''{${_paramPropertySummary}}
        {${_paramPropertyAccessLevel}}{${_paramPropertyType}} {${_paramPropertyName}} { get; set; }''';

  final String _copyRowTemplate = '''${_defaultNewLine}                {${_paramPropertyName}} = {${_paramPropertyName}}{${_paramCloneProperty}},''';
  final String _enumRowTemplate = '''{${_paramPropertySummary}}
        {${_paramPropertyName}},''';

  final _getNewInstanceRowTemplate = '''

                case "{${_paramClassName}}":
                    return new {${_paramPrefix}}{${_paramClassName}}{${_paramPostfix}} { Id = item?.GetValueOrDefault("id") as string ?? GetInlineRowId(ownerId), IsGlobal = item?.ContainsKey("id") == true };
  ''';

  final String _assignValueCaseTemplate = '''

                    case {${_paramClassName}} {${_paramClassName}}:{${_paramAssignValueListProperties}}
                        return {${_paramClassName}};
''';

  final String _assignValueRowTemplate = '''

                        {${_paramClassName}}.{${_paramPropertyName}} = {${_paramParseFunction}};''';

  final String _listItemsListAssignmentRowTemplate = '''

            {${_paramClassName}} = new {${_paramPrefix}}{${_paramClassName}}{${_paramPostfix}}{${_paramMetaEntityType}}${_itemsListSuffix}(allItems);''';

  final String _listItemsListDeclarationRowTemplate = '''

        public {${_paramPrefix}}{${_paramClassName}}{${_paramPostfix}}{${_paramMetaEntityType}}${_itemsListSuffix} {${_paramClassName}} { get; }''';

  final String _parserTemplate = //
      '''#region JSON
    public static partial class {${_paramPrefix}}Root{${_paramPostfix}}Parser
    {
        public static {${_paramPrefix}}Root{${_paramPostfix}} Parse(string jsonText, {${_paramPrefix}}Root{${_paramPostfix}} root = null, Action<ErrorData> onError = null)
        {
            EmptyCollectionFactory emptyCollectionFactory = new EmptyCollectionFactory();

            var objectsByIds = new Dictionary<string, IIdentifiable>();
            var valuesByIds = new Dictionary<string, Dictionary<string, object>>();

#if !UNITY_5_3_OR_NEWER
            var jsonRoot = JsonSerializer.Deserialize<JsonRoot>(jsonText, new JsonSerializerOptions { IncludeFields = true, TypeInfoResolver = JsonRootSourceGenerationContext.Default });
#else
            var jsonRoot = JsonConvert.DeserializeObject<JsonRoot>(jsonText);
#endif
            foreach (var className in jsonRoot.records.Keys)
            {
                var listItems = jsonRoot.records[className];
                for (var i = 0; i < listItems.Count; i++)
                {
                    var item = listItems[i];

                    var instance = GetNewInstance(className, item);
                    objectsByIds[instance.Id] = instance;
                    valuesByIds[instance.Id] = item;
                }
            }

            var allStructs = new List<string>();
            var allClasses = new List<string>();
            foreach (var kvp in objectsByIds)
            {
                if (kvp.Value.GetType().IsValueType)
                    allStructs.Add(kvp.Key);
                else
                    allClasses.Add(kvp.Key);
            }

            var maxStructDepth = {${_paramMaxStructDepth}};
            for (var i = 0; i < maxStructDepth; i++)
            {
                foreach (var objectId in allStructs)
                    objectsByIds[objectId] = AssignValues(objectsByIds[objectId], objectsByIds, valuesByIds[objectId], emptyCollectionFactory, onError);
            }
            foreach (var objectId in allClasses)
                objectsByIds[objectId] = AssignValues(objectsByIds[objectId], objectsByIds, valuesByIds[objectId], emptyCollectionFactory, onError);

            root ??= new {${_paramPrefix}}Root{${_paramPostfix}}();
            root.CreatedBy = jsonRoot.generationUser;
            root.CreationTime = jsonRoot.generationDate;
            root.Init(new List<IIdentifiable>(objectsByIds.Values));

            var cache = new CacheRoot();

            foreach (var objectId in allClasses)
                (objectsByIds[objectId] as Base{${_paramPrefix}}Item{${_paramPostfix}}).OnParsed(root, cache);

            _inlineItemsCounter.Clear();

            return root;
        }

#if !UNITY_5_3_OR_NEWER
        [JsonSerializable(typeof(JsonRoot)), JsonSourceGenerationOptions(WriteIndented = true)]
        internal partial class JsonRootSourceGenerationContext : JsonSerializerContext
        {
        }
#endif

        public class JsonRoot
        {
            public string generationDate;
            public string generationUser;
            public Dictionary<string, List<Dictionary<string, object>>> records;
        }

        private static IIdentifiable GetNewInstance(string className, Dictionary<string, object> item, string ownerId = null)
        {
            switch (className)
            {{${_paramListInstantiate}}
                default:
                    throw new Exception(\$"Can not create a new instance of an unexpected class '{className}'");
            }
        }

        private static Dictionary<string, int> _inlineItemsCounter = new();
        private static string GetInlineRowId(string ownerId)
        {
            _inlineItemsCounter.TryGetValue(ownerId, out var i);
            _inlineItemsCounter[ownerId] = i + 1;
            return \$"{ownerId}#{i:000}";
        }

        private static IIdentifiable AssignValues(IIdentifiable instance, Dictionary<string, IIdentifiable> objectsByIds, Dictionary<string, object> valuesById, EmptyCollectionFactory emptyCollectionFactory, Action<ErrorData> onError)
        {
            try
            {
                switch (instance)
                {{${_paramAssignValueCases}}
                    default:
                        break;
                }
            }
            catch (Exception e)
            {
                onError?.Invoke(new ErrorData(instance, e, \$"Could not assign values for {instance}"));
            }

            return instance;
        }

#region Parse
        private static Dictionary<TKey, TValue> ParseDictionary<TKey, TValue>(
            object values,
            Func<object, TKey> getKey,
            Func<object, TValue> getValue,
            EmptyCollectionFactory emptyCollectionFactory
        )
        {
#if !UNITY_5_3_OR_NEWER
            if (values == null || ((JsonElement)values).ValueKind != JsonValueKind.Object)
                return emptyCollectionFactory.Dictionary<TKey, TValue>();

            var result = new Dictionary<TKey, TValue>();
            foreach (var element in ((JsonElement)values).EnumerateObject())
            {
              result[getKey(element.Name)] = getValue(element.Value);
            }
#else
            var dictionary = values as JObject;
            if (values == null || (values as string) == "" || dictionary == null)
                return emptyCollectionFactory.Dictionary<TKey, TValue>();

            var result = new Dictionary<TKey, TValue>();
            foreach (var property in dictionary.Properties())
            {
                result[getKey(property.Name)] = getValue(property.Value);
            }
#endif
            return result;
        }

        private static List<T> ParseListInline<T>(
            object values,
            Func<Dictionary<string, object>, T> getValue,
            EmptyCollectionFactory emptyCollectionFactory
        )
        {
#if !UNITY_5_3_OR_NEWER
            if (values == null || ((JsonElement)values).GetArrayLength() <= 0)
                return emptyCollectionFactory.List<T>();

            var result = new List<T>();
            foreach (var element in ((JsonElement)values).EnumerateArray())
            {
                var inlineValues = new Dictionary<string, object>();
                foreach (var prop in element.EnumerateObject())
                    inlineValues[prop.Name] = prop.Value as object;
                result.Add(getValue(inlineValues));
            }
#else
            var array = values as JArray;
            if (values == null || (values as string) == "" || array.Count <= 0)
                return emptyCollectionFactory.List<T>();

            var result = new List<T>();
            foreach (JToken jsonValue in array)
            {
                var value = jsonValue.ToObject<Dictionary<string, object>>();
                result.Add(getValue(value));
            }
#endif
            return result;
        }

        private static List<T> ParseList<T>(
            object values,
            Func<object, T> getValue,
            EmptyCollectionFactory emptyCollectionFactory
        )
        {
#if !UNITY_5_3_OR_NEWER
            if (values == null || ((JsonElement)values).GetArrayLength() <= 0)
                return emptyCollectionFactory.List<T>();

            var result = new List<T>();
            foreach (var element in ((JsonElement)values).EnumerateArray())
                result.Add(getValue(element));
#else
            var array = values as JArray;
            if (values == null || (values as string) == "" || array.Count <= 0)
                return emptyCollectionFactory.List<T>();

            var result = new List<T>(array.Count);
            foreach (var value in array)
                result.Add(getValue(value.Value<string>()));

#endif
            return result;
        }

        private static HashSet<T> ParseHashSet<T>(
            object values,
            Func<object, T> getValue,
            EmptyCollectionFactory emptyCollectionFactory
        )
        {
#if !UNITY_5_3_OR_NEWER
            if (values == null || ((JsonElement)values).GetArrayLength() <= 0)
                return emptyCollectionFactory.HashSet<T>();
#else
            var array = values as JArray;
            if (values == null || (values as string) == "" || array.Count <= 0)
                return emptyCollectionFactory.HashSet<T>();
#endif
            return new HashSet<T>(ParseList<T>(values, getValue, emptyCollectionFactory));
        }

        private static bool ParseBool(object value)
        {
            return ParseInt(value) == 1;
        }

        private static int ParseInt(object value)
        {
#if !UNITY_5_3_OR_NEWER
            return ((JsonElement)value).GetInt32();
#else
            return Convert.ToInt32(value, CultureInfo.InvariantCulture);
#endif
        }

        private static long ParseLong(object value)
        {
#if !UNITY_5_3_OR_NEWER
            return ((JsonElement)value).GetInt64();
#else
            return Convert.ToInt64(value, CultureInfo.InvariantCulture);
#endif
        }

        private static float ParseFloat(object value)
        {
#if !UNITY_5_3_OR_NEWER
            return ((JsonElement)value).GetSingle();
#else
            return Convert.ToSingle(value, CultureInfo.InvariantCulture);
#endif
        }

        private static double ParseDouble(object value)
        {
#if !UNITY_5_3_OR_NEWER
            return ((JsonElement)value).GetDouble();
#else
            return Convert.ToDouble(value, CultureInfo.InvariantCulture);
#endif
        }

        private static string ParseString(object value)
        {
#if !UNITY_5_3_OR_NEWER
            return ((JsonElement)value).GetString();
#else
            return Convert.ToString(value, CultureInfo.InvariantCulture);
#endif
        }

        private static T ParseReference<T>(object value, Dictionary<string, IIdentifiable> objectsByIds) where T : IIdentifiable
        {
            var id = ParseString(value);
            if (string.IsNullOrEmpty(id))
                return default;

            if (objectsByIds.TryGetValue(id, out var instance))
                return (T)instance;

            return default;
        }

        private static T ParseEnum<T>(object value)
        {
            var id = ParseString(value);
            if (string.IsNullOrEmpty(id))
                return default;

            return (T)Enum.Parse(typeof(T), id);
        }

        private static DateTime ParseDate(object value)
        {
#if !UNITY_5_3_OR_NEWER
            if (value is JsonElement je && je.ValueKind == JsonValueKind.Number)
                return DateTimeOffset.FromUnixTimeMilliseconds(je.GetInt64()).UtcDateTime;
#endif
            var date = ParseString(value);
            if (string.IsNullOrEmpty(date))
                return default;

            if (long.TryParse(date, out var ms))
                return DateTimeOffset.FromUnixTimeMilliseconds(ms).UtcDateTime;

            return default;
        }

        private static TimeSpan ParseDuration(object value)
        {
#if !UNITY_5_3_OR_NEWER
            if (value is JsonElement je && je.ValueKind == JsonValueKind.Number)
                return TimeSpan.FromMilliseconds(je.GetInt64());
#endif
            var duration = ParseString(value);
            if (string.IsNullOrEmpty(duration))
                return default;

            if (long.TryParse(duration, out var ms))
                return TimeSpan.FromMilliseconds(ms);

            return default;
        }

        private static Vector2 ParseVector2(object value)
        {
            var vector2 = ParseString(value);
            if (string.IsNullOrEmpty(vector2))
                return default;

            var parts = vector2.Split(';');
            if (parts.Length < 2)
                return default;

            return new Vector2(
                float.Parse(parts[0], CultureInfo.InvariantCulture),
                float.Parse(parts[1], CultureInfo.InvariantCulture)
            );
        }

        private static Vector2Int ParseVector2Int(object value)
        {
            var vector2Int = ParseString(value);
            if (string.IsNullOrEmpty(vector2Int))
                return default;

            var parts = vector2Int.Split(';');
            if (parts.Length < 2)
                return default;

            return new Vector2Int(
                int.Parse(parts[0], CultureInfo.InvariantCulture),
                int.Parse(parts[1], CultureInfo.InvariantCulture)
            );
        }

        private static Vector3 ParseVector3(object value)
        {
            var vector3 = ParseString(value);
            if (string.IsNullOrEmpty(vector3))
                return default;

            var parts = vector3.Split(';');
            if (parts.Length < 3)
                return default;

            return new Vector3(
                float.Parse(parts[0], CultureInfo.InvariantCulture),
                float.Parse(parts[1], CultureInfo.InvariantCulture),
                float.Parse(parts[2], CultureInfo.InvariantCulture)
            );
        }

        private static Vector3Int ParseVector3Int(object value)
        {
            var vector3Int = ParseString(value);
            if (string.IsNullOrEmpty(vector3Int))
                return default;

            var parts = vector3Int.Split(';');
            if (parts.Length < 3)
                return default;

            return new Vector3Int(
                int.Parse(parts[0], CultureInfo.InvariantCulture),
                int.Parse(parts[1], CultureInfo.InvariantCulture),
                int.Parse(parts[2], CultureInfo.InvariantCulture)
            );
        }

        private static Vector4 ParseVector4(object value)
        {
            var vector4 = ParseString(value);
            if (string.IsNullOrEmpty(vector4))
                return default;

            var parts = vector4.Split(';');
            if (parts.Length < 4)
                return default;

            return new Vector4(
                float.Parse(parts[0], CultureInfo.InvariantCulture),
                float.Parse(parts[1], CultureInfo.InvariantCulture),
                float.Parse(parts[2], CultureInfo.InvariantCulture),
                float.Parse(parts[3], CultureInfo.InvariantCulture)
            );
        }

        private static Vector4Int ParseVector4Int(object value)
        {
            var vector4Int = ParseString(value);
            if (string.IsNullOrEmpty(vector4Int))
                return default;

            var parts = vector4Int.Split(';');
            if (parts.Length < 4)
                return default;

            return new Vector4Int(
                int.Parse(parts[0], CultureInfo.InvariantCulture),
                int.Parse(parts[1], CultureInfo.InvariantCulture),
                int.Parse(parts[2], CultureInfo.InvariantCulture),
                int.Parse(parts[3], CultureInfo.InvariantCulture)
            );
        }

        private static Rectangle ParseRectangle(object value)
        {
            var rectangle = ParseString(value);
            if (string.IsNullOrEmpty(rectangle))
                return default;

            var parts = rectangle.Split(';');
            if (parts.Length < 4)
                return default;

            return new Rectangle(
                float.Parse(parts[0], CultureInfo.InvariantCulture),
                float.Parse(parts[1], CultureInfo.InvariantCulture),
                float.Parse(parts[2], CultureInfo.InvariantCulture),
                float.Parse(parts[3], CultureInfo.InvariantCulture)
            );
        }

        private static RectangleInt ParseRectangleInt(object value)
        {
            var rectangleInt = ParseString(value);
            if (string.IsNullOrEmpty(rectangleInt))
                return default;

            var parts = rectangleInt.Split(';');
            if (parts.Length < 4)
                return default;

            return new RectangleInt(
                int.Parse(parts[0], CultureInfo.InvariantCulture),
                int.Parse(parts[1], CultureInfo.InvariantCulture),
                int.Parse(parts[2], CultureInfo.InvariantCulture),
                int.Parse(parts[3], CultureInfo.InvariantCulture)
            );
        }

        private static Color ParseColor(object value)
        {
            var argb = ParseLong(value);
            var alpha = (int)((argb >> 24) & 0xFF);
            var red = (int)((argb >> 16) & 0xFF);
            var green = (int)((argb >> 8) & 0xFF);
            var blue = (int)(argb & 0xFF);
#if UNITY_5_3_OR_NEWER || GODOT4_0_OR_GREATER
            return new Color(red / 255f, green / 255f, blue / 255f, alpha / 255f);
#else
            return Color.FromArgb(alpha, red, green, blue);
#endif
        }
#endregion
    }

    public static class ListExtensions
    {
        public static List<T> Clone<T>(this List<T> source)
        {
            var result = new List<T>(source.Count);
            foreach (var item in source)
            {
                if (item is Base{${_paramPrefix}}Item{${_paramPostfix}} modelItem && !modelItem.IsGlobal)
                {
                    result.Add((modelItem as ICloneable<T>).Clone());
                }
                else
                {
                    result.Add(item);
                }
            }
            return result;
        }
    }

    public static class HashSetExtensions
    {
        public static HashSet<T> Clone<T>(this HashSet<T> source)
        {
            return new HashSet<T>(source);
        }
    }

    public static class DictionaryExtensions
    {
        public static Dictionary<TKey, TValue> Clone<TKey, TValue>(this Dictionary<TKey, TValue> source)
        {
            return new Dictionary<TKey, TValue>(source);
        }
    }

    public class ErrorData
    {
        public IIdentifiable Entity { get; }
        public Exception Exception { get; }
        public string Message { get; }

        public ErrorData(IIdentifiable entity, Exception exception, string message)
        {
            Entity = entity;
            Exception = exception;
            Message = message;
        }
    }

    public class CacheRoot
    {
        private Dictionary<object, object> _caches = new Dictionary<object, object>();

        public CacheRootItem<TKey, TValue> Get<TKey, TValue>(object key, Func<TKey, TValue> getCache, Action<CacheRootItem<TKey, TValue>> onCreated = null)
        {
            if (!_caches.TryGetValue(key, out var result))
            {
                var res = new CacheRootItem<TKey, TValue>(getCache);
                onCreated?.Invoke(res);
                _caches[key] = res;
                result = res;
            }
            return result as CacheRootItem<TKey, TValue>;
        }
    }

    public class CacheRootItem<TKey, TValue>
    {
        private readonly Dictionary<TKey, TValue> _values = new();
        private readonly Func<TKey, TValue> _getValue;

        private Func<ICollection<TKey>> _warmupKeys;
        private bool _warmedup;

        private Action _populateFunction;
        private bool _populated;

        public CacheRootItem(Func<TKey, TValue> getValue)
        {
            _getValue = getValue;
        }

        public CacheRootItem<TKey, TValue> WithWarmup(Func<ICollection<TKey>> keys, bool now = false)
        {
            _warmedup = false;
            _warmupKeys = keys;

            if (now)
            {
                WarmupIfNeeded();
            }

            return this;
        }

        public CacheRootItem<TKey, TValue> WithPopulate<TPopulate>(Func<ICollection<TPopulate>> source, Func<TPopulate, TKey> key, Func<TPopulate, TValue> value, bool now = false)
        {
            _populated = false;
            _populateFunction = () =>
            {
                foreach (var src in source.Invoke())
                {
                    _values[key(src)] = value(src);
                }
            };

            if (now)
            {
                PopulateIfNeeded();
            }
            return this;
        }

        private void WarmupIfNeeded()
        {
            if (_warmupKeys == null || _warmedup)
                return;

            foreach (var key in _warmupKeys.Invoke())
            {
                DoGet(key);
            }
            _warmedup = true;
        }

        private void PopulateIfNeeded()
        {
            if (_populateFunction == null || _populated)
                return;

            _populateFunction.Invoke();
            _populated = true;
        }

        public TValue this[TKey key] => Get(key);

        public TValue Get(TKey key)
        {
            PopulateIfNeeded();
            WarmupIfNeeded();

            return DoGet(key);
        }

        protected TValue DoGet(TKey key)
        {
            if (!_values.TryGetValue(key, out var value))
            {
                value = _getValue(key);
                _values[key] = value;
            }
            return value;
        }

        public void Clear(bool full = false)
        {
            _values.Clear();
            _warmedup = false;
            _populated = false;

            if (full)
            {
                _warmupKeys = null;
                _populateFunction = null;
            }
        }
    }
#endregion''';
}

enum MetaEntityType {
  // ignore: constant_identifier_names
  Class,
  // ignore: constant_identifier_names
  Table
}
