import 'dart:collection';

import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/class_meta_group.dart';
import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db/table_meta_group.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';

class DbModelCache {
  DbModel model;
  DbModelCache(this.model);

  bool _initialized = false;

  Map<String, ClassMeta>? _classesById;
  Map<String, TableMeta>? _tablesById;
  Map<String, DataTableRowData>? _tableRowsById;
  Map<String, TableMetaEntity>? _tableByRowId;
  Map<String, Map<ClassMetaEntity, ClassMetaFieldDescription>>? _fieldById;
  Map<ClassMetaFieldDescription, ClassMetaEntity>? _classByField;
  Map<ClassMeta, ClassMetaGroup?>? _classParents;
  Map<TableMeta, TableMetaGroup?>? _tableParents;
  List<TableMeta>? _allTablesMetas;
  List<ClassMeta>? _allClassesMetas;
  List<TableMetaEntity>? _allDataTables;
  List<ClassMetaEntity>? _allClasses;
  List<ClassMetaEntityEnum>? _allEnums;

  Map<ClassMetaEntity, List<ClassMetaFieldDescription>>? _inheritedFields;
  Map<ClassMetaEntity, List<ClassMetaFieldDescription>>? _allFields;
  Map<ClassMetaEntity, List<ClassMetaEntity>>? _parentClasses;
  Map<ClassMetaEntity, List<ClassMetaEntity>>? _subClasses;

  Map<ClassMeta, List<IIdentifiable>>? _availableReferenceValues;
  Map<ClassMetaFieldDescription, DataTableCellValue>? _defaultValues;
  Map<ClassMetaEntity, bool>? _hasBigCells;

  void invalidate() {
    _initialized = false;

    _classesById = null;
    _tablesById = null;
    _tableRowsById = null;
    _tableByRowId = null;
    _fieldById = null;
    _classByField = null;
    _classParents = null;
    _tableParents = null;
    _allTablesMetas = null;
    _allClassesMetas = null;
    _allDataTables = null;
    _allClasses = null;
    _allEnums = null;
    _inheritedFields = null;
    _allFields = null;
    _parentClasses = null;
    _subClasses = null;
    _availableReferenceValues = null;
    _defaultValues = null;
    _hasBigCells = null;
  }

  T? getEntity<T extends IIdentifiable>(String id) {
    validateIfRequired();
    return (_classesById![id] ?? _tablesById![id]) as T?;
  }

  T? getClass<T extends ClassMeta>(String? id) {
    if (id == null) return null;
    validateIfRequired();
    if (_classesById![id] is! T?) //
      return null;
    return _classesById![id] as T?;
  }

  T? getTable<T extends TableMeta>(String? id) {
    if (id == null) return null;
    validateIfRequired();
    if (_tablesById![id] is! T?) //
      return null;
    return _tablesById![id] as T?;
  }

  DataTableRowData? getTableRow(String? id) {
    if (id == null) return null;
    validateIfRequired();
    return _tableRowsById![id];
  }

  TableMetaEntity? getTableByRowId(String? id) {
    if (id == null) return null;
    validateIfRequired();
    return _tableByRowId![id];
  }

  ClassMetaFieldDescription? getField(String id, ClassMetaEntity? entity) {
    validateIfRequired();
    return _fieldById![id]?[entity];
  }

  ClassMetaEntity? getFieldOwner(ClassMetaFieldDescription field) {
    validateIfRequired();
    return _classByField![field];
  }

  void validateIfRequired() {
    if (_initialized) //
      return;

    _initialized = true;

    _buildCacheClassMeta();
    _buildCacheTableMeta();
    _buildCacheFields();
    _buildAvailableReferenceValues();
    _buildDefaultValues();
  }

  List<ClassMeta> _buildCacheClassMeta() {
    _classesById = {};
    _allClassesMetas = [];
    _classParents = {};
    _allClasses = [];
    _allEnums = [];

    final result = <ClassMeta>[];
    for (var classMeta in model.classes) {
      _addClassMeta(classMeta);
      _classParents![classMeta] = null;
    }
    return result;
  }

  void _addClassMeta(ClassMeta classMeta) {
    _classesById![classMeta.id] = classMeta;
    _allClassesMetas!.add(classMeta);

    if (classMeta is ClassMetaGroup) {
      final group = classMeta;
      for (var classMeta in group.entries) {
        _addClassMeta(classMeta);
        _classParents![classMeta] = group;
      }
    } else if (classMeta is ClassMetaEntity) {
      _allClasses!.add(classMeta);
    } else if (classMeta is ClassMetaEntityEnum) {
      _allEnums!.add(classMeta);
    }
  }

  void _buildCacheTableMeta() {
    _tablesById = {};
    _tableParents = {};
    _allTablesMetas = [];
    _allDataTables = [];
    _tableRowsById = {};
    _tableByRowId = {};

    for (var tableMeta in model.tables) {
      _addTableMeta(tableMeta);
      _tableParents![tableMeta] = null;
    }
  }

  void _addTableMeta(TableMeta tableMeta) {
    _tablesById![tableMeta.id] = tableMeta;
    _allTablesMetas!.add(tableMeta);

    if (tableMeta is TableMetaGroup) {
      final group = tableMeta;
      for (var tableMeta in group.entries) {
        _addTableMeta(tableMeta);
        _tableParents![tableMeta] = group;
      }
    } else if (tableMeta is TableMetaEntity) {
      _allDataTables!.add(tableMeta);

      for (var i = 0; i < tableMeta.rows.length; i++) {
        final row = tableMeta.rows[i];
        _tableRowsById![row.id] = DataTableRowData(tableMeta, i, row);
        _tableByRowId![row.id] = tableMeta;
      }
    }
  }

  ClassMetaGroup? getParentClass(ClassMeta classMeta) {
    validateIfRequired();
    return _classParents![classMeta];
  }

  TableMetaGroup? getParentTable(TableMeta tableMeta) {
    validateIfRequired();
    return _tableParents![tableMeta];
  }

  IMetaGroup<T1>? getParent<T1 extends IIdentifiable, T2 extends T1>(T2 entity) {
    validateIfRequired();
    if (entity is ClassMeta) {
      return getParentClass(entity as ClassMeta) as IMetaGroup<T1>?;
    }
    if (entity is TableMeta) {
      return getParentTable(entity as TableMeta) as IMetaGroup<T1>?;
    }
    return null;
  }

  List<IMetaGroup> getParents(IIdentifiable entity) {
    final result = <IMetaGroup>[];
    var parent = getParent(entity);
    while (parent != null) {
      result.add(parent);
      parent = getParent(parent as IIdentifiable);
    }
    return result;
  }

  int? getClassIndex(ClassMeta classMeta) {
    validateIfRequired();
    final parent = _classParents![classMeta];
    if (parent == null)
      return model.classes.indexOf(classMeta);
    else
      return parent.entries.indexOf(classMeta);
  }

  int? getTableIndex(TableMeta tableMeta) {
    validateIfRequired();
    final parent = _tableParents![tableMeta];
    if (parent == null)
      return model.tables.indexOf(tableMeta);
    else
      return parent.entries.indexOf(tableMeta);
  }

  int? getIndex<T extends IIdentifiable>(T entity) {
    validateIfRequired();
    if (entity is ClassMeta) {
      return getClassIndex(entity);
    }
    if (entity is TableMeta) {
      return getTableIndex(entity);
    }
    return null;
  }

  List<ClassMetaEntity> get allClasses {
    validateIfRequired();
    return _allClasses!;
  }

  List<TableMetaEntity> get allDataTables {
    validateIfRequired();
    return _allDataTables!;
  }

  List<TableMeta> get allTablesMetas {
    validateIfRequired();
    return _allTablesMetas!;
  }

  List<ClassMeta> get allClassesMetas {
    validateIfRequired();
    return _allClassesMetas!;
  }

  List<ClassMetaEntityEnum> get allEnums {
    validateIfRequired();
    return _allEnums!;
  }

  void _buildCacheFields() {
    _inheritedFields = {};
    _allFields = {};
    _parentClasses = {};
    _subClasses = {};
    _fieldById = {};
    _classByField = {};
    _hasBigCells = {};

    final subclassesOneLevel = <ClassMetaEntity, Set<ClassMetaEntity>>{};

    for (final entity in _allClasses!) {
      final inheritedFields = <ClassMetaFieldDescription>[];
      var allFields = <ClassMetaFieldDescription>[];

      final parentClasses = _getParentClasses(entity).toList();
      final parents = parentClasses.reversed.toList();
      _parentClasses![entity] = parents;

      for (final parent in parents) {
        inheritedFields.addAll(parent.fields);
      }

      if (parents.isNotEmpty) {
        final parent = parents[0];

        if (subclassesOneLevel[parent] == null) //
          subclassesOneLevel[parent] = {};
        subclassesOneLevel[parent]!.add(entity);
      }

      allFields = inheritedFields.toList();
      allFields.addAll(entity.fields);

      for (final field in allFields) {
        if (_fieldById![field.id] == null) //
          _fieldById![field.id] = <ClassMetaEntity, ClassMetaFieldDescription>{};
        _fieldById![field.id]![entity] = field;
      }

      _inheritedFields![entity] = inheritedFields;
      _allFields![entity] = allFields;

      _hasBigCells![entity] = allFields.any((e) => !e.typeInfo.type.isSimple());
    }

    for (final entity in _allClasses!) {
      _subClasses![entity] = [];

      for (final field in entity.fields) {
        _classByField![field] = entity;
      }

      final queue = Queue<ClassMetaEntity>();
      queue.add(entity);
      while (queue.isNotEmpty) {
        final currentElement = queue.removeFirst();
        if (entity != currentElement) //
          _subClasses![entity]!.add(currentElement);

        if (subclassesOneLevel[currentElement] != null) //
          queue.addAll(subclassesOneLevel[currentElement]!);
      }
    }
  }

  void _buildAvailableReferenceValues() {
    _availableReferenceValues = {};

    for (final table in _allDataTables!) {
      final tableClass = table.classId.isEmpty ? null : _classesById![table.classId];
      if (tableClass == null) //
        continue;

      final thisClassAndParents = [tableClass, ...getParentClasses(tableClass)];
      for (final classEntity in thisClassAndParents) {
        if (_availableReferenceValues![classEntity] == null) //
          _availableReferenceValues![classEntity] = <IIdentifiable>[];

        for (final row in table.rows) //
          _availableReferenceValues![classEntity]!.add(row);
      }
    }

    for (final classEnum in _allEnums!) {
      if (_availableReferenceValues![classEnum.id] == null) //
        _availableReferenceValues![classEnum] = <IIdentifiable>[];

      for (final enumValue in classEnum.values) {
        _availableReferenceValues![classEnum]!.add(enumValue);
      }
    }
  }

  void _buildDefaultValues() {
    _defaultValues = {};
    for (final classEntity in _allClasses!.whereType<ClassMetaEntity>()) {
      for (final field in classEntity.fields) {
        _defaultValues![field] = DbModelUtils.parseDefaultValueByFieldOrDefault(field, field.defaultValue);
      }
    }
  }

  List<ClassMetaFieldDescription> getInheritedFields(ClassMetaEntity entity) {
    validateIfRequired();
    return _inheritedFields![entity]!;
  }

  List<ClassMetaFieldDescription> getAllFields(ClassMetaEntity entity) {
    validateIfRequired();
    return _allFields![entity]!;
  }

  List<ClassMetaFieldDescription>? getAllFieldsById(String id) {
    if (id.isEmpty) //
      return null;
    validateIfRequired();
    final classEntity = getClass<ClassMetaEntity>(id)!;
    return _allFields![classEntity]!;
  }

  List<ClassMetaEntity> getParentClasses(IIdentifiable entity) {
    validateIfRequired();
    return _parentClasses![entity]!;
  }

  List<ClassMetaEntity> getSubClasses(IIdentifiable entity) {
    validateIfRequired();
    return _subClasses![entity]!;
  }

  List<IIdentifiable>? getAvailableValues(ClassMeta? classEntity) {
    if (classEntity == null) //
      return null;
    validateIfRequired();
    return _availableReferenceValues![classEntity] ?? [];
  }

  List<ClassMetaEntity> _getParentClasses(ClassMetaEntity entity) {
    final result = <ClassMetaEntity>[];
    ClassMetaEntity? parent = entity;
    while (true) {
      parent = parent!.parent == null ? null : (_classesById![parent.parent!] as ClassMetaEntity);
      if (parent == null) //
        break;
      result.add(parent);
    }
    return result;
  }

  DataTableCellValue getDefaultValue(ClassMetaFieldDescription field) {
    validateIfRequired();
    return _defaultValues![field]!.copy(); // JsonMapper can't serialize a single object multiple times
  }

  bool hasBigCells(ClassMetaEntity? classEntity) {
    if (classEntity == null) //
      return false;

    validateIfRequired();
    return _hasBigCells![classEntity] ?? false;
  }
}

class DataTableRowData {
  final TableMetaEntity table;
  final int index;
  final DataTableRow row;

  DataTableRowData(
    this.table,
    this.index,
    this.row,
  );
}
