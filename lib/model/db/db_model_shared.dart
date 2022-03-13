import 'package:flutter/foundation.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_group.dart';
import 'package:gceditor/model/db/generator_csharp.dart';
import 'package:gceditor/model/db/generator_json.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db/table_meta_group.dart';
import 'package:json_annotation/json_annotation.dart';

abstract class IIdentifiable {
  String id = '';
}

abstract class IDescribable {
  String description = '';
}

abstract class BaseGenerator {
  GeneratorType? $type;
  String fileName = '';
  String fileExtension = '';

  Map<String, dynamic> toJson();

  static List<dynamic>? encodeGenerators(List<BaseGenerator>? elements) {
    if (elements == null) return null;
    return elements.map((e) => encode(e)).toList();
  }

  static List<BaseGenerator>? decodeGenerators(List<dynamic>? elements) {
    if (elements == null) return null;
    return elements.map((e) => decode(e)).toList();
  }

  static Map<String, dynamic> encode(BaseGenerator element) {
    return element.toJson();
  }

  static BaseGenerator decode(dynamic element) {
    final type = element['\$type'];
    if (type == describeEnum(GeneratorType.json)) {
      return GeneratorJson.fromJson(element);
    } else if (type == describeEnum(GeneratorType.csharp)) {
      return GeneratorCsharp.fromJson(element);
    } else {
      throw Exception('Unsupported generator type $type');
    }
  }
}

abstract class IMetaGroup<T extends IIdentifiable> {
  List<T> entries = <T>[];
  bool canStore(IIdentifiable? obj);
}

mixin MetaGroup<T> {
  bool canStore(IIdentifiable? obj) {
    // ignore: unrelated_type_equality_checks
    return obj != null && obj != this && obj is T;
  }
}

abstract class ClassMeta implements IIdentifiable, IDescribable {
  ClassMetaType? $type;
  @override
  String id = '';
  @override
  String description = '';

  Map<String, dynamic> toJson();

  static List<dynamic> encodeEntries(List<ClassMeta> elements) {
    return elements.map((e) => encode(e)).cast<dynamic>().toList();
  }

  static List<ClassMeta> decodeEntries(List<dynamic> elements) {
    return elements.map((e) => decode(e)).toList();
  }

  static Map<String, dynamic> encode(ClassMeta element) {
    return element.toJson();
  }

  static ClassMeta decode(Map<String, dynamic> element) {
    final type = element['\$type'];
    if (type == describeEnum(ClassMetaType.$group)) {
      return ClassMetaGroup.fromJson(element);
    } else if (type == describeEnum(ClassMetaType.$class)) {
      return ClassMetaEntity.fromJson(element);
    } else if (type == describeEnum(ClassMetaType.$enum)) {
      return ClassMetaEntityEnum.fromJson(element);
    } else {
      throw Exception('Unsupported class meta type $type');
    }
  }
}

abstract class TableMeta implements IIdentifiable, IDescribable {
  TableMetaType? $type;
  @override
  String id = '';
  @override
  String description = '';

  Map<String, dynamic> toJson();

  static List<dynamic> encodeEntries(List<TableMeta> elements) {
    return elements.map((e) => e.toJson()).cast<dynamic>().toList();
  }

  static List<TableMeta> decodeEntries(List<dynamic> elements) {
    return elements.map((e) => decode(e)).toList();
  }

  static Map<String, dynamic> encode(TableMeta element) {
    return element.toJson();
  }

  static TableMeta decode(Map<String, dynamic> element) {
    final type = element['\$type'];
    if (type == describeEnum(TableMetaType.$group)) {
      return TableMetaGroup.fromJson(element);
    } else if (type == describeEnum(TableMetaType.$table)) {
      return TableMetaEntity.fromJson(element);
    } else {
      throw Exception('Unsupported table meta type "$type"');
    }
  }
}

@JsonEnum()
enum ClassFieldType {
  undefined,
  bool,
  int,
  long,
  float,
  double,
  string,
  text,
  reference,
  list,
  set,
  dictionary,
  date,
  duration,
  color,
}

@JsonEnum()
enum ClassMetaType {
  undefined,
  $group,
  $class,
  $enum,
}

@JsonEnum()
enum TableMetaType {
  undefined,
  $group,
  $table,
}

@JsonEnum()
enum GeneratorType {
  undefined,
  json,
  csharp,
}

@JsonEnum()
enum ClassType {
  undefined,
  referenceType,
  valueType,
  interface,
}
