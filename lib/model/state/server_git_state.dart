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

        final projectFile = File(await _resolvePath(appState.projectFile!.path));
        final projectDir = projectFile.parent.path;
        final authListFile = File(await _resolvePath(authListState.filePath!));
        final authListDir = authListFile.parent.path;
        final outputDir = appState.output!.path;
        final historyDir = historyState.folderPath!;

        Future<bool> checkIsModified(GitDir gitDir, String relativePath) async {
          try {
            final pr = await gitDir.runCommand(['status', '--porcelain', relativePath]);
            final out = (pr.stdout as String).trim();
            return out.isNotEmpty;
          } catch (_) {
            return false;
          }
        }

        Future<bool> checkIsUnpushed(GitDir gitDir, String relativePath) async {
          final normalizedPath = relativePath.replaceAll('\\', '/');
          try {
            final pr = await gitDir.runCommand(['log', '@{u}..HEAD', '--name-only', '--format=']);
            final out = (pr.stdout as String).trim();
            final files = out.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty);
            return files.any((e) => e == normalizedPath || normalizedPath.startsWith('$e/'));
          } catch (_) {
            try {
              final pr = await gitDir.runCommand(['log', '--branches', '--not', '--remotes', '--name-only', '--format=']);
              final out = (pr.stdout as String).trim();
              final files = out.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty);
              return files.any((e) => e == normalizedPath || normalizedPath.startsWith('$e/'));
            } catch (_) {
              return false;
            }
          }
        }

        Future<bool> checkIsUnpulled(GitDir gitDir, String relativePath) async {
          final normalizedPath = relativePath.replaceAll('\\', '/');
          try {
            final pr = await gitDir.runCommand(['log', 'HEAD..@{u}', '--name-only', '--format=']);
            final out = (pr.stdout as String).trim();
            final files = out.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty);
            return files.any((e) => e == normalizedPath || normalizedPath.startsWith('$e/'));
          } catch (_) {
            return false; // No upstream or error
          }
        }

        if (await GitDir.isGitDir(projectDir)) {
          final projectGit = await GitDir.fromExisting(projectDir, allowSubdirectory: true);
          final projectBranch = (await projectGit.currentBranch()).branchName;
          final relativePath = path.relative(projectFile.path, from: await Directory(projectGit.path).resolveSymbolicLinks());
          newState.items.add(GitItem(
            id: 'project',
            name: Loc.get.gitItemProject,
            gitDir: projectGit,
            relativePath: relativePath,
            branchName: projectBranch,
            type: GitItemType.project,
            isModified: await checkIsModified(projectGit, relativePath),
            isUnpushed: await checkIsUnpushed(projectGit, relativePath),
            isUnpulled: await checkIsUnpulled(projectGit, relativePath),
          ));
        }

        if (await GitDir.isGitDir(authListDir)) {
          final authListGit = await GitDir.fromExisting(authListDir, allowSubdirectory: true);
          final authListBranch = (await authListGit.currentBranch()).branchName;
          final relativePath = path.relative(authListFile.path, from: await Directory(authListGit.path).resolveSymbolicLinks());
          newState.items.add(GitItem(
            id: 'authList',
            name: Loc.get.gitItemAuthList,
            gitDir: authListGit,
            relativePath: relativePath,
            branchName: authListBranch,
            type: GitItemType.authList,
            isModified: await checkIsModified(authListGit, relativePath),
            isUnpushed: await checkIsUnpushed(authListGit, relativePath),
            isUnpulled: await checkIsUnpulled(authListGit, relativePath),
          ));
        }

        for (var i = 0; i < generatorsList!.length; i++) {
          final generator = generatorsList[i];
          final filePath = await _resolvePath(path.join(outputDir, '${generator.fileName}.${generator.fileExtension}'));
          final fileDir = File(filePath).parent.path;

          if (await GitDir.isGitDir(fileDir)) {
            final fileGit = await GitDir.fromExisting(fileDir, allowSubdirectory: true);
            final fileBranch = (await fileGit.currentBranch()).branchName;
            final relativePath = path.relative(filePath, from: await Directory(fileGit.path).resolveSymbolicLinks());
            newState.items.add(GitItem(
              id: 'g${generator.hashCode}',
              name: Loc.get.gitItemGenerator(generator.$type!.name, i),
              gitDir: fileGit,
              relativePath: relativePath,
              branchName: fileBranch,
              type: GitItemType.generator,
              isModified: await checkIsModified(fileGit, relativePath),
              isUnpushed: await checkIsUnpushed(fileGit, relativePath),
              isUnpulled: await checkIsUnpulled(fileGit, relativePath),
            ));
          }
        }

        await providerContainer.read(serverHistoryStateProvider).waitForInitialization();
        historyState = providerContainer.read(serverHistoryStateProvider).state;
        final historyList = historyState.items;
        for (var i = 0; i < historyList.length; i++) {
          final historyFile = historyList[i];
          final filePath = await _resolvePath(path.join(historyDir, '${historyFile.id}.${Config.historyFileExtension}'));
          final fileDir = File(filePath).parent.path;

          if (await GitDir.isGitDir(fileDir)) {
            final fileGit = await GitDir.fromExisting(fileDir, allowSubdirectory: true);
            final fileBranch = (await fileGit.currentBranch()).branchName;
            final relativePath = path.relative(filePath, from: await Directory(fileGit.path).resolveSymbolicLinks());
            newState.items.add(GitItem(
              id: 'h${historyFile.id}',
              name: Loc.get.gitItemHistory(historyFile.id, i),
              gitDir: fileGit,
              relativePath: relativePath,
              branchName: fileBranch,
              type: GitItemType.history,
              isModified: await checkIsModified(fileGit, relativePath),
              isUnpushed: await checkIsUnpushed(fileGit, relativePath),
              isUnpulled: await checkIsUnpulled(fileGit, relativePath),
            ));
          }
        }

        state = newState;
        return null;
      },
    );
  }

  Future<String?> doCommit(List<String> items, String requestor) async {
    final result = await _doAction(
      () async {
        final selectedItems = _getSelectedItemsByIds(items);
        if (selectedItems.length != items.length) //
          return 'Invalid selected items';

        final errors = <String>[];

        for (final item in selectedItems) {
          try {
            await item.gitDir.runCommand(['add', path.join('.', item.relativePath)]);
            await item.gitDir.runCommand(['commit', path.join('.', item.relativePath), '-m', '$requestor via ${Config.appName}: saved "${item.name}"']);
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
    await refresh();
    return result;
  }

  Future<String?> doPush(List<String> items) async {
    final result = await _doAction(
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
    await refresh();
    return result;
  }

  Future<String?> doPull(List<String> items) async {
    final result = await _doAction(
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
            await item.gitDir.runCommand(['pull', '--rebase']);
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
    await refresh();
    return result;
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

  Future<String> _resolvePath(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.resolveSymbolicLinks();
    }
    return filePath;
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
  final bool isModified;
  final bool isUnpushed;
  final bool isUnpulled;

  GitItem({
    required this.id,
    required this.name,
    required this.gitDir,
    required this.branchName,
    required this.relativePath,
    required this.type,
    required this.isModified,
    required this.isUnpushed,
    required this.isUnpulled,
  });
}
