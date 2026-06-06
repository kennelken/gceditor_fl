// ignore_for_file: unnecessary_brace_in_string_interps

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
  static const _paramPropertyAccessLevel = 'propertyAccessLevel';
  static const _paramPropertyType = 'propertyType';
  static const _paramPropertyName = 'propertyName';
  static const _paramPropertySummary = 'propertySummary';
  static const _paramCloneProperty = 'cloneProperty';

  static const _paramJsonRootRecordsTypedListFields = 'jsonRootRecordsTypedListFields';
  static const _paramJsonRootPopulateObjectsByIds = 'jsonRootPopulateObjectsByIds';
  static const _paramTypeConverterRegistrations = 'typeConverterRegistrations';
  static const _paramClassName = 'className';

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
              _paramJsonRootRecordsTypedListFields: _getJsonRootRecordsTypedListFields(model, data),
              _paramJsonRootPopulateObjectsByIds: _getJsonRootPopulateObjectsByIds(model, data),
              _paramTypeConverterRegistrations: _getTypeConverterRegistrations(model, data),
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
    final additionalInterfaces = <String>[
      ...classEntity.interfaces //
          .where((e) => e != null)
          .map((e) => '${data.prefixInterface}$e${data.postfix}'),
    ];

    switch (classEntity.classType) {
      case ClassType.referenceType:
        additionalInterfaces.add('IIdentifiable');
        break;

      case ClassType.valueType:
        additionalInterfaces.add('IEquatable<${data.prefix}${classEntity.id}${data.postfix}>');
        break;

      case ClassType.undefined:
      case ClassType.interface:
        additionalInterfaces.add('IIdentifiable');
        break;
    }

    final interfaces = additionalInterfaces.join(', ');
    if (interfaces.isEmpty) return '';

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
    final enumClassIds = model.cache.allEnums.map((e) => e.id).toSet();

    for (final field in allFields) {
      items.add(
        _classPropertyTemplate.format(
          {
            _paramPropertyAccessLevel: _getPropertyAccessLevel(classEntity, data),
            _paramPropertyType: _getPropertyType(field, data, enumClassIds),
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
      items.add(',${_defaultNewLine}${_indent * 4}${field.id}');
    }

    return items.join();
  }

  String _getListStructEquals(DbModel model, ClassMetaEntity classEntity) {
    final allFields = model.cache.getAllFields(classEntity);

    final items = <String>[
      _structEqualsTemplate.format({_paramPropertyName: 'Id'}),
      _structEqualsTemplate.format({_paramPropertyName: 'IsGlobal'}),
    ];
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

  String _getPropertyType(ClassMetaFieldDescription field, GeneratorCsharp data, Set<String> enumClassIds) {
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
        return _getSimplePropertyType(field.typeInfo, data, enumClassIds);

      case ClassFieldType.list:
        return 'List<${_getSimplePropertyType(field.valueTypeInfo!, data, enumClassIds)}>';

      case ClassFieldType.listInline:
        return 'List<${_getSimplePropertyType(field.valueTypeInfo!, data, enumClassIds)}>';

      case ClassFieldType.set:
        return 'HashSet<${_getSimplePropertyType(field.valueTypeInfo!, data, enumClassIds)}>';

      case ClassFieldType.dictionary:
        return 'Dictionary<${_getSimplePropertyType(field.keyTypeInfo!, data, enumClassIds)}, ${_getSimplePropertyType(field.valueTypeInfo!, data, enumClassIds)}>';
    }
  }

  String _getSimplePropertyType(ClassFieldDescriptionDataInfo type, GeneratorCsharp data, Set<String> enumClassIds) {
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
        if (enumClassIds.contains(type.classId)) return 'string';
        return '${data.prefix}Item${data.postfix}Ref<${data.prefix}${type.classId!}${data.postfix}>';

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

  String _getJsonRootRecordsTypedListFields(DbModel model, GeneratorCsharp data) {
    final items = <String>[];
    for (final classEntity in model.cache.allClasses) {
      switch (classEntity.classType) {
        case ClassType.undefined:
        case ClassType.interface:
          break;
        case ClassType.referenceType:
        case ClassType.valueType:
          items.add('            public List<${data.prefix}${classEntity.id}${data.postfix}> ${classEntity.id};');
          break;
      }
    }
    for (final tableEntity in model.cache.allDataTables) {
      items.add('            public List<${data.prefix}${tableEntity.classId}${data.postfix}> ${tableEntity.id};');
    }
    return items.join('\n');
  }

  String _getJsonRootPopulateObjectsByIds(DbModel model, GeneratorCsharp data) {
    final items = <String>[];
    final all = <String>[
      ...model.cache.allClasses.where((e) => e.classType == ClassType.referenceType || e.classType == ClassType.valueType).map((e) => e.id),
      ...model.cache.allDataTables.map((e) => e.id),
    ];
    for (final id in all) {
      items.add(_jsonRootPopulateTemplate.format({
        _paramClassName: id,
      }));
    }
    return items.join('\n');
  }

  String _getTypeConverterRegistrations(DbModel model, GeneratorCsharp data) {
    final items = <String>[];
    for (final classEntity in model.cache.allClasses) {
      if (classEntity.classType != ClassType.referenceType && classEntity.classType != ClassType.valueType) continue;
      items.add(
          '            TypeDescriptor.AddAttributes(typeof(${data.prefix}Item${data.postfix}Ref<${data.prefix}${classEntity.id}${data.postfix}>),');
      items.add(
          '                new TypeConverterAttribute(typeof(${data.prefix}Item${data.postfix}RefTypeConverter<${data.prefix}${classEntity.id}${data.postfix}>)));');
    }
    return items.join('\n');
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
using System.ComponentModel;
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
        bool IsGlobal { get; }
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
        public string Id { get; set; }
        public bool IsGlobal { get; set; }{${_paramPropertiesBody}}

        /// <summary>
        /// Deep clone of the item
        /// </summary>
        public {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} Clone()
        {
            return this;
        }

        public bool Equals({${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} other)
        {
            return true{${_paramListStructEquals}};
        }

        public override bool Equals(object obj)
        {
            return obj is {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} other && Equals(other);
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(Id, IsGlobal{${_paramListStructGetHashCode}});
        }

        public static bool operator ==({${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} a, {${_paramPrefix}}{${_paramClass}}{${_paramPostfix}} b)
        {
            return a.Equals(b);
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
  final String _classPropertyTemplate = '''{${_paramPropertySummary}}
        {${_paramPropertyAccessLevel}}{${_paramPropertyType}} {${_paramPropertyName}} { get; set; }''';

  final String _copyRowTemplate = '''${_defaultNewLine}                {${_paramPropertyName}} = {${_paramPropertyName}}{${_paramCloneProperty}},''';
  final String _enumRowTemplate = '''{${_paramPropertySummary}}
        {${_paramPropertyName}},''';

  final String _jsonRootPopulateTemplate = '''
            if (jsonRoot.records.{${_paramClassName}} != null)
                foreach (var item in jsonRoot.records.{${_paramClassName}})
                    objectsByIds[item.Id] = item;''';

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
#if !UNITY_5_3_OR_NEWER
            var options = new JsonSerializerOptions
            {
                IncludeFields = true,
                Converters =
                {
                    new {${_paramPrefix}}Item{${_paramPostfix}}RefConverterFactory(),
                    new BoolConverter(),
                    new DateTimeConverter(),
                    new TimeSpanConverter(),
                    new ColorConverter(),
                    new Vector2Converter(),
                    new Vector2IntConverter(),
                    new Vector3Converter(),
                    new Vector3IntConverter(),
                    new Vector4Converter(),
                    new Vector4IntConverter(),
                    new RectangleConverter(),
                    new RectangleIntConverter(),
                }
            };
            var jsonRoot = JsonSerializer.Deserialize<JsonRoot>(jsonText, options);
#else
            var settings = new JsonSerializerSettings
            {
                Converters =
                {
                    new {${_paramPrefix}}Item{${_paramPostfix}}RefConverter(),
                    new BoolConverter(),
                    new DateTimeConverter(),
                    new TimeSpanConverter(),
                    new ColorConverter(),
                    new Vector2Converter(),
                    new Vector2IntConverter(),
                    new Vector3Converter(),
                    new Vector3IntConverter(),
                    new Vector4Converter(),
                    new Vector4IntConverter(),
                    new RectangleConverter(),
                    new RectangleIntConverter(),
                }
            };
            var jsonRoot = JsonConvert.DeserializeObject<JsonRoot>(jsonText, settings);
#endif
            var objectsByIds = new Dictionary<string, IIdentifiable>();

            {${_paramPrefix}}Item{${_paramPostfix}}RefCache.Items = objectsByIds;

{${_paramJsonRootPopulateObjectsByIds}}

            root ??= new {${_paramPrefix}}Root{${_paramPostfix}}();
            root.CreatedBy = jsonRoot.generationUser;
            root.CreationTime = jsonRoot.generationDate;
            root.Init(new List<IIdentifiable>(objectsByIds.Values));

            var cache = new CacheRoot();

            foreach (var item in objectsByIds.Values)
            {
                if (item is Base{${_paramPrefix}}Item{${_paramPostfix}} baseItem)
                    baseItem.OnParsed(root, cache);
            }

            {${_paramPrefix}}Item{${_paramPostfix}}RefCache.Items = null;

            return root;
        }

        public class JsonRoot
        {
            public string generationDate;
            public string generationUser;
            public JsonRootRecords records;
        }

        public class JsonRootRecords
        {
{${_paramJsonRootRecordsTypedListFields}}
        }

#region JsonConverters
#if !UNITY_5_3_OR_NEWER
        public class {${_paramPrefix}}Item{${_paramPostfix}}RefConverterFactory : JsonConverterFactory
        {
            public override bool CanConvert(Type typeToConvert) =>
                typeToConvert.IsGenericType && typeToConvert.GetGenericTypeDefinition() == typeof({${_paramPrefix}}Item{${_paramPostfix}}Ref<>);

            public override JsonConverter CreateConverter(Type typeToConvert, JsonSerializerOptions options)
            {
                var elementType = typeToConvert.GetGenericArguments()[0];
                return (JsonConverter)Activator.CreateInstance(typeof({${_paramPrefix}}Item{${_paramPostfix}}RefConverter<>).MakeGenericType(elementType));
            }
        }

        public class {${_paramPrefix}}Item{${_paramPostfix}}RefConverter<T> : JsonConverter<{${_paramPrefix}}Item{${_paramPostfix}}Ref<T>> where T : IIdentifiable
        {
            public override {${_paramPrefix}}Item{${_paramPostfix}}Ref<T> Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
            {
                if (reader.TokenType == JsonTokenType.String)
                {
                    var id = reader.GetString();
                    return new {${_paramPrefix}}Item{${_paramPostfix}}Ref<T>(id, id != null);
                }
                if (reader.TokenType == JsonTokenType.StartObject)
                {
                    var value = JsonSerializer.Deserialize<T>(ref reader, options);
                    return new {${_paramPrefix}}Item{${_paramPostfix}}Ref<T>(value);
                }
                return default;
            }

            public override void Write(Utf8JsonWriter writer, {${_paramPrefix}}Item{${_paramPostfix}}Ref<T> value, JsonSerializerOptions options)
            {
                JsonSerializer.Serialize(writer, value.Value, options);
            }
        }

        public class BoolConverter : JsonConverter<bool>
        {
            public override bool Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
            {
                if (reader.TokenType == JsonTokenType.Number)
                    return reader.GetInt32() == 1;
                if (reader.TokenType == JsonTokenType.True)
                    return true;
                if (reader.TokenType == JsonTokenType.False)
                    return false;
                return reader.GetString() == "1";
            }

            public override void Write(Utf8JsonWriter writer, bool value, JsonSerializerOptions options) =>
                writer.WriteNumberValue(value ? 1 : 0);
        }

        public class DateTimeConverter : JsonConverter<DateTime>
        {
            public override DateTime Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
            {
                if (reader.TokenType == JsonTokenType.Number)
                    return DateTimeOffset.FromUnixTimeMilliseconds(reader.GetInt64()).UtcDateTime;
                var date = reader.GetString();
                if (string.IsNullOrEmpty(date) || !long.TryParse(date, out var ms))
                    return default;
                return DateTimeOffset.FromUnixTimeMilliseconds(ms).UtcDateTime;
            }

            public override void Write(Utf8JsonWriter writer, DateTime value, JsonSerializerOptions options) =>
                writer.WriteNumberValue(new DateTimeOffset(value).ToUnixTimeMilliseconds());
        }

        public class TimeSpanConverter : JsonConverter<TimeSpan>
        {
            public override TimeSpan Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
            {
                if (reader.TokenType == JsonTokenType.Number)
                    return TimeSpan.FromMilliseconds(reader.GetInt64());
                var duration = reader.GetString();
                if (string.IsNullOrEmpty(duration) || !long.TryParse(duration, out var ms))
                    return default;
                return TimeSpan.FromMilliseconds(ms);
            }

            public override void Write(Utf8JsonWriter writer, TimeSpan value, JsonSerializerOptions options) =>
                writer.WriteNumberValue((long)value.TotalMilliseconds);
        }

        public class ColorConverter : JsonConverter<Color>
        {
            public override Color Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
            {
                var argb = reader.GetInt64();
                return ArgbToColor(argb);
            }

            public override void Write(Utf8JsonWriter writer, Color value, JsonSerializerOptions options) =>
                writer.WriteNumberValue(ColorToArgb(value));

            private static Color ArgbToColor(long argb)
            {
                var alpha = (int)((argb >> 24) & 0xFF);
                var red = (int)((argb >> 16) & 0xFF);
                var green = (int)((argb >> 8) & 0xFF);
                var blue = (int)(argb & 0xFF);
#if GODOT4_0_OR_GREATER
                return new Color(red / 255f, green / 255f, blue / 255f, alpha / 255f);
#else
                return Color.FromArgb(alpha, red, green, blue);
#endif
            }

            private static long ColorToArgb(Color color)
            {
#if GODOT4_0_OR_GREATER
                return (long)((int)(color.a * 255) << 24 | (int)(color.r * 255) << 16 | (int)(color.g * 255) << 8 | (int)(color.b * 255));
#else
                return (long)((int)color.A << 24 | (int)color.R << 16 | (int)color.G << 8 | (int)color.B);
#endif
            }
        }

        public class Vector2Converter : JsonConverter<Vector2>
        {
            public override Vector2 Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) =>
                ParseVector2(reader.GetString());

            public override void Write(Utf8JsonWriter writer, Vector2 value, JsonSerializerOptions options) =>
                writer.WriteStringValue(\$"{value.X};{value.Y}");

            private static Vector2 ParseVector2(string value)
            {
                if (string.IsNullOrEmpty(value)) return default;
                var parts = value.Split(';');
                if (parts.Length < 2) return default;
                return new Vector2(
                    float.Parse(parts[0], CultureInfo.InvariantCulture),
                    float.Parse(parts[1], CultureInfo.InvariantCulture));
            }
        }

        public class Vector2IntConverter : JsonConverter<Vector2Int>
        {
            public override Vector2Int Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) =>
                ParseVector2Int(reader.GetString());

            public override void Write(Utf8JsonWriter writer, Vector2Int value, JsonSerializerOptions options) =>
                writer.WriteStringValue(\$"{value.X};{value.Y}");

            private static Vector2Int ParseVector2Int(string value)
            {
                if (string.IsNullOrEmpty(value)) return default;
                var parts = value.Split(';');
                if (parts.Length < 2) return default;
                return new Vector2Int(
                    int.Parse(parts[0], CultureInfo.InvariantCulture),
                    int.Parse(parts[1], CultureInfo.InvariantCulture));
            }
        }

        public class Vector3Converter : JsonConverter<Vector3>
        {
            public override Vector3 Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) =>
                ParseVector3(reader.GetString());

            public override void Write(Utf8JsonWriter writer, Vector3 value, JsonSerializerOptions options) =>
                writer.WriteStringValue(\$"{value.X};{value.Y};{value.Z}");

            private static Vector3 ParseVector3(string value)
            {
                if (string.IsNullOrEmpty(value)) return default;
                var parts = value.Split(';');
                if (parts.Length < 3) return default;
                return new Vector3(
                    float.Parse(parts[0], CultureInfo.InvariantCulture),
                    float.Parse(parts[1], CultureInfo.InvariantCulture),
                    float.Parse(parts[2], CultureInfo.InvariantCulture));
            }
        }

        public class Vector3IntConverter : JsonConverter<Vector3Int>
        {
            public override Vector3Int Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) =>
                ParseVector3Int(reader.GetString());

            public override void Write(Utf8JsonWriter writer, Vector3Int value, JsonSerializerOptions options) =>
                writer.WriteStringValue(\$"{value.X};{value.Y};{value.Z}");

            private static Vector3Int ParseVector3Int(string value)
            {
                if (string.IsNullOrEmpty(value)) return default;
                var parts = value.Split(';');
                if (parts.Length < 3) return default;
                return new Vector3Int(
                    int.Parse(parts[0], CultureInfo.InvariantCulture),
                    int.Parse(parts[1], CultureInfo.InvariantCulture),
                    int.Parse(parts[2], CultureInfo.InvariantCulture));
            }
        }

        public class Vector4Converter : JsonConverter<Vector4>
        {
            public override Vector4 Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) =>
                ParseVector4(reader.GetString());

            public override void Write(Utf8JsonWriter writer, Vector4 value, JsonSerializerOptions options) =>
                writer.WriteStringValue(\$"{value.X};{value.Y};{value.Z};{value.W}");

            private static Vector4 ParseVector4(string value)
            {
                if (string.IsNullOrEmpty(value)) return default;
                var parts = value.Split(';');
                if (parts.Length < 4) return default;
                return new Vector4(
                    float.Parse(parts[0], CultureInfo.InvariantCulture),
                    float.Parse(parts[1], CultureInfo.InvariantCulture),
                    float.Parse(parts[2], CultureInfo.InvariantCulture),
                    float.Parse(parts[3], CultureInfo.InvariantCulture));
            }
        }

        public class Vector4IntConverter : JsonConverter<Vector4Int>
        {
            public override Vector4Int Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) =>
                ParseVector4Int(reader.GetString());

            public override void Write(Utf8JsonWriter writer, Vector4Int value, JsonSerializerOptions options) =>
                writer.WriteStringValue(\$"{value.X};{value.Y};{value.Z};{value.W}");

            private static Vector4Int ParseVector4Int(string value)
            {
                if (string.IsNullOrEmpty(value)) return default;
                var parts = value.Split(';');
                if (parts.Length < 4) return default;
                return new Vector4Int(
                    int.Parse(parts[0], CultureInfo.InvariantCulture),
                    int.Parse(parts[1], CultureInfo.InvariantCulture),
                    int.Parse(parts[2], CultureInfo.InvariantCulture),
                    int.Parse(parts[3], CultureInfo.InvariantCulture));
            }
        }

        public class RectangleConverter : JsonConverter<Rectangle>
        {
            public override Rectangle Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) =>
                ParseRectangle(reader.GetString());

            public override void Write(Utf8JsonWriter writer, Rectangle value, JsonSerializerOptions options) =>
                writer.WriteStringValue(\$"{value.X};{value.Y};{value.Width};{value.Height}");

            private static Rectangle ParseRectangle(string value)
            {
                if (string.IsNullOrEmpty(value)) return default;
                var parts = value.Split(';');
                if (parts.Length < 4) return default;
                return new Rectangle(
                    float.Parse(parts[0], CultureInfo.InvariantCulture),
                    float.Parse(parts[1], CultureInfo.InvariantCulture),
                    float.Parse(parts[2], CultureInfo.InvariantCulture),
                    float.Parse(parts[3], CultureInfo.InvariantCulture));
            }
        }

        public class RectangleIntConverter : JsonConverter<RectangleInt>
        {
            public override RectangleInt Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) =>
                ParseRectangleInt(reader.GetString());

            public override void Write(Utf8JsonWriter writer, RectangleInt value, JsonSerializerOptions options) =>
                writer.WriteStringValue(\$"{value.X};{value.Y};{value.Width};{value.Height}");

            private static RectangleInt ParseRectangleInt(string value)
            {
                if (string.IsNullOrEmpty(value)) return default;
                var parts = value.Split(';');
                if (parts.Length < 4) return default;
                return new RectangleInt(
                    int.Parse(parts[0], CultureInfo.InvariantCulture),
                    int.Parse(parts[1], CultureInfo.InvariantCulture),
                    int.Parse(parts[2], CultureInfo.InvariantCulture),
                    int.Parse(parts[3], CultureInfo.InvariantCulture));
            }
        }
#else
        public class {${_paramPrefix}}Item{${_paramPostfix}}RefConverter : JsonConverter
        {
            public override bool CanConvert(Type objectType) =>
                objectType.IsGenericType && objectType.GetGenericTypeDefinition() == typeof({${_paramPrefix}}Item{${_paramPostfix}}Ref<>);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
            {
                var elementType = objectType.GetGenericArguments()[0];
                if (reader.TokenType == JsonToken.String)
                {
                    var id = (string)reader.Value;
                    return Activator.CreateInstance(typeof({${_paramPrefix}}Item{${_paramPostfix}}Ref<>).MakeGenericType(elementType), id, id != null);
                }
                if (reader.TokenType == JsonToken.StartObject)
                {
                    var value = serializer.Deserialize(reader, elementType);
                    return Activator.CreateInstance(typeof({${_paramPrefix}}Item{${_paramPostfix}}Ref<>).MakeGenericType(elementType), value);
                }
                return Activator.CreateInstance(typeof({${_paramPrefix}}Item{${_paramPostfix}}Ref<>).MakeGenericType(elementType), default(string), false);
            }

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                var type = value.GetType();
                var valueProp = type.GetProperty("Value");
                var val = valueProp.GetValue(value);
                serializer.Serialize(writer, val);
            }
        }

        public class BoolConverter : JsonConverter
        {
            public override bool CanConvert(Type objectType) => objectType == typeof(bool);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
            {
                if (reader.TokenType == JsonToken.Integer)
                    return Convert.ToInt32(reader.Value) == 1;
                if (reader.TokenType == JsonToken.Boolean)
                    return (bool)reader.Value;
                return Convert.ToString(reader.Value) == "1";
            }

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer) =>
                writer.WriteValue((bool)value ? 1 : 0);
        }

        public class DateTimeConverter : JsonConverter
        {
            public override bool CanConvert(Type objectType) => objectType == typeof(DateTime);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
            {
                if (reader.TokenType == JsonToken.Integer || reader.TokenType == JsonToken.Float)
                    return DateTimeOffset.FromUnixTimeMilliseconds(Convert.ToInt64(reader.Value)).UtcDateTime;
                var date = Convert.ToString(reader.Value);
                if (string.IsNullOrEmpty(date) || !long.TryParse(date, out var ms))
                    return default(DateTime);
                return DateTimeOffset.FromUnixTimeMilliseconds(ms).UtcDateTime;
            }

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer) =>
                writer.WriteValue(new DateTimeOffset((DateTime)value).ToUnixTimeMilliseconds());
        }

        public class TimeSpanConverter : JsonConverter
        {
            public override bool CanConvert(Type objectType) => objectType == typeof(TimeSpan);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
            {
                if (reader.TokenType == JsonToken.Integer || reader.TokenType == JsonToken.Float)
                    return TimeSpan.FromMilliseconds(Convert.ToInt64(reader.Value));
                var duration = Convert.ToString(reader.Value);
                if (string.IsNullOrEmpty(duration) || !long.TryParse(duration, out var ms))
                    return default(TimeSpan);
                return TimeSpan.FromMilliseconds(ms);
            }

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer) =>
                writer.WriteValue((long)((TimeSpan)value).TotalMilliseconds);
        }

        public class ColorConverter : JsonConverter
        {
            public override bool CanConvert(Type objectType) => objectType == typeof(Color);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
            {
                var argb = Convert.ToInt64(reader.Value);
                return ArgbToColor(argb);
            }

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer) =>
                writer.WriteValue(ColorToArgb((Color)value));

            private static Color ArgbToColor(long argb)
            {
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

            private static long ColorToArgb(Color color)
            {
#if UNITY_5_3_OR_NEWER || GODOT4_0_OR_GREATER
                return (long)((int)(color.a * 255) << 24 | (int)(color.r * 255) << 16 | (int)(color.g * 255) << 8 | (int)(color.b * 255));
#else
                return (long)((int)color.A << 24 | (int)color.R << 16 | (int)color.G << 8 | (int)color.B);
#endif
            }
        }

        public class Vector2Converter : JsonConverter
        {
            public override bool CanConvert(Type objectType) => objectType == typeof(Vector2);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer) =>
                ParseVector2(Convert.ToString(reader.Value));

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                var v = (Vector2)value;
                writer.WriteValue(\$"{v.x};{v.y}");
            }

            private static Vector2 ParseVector2(string value)
            {
                if (string.IsNullOrEmpty(value))
                    return default;
                var parts = value.Split(';');
                if (parts.Length < 2) return default;
                return new Vector2(
                    float.Parse(parts[0], CultureInfo.InvariantCulture),
                    float.Parse(parts[1], CultureInfo.InvariantCulture));
            }
        }

        public class Vector2IntConverter : JsonConverter
        {
            public override bool CanConvert(Type objectType) => objectType == typeof(Vector2Int);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer) =>
                ParseVector2Int(Convert.ToString(reader.Value));

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                var v = (Vector2Int)value;
                writer.WriteValue(\$"{v.x};{v.y}");
            }

            private static Vector2Int ParseVector2Int(string value)
            {
                if (string.IsNullOrEmpty(value))
                    return default;
                var parts = value.Split(';');
                if (parts.Length < 2) return default;
                return new Vector2Int(
                    int.Parse(parts[0], CultureInfo.InvariantCulture),
                    int.Parse(parts[1], CultureInfo.InvariantCulture));
            }
        }

        public class Vector3Converter : JsonConverter
        {
            public override bool CanConvert(Type objectType) => objectType == typeof(Vector3);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer) =>
                ParseVector3(Convert.ToString(reader.Value));

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                var v = (Vector3)value;
                writer.WriteValue(\$"{v.x};{v.y};{v.z}");
            }

            private static Vector3 ParseVector3(string value)
            {
                if (string.IsNullOrEmpty(value))
                    return default;
                var parts = value.Split(';');
                if (parts.Length < 3) return default;
                return new Vector3(
                    float.Parse(parts[0], CultureInfo.InvariantCulture),
                    float.Parse(parts[1], CultureInfo.InvariantCulture),
                    float.Parse(parts[2], CultureInfo.InvariantCulture));
            }
        }

        public class Vector3IntConverter : JsonConverter
        {
            public override bool CanConvert(Type objectType) => objectType == typeof(Vector3Int);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer) =>
                ParseVector3Int(Convert.ToString(reader.Value));

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                var v = (Vector3Int)value;
                writer.WriteValue(\$"{v.x};{v.y};{v.z}");
            }

            private static Vector3Int ParseVector3Int(string value)
            {
                if (string.IsNullOrEmpty(value))
                    return default;
                var parts = value.Split(';');
                if (parts.Length < 3) return default;
                return new Vector3Int(
                    int.Parse(parts[0], CultureInfo.InvariantCulture),
                    int.Parse(parts[1], CultureInfo.InvariantCulture),
                    int.Parse(parts[2], CultureInfo.InvariantCulture));
            }
        }

        public class Vector4Converter : JsonConverter
        {
            public override bool CanConvert(Type objectType) => objectType == typeof(Vector4);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer) =>
                ParseVector4(Convert.ToString(reader.Value));

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                var v = (Vector4)value;
                writer.WriteValue(\$"{v.x};{v.y};{v.z};{v.w}");
            }

            private static Vector4 ParseVector4(string value)
            {
                if (string.IsNullOrEmpty(value))
                    return default;
                var parts = value.Split(';');
                if (parts.Length < 4) return default;
                return new Vector4(
                    float.Parse(parts[0], CultureInfo.InvariantCulture),
                    float.Parse(parts[1], CultureInfo.InvariantCulture),
                    float.Parse(parts[2], CultureInfo.InvariantCulture),
                    float.Parse(parts[3], CultureInfo.InvariantCulture));
            }
        }

        public class Vector4IntConverter : JsonConverter
        {
            public override bool CanConvert(Type objectType) => objectType == typeof(Vector4Int);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer) =>
                ParseVector4Int(Convert.ToString(reader.Value));

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                var v = (Vector4Int)value;
                writer.WriteValue(\$"{v.X};{v.Y};{v.Z};{v.W}");
            }

            private static Vector4Int ParseVector4Int(string value)
            {
                if (string.IsNullOrEmpty(value))
                    return default;
                var parts = value.Split(';');
                if (parts.Length < 4) return default;
                return new Vector4Int(
                    int.Parse(parts[0], CultureInfo.InvariantCulture),
                    int.Parse(parts[1], CultureInfo.InvariantCulture),
                    int.Parse(parts[2], CultureInfo.InvariantCulture),
                    int.Parse(parts[3], CultureInfo.InvariantCulture));
            }
        }

        public class RectangleConverter : JsonConverter
        {
            public override bool CanConvert(Type objectType) => objectType == typeof(Rectangle);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer) =>
                ParseRectangle(Convert.ToString(reader.Value));

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                var v = (Rectangle)value;
                writer.WriteValue(\$"{v.x};{v.y};{v.width};{v.height}");
            }

            private static Rectangle ParseRectangle(string value)
            {
                if (string.IsNullOrEmpty(value))
                    return default;
                var parts = value.Split(';');
                if (parts.Length < 4) return default;
                return new Rectangle(
                    float.Parse(parts[0], CultureInfo.InvariantCulture),
                    float.Parse(parts[1], CultureInfo.InvariantCulture),
                    float.Parse(parts[2], CultureInfo.InvariantCulture),
                    float.Parse(parts[3], CultureInfo.InvariantCulture));
            }
        }

        public class RectangleIntConverter : JsonConverter
        {
            public override bool CanConvert(Type objectType) => objectType == typeof(RectangleInt);

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer) =>
                ParseRectangleInt(Convert.ToString(reader.Value));

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                var v = (RectangleInt)value;
                writer.WriteValue(\$"{v.x};{v.y};{v.width};{v.height}");
            }

            private static RectangleInt ParseRectangleInt(string value)
            {
                if (string.IsNullOrEmpty(value))
                    return default;
                var parts = value.Split(';');
                if (parts.Length < 4) return default;
                return new RectangleInt(
                    int.Parse(parts[0], CultureInfo.InvariantCulture),
                    int.Parse(parts[1], CultureInfo.InvariantCulture),
                    int.Parse(parts[2], CultureInfo.InvariantCulture),
                    int.Parse(parts[3], CultureInfo.InvariantCulture));
            }
        }

        public class {${_paramPrefix}}Item{${_paramPostfix}}RefTypeConverter<T> : TypeConverter where T : IIdentifiable
        {
            public override bool CanConvertFrom(ITypeDescriptorContext context, Type sourceType)
                => sourceType == typeof(string);

            public override object ConvertFrom(ITypeDescriptorContext context, CultureInfo culture, object value)
            {
                if (value is string stringValue)
                    return new {${_paramPrefix}}Item{${_paramPostfix}}Ref<T>(stringValue, false);
                return base.ConvertFrom(context, culture, value);
            }
        }
#endif
#endregion

#if UNITY_5_3_OR_NEWER
        static {${_paramPrefix}}Root{${_paramPostfix}}Parser()
        {
{${_paramTypeConverterRegistrations}}
        }
#endif
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

    internal static class {${_paramPrefix}}Item{${_paramPostfix}}RefCache
    {
        [ThreadStatic]
        internal static Dictionary<string, IIdentifiable> Items;
    }

#if !UNITY_5_3_OR_NEWER
    [JsonConverter(typeof({${_paramPrefix}}Root{${_paramPostfix}}Parser.{${_paramPrefix}}Item{${_paramPostfix}}RefConverterFactory))]
#else
    [JsonConverter(typeof({${_paramPrefix}}Root{${_paramPostfix}}Parser.{${_paramPrefix}}Item{${_paramPostfix}}RefConverter))]
#endif
    public struct {${_paramPrefix}}Item{${_paramPostfix}}Ref<T> : IEquatable<{${_paramPrefix}}Item{${_paramPostfix}}Ref<T>>, IIdentifiable
    {
        public string Id { get; }
        public bool IsGlobal { get; }
        private bool _valueSet;
        private T _value;

        public T Value
        {
            get
            {
                if (!_valueSet && {${_paramPrefix}}Item{${_paramPostfix}}RefCache.Items != null && Id != null)
                    Value = (T){${_paramPrefix}}Item{${_paramPostfix}}RefCache.Items[Id];
                return _value;
            }
            set
            {
                _valueSet = true;
                _value = value;
            }
        }

        public {${_paramPrefix}}Item{${_paramPostfix}}Ref(string id, bool isGlobal)
        {
            Id = id;
            IsGlobal = isGlobal;
            _valueSet = false;
            _value = default;
        }

        public {${_paramPrefix}}Item{${_paramPostfix}}Ref(T value)
        {
            Id = default;
            IsGlobal = false;
            _valueSet = true;
            _value = value;
        }

        public bool Equals({${_paramPrefix}}Item{${_paramPostfix}}Ref<T> other)
        {
            return Id == other.Id;
        }

        public override bool Equals(object obj)
        {
            return obj is {${_paramPrefix}}Item{${_paramPostfix}}Ref<T> other && Equals(other);
        }

        public override int GetHashCode()
        {
            return Id.GetHashCode();
        }

        public static bool operator ==({${_paramPrefix}}Item{${_paramPostfix}}Ref<T> a, {${_paramPrefix}}Item{${_paramPostfix}}Ref<T> b)
        {
            return a.Equals(b);
        }

        public static bool operator !=({${_paramPrefix}}Item{${_paramPostfix}}Ref<T> a, {${_paramPrefix}}Item{${_paramPostfix}}Ref<T> b)
        {
            return !(a == b);
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
