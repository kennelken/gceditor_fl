import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/model/db_network/command_request_git_payload.dart';
import 'package:gceditor/model/db_network/command_request_git_response_payload.dart';
import 'package:gceditor/model/db_network/get_item_data.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';

final clientGitStateProvider = ChangeNotifierProvider((ref) {
  final notifier = ClientGitStateNotifier(ClientGitState());

/*   ref.read(clientStateProvider).addListener(() {
    notifier.refresh();
  }); */

  return notifier;
});

class ClientGitState {
  List<GitItemData> items = [];
  Set<String> selectedItems = {};

  bool isProcessing = false;

  bool hasAnyBranch() {
    return items.isNotEmpty;
  }
}

class ClientGitStateNotifier extends ChangeNotifier {
  ClientGitState state;

  ClientGitStateNotifier(this.state);

  Future refresh() async {
    await _doAction(
      () async {
        final payload = await providerContainer.read(appStateProvider).state.clientApp!.requestGit(
              CommandRequestGitPayload.values(refresh: true),
            );
        _updateByPayload(payload);
      },
    );
  }

  Future doCommit() async {
    await _doAction(() async {
      final payload = await providerContainer.read(appStateProvider).state.clientApp!.requestGit(
            CommandRequestGitPayload.values(
              commit: true,
              items: state.selectedItems.toList(),
            ),
          );
      _updateByPayload(payload);
    });
  }

  Future doPush() async {
    await _doAction(() async {
      final payload = await providerContainer.read(appStateProvider).state.clientApp!.requestGit(
            CommandRequestGitPayload.values(
              push: true,
              items: state.selectedItems.toList(),
            ),
          );
      _updateByPayload(payload);
    });
  }

  Future doPull() async {
    await _doAction(() async {
      final payload = await providerContainer.read(appStateProvider).state.clientApp!.requestGit(
            CommandRequestGitPayload.values(
              pull: true,
              items: state.selectedItems.toList(),
            ),
          );
      _updateByPayload(payload);
    });
  }

  void toggleSelection(GitItemData item, {bool? value}) {
    final selected = value ?? !state.selectedItems.contains(item.id);
    if (selected)
      state.selectedItems.add(item.id);
    else
      state.selectedItems.remove(item.id);
    notifyListeners();
  }

  void clear({bool silent = false}) {
    state.items.clear();

    if (!silent) //
      notifyListeners();
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

  void _updateSelectedItems() {
    for (final id in state.selectedItems.toList()) {
      if (!state.items.any((e) => e.id == id)) state.selectedItems.remove(id);
    }
  }

  void _updateByPayload(CommandRequestGitResponsePayload? payload) {
    if (payload == null) //
      return;

    state.items = payload.items!;
    _updateSelectedItems();
  }
}
