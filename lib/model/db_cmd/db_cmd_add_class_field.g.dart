// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_cmd_add_class_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbCmdAddClassField _$DbCmdAddClassFieldFromJson(Map<String, dynamic> json) =>
    DbCmdAddClassField()
      ..id = json['id'] as String
      ..$type = $enumDecodeNullable(_$DbCmdTypeEnumMap, json[r'$type'])
      ..entityId = json['entityId'] as String
      ..index = (json['index'] as num).toInt()
      ..field = ClassMetaFieldDescription.fromJson(
          json['field'] as Map<String, dynamic>)
      ..listInlineValuesByTableColumn =
          (json['listInlineValuesByTableColumn'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => DataTableColumnInlineValues.fromJson(
                    e as Map<String, dynamic>))
                .toList()),
      )
      ..dataColumnsByTable =
          (json['dataColumnsByTable'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => DataTableColumn.fromJson(e as Map<String, dynamic>))
                .toList()),
      );

Map<String, dynamic> _$DbCmdAddClassFieldToJson(DbCmdAddClassField instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$DbCmdTypeEnumMap[instance.$type]);
  val['entityId'] = instance.entityId;
  val['index'] = instance.index;
  val['field'] = instance.field.toJson();
  writeNotNull(
      'listInlineValuesByTableColumn',
      instance.listInlineValuesByTableColumn
          ?.map((k, e) => MapEntry(k, e.map((e) => e.toJson()).toList())));
  writeNotNull(
      'dataColumnsByTable',
      instance.dataColumnsByTable
          ?.map((k, e) => MapEntry(k, e.map((e) => e.toJson()).toList())));
  return val;
}

const _$DbCmdTypeEnumMap = {
  DbCmdType.unknown: 'unknown',
  DbCmdType.addNewTable: 'addNewTable',
  DbCmdType.addNewClass: 'addNewClass',
  DbCmdType.addDataRow: 'addDataRow',
  DbCmdType.addEnumValue: 'addEnumValue',
  DbCmdType.addClassField: 'addClassField',
  DbCmdType.addClassInterface: 'addClassInterface',
  DbCmdType.deleteClass: 'deleteClass',
  DbCmdType.deleteTable: 'deleteTable',
  DbCmdType.deleteEnumValue: 'deleteEnumValue',
  DbCmdType.deleteClassField: 'deleteClassField',
  DbCmdType.deleteClassInterface: 'deleteClassInterface',
  DbCmdType.deleteDataRow: 'deleteDataRow',
  DbCmdType.editMetaEntityId: 'editMetaEntityId',
  DbCmdType.editMetaEntityDescription: 'editMetaEntityDescription',
  DbCmdType.editEnumValue: 'editEnumValue',
  DbCmdType.editClassField: 'editClassField',
  DbCmdType.editClassInterface: 'editClassInterface',
  DbCmdType.editClass: 'editClass',
  DbCmdType.editTable: 'editTable',
  DbCmdType.editTableRowId: 'editTableRowId',
  DbCmdType.editTableCellValue: 'editTableCellValue',
  DbCmdType.editProjectSettings: 'editProjectSettings',
  DbCmdType.reorderMetaEntity: 'reorderMetaEntity',
  DbCmdType.reorderEnum: 'reorderEnum',
  DbCmdType.reorderClassField: 'reorderClassField',
  DbCmdType.reorderClassInterface: 'reorderClassInterface',
  DbCmdType.reorderDataRow: 'reorderDataRow',
  DbCmdType.resizeColumn: 'resizeColumn',
  DbCmdType.resizeInnerCell: 'resizeInnerCell',
  DbCmdType.copypaste: 'copypaste',
  DbCmdType.fillColumn: 'fillColumn',
};
