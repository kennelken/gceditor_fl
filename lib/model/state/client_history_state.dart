import 'package:collection/collection.dart';
import 'package:darq/darq.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/global_shortcuts.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db_network/command_request_history_execute_payload.dart';
import 'package:gceditor/model/db_network/command_request_history_payload.dart';
import 'package:gceditor/model/db_network/command_request_history_response_payload.dart';
import 'package:gceditor/model/db_network/history_item_data.dart';
import 'package:gceditor/model/db_network/history_item_data_entry.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';

final clientHistoryStateProvider = ChangeNotifierProvider((ref) {
  final notifier = ClientHistoryStateNotifier(ClientHistoryState());

/*   ref.read(clientStateProvider).addListener(() {
    notifier.refresh();
  }); */

  return notifier;
});

class ClientHistoryState {
  List<HistoryItemData> items = [];
  String? currentTag;
  HistoryItemData? selectedItem;

  final _historyItemJson = <HistoryItemDataEntry, String>{};
  final _executionResult = <HistoryItemDataEntry, bool>{};

  bool isProcessing = false;

  bool hasAnyHistory() {
    return items.isNotEmpty;
  }

  String getEntryString(HistoryItemDataEntry entry) {
    if (!_historyItemJson.containsKey(entry)) {
      _historyItemJson[entry] = Config.historyViewJsonOptions.convert(entry.command.toJson());
    }
    return _historyItemJson[entry]!;
  }

  bool? getExecutionResult(HistoryItemDataEntry entry) {
    return _executionResult[entry];
  }
}

class ClientHistoryStateNotifier extends ChangeNotifier {
  ClientHistoryState state;

  ClientHistoryStateNotifier(this.state);

  void refresh() async {
    await _doAction(
      () async {
        final payload = await providerContainer.read(appStateProvider).state.clientApp!.requestHistory(
              CommandRequestHistoryPayload.values(refresh: true),
            );
        _updateByPayload(payload);
      },
    );
  }

  void toggleSelection(HistoryItemData item) async {
    await _doAction(
      () async {
        state.selectedItem = item;
        final payload = await providerContainer.read(appStateProvider).state.clientApp!.requestHistory(
              CommandRequestHistoryPayload.values(refresh: true, items: [item.id]),
            );
        _updateByPayload(payload);

        GlobalShortcuts.openHistory(state.selectedItem!);
      },
    );
  }

  Future _doAction(Future Function() action) async {
    if (state.isProcessing) //
      return;
    state.isProcessing = true;
    notifyListeners();

    await action();

    state.isProcessing = false;
    notifyListeners();
  }

  void _updateByPayload(CommandRequestHistoryResponsePayload? payload) {
    if (payload == null) //
      return;

    state.items = payload.items!;
    state.currentTag = payload.currentTag;
    state.selectedItem = state.items.firstWhereOrNull((e) => e.id == state.selectedItem?.id);
    state._historyItemJson.clear();
  }

  Future requestHistoryExecute(List<HistoryItemDataEntry> items) async {
    if (items.isEmpty) //
      return;

    items = items.orderBy((i) => i.time).toList();

    final response = await providerContainer.read(appStateProvider).state.clientApp!.requestHistoryExecute(
          CommandRequestHistoryExecutePayload.values(items: items),
        );

    if (response == null) //
      return;

    for (var i = 0; i < response.results!.length; i++) {
      final result = i >= response.results!.length ? null : response.results![i];
      if (result == null) //
        state._executionResult.remove(items[i]);
      else
        state._executionResult[items[i]] = result;
    }

    notifyListeners();
  }
}
