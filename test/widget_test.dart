import 'package:flutter_test/flutter_test.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:gceditor/model/db/data_table_row.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';

void main() {
  test('rowToJson serializes row data correctly', () {
    final dbModel = DbModel();

    final classEntity = ClassMetaEntity()
      ..id = 'Player'
      ..fields = [
        ClassMetaFieldDescription()
          ..id = 'name'
          ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.string),
        ClassMetaFieldDescription()
          ..id = 'hp'
          ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.int),
        ClassMetaFieldDescription()
          ..id = 'created'
          ..typeInfo = ClassFieldDescriptionDataInfo.fromData(type: ClassFieldType.date),
      ];

    final table = TableMetaEntity()
      ..id = 'players'
      ..classId = 'Player';

    final row = DataTableRow()
      ..id = 'p1'
      ..values = [
        DataTableCellValue.simple('Alice'),
        DataTableCellValue.simple(100),
        DataTableCellValue.simple('2026.07.10 21:20'),
      ];

    table.rows.add(row);
    dbModel.classes.add(classEntity);
    dbModel.tables.add(table);
    dbModel.cache.invalidate();

    final jsonMap = DbModelUtils.rowToJson(dbModel, table, row);

    expect(jsonMap['id'], 'p1');
    expect(jsonMap['name'], 'Alice');
    expect(jsonMap['hp'], 100);
    // 2026.07.10 21:20:00 date is parsed to milliseconds since epoch
    final parsedDate = DbModelUtils.parseDate('2026.07.10 21:20');
    expect(jsonMap['created'], parsedDate?.millisecondsSinceEpoch);
  });
}
