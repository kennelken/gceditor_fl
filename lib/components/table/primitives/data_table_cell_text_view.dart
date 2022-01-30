import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_view.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';

class DataTableCellTextView extends StatefulWidget {
  final ClassFieldDescriptionDataInfo fieldType;
  final dynamic value;
  final dynamic defaultValue;
  final ValueChanged<dynamic> onValueChanged;
  final DataTableValueCoordinates coordinates;

  const DataTableCellTextView({
    Key? key,
    required this.coordinates,
    required this.fieldType,
    required this.value,
    required this.defaultValue,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  State<DataTableCellTextView> createState() => _DataTableCellTextViewState();
}

class _DataTableCellTextViewState extends State<DataTableCellTextView> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    var currentValue = widget.value;
    if (widget.fieldType.type == ClassFieldType.date) {
      currentValue = DbModelUtils.applyTimezone(currentValue.toString(), clientModel.settings.timeZone);
    }

    _textController = TextEditingController(text: DbModelUtils.simpleValueToText(currentValue));

    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(context) {
    List<FilteringTextInputFormatter>? formatter;
    switch (widget.fieldType.type) {
      case ClassFieldType.int:
      case ClassFieldType.long:
        formatter = Config.filterCellTypeInt;
        break;

      case ClassFieldType.float:
      case ClassFieldType.double:
        formatter = Config.filterCellTypeFloat;
        break;

      case ClassFieldType.string:
      case ClassFieldType.text:
        formatter = Config.filterCellTypeText;
        break;

      case ClassFieldType.date:
        formatter = Config.filterCellTypeDate;
        break;
      case ClassFieldType.duration:
        formatter = Config.filterCellTypeDuration;
        break;

      case ClassFieldType.undefined:
      case ClassFieldType.bool:
      case ClassFieldType.reference:
      case ClassFieldType.color:
      case ClassFieldType.list:
      case ClassFieldType.set:
      case ClassFieldType.dictionary:
        break;
    }

    return Consumer(builder: (context, watch, child) {
      return Align(
        alignment: Alignment.topCenter,
        child: TextField(
          controller: _textController,
          focusNode: _focusNode,
          decoration: DbModelUtils.getDataCellInputDecoration(
            widget.coordinates,
            watch(clientProblemsStateProvider).state,
            watch(clientFindStateProvider).state,
            watch(clientNavigationServiceProvider).state,
          ),
          maxLines: widget.fieldType.type.isSimple() ? 1 : Config.dataTableTextMaxLines,
          inputFormatters: formatter,
        ),
      );
    });
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) //
      return;

    var newValue = DbModelUtils.parseDefaultValue(widget.fieldType, null, null, _textController.text)?.simpleValue;

    if (newValue is String && widget.fieldType.type == ClassFieldType.date) {
      newValue = DbModelUtils.applyTimezone(newValue.toString(), -clientModel.settings.timeZone);
    }

    if (newValue == null) {
      if (DbModelUtils.validateSimpleValue(widget.fieldType.type, widget.value)) {
        providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Incorrect value "${_textController.text}"'));
        _textController.text = widget.value.toString();
        return;
      } else {
        providerContainer
            .read(logStateProvider)
            .addMessage(LogEntry(LogLevel.warning, 'Incorrect value "${_textController.text}". The default value set.'));
        newValue = widget.defaultValue;
      }
    }

    if (DbModelUtils.simpleValuesAreEqual(newValue, widget.value)) //
      return;

    widget.onValueChanged(newValue);
  }
}
