// ignore_for_file: prefer_initializing_formals

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/event_notifier.dart';
import 'package:gceditor/utils/utils.dart';

final selectFindFieldProvider = ChangeNotifierProvider((_) => EventNotifier());
final clientFindStateProvider = ChangeNotifierProvider((ref) => ClientFindStateNotifier(ClientFindState()));

class ClientFindState {
  List<FindResultItem>? _results;
  int currentItemIndex = -1;
  FindSettings settings = FindSettings();
  bool visible = false;

  List<FindResultItem>? getResults() {
    return _results;
  }

  FindResultItem? getNextResult() {
    if (_results?.isEmpty ?? true) //
      return null;

    currentItemIndex = (currentItemIndex + 1) % _results!.length;
    return _results![currentItemIndex];
  }
}

class ClientFindStateNotifier extends ChangeNotifier {
  static const priorityVeryHigh = 4;
  static const priorityHigh = 3;
  static const priorityCommon = 2;
  static const priorityLow = 1;
  static const prioritySuperLow = 0;

  final ClientFindState state;

  ClientFindStateNotifier(this.state);
  late _FindContext _findContext;

  void find(DbModel model) async {
    state.settings.text ??= '';

    if (state.settings.text!.isEmpty) {
      _findContext = _FindContext(text: '', settings: state.settings.copyWith());
    }
    if (state.settings.regEx == true) {
      _findContext = _FindContext(
          regExp: RegExp(state.settings.text!, caseSensitive: state.settings.caseSensitive == true), settings: state.settings.copyWith());
    } else {
      var text = state.settings.text!;

      if (state.settings.caseSensitive != true) {
        text = text.toLowerCase();
      }

      if (state.settings.word == true) {
        final regexPattern = Utils.escapeRegexSpecial(state.settings.text!, true);
        final regex = RegExp(regexPattern);
        _findContext = _FindContext(regExp: regex, settings: state.settings.copyWith());
      } else {
        _findContext = _FindContext(text: text, settings: state.settings.copyWith());
      }
    }

    _doFind(model);
    notifyListeners();
  }

  void findUsage(DbModel model, String id) {
    toggleVisibility(true);
    setSettings(FindSettings(onlyId: true, text: id, regEx: false, caseSensitive: true, word: true));
    find(model);
  }

  void setSettings(FindSettings settings, {bool silent = false}) {
    if (settings.caseSensitive != null) //
      state.settings.caseSensitive = settings.caseSensitive;
    if (settings.regEx != null) //
      state.settings.regEx = settings.regEx!;
    if (settings.onlyId != null) //
      state.settings.onlyId = settings.onlyId!;
    if (settings.text != null) //
      state.settings.text = settings.text!;
    if (settings.word != null) //
      state.settings.word = settings.word!;

    if (!silent) //
      notifyListeners();
  }

  void toggleVisibility(bool visible) {
    state.visible = visible;
    notifyListeners();
  }

  void focusOn(FindResultItem item) {
    switch (item.type) {
      case FindResultType.declaration:
      case FindResultType.value:
      case FindResultType.reference:
        providerContainer.read(clientNavigationServiceProvider).focusOn(
              NavigationData.toTable(
                tableId: item.tableItem!.tableId,
                fieldId: item.tableItem!.fieldId,
                rowIndex: item.tableItem!.rowIndex,
              ),
              findResultItem: item,
            );
        break;

      case FindResultType.tableDeclaration:
      case FindResultType.tableParentClass:
        providerContainer.read(clientNavigationServiceProvider).focusOn(
              NavigationData.toTableProperties(
                tableId: item.metaItem!.tableId!,
              ),
              findResultItem: item,
            );
        break;

      case FindResultType.classDeclaration:
      case FindResultType.enumDeclaration:
      case FindResultType.classParentClass:
        providerContainer.read(clientNavigationServiceProvider).focusOn(
              NavigationData.toClassProperties(
                classId: item.metaItem!.classId!,
              ),
              findResultItem: item,
            );
        break;

      case FindResultType.fieldDeclaration:
      case FindResultType.columnUsedAsReferenceType:
        providerContainer.read(clientNavigationServiceProvider).focusOn(
              NavigationData.toFieldProperties(
                classId: item.metaItem!.classId!,
                fieldId: item.metaItem!.fieldId!,
              ),
              findResultItem: item,
            );
        break;
    }
  }

  void _doFind(DbModel model) {
    state._results ??= [];
    state._results!.clear();

    final stopWatch = Stopwatch();
    stopWatch.start();

    if (_findContext.settings.text?.isNotEmpty ?? false) {
      for (var table in model.cache.allDataTables) {
        final allFields = model.cache.getAllFieldsById(table.classId);
        if (allFields == null) //
          continue;

        for (var i = -1; i < allFields.length; i++) {
          ClassMetaFieldDescription? field;

          for (var j = 0; j < table.rows.length; j++) {
            final row = table.rows[j];

            int? closureInnerListRow;
            int? closureInnerListColumn;

            addResult(String v, int priority, FindResultType type) {
              state._results!.add(
                FindResultItem.tableItem(
                  tableItem: FindResultItemTableItem(
                    tableId: table.id,
                    rowIndex: j,
                    fieldIndex: i,
                    fieldId: field?.id,
                    innerListRowIndex: closureInnerListRow,
                    innerListColumnIndex: closureInnerListColumn,
                  ),
                  value: v,
                  priority: priority,
                  type: type,
                ),
              );
            }

            if (i == -1) {
              if (_checkMatch(row.id, isId: true)) {
                addResult(row.id, priorityVeryHigh, FindResultType.declaration);
              }
              continue;
            }

            field = allFields[i];

            final value = row.values[i];

            switch (field.typeInfo.type) {
              case ClassFieldType.undefined:
              case ClassFieldType.bool:
              case ClassFieldType.int:
              case ClassFieldType.long:
              case ClassFieldType.float:
              case ClassFieldType.double:
              case ClassFieldType.string:
              case ClassFieldType.text:
              case ClassFieldType.reference:
              case ClassFieldType.date:
              case ClassFieldType.duration:
              case ClassFieldType.color:
                _doFindInSimpleValue(value.simpleValue, field.typeInfo.type, priorityLow, addResult);
                break;

              case ClassFieldType.list:
              case ClassFieldType.set:
                for (var k = 0; k < value.listCellValues!.length; k++) {
                  closureInnerListRow = k;
                  closureInnerListColumn = 0;
                  _doFindInSimpleValue(value.listCellValues![k], field.valueTypeInfo!.type, prioritySuperLow, addResult);
                }
                break;
              case ClassFieldType.dictionary:
                for (var k = 0; k < value.dictionaryCellValues!.length; k++) {
                  closureInnerListRow = k;
                  closureInnerListColumn = 0;
                  _doFindInSimpleValue(value.dictionaryCellValues![k].key, field.keyTypeInfo!.type, prioritySuperLow, addResult);
                  closureInnerListColumn = 1;
                  _doFindInSimpleValue(value.dictionaryCellValues![k].value, field.valueTypeInfo!.type, prioritySuperLow, addResult);
                }
                break;
            }
          }
        }
      }

      for (final enumEntity in model.cache.allEnums) {
        for (final enumValue in enumEntity.values) {
          if (_checkMatch(enumValue.id, isId: true)) //
            state._results!.add(
              FindResultItem.metaItem(
                metaItem: FindResultItemMetaItem(
                  classId: enumEntity.id,
                  enumId: enumValue.id,
                ),
                priority: priorityVeryHigh,
                type: FindResultType.enumDeclaration,
                value: enumValue.id,
              ),
            );
        }
      }

      for (final classEntity in model.cache.allClassesMetas) {
        if (_checkMatch(classEntity.id, isId: true)) {
          state._results!.add(
            FindResultItem.metaItem(
              metaItem: FindResultItemMetaItem(
                classId: classEntity.id,
              ),
              priority: priorityHigh,
              type: FindResultType.classDeclaration,
              value: classEntity.id,
            ),
          );
        }

        if (classEntity is ClassMetaEntity && classEntity.parent != null && _checkMatch(classEntity.parent!, isId: true)) {
          state._results!.add(
            FindResultItem.metaItem(
              metaItem: FindResultItemMetaItem(
                classId: classEntity.id,
                parentClass: classEntity.parent!,
              ),
              priority: priorityCommon,
              type: FindResultType.classParentClass,
              value: classEntity.parent!,
            ),
          );
        }
      }

      for (final classEntity in model.cache.allClasses) {
        final fields = classEntity.fields;
        for (final field in fields) {
          if (_checkMatch(field.id, isId: true)) {
            state._results!.add(
              FindResultItem.metaItem(
                metaItem: FindResultItemMetaItem(
                  classId: classEntity.id,
                  fieldId: field.id,
                ),
                priority: priorityCommon,
                type: FindResultType.fieldDeclaration,
                value: field.id,
              ),
            );
          }

          FindResultFieldDefinistionValueType? fieldValueType;
          if (fieldValueType == null && field.typeInfo.classId != null && _checkMatch(field.typeInfo.classId!, isId: true)) {
            fieldValueType = FindResultFieldDefinistionValueType.simple;
          }
          if (fieldValueType == null && field.keyTypeInfo?.classId != null && _checkMatch(field.keyTypeInfo!.classId!, isId: true)) {
            fieldValueType = FindResultFieldDefinistionValueType.simple;
          }
          if (fieldValueType == null && field.valueTypeInfo?.classId != null && _checkMatch(field.valueTypeInfo!.classId!, isId: true)) {
            fieldValueType = FindResultFieldDefinistionValueType.simple;
          }

          if (fieldValueType != null) {
            state._results!.add(
              FindResultItem.metaItem(
                metaItem: FindResultItemMetaItem(
                  classId: classEntity.id,
                  fieldId: field.id,
                  fieldValueType: fieldValueType,
                ),
                priority: priorityCommon,
                type: FindResultType.columnUsedAsReferenceType,
                value: field.id,
              ),
            );
          }
        }
      }

      for (final tableEntity in model.cache.allTablesMetas) {
        if (_checkMatch(tableEntity.id, isId: true)) {
          state._results!.add(
            FindResultItem.metaItem(
              metaItem: FindResultItemMetaItem(
                tableId: tableEntity.id,
              ),
              priority: priorityHigh,
              type: FindResultType.tableDeclaration,
              value: tableEntity.id,
            ),
          );
        }

        if (tableEntity is TableMetaEntity && _checkMatch(tableEntity.classId, isId: true)) {
          state._results!.add(
            FindResultItem.metaItem(
              metaItem: FindResultItemMetaItem(
                tableId: tableEntity.id,
                parentClass: tableEntity.classId,
              ),
              priority: priorityCommon,
              type: FindResultType.tableParentClass,
              value: tableEntity.classId,
            ),
          );
        }
      }
    }

    insertionSort<FindResultItem>(state._results!, compare: (a, b) => -a.priority.compareTo(b.priority));

    providerContainer.read(logStateProvider).addMessage(
          LogEntry(
              LogLevel.debug, 'Found ${state._results!.length} results for "${_findContext.settings.text}" in ${stopWatch.elapsedMilliseconds} ms'),
        );
  }

  void _doFindInSimpleValue(dynamic value, ClassFieldType type, int priority, void Function(String, int, FindResultType) onFind) {
    switch (type) {
      case ClassFieldType.bool:
        break;

      case ClassFieldType.int:
      case ClassFieldType.long:
      case ClassFieldType.float:
      case ClassFieldType.double:
      case ClassFieldType.string:
      case ClassFieldType.text:
      case ClassFieldType.date:
      case ClassFieldType.duration:
      case ClassFieldType.color:
        if (_checkMatch(value.toString())) //
          onFind(value.toString(), priority, FindResultType.value);
        break;

      case ClassFieldType.reference:
        if (_checkMatch(value.toString(), isId: true)) //
          onFind(value.toString(), priority, FindResultType.reference);
        break;

      case ClassFieldType.undefined:
      case ClassFieldType.list:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        throw Exception('Unexpected type "${describeEnum(type)}"');
    }
  }

  bool _checkMatch(String text, {bool isId = false}) {
    if (!isId && _findContext.settings.onlyId == true) //
      return false;
    if (_findContext.text != null) {
      text = _findContext.settings.caseSensitive == true ? text : text.toLowerCase();
      return text.contains(_findContext.text!);
    }
    return _findContext.regExp!.hasMatch(text);
  }
}

class FindResultItem {
  FindResultItemTableItem? tableItem;
  FindResultItemMetaItem? metaItem;
  String value;
  int priority;
  FindResultType type;

  FindResultItem.tableItem({
    required FindResultItemTableItem tableItem,
    required this.value,
    required this.priority,
    required this.type,
  }) : tableItem = tableItem;

  FindResultItem.metaItem({
    required FindResultItemMetaItem metaItem,
    required this.value,
    required this.priority,
    required this.type,
  }) : metaItem = metaItem;

  String getDescription() {
    switch (type) {
      case FindResultType.declaration:
        return Loc.get.findTypeDeclaration;

      case FindResultType.value:
        return Loc.get.findTypeValue;

      case FindResultType.reference:
        return Loc.get.findTypeReference;

      case FindResultType.tableDeclaration:
        return Loc.get.findTypeTableDeclaration;

      case FindResultType.classDeclaration:
        return Loc.get.findTypeClassDeclaration;

      case FindResultType.enumDeclaration:
        return Loc.get.findTypeEnumDeclaration;

      case FindResultType.fieldDeclaration:
        return Loc.get.findTypeFieldDeclaration;

      case FindResultType.classParentClass:
        return Loc.get.classParentClassReference;

      case FindResultType.tableParentClass:
        return Loc.get.tableParentClassReference;

      case FindResultType.columnUsedAsReferenceType:
        return Loc.get.referenceValue;
    }
  }

  Color color() {
    switch (type) {
      case FindResultType.declaration:
        return kColorAccentOrange;

      case FindResultType.value:
        return kColorAccentYellow;

      case FindResultType.reference:
        return kColorAccentPink;

      case FindResultType.tableDeclaration:
        return kColorAccentGreen;

      case FindResultType.classDeclaration:
        return kColorAccentGreen;

      case FindResultType.enumDeclaration:
        return kColorAccentOrange;

      case FindResultType.fieldDeclaration:
        return kColorAccentGreen;

      case FindResultType.classParentClass:
        return kColorAccentPink;

      case FindResultType.tableParentClass:
        return kColorAccentPink;

      case FindResultType.columnUsedAsReferenceType:
        return kColorAccentYellow;
    }
  }

  InputDecoration inputDecoration(bool isSelected) {
    return kStyle.getInputDecoration(color().withAlpha(isSelected ? kFindResultBackgroundAlphaSelected : kFindResultBackgroundAlpha));
  }

  BoxDecoration boxDecoration(bool isSelected) {
    return kStyle.kDataTableIdBoxDecoration
        .copyWith(color: color().withAlpha(isSelected ? kFindResultBackgroundAlphaSelected : kFindResultBackgroundAlpha));
  }
}

class FindResultItemTableItem {
  String tableId;
  int rowIndex;
  int fieldIndex;
  String? fieldId;
  int? innerListRowIndex;
  int? innerListColumnIndex;

  FindResultItemTableItem({
    required this.tableId,
    required this.rowIndex,
    required this.fieldIndex,
    required this.fieldId,
    this.innerListRowIndex,
    this.innerListColumnIndex,
  });
}

class FindResultItemMetaItem {
  String? tableId;
  String? classId;
  String? fieldId;
  String? enumId;
  String? parentClass;
  FindResultFieldDefinistionValueType? fieldValueType;

  FindResultItemMetaItem({
    this.tableId,
    this.classId,
    this.fieldId,
    this.enumId,
    this.parentClass,
    this.fieldValueType,
  });
}

enum FindResultType {
  declaration,
  value,
  reference,
  tableDeclaration,
  classDeclaration,
  enumDeclaration,
  fieldDeclaration,
  classParentClass,
  tableParentClass,
  columnUsedAsReferenceType,
}

enum FindResultFieldDefinistionValueType {
  simple,
  key,
  value,
}

class FindSettings {
  bool? onlyId;
  bool? caseSensitive;
  bool? regEx;
  bool? word;
  String? text;

  FindSettings({
    this.onlyId,
    this.caseSensitive,
    this.regEx,
    this.word,
    this.text,
  });

  FindSettings copyWith({
    bool? onlyId,
    bool? caseSensitive,
    bool? regEx,
    bool? word,
    String? text,
  }) {
    return FindSettings(
      onlyId: onlyId ?? this.onlyId,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      regEx: regEx ?? this.regEx,
      word: word ?? this.word,
      text: text ?? this.text,
    );
  }
}

class _FindContext {
  String? text;
  RegExp? regExp;
  FindSettings settings;

  _FindContext({this.text, this.regExp, required this.settings});
}
