import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/properties/primitives/delete_button.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_field_description_data_info.dart';
import 'package:gceditor/model/db/data_table_cell_dictionary_item.dart';
import 'package:gceditor/model/db/data_table_cell_value.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:gceditor/model/db_cmd/db_cmd_resize_inner_cell.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';

import '../context_menu_button.dart';
import 'data_table_cell_view.dart';

List<double>? _initialInnerCellFlex;

class DataTableCellDictionaryView extends StatefulWidget {
  final DataTableValueCoordinates coordinates;
  final ClassFieldDescriptionDataInfo fieldType;
  final ClassFieldDescriptionDataInfo keyFieldType;
  final ClassFieldDescriptionDataInfo valueFieldType;
  final DataTableCellValue value;
  final DataTableSimpleCellFactory cellFactory;
  final ValueChanged<DataTableCellValue> onValueChanged;

  const DataTableCellDictionaryView({
    super.key,
    required this.coordinates,
    required this.fieldType,
    required this.keyFieldType,
    required this.valueFieldType,
    required this.value,
    required this.cellFactory,
    required this.onValueChanged,
  });

  @override
  State<DataTableCellDictionaryView> createState() => _DataTableCellDictionaryViewState();
}

class _DataTableCellDictionaryViewState extends State<DataTableCellDictionaryView> {
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
  Widget build(BuildContext cellContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: kTextColorLightHalfTransparent2,
          height: 22 * kScale,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 5 * kScale),
                  child: Text(
                    Loc.get.cellListSize(_cellValue.listCellValues?.length ?? 0),
                    textAlign: TextAlign.left,
                    style: kStyle.kTextExtraSmall,
                  ),
                ),
              ),
              SizedBox(
                width: 36 * kScale,
                child: IconButtonTransparent(
                  size: 35 * kScale,
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
              child: Consumer(
                builder: (context, ref, child) {
                  ref.watch(columnSizeChangedProvider);
                  return ReorderableListView.builder(
                    scrollController: _scrollController,
                    itemCount: _cellValue.listCellValues?.length ?? 0,
                    onReorder: _handleReorder,
                    itemBuilder: (context, index) {
                      final value = _cellValue.listCellValues![index] as DataTableCellDictionaryItem;
                      final key = '${index}_${value.key}_${value.value}';
                      final innerCellsFlex = DbModelUtils.getTableInnerCellsFlex(clientModel, widget.coordinates.table, widget.coordinates.field!);

                      return SizedBox(
                        key: ValueKey(key),
                        height: kStyle.kDataTableInlineRowHeight,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4 * kScale, right: 29 * kScale),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                flex: 0,
                                child: Text(
                                  '$index.',
                                  style: kStyle.kTextExtraSmallInactive,
                                ),
                              ),
                              Expanded(
                                flex: (innerCellsFlex[0] * Config.flexRatioMultiplier).toInt(),
                                child: Container(
                                  decoration: kStyle.kDataTableCellListBoxDecoration,
                                  child: widget.cellFactory(
                                    coordinates: widget.coordinates.copyWith(innerListRowIndex: index, innerListColumnIndex: 0),
                                    value: value.key,
                                    fieldInfo: widget.keyFieldType,
                                    onValueChanged: (value) => _handleKeyChanged(index, value),
                                  ),
                                ),
                              ),
                              MouseRegion(
                                cursor: SystemMouseCursors.resizeColumn,
                                child: GestureDetector(
                                  onHorizontalDragUpdate: (d) => _handleHorizontalDragUpdate(cellContext, d),
                                  onHorizontalDragEnd: _handleHorizontalDragEnd,
                                  onHorizontalDragStart: _handleHorizontalDragStart,
                                  child: Container(
                                    width: kDividerLineWidth,
                                    color: kColorTransparent,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: (innerCellsFlex[1] * Config.flexRatioMultiplier).toInt(),
                                child: Container(
                                  decoration: kStyle.kDataTableCellListBoxDecoration,
                                  child: widget.cellFactory(
                                    coordinates: widget.coordinates.copyWith(innerListRowIndex: index, innerListColumnIndex: 1),
                                    value: value.value,
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
    setState(
      () {
        _cellValue = DataTableCellValue.dictionary(Utils.copyAndReorder(_cellValue.copy().dictionaryCellValues()!, oldIndex, newIndex));

        widget.onValueChanged(_cellValue);
      },
    );
  }

  _handleDeleteItem(int index) {
    setState(
      () {
        final valuesListCopy = _cellValue.copy();
        valuesListCopy.listCellValues!.removeAt(index);
        _cellValue = valuesListCopy;

        widget.onValueChanged(valuesListCopy);
      },
    );
  }

  void _handleAddRow() {
    setState(
      () {
        final valuesListCopy = _cellValue.copy();
        valuesListCopy.listCellValues!.add(
          DataTableCellDictionaryItem.values(
            key: DbModelUtils.getDefaultValue(widget.keyFieldType.type).simpleValue,
            value: DbModelUtils.getDefaultValue(widget.valueFieldType.type).simpleValue,
          ),
        );
        _cellValue = valuesListCopy;

        _scrollController.animateTo(_scrollController.position.maxScrollExtent + 40,
            duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);

        widget.onValueChanged(valuesListCopy);
      },
    );
  }

  void _handleKeyChanged(int index, dynamic value) {
    setState(
      () {
        final valuesListCopy = _cellValue.copy();
        valuesListCopy.listCellValues![index].key = value;
        _cellValue = valuesListCopy;

        widget.onValueChanged(_cellValue);
      },
    );
  }

  void _handleValueChanged(int index, dynamic value) {
    setState(
      () {
        final valuesListCopy = _cellValue.copy();
        (valuesListCopy.listCellValues![index] as DataTableCellDictionaryItem).value = value;
        _cellValue = valuesListCopy;

        widget.onValueChanged(_cellValue);
      },
    );
  }

  void _handleHorizontalDragUpdate(BuildContext context, DragUpdateDetails details) {
    if (details.delta.dx == 0.0) //
      return;

    final relDelta = details.delta.dx / context.size!.width;

    DbModelUtils.setInnerCellColumnFlex(
      clientModel,
      widget.coordinates.table,
      widget.coordinates.field!,
      deltaRatio: [relDelta, -relDelta],
    );
    providerContainer.read(columnSizeChangedProvider).dispatchEvent();
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _initialInnerCellFlex = DbModelUtils.getTableInnerCellsFlex(clientModel, widget.coordinates.table, widget.coordinates.field!);
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_initialInnerCellFlex != null &&
        _initialInnerCellFlex != DbModelUtils.getTableInnerCellsFlex(clientModel, widget.coordinates.table, widget.coordinates.field!)) {
      providerContainer.read(clientOwnCommandsStateProvider).addCommand(
            DbCmdResizeInnerCell.values(
              tableId: widget.coordinates.table.id,
              fieldId: widget.coordinates.field!.id,
              flexes: DbModelUtils.getTableInnerCellsFlex(clientModel, widget.coordinates.table, widget.coordinates.field!),
              oldFlexes: _initialInnerCellFlex!,
            ),
          );
    }

    _initialInnerCellFlex = null;
  }
}
