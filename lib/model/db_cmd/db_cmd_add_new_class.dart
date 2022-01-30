import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_group.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_delete_class.dart';
import 'db_cmd_result.dart';

part 'db_cmd_add_new_class.g.dart';

@JsonSerializable()
class DbCmdAddNewClass extends BaseDbCmd {
  @JsonKey(toJson: ClassMeta.encode, fromJson: ClassMeta.decode)
  late ClassMeta classMeta;
  String? parentId;
  int? index;

  DbCmdAddNewClass.values({
    String? id,
    required this.classMeta,
    this.parentId,
    this.index,
  }) : super.withId(id) {
    $type = DbCmdType.addNewClass;
  }

  DbCmdAddNewClass();

  factory DbCmdAddNewClass.fromJson(Map<String, dynamic> json) => _$DbCmdAddNewClassFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdAddNewClassToJson(this);

  factory DbCmdAddNewClass.fromType({
    required String entityId,
    required ClassMetaType type,
    required int? index,
    required String? parentId,
  }) {
    ClassMeta? entity;
    switch (type) {
      case ClassMetaType.undefined:
        break;

      case ClassMetaType.$group:
        entity = ClassMetaGroup()
          ..id = entityId
          ..entries = <ClassMeta>[]
          ..description = Config.newFolderDescription;
        break;

      case ClassMetaType.$enum:
        entity = ClassMetaEntityEnum()
          ..id = entityId
          ..values = <EnumValue>[]
          ..description = Config.newEnumDescription;
        break;

      case ClassMetaType.$class:
        entity = ClassMetaEntity()
          ..id = entityId
          ..fields = []
          ..description = Config.newClassDescription;
        break;
    }

    return DbCmdAddNewClass.values(classMeta: entity!, index: index, parentId: parentId);
  }

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    if (parentId != null) {
      final parent = dbModel.cache.getClass(parentId!) as ClassMetaGroup;
      parent.entries.insert(index ?? 0, classMeta);
    } else {
      dbModel.classes.insert(index ?? 0, classMeta);
    }

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    if (!DbModelUtils.validateId(classMeta.id)) //
      return DbCmdResult.fail('Id "${classMeta.id}" is invalid. Valid format: "${Config.idFormatRegex.pattern}"');

    final existingEntity = dbModel.cache.getEntity(classMeta.id);

    if (existingEntity != null) //
      return DbCmdResult.fail('Entity with id "${classMeta.id}" already exists');

    var entriesCount = dbModel.classes.length;
    if (parentId != null) {
      final parent = dbModel.cache.getClass(parentId!);
      if (parent == null) {
        return DbCmdResult.fail('ClassMeta with id "$parentId" does not exist');
      }
      if (parent is! ClassMetaGroup) {
        return DbCmdResult.fail('ClassMeta with id "$classMeta.id" is not a group');
      }
      entriesCount = parent.entries.length;
    }

    final idx = index ?? 0;
    if (idx < 0 || idx > entriesCount) {
      return DbCmdResult.fail('Index "$index" is invalid');
    }

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    return DbCmdDeleteClass.values(
      entityId: classMeta.id,
    );
  }
}
