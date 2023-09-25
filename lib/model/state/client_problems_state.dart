// ignore_for_file: unused_catch_stack

import 'dart:convert';

import 'package:darq/darq.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/main.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/multi_dimensional_map.dart';

import '../model_root.dart';
import 'service/client_navigation_service.dart';

final clientProblemsStateProvider = ChangeNotifierProvider((ref) {
  final notifier = ClientProblemsStateNotifier(ClientProblemsState());
  ref.read(clientStateProvider).addListener(
    () {
      final model = ref.read(clientStateProvider).state.model;
      notifier.updateProblems(model);
    },
  );
  return notifier;
});

class ClientProblemsState {
  List<DbModelProblem> problems = [];
  final Map<ProblemSeverity, List<DbModelProblem>> _errorsBySeverity = {};
  int warningsCount = 0;
  int errorsCount = 0;
  int currentProblemIndex = -1;

  void _setProblems(List<DbModelProblem> problems) {
    this.problems = problems;

    _errorsBySeverity.clear();
    for (var severity in ProblemSeverity.values) {
      _errorsBySeverity[severity] = [];
    }
    for (var problem in problems) {
      _errorsBySeverity[problem.severity]!.add(problem);
    }
  }

  List<DbModelProblem> getProblems(ProblemSeverity severity) {
    return _errorsBySeverity[severity] ?? [];
  }
}

class ClientProblemsStateNotifier extends ChangeNotifier {
  final ClientProblemsState state;

  DbModel? _needUpdateModel;
  bool _isUpdating = false;

  ClientProblemsStateNotifier(this.state);

  void updateProblems(DbModel model) async {
    _needUpdateModel = model;
    _updateIfRequired();
  }

  void _updateIfRequired() async {
    if (_isUpdating) //
      return;

    if (_needUpdateModel != null) {
      final model = _needUpdateModel!;
      _needUpdateModel = null;
      _isUpdating = true;

      final modelJson = jsonEncode(model.toJson());

      late final List<DbModelProblem> computeResult;
      if (kIsWeb) {
        computeResult = await compute(_computeProblems, modelJson);
      } else {
        computeResult = await computer.compute(
          _computeProblems,
          param: modelJson, // optional
        );
      }

      state._setProblems(computeResult);

      notifyListeners();
      _isUpdating = false;
      _updateIfRequired();
    }
  }

  void focusOnNextProblem(DbModelProblem? problem) {
    if (state.problems.isEmpty) //
      return;

    var nextProblem = problem;
    if (nextProblem != null) {
      state.currentProblemIndex = state.problems.indexOf(problem!);
    } else {
      state.currentProblemIndex = (state.currentProblemIndex + 1) % state.problems.length;
      nextProblem = state.problems[state.currentProblemIndex];
    }

    providerContainer.read(clientNavigationServiceProvider).focusOn(
          NavigationData.toTable(
            tableId: nextProblem.tableId,
            fieldId: nextProblem.fieldId,
            rowIndex: nextProblem.rowIndex,
          ),
        );

    notifyListeners();
  }
}

class DbModelProblem {
  String tableId;
  int rowIndex;
  int fieldIndex;
  String fieldId;
  int? innerListRowIndex;
  int? innerListColumnIndex;
  ProblemSeverity severity;
  ProblemType type;
  String? value;

  DbModelProblem({
    required this.severity,
    required this.type,
    required this.tableId,
    required this.rowIndex,
    required this.fieldIndex,
    required this.fieldId,
    this.innerListRowIndex,
    this.innerListColumnIndex,
    this.value,
  });

  String getDescription() {
    switch (type) {
      case ProblemType.invalidReference:
        return Loc.get.problemInvalidReference;
      case ProblemType.invalidValue:
        return Loc.get.problemInvalidValue;
      case ProblemType.notUniqueValue:
        return Loc.get.problemValueIsNotUnique;
      case ProblemType.repeatingSetValue:
        return Loc.get.problemRepeatingSetValue;
      case ProblemType.repeatingDictionaryKey:
        return Loc.get.problemRepeatingDictionaryKey;
    }
  }

  Color get color {
    switch (severity) {
      case ProblemSeverity.error:
        return kColorAccentRed2;

      case ProblemSeverity.warning:
        return kColorAccentYellow;
    }
  }

  InputDecoration inputDecoration(bool isSelected) {
    switch (severity) {
      case ProblemSeverity.error:
        return isSelected ? kStyle.kInputTextStyleError : kStyle.kInputTextStyleErrorTransparent;

      case ProblemSeverity.warning:
        return isSelected ? kStyle.kInputTextStyleWarning : kStyle.kInputTextStyleWarningTransparent;
    }
  }
}

enum ProblemSeverity {
  warning,
  error,
}

enum ProblemType {
  invalidReference,
  invalidValue,
  notUniqueValue,
  repeatingSetValue,
  repeatingDictionaryKey,
}

List<DbModelProblem> _computeProblems(String modelJson) {
  var result = <DbModelProblem>[];

  final model = DbModel.fromJson(jsonDecode(modelJson));

  _computeAndAppendInvalidReferences(model, result);
  _computeAndAppendInvalidValues(model, result);
  _computeAndAppendDuplicateUniqueValues(model, result);
  _computeAndAppendRepeatingSetValues(model, result);
  _computeAndAppendRepeatingDictionaryKeys(model, result);

  result = result.orderByDescending((p) => p.severity.index).toList();

  return result;
}

void _computeAndAppendInvalidReferences(DbModel model, List<DbModelProblem> result) {
  for (var table in model.cache.allDataTables) {
    final allFields = model.cache.getAllFieldsById(table.classId);
    if (allFields == null) //
      continue;

    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];

      for (var j = 0; j < table.rows.length; j++) {
        try {
          final row = table.rows[j];
          final value = row.values[i];

          switch (field.typeInfo.type) {
            case ClassFieldType.reference:
              if (!DbModelUtils.validateReferenceExists(model, field.typeInfo, value.simpleValue))
                result.add(
                  DbModelProblem(
                    severity: ProblemSeverity.error,
                    type: ProblemType.invalidReference,
                    tableId: table.id,
                    rowIndex: j,
                    fieldIndex: i,
                    fieldId: field.id,
                    value: value.simpleValue?.toString(),
                  ),
                );
              break;

            case ClassFieldType.list:
            case ClassFieldType.set:
              if (field.valueTypeInfo!.type == ClassFieldType.reference) {
                final list = value.listCellValues!;
                for (var k = 0; k < list.length; k++) {
                  final listValue = list[k];
                  if (listValue is! String || !DbModelUtils.validateReferenceExists(model, field.valueTypeInfo!, listValue))
                    result.add(
                      DbModelProblem(
                        severity: ProblemSeverity.error,
                        type: ProblemType.invalidReference,
                        tableId: table.id,
                        rowIndex: j,
                        fieldIndex: i,
                        fieldId: field.id,
                        innerListRowIndex: k,
                        innerListColumnIndex: 0,
                        value: listValue?.toString(),
                      ),
                    );
                }
              }
              break;

            case ClassFieldType.dictionary:
              final list = value.dictionaryCellValues()!;
              for (var k = 0; k < list.length; k++) {
                final listValue = list[k];

                if (field.keyTypeInfo!.type == ClassFieldType.reference) {
                  if (!DbModelUtils.validateReferenceExists(model, field.keyTypeInfo!, listValue.key))
                    result.add(
                      DbModelProblem(
                        severity: ProblemSeverity.error,
                        type: ProblemType.invalidReference,
                        tableId: table.id,
                        rowIndex: j,
                        fieldIndex: i,
                        fieldId: field.id,
                        innerListRowIndex: k,
                        innerListColumnIndex: 0,
                        value: listValue.key?.toString(),
                      ),
                    );
                }
                if (field.valueTypeInfo!.type == ClassFieldType.reference) {
                  if (!DbModelUtils.validateReferenceExists(model, field.valueTypeInfo!, listValue.value))
                    result.add(
                      DbModelProblem(
                        severity: ProblemSeverity.error,
                        type: ProblemType.invalidReference,
                        tableId: table.id,
                        rowIndex: j,
                        fieldIndex: j,
                        fieldId: field.id,
                        innerListRowIndex: k,
                        innerListColumnIndex: 1,
                        value: listValue.value?.toString(),
                      ),
                    );
                }
              }
              break;

            case ClassFieldType.undefined:
            case ClassFieldType.bool:
            case ClassFieldType.int:
            case ClassFieldType.long:
            case ClassFieldType.float:
            case ClassFieldType.double:
            case ClassFieldType.string:
            case ClassFieldType.text:
            case ClassFieldType.date:
            case ClassFieldType.duration:
            case ClassFieldType.color:
            case ClassFieldType.vector2:
            case ClassFieldType.vector2Int:
            case ClassFieldType.vector3:
            case ClassFieldType.vector3Int:
            case ClassFieldType.vector4:
            case ClassFieldType.vector4Int:
            case ClassFieldType.rectangle:
            case ClassFieldType.rectangleInt:
              break;
          }
        } catch (e, stacktrace) {
          result.add(
            DbModelProblem(
              severity: ProblemSeverity.error,
              type: ProblemType.invalidReference,
              tableId: table.id,
              rowIndex: j,
              fieldIndex: i,
              fieldId: field.id,
              value: '<Exception> $e',
            ),
          );
        }
      }
    }
  }
}

void _computeAndAppendInvalidValues(DbModel model, List<DbModelProblem> result) {
  for (var table in model.cache.allDataTables) {
    final allFields = model.cache.getAllFieldsById(table.classId);
    if (allFields == null) //
      continue;

    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];

      for (var j = 0; j < table.rows.length; j++) {
        try {
          final row = table.rows[j];
          final value = row.values[i];

          switch (field.typeInfo.type) {
            case ClassFieldType.reference:
              if (!DbModelUtils.validateSimpleValue(field.typeInfo.type, value.simpleValue))
                result.add(
                  DbModelProblem(
                    severity: ProblemSeverity.error,
                    type: ProblemType.invalidValue,
                    tableId: table.id,
                    rowIndex: j,
                    fieldIndex: i,
                    fieldId: field.id,
                    value: value.simpleValue?.toString(),
                  ),
                );
              break;

            case ClassFieldType.list:
            case ClassFieldType.set:
              if (field.valueTypeInfo!.type == ClassFieldType.reference) {
                final list = value.listCellValues!;
                for (var k = 0; k < list.length; k++) {
                  final listValue = list[k];
                  if (!DbModelUtils.validateSimpleValue(field.valueTypeInfo!.type, listValue))
                    result.add(
                      DbModelProblem(
                        severity: ProblemSeverity.error,
                        type: ProblemType.invalidValue,
                        tableId: table.id,
                        rowIndex: j,
                        fieldIndex: i,
                        fieldId: field.id,
                        innerListRowIndex: k,
                        innerListColumnIndex: 0,
                        value: listValue?.toString(),
                      ),
                    );
                }
              }
              break;

            case ClassFieldType.dictionary:
              final list = value.dictionaryCellValues()!;
              for (var k = 0; k < list.length; k++) {
                final listValue = list[k];

                if (!DbModelUtils.validateSimpleValue(field.keyTypeInfo!.type, listValue.key))
                  result.add(
                    DbModelProblem(
                      severity: ProblemSeverity.error,
                      type: ProblemType.invalidValue,
                      tableId: table.id,
                      rowIndex: j,
                      fieldIndex: i,
                      fieldId: field.id,
                      innerListRowIndex: k,
                      innerListColumnIndex: 0,
                      value: listValue.key?.toString(),
                    ),
                  );

                if (!DbModelUtils.validateSimpleValue(field.valueTypeInfo!.type, listValue.value))
                  result.add(
                    DbModelProblem(
                      severity: ProblemSeverity.error,
                      type: ProblemType.invalidValue,
                      tableId: table.id,
                      rowIndex: j,
                      fieldIndex: j,
                      fieldId: field.id,
                      innerListRowIndex: k,
                      innerListColumnIndex: 1,
                      value: listValue.value?.toString(),
                    ),
                  );
              }
              break;

            case ClassFieldType.bool:
            case ClassFieldType.int:
            case ClassFieldType.long:
            case ClassFieldType.float:
            case ClassFieldType.double:
            case ClassFieldType.string:
            case ClassFieldType.text:
            case ClassFieldType.date:
            case ClassFieldType.duration:
            case ClassFieldType.color:
            case ClassFieldType.vector2:
            case ClassFieldType.vector2Int:
            case ClassFieldType.vector3:
            case ClassFieldType.vector3Int:
            case ClassFieldType.vector4:
            case ClassFieldType.vector4Int:
            case ClassFieldType.rectangle:
            case ClassFieldType.rectangleInt:
              if (!DbModelUtils.validateSimpleValue(field.typeInfo.type, value.simpleValue))
                result.add(
                  DbModelProblem(
                    severity: ProblemSeverity.error,
                    type: ProblemType.invalidValue,
                    tableId: table.id,
                    rowIndex: j,
                    fieldIndex: j,
                    fieldId: field.id,
                    value: value.simpleValue?.toString(),
                  ),
                );
              break;

            case ClassFieldType.undefined:
              break;
          }
        } catch (e, stacktrace) {
          result.add(
            DbModelProblem(
              severity: ProblemSeverity.error,
              type: ProblemType.invalidReference,
              tableId: table.id,
              rowIndex: j,
              fieldIndex: i,
              fieldId: field.id,
              value: '<Exception> $e',
            ),
          );
        }
      }
    }
  }
}

void _computeAndAppendDuplicateUniqueValues(DbModel model, List<DbModelProblem> result) {
  final allValues = MultidimensionalMap2<ClassMetaFieldDescription, dynamic, List<DbModelProblem>>();

  for (var table in model.cache.allDataTables) {
    final allFields = model.cache.getAllFieldsById(table.classId);
    if (allFields == null) //
      continue;

    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      if (!field.isUniqueValue) //
        continue;

      for (var j = 0; j < table.rows.length; j++) {
        try {
          final row = table.rows[j];

          if (allValues.get(field, row.values[i]) == null) //
            allValues.set(field, row.values[i], []);

          allValues.get(field, row.values[i])!.add(
                DbModelProblem(
                  severity: ProblemSeverity.warning,
                  type: ProblemType.notUniqueValue,
                  tableId: table.id,
                  rowIndex: j,
                  fieldIndex: i,
                  fieldId: field.id,
                  value: row.values[i].toString(),
                ),
              );
        } catch (e, stacktrace) {
          result.add(
            DbModelProblem(
              severity: ProblemSeverity.error,
              type: ProblemType.invalidReference,
              tableId: table.id,
              rowIndex: j,
              fieldIndex: i,
              fieldId: field.id,
              value: '<Exception> $e',
            ),
          );
        }
      }
    }
  }

  final map = allValues.depth0();
  for (final field in map.keys) {
    for (final value in map[field]!.keys) {
      if (map[field]![value]!.length > 1) {
        result.addAll(map[field]![value]!);
      }
    }
  }
}

void _computeAndAppendRepeatingSetValues(DbModel model, List<DbModelProblem> result) {
  for (var table in model.cache.allDataTables) {
    final allFields = model.cache.getAllFieldsById(table.classId);
    if (allFields == null) //
      continue;

    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      if (field.typeInfo.type != ClassFieldType.set) //
        continue;

      for (var j = 0; j < table.rows.length; j++) {
        try {
          final row = table.rows[j];

          final values = row.values[i].listCellValues!;

          final allValues = <dynamic, List<DbModelProblem>>{};

          for (var k = 0; k < values.length; k++) {
            final value = values[k];
            if (!allValues.containsKey(value)) //
              allValues[value] = [];

            allValues[value]!.add(
              DbModelProblem(
                severity: ProblemSeverity.warning,
                type: ProblemType.repeatingSetValue,
                tableId: table.id,
                rowIndex: j,
                fieldIndex: i,
                fieldId: field.id,
                innerListRowIndex: k,
                innerListColumnIndex: 0,
                value: value?.toString() ?? '',
              ),
            );
          }

          for (final value in allValues.keys) {
            if (allValues[value]!.length > 1) {
              result.addAll(allValues[value]!);
            }
          }
        } catch (e, stacktrace) {
          result.add(
            DbModelProblem(
              severity: ProblemSeverity.error,
              type: ProblemType.invalidReference,
              tableId: table.id,
              rowIndex: j,
              fieldIndex: i,
              fieldId: field.id,
              value: '<Exception> $e',
            ),
          );
        }
      }
    }
  }
}

void _computeAndAppendRepeatingDictionaryKeys(DbModel model, List<DbModelProblem> result) {
  for (var table in model.cache.allDataTables) {
    final allFields = model.cache.getAllFieldsById(table.classId);
    if (allFields == null) //
      continue;

    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      if (field.typeInfo.type != ClassFieldType.dictionary) //
        continue;

      for (var j = 0; j < table.rows.length; j++) {
        try {
          final row = table.rows[j];

          final keys = row.values[i].dictionaryCellValues()!.map((e) => e.key).toList();

          final allValues = <dynamic, List<DbModelProblem>>{};

          for (var k = 0; k < keys.length; k++) {
            final value = keys[k];
            if (!allValues.containsKey(value)) //
              allValues[value] = [];

            allValues[value]!.add(
              DbModelProblem(
                severity: ProblemSeverity.error,
                type: ProblemType.repeatingDictionaryKey,
                tableId: table.id,
                rowIndex: j,
                fieldIndex: i,
                fieldId: field.id,
                innerListRowIndex: k,
                innerListColumnIndex: 0,
                value: value?.toString() ?? '',
              ),
            );
          }

          for (final value in allValues.keys) {
            if (allValues[value]!.length > 1) {
              result.addAll(allValues[value]!);
            }
          }
        } catch (e, stacktrace) {
          result.add(
            DbModelProblem(
              severity: ProblemSeverity.error,
              type: ProblemType.invalidReference,
              tableId: table.id,
              rowIndex: j,
              fieldIndex: i,
              fieldId: field.id,
              value: '<Exception> $e',
            ),
          );
        }
      }
    }
  }
}
