import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:darq/darq.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:gceditor/model/db_network/history_item_data.dart';
import 'package:gceditor/model/db_network/history_item_data_entry.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:path/path.dart' as path;

final serverHistoryStateProvider = ChangeNotifierProvider((ref) {
  final notifier = ServerHistoryStateNotifier(ServerHistoryState());

/*   ref.read(serverStateProvider).addListener(() {
    notifier.refresh(null); // in case the settings has been changed
  }); */

  return notifier;
});

class ServerHistoryState {
  String? folderPath;
  String? currentTag;
  File? _currentHistoryFile;

  final List<HistoryItemData> items = [];
  HistoryItemData? currentItem;

  bool isProcessing = false;

  bool hasAnyBranch() {
    return items.isNotEmpty || currentTag != null;
  }

  ServerHistoryState copyMainFields() {
    return ServerHistoryState()
      ..folderPath = folderPath
      ..currentTag = currentTag
      .._currentHistoryFile = _currentHistoryFile
      ..isProcessing = isProcessing;
  }
}

class ServerHistoryStateNotifier extends ChangeNotifier {
  ServerHistoryState state;

  ServerHistoryStateNotifier(this.state);

  Future refresh(Set<String>? detailedTags) async {
    return await _doAction(
      () async {
        if (state.folderPath?.isEmpty ?? true) //
          return;

        await _updateCurrentItemIfRequired(false);

        final newState = state.copyMainFields();

        final directory = Directory(newState.folderPath!);
        if (await directory.exists()) {
          const fileExtension = '.${Config.historyFileExtension}';

          var allFiles = (await directory.list().toList()).whereType<File>().where((e) => path.extension(e.path) == fileExtension).toList();

          final lastModificationDate = {for (var f in allFiles) f: await f.lastModified()};

          allFiles = allFiles
              .orderBy((e) => _isCurrentTag(e) ? 0 : 1) //
              .thenBy((e) => lastModificationDate[e]!)
              .toList();

          for (final file in allFiles) {
            final item = HistoryItemData.values(id: path.basenameWithoutExtension(file.path), items: null);
            newState.items.add(item);

            if (item.id == newState.currentTag) //
              newState.currentItem = item;

            if ((detailedTags?.contains(item.id) ?? false)) {
              item.items = await _readHistoryFromFile(file);
            } else {
              final oldItem = state.items.firstWhereOrNull((e) => e.id == item.id);
              item.items = oldItem?.items?.toList();
            }
          }
        } else {
          await directory.create(recursive: true);
        }

        if (newState.currentItem == null && (newState.currentTag?.isNotEmpty ?? false)) {
          final item = HistoryItemData.values(id: newState.currentTag!, items: null);
          newState.currentItem = item;
          newState.items.add(newState.currentItem!);
        }

        state = newState;

        await _updateCurrentItemIfRequired(false);
        return null;
      },
    );
  }

  void clear({bool silent = false}) {
    state.items.clear();

    if (!silent) //
      notifyListeners();
  }

  void setPath(String path) {
    if (state.folderPath == path) //
      return;

    state.folderPath = path;
    _updateCurrentHistoryFile();
  }

  void setTag(String tag) {
    if (state.currentTag == tag) //
      return;

    state.currentTag = tag;
    _updateCurrentHistoryFile();
  }

  void _updateCurrentHistoryFile() {
    state._currentHistoryFile = (state.currentTag?.isEmpty ?? true) || state.folderPath == null
        ? null
        : File(
            path.join(
              state.folderPath!,
              '${state.currentTag}.${Config.historyFileExtension}',
            ),
          );
    state.currentItem = null;
    notifyListeners();
  }

  void putIntoHistory(BaseDbCmd cmd, String user) async {
    await _doAction(
      () async {
        await _updateCurrentItemIfRequired(false);
        if (state.currentItem == null) //
          return;

        final newEntry = HistoryItemDataEntry.values(id: cmd.id, command: cmd, time: DateTime.now().toUtc(), user: user);
        await state._currentHistoryFile!.writeAsString('${Config.streamJsonOptions.convert(newEntry.toJson())}\n', mode: FileMode.append);
        return null;
      },
    );
  }

  Future waitForInitialization() async {
    await Utils.waitWhile(() => state.isProcessing);
    if (state.currentItem == null) //
      await refresh(null);
  }

  Future _updateCurrentItemIfRequired([bool readFile = true]) async {
    state.currentItem ??= state.items.firstWhereOrNull((e) => e.id == state.currentTag);
    if (state.currentItem == null) //
      return;

    if (state.currentItem!.items == null) {
      if (!(await state._currentHistoryFile!.exists())) //
        await state._currentHistoryFile!.create(recursive: true);

      if (readFile) {
        final newList = await _readHistoryFromFile(state._currentHistoryFile!);
        state.currentItem!.items = newList;
      }
    }
  }

  Future<List<HistoryItemDataEntry>> _readHistoryFromFile(File file) async {
    final result = <HistoryItemDataEntry>[];

    if (await file.exists()) {
      final fileContent = (await file.readAsString()).trimRight();
      for (final line in LineSplitter.split(fileContent)) {
        result.add(HistoryItemDataEntry.fromJson(jsonDecode(line)));
      }
    }

    return result;
  }

  Future<String?> _doAction(Future<String?> Function() action) async {
    await Utils.waitWhile(() => state.isProcessing);
    state.isProcessing = true;
    notifyListeners();

    final result = await action();

    state.isProcessing = false;
    notifyListeners();

    return result;
  }

  bool _isCurrentTag(File file) {
    return path.basenameWithoutExtension(file.path) == state.currentTag;
  }
}
