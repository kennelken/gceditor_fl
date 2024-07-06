// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_cmd_copypaste.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbCmdCopyPaste _$DbCmdCopyPasteFromJson(Map<String, dynamic> json) =>
    DbCmdCopyPaste()
      ..id = json['id'] as String
      ..$type = $enumDecodeNullable(_$DbCmdTypeEnumMap, json[r'$type'])
      ..fromTableId = json['fromTableId'] as String?
      ..toTableId = json['toTableId'] as String?
      ..fromIndices =
          (json['fromIndices'] as List<dynamic>?)?.map((e) => e as int).toList()
      ..toIndices =
          (json['toIndices'] as List<dynamic>?)?.map((e) => e as int).toList()
      ..fromValues = (json['fromValues'] as List<dynamic>?)
          ?.map((e) => e as List<dynamic>)
          .toList()
      ..fromColumns = (json['fromColumns'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..idSuffixes = (json['idSuffixes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..restoreValues = (json['restoreValues'] as List<dynamic>?)
          ?.map((e) => e as List<dynamic>)
          .toList()
      ..restoreColumns = (json['restoreColumns'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..restoreTableId = json['restoreTableId'] as String?
      ..restoreIndices = (json['restoreIndices'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList()
      ..replace = json['replace'] as bool?
      ..delete = json['delete'] as bool?
      ..cut = json['cut'] as bool?
      ..after = json['after'] as bool?;

Map<String, dynamic> _$DbCmdCopyPasteToJson(DbCmdCopyPaste instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', _$DbCmdTypeEnumMap[instance.$type]);
  writeNotNull('fromTableId', instance.fromTableId);
  writeNotNull('toTableId', instance.toTableId);
  writeNotNull('fromIndices', instance.fromIndices);
  writeNotNull('toIndices', instance.toIndices);
  writeNotNull('fromValues', instance.fromValues);
  writeNotNull('fromColumns', instance.fromColumns);
  writeNotNull('idSuffixes', instance.idSuffixes);
  writeNotNull('restoreValues', instance.restoreValues);
  writeNotNull('restoreColumns', instance.restoreColumns);
  writeNotNull('restoreTableId', instance.restoreTableId);
  writeNotNull('restoreIndices', instance.restoreIndices);
  writeNotNull('replace', instance.replace);
  writeNotNull('delete', instance.delete);
  writeNotNull('cut', instance.cut);
  writeNotNull('after', instance.after);
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
