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
  Map<ClassMetaEntity, List<ClassMetaEntity>>? _parentInterfaces;
  Map<ClassMetaEntity, List<ClassMetaEntity>>? _subInterfaces;

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
    _parentInterfaces = null;
    _subInterfaces = null;
    _availableReferenceValues = null;
    _defaultValues = null;
    _hasBigCells = null;
  }

  T? getEntity<T extends IIdentifiable>(String id) {
    _validateIfRequired();
    return (_classesById![id] ?? _tablesById![id]) as T?;
  }

  T? getClass<T extends ClassMeta>(String? id) {
    if (id == null) return null;
    _validateIfRequired();
    if (_classesById![id] is! T?) //
      return null;
    return _classesById![id] as T?;
  }

  T? getTable<T extends TableMeta>(String? id) {
    if (id == null) return null;
    _validateIfRequired();
    if (_tablesById![id] is! T?) //
      return null;
    return _tablesById![id] as T?;
  }

  DataTableRowData? getTableRow(String? id) {
    if (id == null) return null;
    _validateIfRequired();
    return _tableRowsById![id];
  }

  TableMetaEntity? getTableByRowId(String? id) {
    if (id == null) return null;
    _validateIfRequired();
    return _tableByRowId![id];
  }

  ClassMetaFieldDescription? getField(String id, ClassMetaEntity? entity) {
    _validateIfRequired();
    return _fieldById![id]?[entity];
  }

  ClassMetaEntity? getFieldOwner(ClassMetaFieldDescription field) {
    _validateIfRequired();
    return _classByField![field];
  }

  void _validateIfRequired() {
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
    _validateIfRequired();
    return _classParents![classMeta];
  }

  TableMetaGroup? getParentTable(TableMeta tableMeta) {
    _validateIfRequired();
    return _tableParents![tableMeta];
  }

  IMetaGroup<T1>? getParent<T1 extends IIdentifiable, T2 extends T1>(T2 entity) {
    _validateIfRequired();
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
    _validateIfRequired();
    final parent = _classParents![classMeta];
    if (parent == null)
      return model.classes.indexOf(classMeta);
    else
      return parent.entries.indexOf(classMeta);
  }

  int? getTableIndex(TableMeta tableMeta) {
    _validateIfRequired();
    final parent = _tableParents![tableMeta];
    if (parent == null)
      return model.tables.indexOf(tableMeta);
    else
      return parent.entries.indexOf(tableMeta);
  }

  int? getIndex<T extends IIdentifiable>(T entity) {
    _validateIfRequired();
    if (entity is ClassMeta) {
      return getClassIndex(entity);
    }
    if (entity is TableMeta) {
      return getTableIndex(entity);
    }
    return null;
  }

  List<ClassMetaEntity> get allClasses {
    _validateIfRequired();
    return _allClasses!;
  }

  List<TableMetaEntity> get allDataTables {
    _validateIfRequired();
    return _allDataTables!;
  }

  List<TableMeta> get allTablesMetas {
    _validateIfRequired();
    return _allTablesMetas!;
  }

  List<ClassMeta> get allClassesMetas {
    _validateIfRequired();
    return _allClassesMetas!;
  }

  List<ClassMetaEntityEnum> get allEnums {
    _validateIfRequired();
    return _allEnums!;
  }

  void _buildCacheFields() {
    _inheritedFields = {};
    _allFields = {};
    _parentClasses = {};
    _subClasses = {};
    _parentInterfaces = {};
    _subInterfaces = {};
    _fieldById = {};
    _classByField = {};
    _hasBigCells = {};

    final subClassesOneLevel = <ClassMetaEntity, Set<ClassMetaEntity>>{};
    final subInterfacesOneLevel = <ClassMetaEntity, Set<ClassMetaEntity>>{};

    for (final entity in _allClasses!) {
      _getOrBuildAllFields(entity);
    }

    for (final entity in _allClasses!) {
      final parents = _parentClasses![entity]!;

      if (parents.isNotEmpty) {
        final parent = parents[0];

        if (subClassesOneLevel[parent] == null) //
          subClassesOneLevel[parent] = {};
        subClassesOneLevel[parent]!.add(entity);
      }

      for (var interfaceId in entity.interfaces) {
        if (interfaceId == null) //
          continue;

        final parentInterface = getClass<ClassMetaEntity>(interfaceId)!;

        if (subInterfacesOneLevel[parentInterface] == null) //
          subInterfacesOneLevel[parentInterface] = {};
        subInterfacesOneLevel[parentInterface]!.add(entity);
      }
    }

    for (final entity in _allClasses!) {
      _subClasses![entity] = [];
      _subInterfaces![entity] = [];

      final queue = Queue<ClassMetaEntity>();
      queue.add(entity);
      while (queue.isNotEmpty) {
        final currentElement = queue.removeFirst();
        if (entity != currentElement) //
          _subClasses![entity]!.add(currentElement);

        if (subClassesOneLevel[currentElement] != null) //
          queue.addAll(subClassesOneLevel[currentElement]!);
      }

      queue.add(entity);
      while (queue.isNotEmpty) {
        final currentElement = queue.removeFirst();
        if (entity != currentElement) //
          _subInterfaces![entity]!.add(currentElement);

        if (subInterfacesOneLevel[currentElement] != null) //
          queue.addAll(subInterfacesOneLevel[currentElement]!);
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
    _validateIfRequired();
    return _inheritedFields![entity]!;
  }

  List<ClassMetaFieldDescription> getAllFields(ClassMetaEntity entity) {
    _validateIfRequired();
    return _allFields![entity]!;
  }

  List<ClassMetaFieldDescription>? getAllFieldsById(String id) {
    if (id.isEmpty) //
      return null;
    _validateIfRequired();
    final classEntity = getClass<ClassMetaEntity>(id)!;
    return _allFields![classEntity]!;
  }

  List<ClassMetaEntity> getParentClasses(IIdentifiable entity) {
    _validateIfRequired();
    return _parentClasses![entity]!;
  }

  List<ClassMetaEntity> getSubClasses(IIdentifiable entity) {
    _validateIfRequired();
    return _subClasses![entity]!;
  }

  List<ClassMetaEntity> getParentInterfaces(IIdentifiable entity) {
    _validateIfRequired();
    return _parentInterfaces![entity]!;
  }

  final List<ClassMetaEntity> _emptySubInterfaces = [];
  List<ClassMetaEntity> getSubInterfaces(IIdentifiable entity) {
    _validateIfRequired();
    return _subInterfaces![entity] ?? _emptySubInterfaces;
  }

  List<IIdentifiable>? getAvailableValues(ClassMeta? classEntity) {
    if (classEntity == null) //
      return null;
    _validateIfRequired();
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

  List<ClassMetaEntity> _getParentInterfaces(ClassMetaEntity entity,
      [List<ClassMetaEntity>? accumulatedResult, Set<ClassMetaEntity>? accumulatedResultHashMap]) {
    accumulatedResult ??= <ClassMetaEntity>[];
    accumulatedResultHashMap ??= <ClassMetaEntity>{};

    for (var i = 0; i < entity.interfaces.length; i++) {
      if (entity.interfaces[i] == null) //
        continue;

      final parent = _classesById![entity.interfaces[i]] as ClassMetaEntity;

      if (accumulatedResultHashMap.contains(parent)) //
        continue;

      accumulatedResultHashMap.add(parent);
      accumulatedResult.add(parent);

      _getParentInterfaces(
        parent,
        accumulatedResult,
        accumulatedResultHashMap,
      );
    }

    return accumulatedResult;
  }

  DataTableCellValue getDefaultValue(ClassMetaFieldDescription field) {
    _validateIfRequired();
    return _defaultValues![field]!.copy(); // JsonMapper can't serialize a single object multiple times
  }

  bool hasBigCells(ClassMetaEntity? classEntity) {
    if (classEntity == null) //
      return false;

    _validateIfRequired();
    return _hasBigCells![classEntity] ?? false;
  }

  List<ClassMetaFieldDescription> _getOrBuildAllFields(ClassMetaEntity entity) {
    if (!_parentInterfaces!.containsKey(entity)) {
      _parentInterfaces![entity] = _getParentInterfaces(entity);
    }

    if (!_parentClasses!.containsKey(entity)) {
      _parentClasses![entity] = _getParentClasses(entity).reversed.toList();
    }

    if (!_allFields!.containsKey(entity)) {
      final inheritedFields = <ClassMetaFieldDescription>[];
      final allFields = <ClassMetaFieldDescription>[];

      final parent = getClass<ClassMetaEntity>(entity.parent);
      if (parent != null) {
        inheritedFields.addAll(_getOrBuildAllFields(parent));
      }

      final interfaces = entity.interfaces //
          .where((e) => e != null)
          .map((e) => getClass<ClassMetaEntity>(e)!)
          .toList();

      for (final interface in interfaces) {
        inheritedFields.addAll(_getOrBuildAllFields(interface));
      }

      allFields.addAll(inheritedFields);
      allFields.addAll(entity.fields);

      _allFields![entity] = allFields;
      _inheritedFields![entity] = inheritedFields;

      for (final field in allFields) {
        if (_fieldById![field.id] == null) //
          _fieldById![field.id] = <ClassMetaEntity, ClassMetaFieldDescription>{};
        _fieldById![field.id]![entity] = field;
      }

      for (final field in entity.fields) {
        _classByField![field] = entity;
      }

      _hasBigCells![entity] = allFields.any((e) => !e.typeInfo.type.isSimple());
    }
    return _allFields![entity]!;
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
