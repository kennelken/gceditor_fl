// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_cmd_edit_class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbCmdEditClass _$DbCmdEditClassFromJson(Map<String, dynamic> json) =>
    DbCmdEditClass()
      ..id = json['id'] as String
      ..$type = $enumDecodeNullable(_$DbCmdTypeEnumMap, json[r'$type'])
      ..entityId = json['entityId'] as String
      ..parentClassId = json['parentClassId'] as String?
      ..editParentClassId = json['editParentClassId'] as bool?
      ..classType = $enumDecodeNullable(_$ClassTypeEnumMap, json['classType'])
      ..exportList = json['exportList'] as bool?
      ..valuesByTable = (json['valuesByTable'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => DataTableColumn.fromJson(e as Map<String, dynamic>))
                .toList()),
      );

Map<String, dynamic> _$DbCmdEditClassToJson(DbCmdEditClass instance) {
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
  writeNotNull('parentClassId', instance.parentClassId);
  writeNotNull('editParentClassId', instance.editParentClassId);
  writeNotNull('classType', _$ClassTypeEnumMap[instance.classType]);
  writeNotNull('exportList', instance.exportList);
  writeNotNull(
      'valuesByTable',
      instance.valuesByTable
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

const _$ClassTypeEnumMap = {
  ClassType.undefined: 'undefined',
  ClassType.referenceType: 'referenceType',
  ClassType.valueType: 'valueType',
  ClassType.interface: 'interface',
};
