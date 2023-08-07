import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:darq/darq.dart';
import 'package:dartx/dartx_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/delete_button.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/table/context_menu_button.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db_cmd/db_cmd_copypaste.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/service/client_data_selection_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';
import 'package:gceditor/utils/components/conditional_wrapper.dart';

import '../tooltip_wrapper.dart';

class DataSelectionPanel extends StatefulWidget {
  const DataSelectionPanel({
    Key? key,
  }) : super(key: key);

  @override
  State<DataSelectionPanel> createState() => _DataSelectionPanelState();
}

class _DataSelectionPanelState extends State<DataSelectionPanel> {
  late final ScrollController _scrollController;
  late final CustomPopupMenuController _pastePopupController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pastePopupController = CustomPopupMenuController();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _pastePopupController.dispose();
  }

  @override
  Widget build(context) {
    return Consumer(
      builder: (context, ref, child) {
        final dataSelection = ref.watch(clientDataSelectionStateProvider);

        return Container(
          height: 40 * kScale,
          color: kColorPrimaryDarker,
          child: Padding(
            padding: EdgeInsets.only(left: 7 * kScale, top: 3 * kScale, right: 3 * kScale, bottom: 3 * kScale),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  Loc.get.dataSelectionCount(dataSelection.state.selectedItems.length),
                  style: kStyle.kTextSmall,
                ),
                const Expanded(child: SizedBox()),
                if ((dataSelection.state.copiedItems?.length ?? 0) > 0) ...[
                  Builder(builder: (context) {
                    final loc = dataSelection.state.cut ? Loc.get.dataCutCount : Loc.get.dataCopiedCount;
                    return Text(
                      loc(dataSelection.state.copiedItems!.length, dataSelection.state.copiedItemsTable!.id),
                      style: kStyle.kTextExtraSmallInactive,
                    );
                  }),
                  _horizontalSpace(),
                ],
                if (dataSelection.state.externalCopiedItems != null) ...[
                  Builder(builder: (context) {
                    return Text(
                      Loc.get.dataCopiedExternalCount(dataSelection.state.externalCopiedItems!.length),
                      style: kStyle.kTextExtraSmallInactive,
                    );
                  }),
                  _horizontalSpace(),
                ],
                TooltipWrapper(
                  message: Loc.get.fromClipboard,
                  child: IconButtonTransparent(
                    enabled: _isCopyFromClipboardAvailable,
                    icon: Icon(
                      FontAwesomeIcons.fileImport,
                      color: kColorAccentBlue.withAlpha(_isCopyFromClipboardAvailable ? kIconActiveAlpha : kIconInactiveAlpha),
                      size: 17 * kScale,
                    ),
                    onClick: _handleCopyFromClipboardClick,
                  ),
                ),
                TooltipWrapper(
                  message: Loc.get.copy,
                  child: IconButtonTransparent(
                    enabled: _isCopyAvailable,
                    icon: Icon(
                      FontAwesomeIcons.copy,
                      color: kColorAccentBlue.withAlpha(_isCopyAvailable ? kIconActiveAlpha : kIconInactiveAlpha),
                      size: 17 * kScale,
                    ),
                    onClick: _handleCopyClick,
                  ),
                ),
                TooltipWrapper(
                  message: Loc.get.cut,
                  child: IconButtonTransparent(
                    icon: Icon(
                      FontAwesomeIcons.scissors,
                      color: kColorAccentOrange.withAlpha(_isCopyAvailable ? kIconActiveAlpha : kIconInactiveAlpha),
                      size: 17 * kScale,
                    ),
                    onClick: _handleCutClick,
                  ),
                ),
                _horizontalSpace(),
                TooltipWrapper(
                  message: Loc.get.paste,
                  child: ConditionalWrapper(
                    enabled: !_isPasteAvailable,
                    wrapperBuilder: (c) => IgnorePointer(
                      child: c,
                    ),
                    child: ContextMenuButton(
                      controller: _pastePopupController,
                      icon: Icon(
                        FontAwesomeIcons.paste,
                        color: kColorAccentBlue.withAlpha(_isPasteAvailable ? kIconActiveAlpha : kIconInactiveAlpha),
                        size: 17 * kScale,
                      ),
                      buttons: [
                        ContextMenuChildButtonData(Loc.get.before, _handlePasteBefore),
                        ContextMenuChildButtonData(Loc.get.after, _handlePasteAfter),
                        if (_isReplaceAvailable) //
                          ContextMenuChildButtonData(Loc.get.replace, _handlePasteReplace),
                      ],
                    ),
                  ),
                ),
                DeleteButton(
                  color: kColorAccentRed.withAlpha(_isDeleteAvailable ? kIconActiveAlpha : kIconInactiveAlpha),
                  size: 18,
                  onAction: _handleDeleteClick,
                  tooltipText: Loc.get.delete,
                ),
                _horizontalSpace(),
                TooltipWrapper(
                  message: Loc.get.deselect,
                  child: IconButtonTransparent(
                    icon: Icon(
                      FontAwesomeIcons.xmark,
                      color: kColorPrimaryLight,
                      size: 20 * kScale,
                    ),
                    onClick: () => dataSelectionState.clear(true),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SizedBox _horizontalSpace() => SizedBox(width: 13 * kScale);

  void _handleCopyClick() {
    if (!_isCopyAvailable) //
      return;
    dataSelectionState.copySelected(cut: false);
  }

  void _handleCutClick() {
    if (!_isCopyAvailable) //
      return;
    dataSelectionState.copySelected(cut: true);
  }

  void _handlePasteBefore() {
    if (!_isPasteAvailable) //
      return;

    final toTable = dataSelectionState.state.selectionTable ?? providerContainer.read(tableSelectionStateProvider).state.selectedTable;
    final firstSelectedIndex = dataSelectionState.state.selectedItems.orderBy((e) => e).firstOrNull ?? 0;

    final toIndices = IntRange(
      firstSelectedIndex,
      firstSelectedIndex + (dataSelectionState.state.copiedItems ?? dataSelectionState.state.externalCopiedItems)!.length - 1,
    ).toList();

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
      DbCmdCopyPaste.values(
        fromTableId: dataSelectionState.state.copiedItemsTable?.id,
        fromValues: dataSelectionState.state.externalCopiedItems,
        fromColumns: dataSelectionState.state.externalCopiedColumns,
        toTableId: toTable?.id,
        fromIndices: dataSelectionState.state.copiedItems?.map((e) => dataSelectionState.state.copiedItemsTable!.rows.indexOf(e)).toList(),
        toIndices: toIndices,
        cut: dataSelectionState.state.cut,
      ).prepareCommand(clientModel),
      onSuccess: () {
        providerContainer.read(clientDataSelectionStateProvider).clear(true);
        providerContainer.read(clientDataSelectionStateProvider).selectMany(toTable!, toIndices);
      },
    );

    providerContainer.read(clientDataSelectionStateProvider).clear(true);
  }

  void _handlePasteAfter() {
    if (!_isPasteAvailable) //
      return;

    final toTable = dataSelectionState.state.selectionTable ?? providerContainer.read(tableSelectionStateProvider).state.selectedTable;
    final lastSelectedIndex = dataSelectionState.state.selectedItems.orderBy((e) => e).lastOrNull ?? toTable!.rows.length - 1;

    final toIndices = IntRange(
      lastSelectedIndex + 1,
      lastSelectedIndex + 1 + (dataSelectionState.state.copiedItems ?? dataSelectionState.state.externalCopiedItems)!.length - 1,
    ).toList();

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
      DbCmdCopyPaste.values(
        fromTableId: dataSelectionState.state.copiedItemsTable?.id,
        fromValues: dataSelectionState.state.externalCopiedItems,
        fromColumns: dataSelectionState.state.externalCopiedColumns,
        toTableId: toTable?.id,
        fromIndices: dataSelectionState.state.copiedItems?.map((e) => dataSelectionState.state.copiedItemsTable!.rows.indexOf(e)).toList(),
        toIndices: toIndices,
        cut: dataSelectionState.state.cut,
      ).prepareCommand(clientModel),
      onSuccess: () {
        providerContainer.read(clientDataSelectionStateProvider).clear(true);
        providerContainer.read(clientDataSelectionStateProvider).selectMany(toTable!, toIndices);
      },
    );
  }

  void _handlePasteReplace() {
    if (!_isPasteAvailable) //
      return;

    final toTable = dataSelectionState.state.selectionTable ?? providerContainer.read(tableSelectionStateProvider).state.selectedTable;
    final toIndices = dataSelectionState.state.selectedItems.orderBy((e) => e).toList();

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
      DbCmdCopyPaste.values(
        fromValues: dataSelectionState.state.externalCopiedItems,
        fromColumns: dataSelectionState.state.externalCopiedColumns,
        fromTableId: dataSelectionState.state.copiedItemsTable?.id,
        toTableId: toTable?.id,
        fromIndices: dataSelectionState.state.copiedItems?.map((e) => dataSelectionState.state.copiedItemsTable!.rows.indexOf(e)).toList(),
        toIndices: toIndices,
        cut: dataSelectionState.state.cut,
        replace: true,
      ).prepareCommand(clientModel),
      onSuccess: () {
        providerContainer.read(clientDataSelectionStateProvider).clear(true);
        providerContainer.read(clientDataSelectionStateProvider).selectMany(toTable!, toIndices);
      },
    );

    providerContainer.read(clientDataSelectionStateProvider).clear(true);
  }

  void _handleDeleteClick() {
    if (!_isDeleteAvailable) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdCopyPaste.values(
            fromTableId: dataSelectionState.state.selectionTable!.id,
            toTableId: null,
            fromIndices: dataSelectionState.state.selectedItems.orderBy((e) => e).toList(),
            toIndices: null,
            delete: true,
          ).prepareCommand(clientModel),
        );

    providerContainer.read(clientDataSelectionStateProvider).clear(true);
  }

  ClientDataSelectionStateNotifier get dataSelectionState => providerContainer.read(clientDataSelectionStateProvider);

  bool get _isCopyAvailable => dataSelectionState.state.selectedItems.isNotEmpty;
  bool get _isCopyFromClipboardAvailable => true;
  bool get _isPasteAvailable =>
      (dataSelectionState.state.copiedItems?.isNotEmpty ?? false) || (dataSelectionState.state.externalCopiedItems?.isNotEmpty ?? false);
  bool get _isReplaceAvailable =>
      (dataSelectionState.state.selectedItems.isNotEmpty &&
          !listEquals(
            dataSelectionState.state.copiedItems,
            dataSelectionState.state.selectedItems.map((e) => dataSelectionState.state.selectionTable?.rows[e]).toList(),
          )) ||
      (dataSelectionState.state.externalCopiedItems?.isNotEmpty ?? false);
  bool get _isDeleteAvailable => dataSelectionState.state.selectedItems.isNotEmpty;

  void _handleCopyFromClipboardClick() async {
    final clipboardText = await Clipboard.getData(Clipboard.kTextPlain);

    if (clipboardText?.text?.isNullOrEmpty ?? true) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Clipboard text is empty'));
      return;
    }

    final rows = clipboardText!.text!.split(ClientDataSelectionStateNotifier.rowsDelimiterPattern);
    if (rows.length < 2) {
      providerContainer
          .read(logStateProvider)
          .addMessage(LogEntry(LogLevel.error, 'At least two rows are supposed to be selected (one for column names, and all the others are data)'));
      return;
    }

    List<String>? columns;
    final values = <List<String>>[];

    int? columnsCount;
    for (var i = 0; i < rows.length; i++) {
      final rowData = rows[i].split(ClientDataSelectionStateNotifier.csvDelimiter);
      if (i == 0) {
        columnsCount = rowData.length;
        if (columnsCount < 1) {
          providerContainer
              .read(logStateProvider)
              .addMessage(LogEntry(LogLevel.error, 'At least one column expected ("${ClientDataSelectionStateNotifier.idColumnName}")'));
          return;
        }

        if (rowData[0] != ClientDataSelectionStateNotifier.idColumnName) {
          providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error,
              'The first row should contain columns names and the first column name "${ClientDataSelectionStateNotifier.idColumnName}"'));
          return;
        }

        columns = rowData.skip(1).toList();
        continue;
      }

      if (rowData.length != columnsCount) {
        providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Data row length varies from columns count'));
        return;
      }

      values.add(rowData);
    }

    providerContainer.read(clientDataSelectionStateProvider).copyExternal(columns: columns!, values: values);
  }
}
