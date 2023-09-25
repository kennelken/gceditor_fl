import 'package:darq/darq.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/history/history_dialog_item.dart';
import 'package:gceditor/components/waiting_overlay.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/main.dart';
import 'package:gceditor/model/db_network/history_item_data.dart';
import 'package:gceditor/model/db_network/history_item_data_entry.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_history_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/waiting_state.dart';
import 'package:gceditor/utils/components/selectable_list.dart';
import 'package:gceditor/utils/selection_list_controller.dart';

class HistoryDialog extends StatefulWidget {
  final HistoryItemData data;

  const HistoryDialog({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<HistoryDialog> {
  late SelectionListController _controller;
  late List<HistoryItemDataEntry> _items;

  @override
  void initState() {
    super.initState();
    _controller = SelectionListController();
    _controller.onChange.stream.listen((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    _items = widget.data.items!.reversed.toList();
    final viewModeState = providerContainer.read(clientViewModeStateProvider).state;

    return Consumer(builder: (context, ref, child) {
      final historyState = ref.watch(clientHistoryStateProvider).state;

      return Container(
        width: MediaQuery.of(popupContext!).size.width - 200,
        height: MediaQuery.of(popupContext!).size.height - 150,
        color: kTextColorLightest,
        child: WaitingOverlay(
          child: Column(
            children: [
              Container(
                alignment: Alignment.center,
                height: 50 * kScale,
                color: kColorAccentBlue2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Loc.get.historyDialogTitle(widget.data.id),
                      style: kStyle.kTextBig,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8.0 * kScale),
                  child: SelectableList(
                    controller: _controller,
                    builder: (context, isSelected, onClick) {
                      return ScrollConfiguration(
                        behavior: kScrollDraggable,
                        child: ListView.builder(
                          itemExtent: 35 * kScale,
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            return HistoryDialogItem(
                              key: ObjectKey(_items[index]),
                              data: _items[index],
                              selected: isSelected(index),
                              executionResult: historyState.getExecutionResult(_items[index]),
                              onClick: () => onClick(
                                index,
                                viewModeState.controlKey,
                                viewModeState.shiftKey,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                height: 50 * kScale,
                color: kColorAccentTeal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        Loc.get.historySelectedItems(_controller.selectedItems.length, _items.length),
                        style: kStyle.kTextRegular,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 20),
                    TextButton(
                      style: kButtonWhite,
                      onPressed: _handleExecuteClicked,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Text(
                          Loc.get.buttonExecute,
                          style: kStyle.kTextBig.copyWith(color: kColorPrimaryLighter, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _handleExecuteClicked() async {
    providerContainer.read(waitingStateProvider).toggleWaiting(this, true);
    await providerContainer
        .read(clientHistoryStateProvider)
        .requestHistoryExecute(_controller.selectedItems.toList().orderByDescending((e) => e).map((e) => _items[e]).toList());
    providerContainer.read(waitingStateProvider).toggleWaiting(this, false);
  }
}
