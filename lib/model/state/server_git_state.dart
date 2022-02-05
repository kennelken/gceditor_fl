import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db_network/commands_common.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/auth_list_state.dart';
import 'package:gceditor/model/state/server_history_state.dart';
import 'package:gceditor/model/state/server_state.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:git/git.dart';
import 'package:path/path.dart' as path;

final serverGitStateProvider = ChangeNotifierProvider((ref) {
  final notifier = ServerGitStateNotifier(ServerGitState());

/*   ref.read(serverStateProvider).addListener(() {
    notifier.refresh(); // in case the settings has been changed
  }); */

  return notifier;
});

class ServerGitState {
  final List<GitItem> items = [];

  bool isProcessing = false;

  bool hasAnyBranch() {
    return items.isNotEmpty;
  }
}

class ServerGitStateNotifier extends ChangeNotifier {
  ServerGitState state;

  ServerGitStateNotifier(this.state);

  Future refresh() async {
    return await _doAction(
      () async {
        final appState = providerContainer.read(appStateProvider).state;
        final authListState = providerContainer.read(authListStateProvider).state;
        final generatorsList = providerContainer.read(serverStateProvider).state.model.settings.generators;
        var historyState = providerContainer.read(serverHistoryStateProvider).state; // will be updated later

        final newState = ServerGitState();

        final projectDir = appState.projectFile!.parent.path;
        final authListDir = File(authListState.filePath!).parent.path;
        final outputDir = appState.output!.path;
        final historyDir = historyState.folderPath!;

        if (await GitDir.isGitDir(projectDir)) {
          final projectGit = await GitDir.fromExisting(projectDir, allowSubdirectory: true);
          final projectBranch = (await projectGit.currentBranch()).branchName;
          newState.items.add(GitItem(
            id: 'project',
            name: Loc.get.gitItemProject,
            gitDir: projectGit,
            relativePath: path.relative(appState.projectFile!.path, from: projectGit.path),
            branchName: projectBranch,
            type: GitItemType.project,
          ));
        }

        if (await GitDir.isGitDir(authListDir)) {
          final authListGit = await GitDir.fromExisting(authListDir, allowSubdirectory: true);
          final authListBranch = (await authListGit.currentBranch()).branchName;
          newState.items.add(GitItem(
            id: 'authList',
            name: Loc.get.gitItemAuthList,
            gitDir: authListGit,
            relativePath: path.relative(authListState.filePath!, from: authListGit.path),
            branchName: authListBranch,
            type: GitItemType.authList,
          ));
        }

        for (var i = 0; i < generatorsList!.length; i++) {
          final generator = generatorsList[i];
          final filePath = path.join(outputDir, '${generator.fileName}.${generator.fileExtension}');
          final fileDir = File(filePath).parent.path;

          if (await GitDir.isGitDir(fileDir)) {
            final fileGit = await GitDir.fromExisting(fileDir, allowSubdirectory: true);
            final fileBranch = (await fileGit.currentBranch()).branchName;
            newState.items.add(GitItem(
              id: 'g${generator.hashCode}',
              name: Loc.get.gitItemGenerator(describeEnum(generator.$type!), i),
              gitDir: fileGit,
              relativePath: path.relative(filePath, from: fileGit.path),
              branchName: fileBranch,
              type: GitItemType.generator,
            ));
          }
        }

        await providerContainer.read(serverHistoryStateProvider).waitForInitialization();
        historyState = providerContainer.read(serverHistoryStateProvider).state;
        final historyList = historyState.items;
        for (var i = 0; i < historyList.length; i++) {
          final historyFile = historyList[i];
          final filePath = path.join(historyDir, '${historyFile.id}.${Config.historyFileExtension}');
          final fileDir = File(filePath).parent.path;

          if (await GitDir.isGitDir(fileDir)) {
            final fileGit = await GitDir.fromExisting(fileDir, allowSubdirectory: true);
            final fileBranch = (await fileGit.currentBranch()).branchName;
            newState.items.add(GitItem(
              id: 'h${historyFile.id}',
              name: Loc.get.gitItemHistory(historyFile.id, i),
              gitDir: fileGit,
              relativePath: path.relative(filePath, from: fileGit.path),
              branchName: fileBranch,
              type: GitItemType.history,
            ));
          }
        }

        state = newState;
        return null;
      },
    );
  }

  Future<String?> doCommit(List<String> items, String requestor) async {
    return await _doAction(
      () async {
        final selectedItems = _getSelectedItemsByIds(items);
        if (selectedItems.length != items.length) //
          return 'Invalid selected items';

        final errors = <String>[];

        for (final item in selectedItems) {
          try {
            await item.gitDir.runCommand(['add', '.\\${item.relativePath}']);
            await item.gitDir.runCommand(['commit', '.\\${item.relativePath}', '-m', '$requestor via ${Config.appName}: saved "${item.name}"']);
          } catch (e) {
            errors.add(e.toString());
          }
        }

        if (errors.isNotEmpty) {
          errors.add('');
          return errors.join('\n\n\n');
        }
        return null;
      },
    );
  }

  Future<String?> doPush(List<String> items) async {
    return await _doAction(
      () async {
        final selectedItems = _getSelectedItemsByIds(items);
        if (selectedItems.length != items.length) //
          return 'Invalid selected items';

        final errors = <String>[];

        final allPathes = selectedItems.map((e) => path.normalize(e.gitDir.path)).toSet();

        for (final item in selectedItems) {
          if (!allPathes.contains(path.normalize(item.gitDir.path))) //
            continue;

          allPathes.remove(item.gitDir.path);
          try {
            await item.gitDir.runCommand(['push', '--all']);
          } catch (e) {
            errors.add(e.toString());
          }
        }

        if (errors.isNotEmpty) {
          errors.add('');
          return errors.join('\n\n\n');
        }
        return null;
      },
    );
  }

  Future<String?> doPull(List<String> items) async {
    return await _doAction(
      () async {
        final selectedItems = _getSelectedItemsByIds(items);
        if (selectedItems.length != items.length) //
          return 'Invalid selected items';

        final errors = <String>[];

        final allPathes = selectedItems.map((e) => path.normalize(e.gitDir.path)).toSet();

        for (final item in selectedItems) {
          if (!allPathes.contains(path.normalize(item.gitDir.path))) //
            continue;

          allPathes.remove(item.gitDir.path);
          try {
            await item.gitDir.runCommand(['pull']);
          } catch (e) {
            errors.add(e.toString());
          }
        }

        if (errors.isNotEmpty) {
          errors.add('');
          return errors.join('\n\n\n');
        }
        return null;
      },
    );
  }

  void clear({bool silent = false}) {
    state.items.clear();

    if (!silent) //
      notifyListeners();
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

  List<GitItem> _getSelectedItemsByIds(List<String> ids) {
    return ids.map((id) => state.items.firstWhere((i) => i.id == id)).toList();
  }
}

class GitItem {
  final String id;
  final String name;
  final GitDir gitDir;
  final String branchName;
  final String relativePath;
  final GitItemType type;

  GitItem({
    required this.id,
    required this.name,
    required this.gitDir,
    required this.branchName,
    required this.relativePath,
    required this.type,
  });
}
