import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_db_cmd.dart';
import 'db_cmd_result.dart';

part 'db_cmd_reorder_meta_entity.g.dart';

@JsonSerializable()
class DbCmdReorderMetaEntity extends BaseDbCmd {
  late String entityId;
  String? parentId;
  int? index;

  DbCmdReorderMetaEntity.values({
    String? id,
    required this.entityId,
    this.parentId,
    this.index,
  }) : super.withId(id) {
    $type = DbCmdType.reorderMetaEntity;
  }

  DbCmdReorderMetaEntity();

  factory DbCmdReorderMetaEntity.fromJson(Map<String, dynamic> json) => _$DbCmdReorderMetaEntityFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DbCmdReorderMetaEntityToJson(this);

  @override
  DbCmdResult doExecute(DbModel dbModel) {
    final entity = dbModel.cache.getEntity(entityId)!;

    final currentParent = dbModel.cache.getParent(entity);
    var currentIndex = dbModel.cache.getIndex(entity) ?? 0;

    // when we put item behind its current index we should increase currentIndex
    if ((currentParent as IIdentifiable?)?.id == parentId && currentIndex > (index ?? 0)) {
      currentIndex++;
    }

    if (parentId != null) {
      final newParent = dbModel.cache.getEntity(parentId!);
      (newParent as IMetaGroup).entries.insert(index ?? 0, entity);
    } else {
      if (entity is ClassMeta) //
        dbModel.classes.insert(index ?? 0, entity);
      if (entity is TableMeta) //
        dbModel.tables.insert(index ?? 0, entity);
    }

    if (currentParent != null) {
      currentParent.entries.removeAt(currentIndex);
    } else {
      if (entity is ClassMeta) //
        dbModel.classes.removeAt(currentIndex);
      if (entity is TableMeta) //
        dbModel.tables.removeAt(currentIndex);
    }

    return DbCmdResult.success();
  }

  @override
  DbCmdResult validate(DbModel dbModel) {
    final entity = dbModel.cache.getEntity(entityId);

    if (entity == null) //
      return DbCmdResult.fail('Entity with id "$entityId" does not exist');

    var entriesCount = entity is ClassMeta ? dbModel.classes.length : dbModel.tables.length;

    if (parentId != null) {
      final parent = dbModel.cache.getEntity(parentId!);
      if (parent == null) //
        return DbCmdResult.fail('Entity with id "$parentId" does not exist');
      if (parent is! IMetaGroup || !(parent as IMetaGroup).canStore(entity)) {
        return DbCmdResult.fail('Entity with id "$parentId" is not a suitable group');
      }
      entriesCount = (parent as IMetaGroup).entries.length;

      if (dbModel.cache.getParents(parent).any((e) => e as IIdentifiable == entity)) return DbCmdResult.fail('Can not move to child node');
    }

    final idx = index ?? 0;
    if (idx < 0 || idx > entriesCount) {
      return DbCmdResult.fail('Index "$index" is invalid');
    }

    return DbCmdResult.success();
  }

  @override
  BaseDbCmd createUndoCmd(DbModel dbModel) {
    final entity = dbModel.cache.getEntity(entityId)!;

    final parent = dbModel.cache.getParent(entity) as IIdentifiable?;
    final index = dbModel.cache.getIndex(entity);

    return DbCmdReorderMetaEntity.values(
      entityId: entity.id,
      index: index,
      parentId: parent?.id,
    );
  }
}
