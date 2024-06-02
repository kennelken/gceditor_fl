// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_cmd_edit_class_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbCmdEditClassField _$DbCmdEditClassFieldFromJson(Map<String, dynamic> json) =>
    DbCmdEditClassField()
      ..id = json['id'] as String
      ..$type = $enumDecodeNullable(_$DbCmdTypeEnumMap, json[r'$type'])
      ..entityId = json['entityId'] as String
      ..fieldId = json['fieldId'] as String
      ..listInlineValuesByTableColumn =
          (json['listInlineValuesByTableColumn'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k,
            (e as Map<String, dynamic>).map(
              (k, e) => MapEntry(int.parse(k),
                  (e as List<dynamic>).map((e) => e as List<dynamic>).toList()),
            )),
      )
      ..newId = json['newId'] as String?
      ..newDescription = json['newDescription'] as String?
      ..newIsUniqueValue = json['newIsUniqueValue'] as bool?
      ..newToExportValue = json['newToExportValue'] as bool?
      ..newType = json['newType'] == null
          ? null
          : ClassFieldDescriptionDataInfo.fromJson(
              json['newType'] as Map<String, dynamic>)
      ..newKeyType = json['newKeyType'] == null
          ? null
          : ClassFieldDescriptionDataInfo.fromJson(
              json['newKeyType'] as Map<String, dynamic>)
      ..newValueType = json['newValueType'] == null
          ? null
          : ClassFieldDescriptionDataInfo.fromJson(
              json['newValueType'] as Map<String, dynamic>)
      ..newDefaultValue = json['newDefaultValue'] as String?
      ..valuesByTable = (json['valuesByTable'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => DataTableColumn.fromJson(e as Map<String, dynamic>))
                .toList()),
      );

Map<String, dynamic> _$DbCmdEditClassFieldToJson(DbCmdEditClassField instance) {
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
  val['fieldId'] = instance.fieldId;
  writeNotNull(
      'listInlineValuesByTableColumn',
      instance.listInlineValuesByTableColumn?.map(
          (k, e) => MapEntry(k, e.map((k, e) => MapEntry(k.toString(), e)))));
  writeNotNull('newId', instance.newId);
  writeNotNull('newDescription', instance.newDescription);
  writeNotNull('newIsUniqueValue', instance.newIsUniqueValue);
  writeNotNull('newToExportValue', instance.newToExportValue);
  writeNotNull('newType', instance.newType?.toJson());
  writeNotNull('newKeyType', instance.newKeyType?.toJson());
  writeNotNull('newValueType', instance.newValueType?.toJson());
  writeNotNull('newDefaultValue', instance.newDefaultValue);
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
