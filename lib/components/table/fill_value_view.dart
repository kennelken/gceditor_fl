import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/main.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_network/data_table_column.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/style_state.dart';

import '../../model/db/data_table_cell_value.dart';
import '../../model/db_cmd/db_cmd_fill_column.dart';
import '../../model/state/log_state.dart';
import '../properties/primitives/info_button.dart';

class FillValueView extends StatefulWidget {
  final ClassMetaFieldDescription field;
  final TableMetaEntity table;

  const FillValueView({
    Key? key,
    required this.field,
    required this.table,
  }) : super(key: key);

  @override
  State<FillValueView> createState() => _FillValueViewState();
}

class _FillValueViewState extends State<FillValueView> {
  late final TextEditingController _valueController;
  bool _isValidValue = false;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.field.defaultValue);
    _valueController.addListener(_handleValueChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _valueController.removeListener(_handleValueChanged);
    _valueController.dispose();
  }

  @override
  Widget build(context) {
    return Consumer(builder: (context, ref, child) {
      ref.watch(styleStateProvider);
      _isValidValue = _parseCurrentValue() != null;

      return Container(
        width: 500 * kScale,
        height: 170 * kScale,
        color: kTextColorLightest,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              alignment: Alignment.center,
              height: 50 * kScale,
              color: kColorAccentBlue2,
              child: Text(
                Loc.get.fillColumnLabel(widget.field.id),
                style: kStyle.kTextSmall,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20 * kScale),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            controller: _valueController,
                            decoration: _isValidValue ? kStyle.kInputTextStyleSettingsProperties : kStyle.kInputTextStyleWarning,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 10 * kScale),
                        InfoButton(
                          text: Loc.get.defaultFieldInfo,
                          color: kColorAccentBlue2,
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * kScale),
                    TextButton(
                      style: kButtonWhite,
                      onPressed: () => _handleExecuteClicked(_valueController.text),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Text(
                          Loc.get.buttonExecute,
                          style: kStyle.kTextBig.copyWith(color: kColorPrimaryLighter, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _handleExecuteClicked(String value) {
    final parsedValue = _parseCurrentValue();
    if (parsedValue == null) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Invalid value was specified'));
      return;
    }

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdFillColumn.values(
            dataColumnsByTable: {
              widget.table.id: [DataTableColumn.data(widget.field.id, widget.table.rows.map((e) => parsedValue).toList())]
            },
          ),
        );
    Navigator.pop(popupContext!);
  }

  void _handleValueChanged() {
    final newValidValue = _parseCurrentValue() != null;

    if (newValidValue != _isValidValue) {
      setState(() => {});
    }
  }

  DataTableCellValue? _parseCurrentValue() {
    return DbModelUtils.parseDefaultValueByField(widget.field, _valueController.text, silent: true);
  }
}
