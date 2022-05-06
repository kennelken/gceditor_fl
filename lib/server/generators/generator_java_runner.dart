// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:math';

import 'package:darq/darq.dart';
import 'package:flutter/foundation.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/generator_csharp.dart';
import 'package:gceditor/utils/utils.dart';

import '../../model/db/generator_java.dart';
import 'generators_job.dart';

class GeneratorJavaRunner extends BaseGeneratorRunner<GeneratorJava> with OutputFolderSaver, FilesComparer {
  static final _newLineRegExp = RegExp(r'[\r\n]+');
  static const _indent = '    ';
  static const _defaultNewLine = '\n';
  static const _itemsListSuffix = 'ItemsList';

  static const _paramNamespaceStart = 'namespaceStart';

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
  static const _paramInterfacePropertiesBody = 'interfacePropertiesBody';
  static const _paramEnumBody = '_enumBody';
  static const _methodCloneBody = 'cloneBody';

  static const _paramPropertyAccessLevel = 'propertyAccessLevel';
  static const _paramPropertyType = 'propertyType';
  static const _paramPropertyName = 'propertyName';
  static const _paramPropertySummary = 'propertySummary';
  static const _paramCloneProperty = 'cloneProperty';

  static const _paramListInstantiate = 'listInstantiate';
  static const _paramClassName = 'className';
  static const _paramRegexDate = 'regexDate';
  static const _paramRegexDuration = 'regexDuration';
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
              _paramRegexDate: Config.dateFormatRegex.pattern.replaceAll('\\', '\\\\'),
              _paramRegexDuration: Config.durationFormatRegex.pattern.replaceAll('\\', '\\\\'),
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

      if (!resultChanged(result, previousResult, 'package ')) //
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
    return '''package ${data.namespace};
''';
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
          _paramClassDescription: _makeSummary(enumEntity.description.isNotEmpty ? enumEntity.description : 'No description', 1, true),
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
          _paramClassDescription: _makeSummary(classEntity.description.isNotEmpty ? classEntity.description : 'No description', 1, true),
          _paramPropertiesBody: _getClassProperties(model, data, classEntity, false),
          _paramInterfacePropertiesBody: _getClassProperties(model, data, classEntity, true),
          _methodCloneBody: _getCloneProperties(model, classEntity),
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
          _paramMetaEntityType: describeEnum(MetaEntityType.Class),
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
          _paramMetaEntityType: describeEnum(MetaEntityType.Table),
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
      case ClassType.valueType:
        return _classTemplate;

      case ClassType.interface:
        return _interfaceTemplate;
    }
  }

  String _getParentClass(ClassMetaEntity classEntity, GeneratorCsharp data) {
    switch (classEntity.classType) {
      case ClassType.referenceType:
        return 'extends ${classEntity.parent != null ? '${data.prefix}${classEntity.parent}${data.postfix}' : 'Base${data.prefix}Item${data.postfix}'} implements';

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
        .join(', ');

    if (interfaces.isEmpty) //
      return '';

    switch (classEntity.classType) {
      case ClassType.referenceType:
      case ClassType.valueType:
        return ', $interfaces';

      case ClassType.undefined:
      case ClassType.interface:
        return ' extends $interfaces';
    }
  }

  String _getClassProperties(DbModel model, GeneratorCsharp data, ClassMetaEntity classEntity, bool interface) {
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
              .selectMany((e, index) => model.cache.getAllFieldsById(e!)!),
        );
        break;
    }

    final allFields = [...classEntity.fields, ...inheritedInterfaceFields];

    for (final field in allFields) {
      items.add(
        (interface ? _interfacePropertyTemplate : _classPropertyTemplate).format(
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
        return _getSimplePropertyType(field.typeInfo, data);

      case ClassFieldType.list:
        return 'ArrayList<${_getSimplePropertyType(field.valueTypeInfo!, data)}>';

      case ClassFieldType.set:
        return 'HashSet<${_getSimplePropertyType(field.valueTypeInfo!, data)}>';

      case ClassFieldType.dictionary:
        return 'HashMap<${_getSimplePropertyType(field.keyTypeInfo!, data)}, ${_getSimplePropertyType(field.valueTypeInfo!, data)}>';
    }
  }

  String _getSimplePropertyType(ClassFieldDescriptionDataInfo type, GeneratorCsharp data) {
    switch (type.type) {
      case ClassFieldType.bool:
        return 'Boolean';

      case ClassFieldType.int:
        return 'Integer';

      case ClassFieldType.long:
        return 'Long';

      case ClassFieldType.float:
        return 'Float';

      case ClassFieldType.double:
        return 'Double';

      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.undefined:
        return 'String';

      case ClassFieldType.reference:
        return '${data.prefix}${type.classId!}${data.postfix}';

      case ClassFieldType.list:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        throw Exception('"${describeEnum(type.type)}" is not a simple type');

      case ClassFieldType.date:
        return 'Instant';

      case ClassFieldType.duration:
        return 'Duration';

      case ClassFieldType.color:
        return 'Long';
    }
  }

  String _makeSummary(String source, int indentDepth, bool body) {
    if (!body) {
      return '${_indent * indentDepth}$source';
    }
    final lines = source.split(_newLineRegExp).map((e) => '${_indent * indentDepth} * ${e.trim()}');
    return lines.join(_defaultNewLine);
  }

  String _makeWholeSummary(String summary, int indentDepth) {
    if (summary.isEmpty) return '';

    return '''

${_makeSummary('/**', indentDepth, false)}
${_makeSummary(summary, indentDepth, true)}
${_makeSummary(' */', indentDepth, false)}''';
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
            _paramParseFunction: _getAssignValueFunction(model, data, classEntity, field),
          },
        ),
      );
    }

    return items.join();
  }

  String _getAssignValueFunction(DbModel model, GeneratorCsharp data, ClassMetaEntity classEntity, ClassMetaFieldDescription field) {
    final value = 'valuesById.values.get("${field.id}")';

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
        return _getAssignSimpleValueFunction(model, data, field.typeInfo, '${value}.v');

      case ClassFieldType.list:
        return 'ParseList(${value}.lv, ${_getSimplePropertyType(field.valueTypeInfo!, data)}.class, v -> ${_getAssignSimpleValueFunction(model, data, field.valueTypeInfo!, 'v')}, emptyCollectionFactory)';

      case ClassFieldType.set:
        return 'ParseHashSet(${value}.lv, ${_getSimplePropertyType(field.valueTypeInfo!, data)}.class, v -> ${_getAssignSimpleValueFunction(model, data, field.valueTypeInfo!, 'v')}, emptyCollectionFactory)';

      case ClassFieldType.dictionary:
        return 'ParseDictionary(${value}.dv, ${_getSimplePropertyType(field.keyTypeInfo!, data)}.class, ${_getSimplePropertyType(field.valueTypeInfo!, data)}.class, k -> ${_getAssignSimpleValueFunction(model, data, field.keyTypeInfo!, 'k')}, v -> ${_getAssignSimpleValueFunction(model, data, field.valueTypeInfo!, 'v')}, emptyCollectionFactory)';
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
          return 'GceditorJsonParser.<${genericType}>ParseEnum(${value}, ${genericType}.class)';
        return 'GceditorJsonParser.<${genericType}>ParseReference(${value}, objectsByIds)';

      case ClassFieldType.date:
        return 'ParseDate(${value})';

      case ClassFieldType.duration:
        return 'ParseDuration(${value})';

      case ClassFieldType.color:
        return 'ParseColor(${value})';

      case ClassFieldType.list:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        throw Exception('Unexpected type "${describeEnum(type.type)}"');
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
        return field.id;

      case ClassFieldType.list:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        return 'CloneUtils.Clone(${field.id})';
    }
  }

  String _getListItemsListAssignment(DbModel model, GeneratorCsharp data) {
    final classes = model.cache.allClasses.where((e) => e.exportList == true).map((e) => _listItemsListAssignmentRowTemplate.format({
          _paramClassName: e.id,
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramMetaEntityType: describeEnum(MetaEntityType.Class),
        }));

    final tables = model.cache.allDataTables.where((e) => e.exportList == true).map((e) => _listItemsListAssignmentRowTemplate.format({
          _paramClassName: e.id,
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramMetaEntityType: describeEnum(MetaEntityType.Table),
        }));

    return classes.concat(tables).join();
  }

  String _getListItemsListsDeclarations(DbModel model, GeneratorCsharp data) {
    final classes = model.cache.allClasses.where((e) => e.exportList == true).map((e) => _listItemsListDeclarationRowTemplate.format({
          _paramClassName: e.id,
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramMetaEntityType: describeEnum(MetaEntityType.Class),
        }));

    final tables = model.cache.allDataTables.where((e) => e.exportList == true).map((e) => _listItemsListDeclarationRowTemplate.format({
          _paramClassName: e.id,
          _paramPrefix: data.prefix,
          _paramPrefixInterface: data.prefixInterface,
          _paramPostfix: data.postfix,
          _paramMetaEntityType: describeEnum(MetaEntityType.Table),
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
      final allFields = model.cache.getAllFieldsById(classEntity.id);
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
      '''// This file was autogenerated via gceditor
// {${_paramDate}}
// by {${_paramUser}}

/** Usage:
 *	ObjectMapper objectMapper = new ObjectMapper();
 *	var modelRoot = new ModelRoot();
 *	ModelRoot.GceditorJsonParser.Parse(str, (s) -> {
 *		try {
 *			return objectMapper.readValue(s, ModelRoot.GceditorJsonParser.JsonRoot.class);
 *		} catch (IOException e) {
 *			throw new RuntimeException(e);
 *		}
 *	}, modelRoot, errorData -> HandleError(errorData));
 */

{${_paramNamespaceStart}}
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Type;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.regex.Pattern;

/**
 * Autogenerated via gceditor
 */
public class {${_paramPrefix}}Root{${_paramPostfix}}
{
    public interface ICloneable
    {
        IIdentifiable Clone();
    }

    public static class CloneUtils
    {
        public static <T> ArrayList<T> Clone(ArrayList<T> source)
        {
            return (ArrayList<T>)source.clone();
        }

        public static <T> HashSet<T> Clone(HashSet<T> source)
        {
            return (HashSet<T>)source.clone();
        }

        public static <TKey, TValue> HashMap<TKey, TValue> Clone(HashMap<TKey, TValue> source)
        {
            return (HashMap<TKey, TValue>)source.clone();
        }
    }

    public interface IIdentifiable
    {
        String getId();
    }

    public String CreatedBy;
    public String CreationTime;

    private EmptyCollectionFactory _emptyCollectionFactory;

    private HashMap<String, IIdentifiable> AllItems;
    public HashMap<String, IIdentifiable> getAllItems() { return AllItems; }

    private HashMap<Type, Object> AllItemsByType;
    public HashMap<Type, Object> getAllItemsByType() { return AllItemsByType; }

    private ItemsLists Lists;
    public ItemsLists getLists() { return Lists; }

    public <T extends IIdentifiable> T Get(Class<T> itemClass, String id) throws Exception
    {
        var item = AllItems.get(id);
        if (item != null)
        {
            if (item.getClass() == itemClass)
                return (T)item;

            throw new Exception(String.format("Item with id='%s' is not %s", id, itemClass));
        }
        throw new Exception(String.format("Could not find item with id '%s'", id));
    }

    public <T extends IIdentifiable> T GetOrDefault(Class<T> itemClass, String id, T defaultValue) throws Exception
    {
        var item = AllItems.get(id);
        if (item != null)
        {
            if (item.getClass() == itemClass)
                return (T)item;

            throw new Exception(String.format("Item with id='%s' is not %s", id, itemClass));
        }
        return defaultValue;
    }

    public <T extends IIdentifiable> ArrayList<T> GetAll(Class<T> itemClass)
    {
        var items = AllItemsByType.get(itemClass);
        if (items == null)
        {
            items = _emptyCollectionFactory.List(itemClass);
            AllItemsByType.put(itemClass, items);
        }
        return (ArrayList<T>)items;
    }

    /**
     * Supposed to be called only once when the model is parsed
     */
    public void Init(ArrayList<IIdentifiable> items) throws NoSuchMethodException, InvocationTargetException, InstantiationException, IllegalAccessException
    {
        _emptyCollectionFactory = new EmptyCollectionFactory();

        AllItems = new HashMap<String, IIdentifiable>();
        AllItemsByType = new HashMap<Type, Object>();

        var cache = new HashMap<Type, ArrayList<Class<?>>>();

        for (var item : items)
        {
            AllItems.put(item.getId(), item);

            var allClasses = GetParentTypesIncludingCurrent(item.getClass(), cache);
            for (var type : allClasses)
            {
                if (type == Object.class)
                    continue;

                var listItemsByType = AllItemsByType.get(type);
                if (listItemsByType == null)
                {
                    var constructor = ArrayList.class.getConstructor();
                    listItemsByType = constructor.newInstance();
                    AllItemsByType.put(type, listItemsByType);
                }
                ((ArrayList)listItemsByType).add(item);
            }
        }

        Lists = new ItemsLists(AllItems);
    }

    private ArrayList<Class<?>> GetParentTypesIncludingCurrent(Class<?> type, HashMap<Type, ArrayList<Class<?>>> cache)
    {
        var result = cache.get(type);
        if (result == null)
        {
            result = new ArrayList();
            var interfaces = type.getInterfaces();
            result.addAll(List.of(interfaces));

            var parent = type;
            while (parent != null)
            {
                result.add(parent);
                parent = parent.getSuperclass();
            }

            cache.put(type, result);
        }
        return result;
    }

    public static class ErrorData
    {
        private IIdentifiable Entity;
        public IIdentifiable getEntity() { return Entity; }

        private Exception Exception;
        public Exception getException() { return Exception; }

        private String Message;
        public String getMessage() { return Message; }

        public ErrorData(IIdentifiable entity, Exception exception, String message)
        {
            Entity = entity;
            Exception = exception;
            Message = message;
        }
    }

    public static class ItemsLists
    {{${_paramListItemsListsDeclarations}}
        public ItemsLists(HashMap<String, IIdentifiable> allItems)
        {{${_paramListItemsListsAssignment}}
        }
    }

    public static class Base{${_paramPrefix}}Item{${_paramPostfix}} implements IIdentifiable
    {
        protected String Id;
        public String getId() { return Id; }
    }

{${_paramClasses}}

{${_paramItemsLists}}

{${_paramJsonParser}}
}

class EmptyCollectionFactory
{
    private HashMap<Type, Object> _lists = new HashMap<Type, Object>();
    public <T> ArrayList<T> List(Class<T> itemClass)
    {
        var list = _lists.get(itemClass);
        if (list == null)
        {
            list = new ArrayList<T>();
            _lists.put(itemClass, list);
        }
        return (ArrayList<T>)list;
    }

    private HashMap<Type, Object> _hashsets = new HashMap<Type, Object>();
    public <T> HashSet<T> HashSet(Class<T> itemClass)
    {
        var hashSet = _hashsets.get(itemClass);
        if (hashSet == null)
        {
            hashSet = new HashSet<T>();
            _hashsets.put(itemClass, hashSet);
        }
        return (HashSet<T>)hashSet;
    }

    private HashMap<Type, HashMap<Type, Object>> _dictionaries = new HashMap<Type, HashMap<Type, Object>>();
    public <TKey, TValue> HashMap<TKey, TValue> HashMap(Class<TKey> keyClass, Class<TValue> valueClass)
    {
        HashMap<Type, Object> dict = _dictionaries.get(keyClass);
        if (dict == null)
        {
            dict = new HashMap<Type, Object>();
            _dictionaries.put(keyClass, dict);
        }
        var dicts = dict.get(valueClass);
        if (dicts == null)
        {
            dicts = new HashMap<TKey, TValue>();
            dict.put(valueClass, dicts);
        }
        return (HashMap<TKey, TValue>)dicts;
    }
}
''';

  final String _enumTemplate = '''    /**
{${_paramClassDescription}}
     */
    public enum {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}}
    {{${_paramEnumBody}}
    }''';

  final String _classTemplate = '''    /**
{${_paramClassDescription}}
     */
    public static class {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} {${_paramParentClass}} ICloneable{${_paramParentInterfaces}}
    {{${_paramPropertiesBody}}

        /**
         *  Clone of the item. Warning: references to the model entities are not being copied!
         */
        public {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} Clone()
        {
            {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} result = new {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}}();{${_methodCloneBody}}
            return result;
        }

        public String ToString()
        {
            return String.format("{{${_paramPrefix}}{${_paramClass}}} {Id: %s}", Id);
        }
    }''';

  final String _interfaceTemplate = '''    /**
    {${_paramClassDescription}}
     */
    public interface {${_paramPrefixInterface}}{${_paramClass}}{${_paramPostfix}}{${_paramParentInterfaces}}
    {{${_paramInterfacePropertiesBody}}
    }''';

  final String _classItemsListTemplate =
      '''    public static class {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}}{${_paramMetaEntityType}}${_itemsListSuffix}
    {{${_paramItemsListPropertiesList}}

        public {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}}{${_paramMetaEntityType}}${_itemsListSuffix}(HashMap<String, IIdentifiable> allItems)
        {{${_paramItemsListConstructorList}}
        }
    }''';

  final String _paramItemsListPropertyEntryTemplate = '''

        private {${_paramPrefix}}{${_paramClassName}}{${_paramPostfix}} {${_paramEntryName}};
        public {${_paramPrefix}}{${_paramClassName}}{${_paramPostfix}} get{${_paramEntryName}}() { return {${_paramEntryName}}; }''';
  final String _paramItemsListConstructorEntryTemplate = '''

            var {${_paramEntryName}}Value = allItems.get("{${_paramEntryName}}");
            if ({${_paramEntryName}}Value != null) {${_paramEntryName}} = ({${_paramPrefix}}{${_paramClassName}}{${_paramPostfix}}){${_paramEntryName}}Value;''';

  final String _classPropertyTemplate = '''{${_paramPropertySummary}}
        {${_paramPropertyAccessLevel}}{${_paramPropertyType}} get{${_paramPropertyName}}() { return {${_paramPropertyName}}; }
        {${_paramPropertyAccessLevel}}{${_paramPropertyType}} {${_paramPropertyName}};
        ''';

  final String _interfacePropertyTemplate = '''{${_paramPropertySummary}}
        {${_paramPropertyAccessLevel}}{${_paramPropertyType}} get{${_paramPropertyName}}();
        ''';

  final String _copyRowTemplate = '''${_defaultNewLine}            result.{${_paramPropertyName}} = {${_paramCloneProperty}};''';
  final String _enumRowTemplate = '''{${_paramPropertySummary}}
        {${_paramPropertyName}},''';

  final _getNewInstanceRowTemplate = '''

                case "{${_paramClassName}}":
                    value = new {${_paramPrefix}}{${_paramClassName}}{${_paramPostfix}}(); break;''';

  final String _assignValueCaseTemplate = '''

                if (instance instanceof {${_paramClassName}} {${_paramClassName}})
                {{${_paramAssignValueListProperties}}
                    return {${_paramClassName}};
                }''';

  final String _assignValueRowTemplate = '''

                    {${_paramClassName}}.{${_paramPropertyName}} = {${_paramParseFunction}};''';

  final String _listItemsListAssignmentRowTemplate = '''

            {${_paramClassName}} = new {${_paramPrefix}}{${_paramClassName}}{${_paramPostfix}}{${_paramMetaEntityType}}${_itemsListSuffix}(allItems);''';

  final String _listItemsListDeclarationRowTemplate = '''

        public {${_paramPrefix}}{${_paramClassName}}{${_paramPostfix}}{${_paramMetaEntityType}}${_itemsListSuffix} get{${_paramClassName}}() { return {${_paramClassName}}; }
        private {${_paramPrefix}}{${_paramClassName}}{${_paramPostfix}}{${_paramMetaEntityType}}${_itemsListSuffix} {${_paramClassName}};''';

  final String _parserTemplate = //
      '''
    public static class GceditorJsonParser
    {
        public static {${_paramPrefix}}Root{${_paramPostfix}} Parse(String jsonText, Function<String, JsonRoot> parseFunction, {${_paramPrefix}}Root{${_paramPostfix}} root, Consumer<ErrorData> onError)  throws InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException
        {
            EmptyCollectionFactory emptyCollectionFactory = new EmptyCollectionFactory();

            var objectsByIds = new HashMap<String, IIdentifiable>();
            var valuesByIds = new HashMap<String, JsonItem>();

            var jsonRoot = parseFunction.apply(jsonText);
            for (var className : jsonRoot.classes.keySet())
            {
                var listItems = jsonRoot.classes.get(className);
                for (var i = 0; i < listItems.items.size(); i++)
                {
                    var item = listItems.items.get(i);

                    var instance = GetNewInstance(className, item);
                    objectsByIds.put(instance.getId(), instance);
                    valuesByIds.put(instance.getId(), item);
                }
            }

            var allClasses = objectsByIds.keySet();
            for (var objectId : allClasses)
                objectsByIds.put(objectId, AssignValues(objectsByIds.get(objectId), objectsByIds, valuesByIds.get(objectId), emptyCollectionFactory, onError));

            if (root == null)
              root = new {${_paramPrefix}}Root{${_paramPostfix}}();
            root.CreatedBy = jsonRoot.user;
            root.CreationTime = jsonRoot.date;
            root.Init(new ArrayList<IIdentifiable>(objectsByIds.values()));

            return root;
        }

        public static class JsonRoot
        {
            public String date;
            public String user;
            public HashMap<String, JsonItemList> classes;
        }

        public static class JsonItemList
        {
            public ArrayList<JsonItem> items;
        }

        public static class JsonItem
        {
            public String id;
            public HashMap<String, JsonCellValue> values;
        }

        public static class JsonCellValue {
            public Object v;
            public ArrayList<Object> lv;
            public ArrayList<JsonDictionaryItem> dv;
        }

        public static class JsonDictionaryItem {
            public Object key;
            public Object value;
        }

        private static IIdentifiable GetNewInstance(String className, JsonItem item)
        {
            Base{${_paramPrefix}}Item{${_paramPostfix}} value;

            switch (className)
            {{${_paramListInstantiate}}
                default:
                    value = new Base{${_paramPrefix}}Item{${_paramPostfix}}(); break;
            }
            value.Id = item.id;
            return value;
        }

        private static IIdentifiable AssignValues(IIdentifiable instance, HashMap<String, IIdentifiable> objectsByIds, JsonItem valuesById, EmptyCollectionFactory emptyCollectionFactory, Consumer<ErrorData> onError)
        {
            try
            {{${_paramAssignValueCases}}
            }
            catch (Exception e)
            {
                if (onError != null)
                    onError.accept(new ErrorData(instance, e, String.format("Could not assign values for '%s'", instance)));
            }

            return instance;
        }

        private static <TKey, TValue> HashMap<TKey, TValue> ParseDictionary(
            ArrayList<JsonDictionaryItem> values,
            Class<TKey> keyClass,
            Class<TValue> valueClass,
            Function<Object, TKey> getKey,
            Function<Object, TValue> getValue,
            EmptyCollectionFactory emptyCollectionFactory
        )
        {
            if (values.size() <= 0)
                return emptyCollectionFactory.<TKey, TValue>HashMap(keyClass, valueClass);

            var result = new HashMap<TKey, TValue>();
            for (var value : values)
                result.put(getKey.apply(value.key), getValue.apply(value.value));

            return result;
        }

        private static <T> ArrayList<T> ParseList(
            ArrayList<Object> values,
            Class<T> valueClass,
            Function<Object, T> getValue,
            EmptyCollectionFactory emptyCollectionFactory
        )
        {
            if (values.size() <= 0)
                return emptyCollectionFactory.<T>List(valueClass);

            var result = new ArrayList<T>();
            for (var value : values)
                result.add(getValue.apply(value));
            return result;
        }

        private static <T> HashSet<T> ParseHashSet(
            ArrayList<Object> values,
            Class<T> valueClass,
            Function<Object, T> getValue,
            EmptyCollectionFactory emptyCollectionFactory
        )
        {
            if (values.size() <= 0)
                return emptyCollectionFactory.<T>HashSet(valueClass);

            return new HashSet<T>(GceditorJsonParser.<T>ParseList(values, valueClass, getValue, emptyCollectionFactory));
        }

        private static boolean ParseBool(Object value)
        {
            return Integer.parseInt(value.toString()) == 1;
        }

        private static Integer ParseInt(Object value)
        {
            return Integer.parseInt(value.toString());
        }

        private static Long ParseLong(Object value)
        {
            return Long.parseLong(value.toString());
        }

        private static Float ParseFloat(Object value)
        {
            return Float.parseFloat(value.toString());
        }

        private static Double ParseDouble(Object value)
        {
            return Double.parseDouble(value.toString());
        }

        private static String ParseString(Object value)
        {
            return value.toString();
        }

        private static <T extends IIdentifiable> T ParseReference(Object value, HashMap<String, IIdentifiable> objectsByIds)
        {
            var id = value.toString();
            if (id == null || id == "")
                return null;

            return (T)objectsByIds.get(id);
        }

        private static <T extends Enum<T>> T ParseEnum(Object value, Class<T> enumClass)
        {
            var id = value.toString();
            if (id == null || id == "")
                return null;

            return (T)Enum.valueOf(enumClass, id);
        }

        private static Pattern dateFormatRegex = Pattern.compile("{${_paramRegexDate}}");
        private static Instant ParseDate(Object value)
        {
            var date = value.toString();
            if (date == null || date == "")
                return null;

            var matcher = dateFormatRegex.matcher(date);
            if (matcher.matches()) {
                var y = matcher.group("y");
                var m = matcher.group("m");
                var d = matcher.group("d");
                var hh = matcher.group("hh");
                var mm = matcher.group("mm");
                var ss = matcher.group("ss");

                var year = y == null ? 0 : Integer.parseInt(y);
                var month = m == null ? 0 : Integer.parseInt(m);
                var day = d == null ? 0 : Integer.parseInt(d);
                var hour = hh == null ? 0 : Integer.parseInt(hh);
                var minute = mm == null ? 0 : Integer.parseInt(mm);
                var second = ss == null ? 0 : Integer.parseInt(ss);

                return Instant.ofEpochMilli(0)
                    .atZone(ZoneOffset.UTC)
                    .withYear(year)
                    .withMonth(month)
                    .withDayOfMonth(day)
                    .withHour(hour)
                    .withMinute(minute)
                    .withSecond(second)
                    .toInstant();
            }

            return null;
        }

        private static Pattern durationFormatRegex = Pattern.compile("{${_paramRegexDuration}}");
        private static Duration ParseDuration(Object value)
        {
            var duration = value.toString();
            if (duration == null || duration == "")
                return null;

            var matcher = durationFormatRegex.matcher(duration);
            if (matcher.matches()) {
                var d = matcher.group("d");
                var h = matcher.group("h");
                var m = matcher.group("m");
                var s = matcher.group("s");

                var days = d == null ? 0 : Integer.parseInt(d);
                var hours = h == null ? 0 : Integer.parseInt(h);
                var minutes = m == null ? 0 : Integer.parseInt(m);
                var seconds = s == null ? 0 : Integer.parseInt(s);

                return Duration.ofDays(days).plusHours(hours).plusMinutes(minutes).plusSeconds(seconds);
            }

            return null;
        }

        private static Long ParseColor(Object value)
        {
            return ParseLong(value);
        }
    }
''';
}

enum MetaEntityType {
  // ignore: constant_identifier_names
  Class,
  // ignore: constant_identifier_names
  Table
}
