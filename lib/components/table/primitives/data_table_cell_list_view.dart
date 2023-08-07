import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/properties/primitives/delete_button.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';

import '../context_menu_button.dart';
import 'data_table_cell_view.dart';

class DataTableCellListView extends StatefulWidget {
  final DataTableValueCoordinates coordinates;
  final ClassFieldDescriptionDataInfo fieldType;
  final ClassFieldDescriptionDataInfo valueFieldType;
  final DataTableCellValue value;
  final DataTableSimpleCellFactory cellFactory;
  final ValueChanged<DataTableCellValue> onValueChanged;

  const DataTableCellListView({
    Key? key,
    required this.coordinates,
    required this.fieldType,
    required this.valueFieldType,
    required this.value,
    required this.cellFactory,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  State<DataTableCellListView> createState() => _DataTableCellListViewState();
}

class _DataTableCellListViewState extends State<DataTableCellListView> {
  late DataTableCellValue _cellValue;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _cellValue = widget.value.copy();
    _scrollController = ScrollController();

    providerContainer.read(clientRestoredProvider).addListener(_handleClientRestored);
    providerContainer.read(clientStateProvider).addListener(_handleClientStateChanged);
  }

  @override
  void deactivate() {
    super.deactivate();
    providerContainer.read(clientRestoredProvider).removeListener(_handleClientRestored);
    providerContainer.read(clientStateProvider).removeListener(_handleClientStateChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
    providerContainer.read(clientRestoredProvider).removeListener(_handleClientRestored);
    providerContainer.read(clientStateProvider).removeListener(_handleClientStateChanged);
  }

  void _handleClientRestored() {
    if (!DbModelUtils.valuesAreEqual(_cellValue, widget.value)) {
      setState(() {
        _cellValue = widget.value.copy();
      });
    }
  }

  void _handleClientStateChanged() {
    final value = DbModelUtils.getValueByCoordinates(clientModel, widget.coordinates);
    if (value == null) //
      return;
    final lastCommand = lastClientCommand;
    if ((lastCommand?.$type ?? DbCmdType.unknown) == DbCmdType.editClassField || //
        !DbModelUtils.valuesAreEqual(_cellValue, value)) {
      setState(() {
        _cellValue = value.copy();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: kTextColorLightHalfTransparent2,
          height: 22 * kScale,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 5 * kScale),
                  child: Text(
                    Loc.get.cellListSize(_cellValue.listCellValues!.length),
                    textAlign: TextAlign.left,
                    style: kStyle.kTextExtraSmall,
                  ),
                ),
              ),
              SizedBox(
                width: 36 * kScale,
                child: IconButtonTransparent(
                  icon: const IconPlus(),
                  onClick: _handleAddRow,
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: Theme(
            data: kStyle.kReorderableListThemeInvisibleScrollbars,
            child: ScrollConfiguration(
              behavior: kScrollDraggable,
              child: ReorderableListView.builder(
                scrollController: _scrollController,
                itemCount: _cellValue.listCellValues!.length,
                onReorder: _handleReorder,
                itemBuilder: (context, index) {
                  return Consumer(
                    key: ValueKey(index),
                    builder: (context, ref, child) {
                      return SizedBox(
                        height: kStyle.kDataTableInlineRowHeight,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4 * kScale, right: 26 * kScale),
                          child: Row(
                            children: [
                              Flexible(
                                flex: 0,
                                child: Text(
                                  '$index.',
                                  style: kStyle.kTextExtraSmallInactive,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: kStyle.kDataTableCellListBoxDecoration,
                                  child: widget.cellFactory(
                                    coordinates: widget.coordinates.copyWith(innerListRowIndex: index, innerListColumnIndex: 0),
                                    value: _cellValue.listCellValues![index],
                                    fieldInfo: widget.valueFieldType,
                                    onValueChanged: (value) => _handleValueChanged(index, value),
                                  ),
                                ),
                              ),
                              if (ref.watch(clientViewModeStateProvider).state.actionsMode) ...[
                                DeleteButton(
                                  onAction: () => _handleDeleteItem(index),
                                  size: 14 * kScale,
                                  width: 25 * kScale,
                                  color: kColorPrimaryLight,
                                  tooltipText: Loc.get.delete,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      _cellValue = DataTableCellValue.list(Utils.copyAndReorder(_cellValue.listCellValues!, oldIndex, newIndex));

      widget.onValueChanged(_cellValue);
    });
  }

  _handleDeleteItem(int index) {
    setState(() {
      final valuesListCopy = _cellValue.copy();
      valuesListCopy.listCellValues!.removeAt(index);
      _cellValue = valuesListCopy;

      widget.onValueChanged(_cellValue);
    });
  }

  void _handleAddRow() {
    setState(() {
      final valuesListCopy = _cellValue.copy();
      valuesListCopy.listCellValues!.add(DbModelUtils.getDefaultValue(widget.valueFieldType.type).simpleValue);
      _cellValue = valuesListCopy;

      _scrollController.animateTo(_scrollController.position.maxScrollExtent + 40,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);

      widget.onValueChanged(_cellValue);
    });
  }

  void _handleValueChanged(int index, dynamic value) {
    setState(() {
      final valuesListCopy = _cellValue.copy();
      valuesListCopy.listCellValues![index] = value;
      _cellValue = valuesListCopy;

      widget.onValueChanged(_cellValue);
    });
  }
}
