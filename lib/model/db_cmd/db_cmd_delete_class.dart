import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_group.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_add_new_class.dart';
import 'db_cmd_result.dart';

part 'db_cmd_delete_class.g.dart';

@JsonSerializable()
class DbCmdDeleteClass extends BaseDbCmd {
  late String entityId;

  DbCmdDeleteClass.values({
    String? id,
    required this.entityId,
  }) : super.withId(id) {
    $type = DbCmdType.deleteClass;
  }

  DbCmdDeleteClass();

  factory DbCmdDeleteClass.fromJson(Map<String, dynamic> json) => _$DbCmdDeleteClassFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdDeleteClassToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final classMeta = dbModel.cache.getClass(entityId);

    final group = dbModel.cache.getParentClass(classMeta!);
    final index = dbModel.cache.getClassIndex(classMeta);

    if (group != null) {
      group.entries.removeAt(index!);
    } else {
      dbModel.classes.removeAt(index!);
    }

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final classMeta = dbModel.cache.getClass(entityId);

    if (classMeta == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    if (classMeta is ClassMetaGroup) {
      if (classMeta.entries.isNotEmpty) {
        return DbCmdResult.fail('Entity with id "$entityId" is not empty');
      }
    }

    if (classMeta is ClassMetaEntity || classMeta is ClassMetaEntityEnum) {
      for (var table in dbModel.cache.allDataTables) {
        if (table.classId == classMeta.id) //
          return DbCmdResult.fail('Class "${classMeta.id}" is used in table "${table.id}"');
      }
      for (var table in dbModel.cache.allClasses) {
        if (table.fields
            .any((f) => f.typeInfo.classId == classMeta.id || f.valueTypeInfo?.classId == classMeta.id || f.keyTypeInfo?.classId == classMeta.id)) //
          return DbCmdResult.fail('Class "${classMeta.id}" is used in table "${table.id}"');
      }
    }

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final classMeta = dbModel.cache.getClass(entityId)!;

    final deletedClass = classMeta;
    final deletedClassParent = dbModel.cache.getParentClass(deletedClass);
    final deletedClassIndex = dbModel.cache.getClassIndex(deletedClass);

    return DbCmdAddNewClass.values(
      classMeta: ClassMeta.decode(ClassMeta.encode(deletedClass).clone()),
      parentId: deletedClassParent?.id,
      index: deletedClassIndex,
    );
  }
}
