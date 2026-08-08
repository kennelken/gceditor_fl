import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/tree/tree_node_tile.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';

class BaseTreeView extends ConsumerWidget {
  final TreeController<IIdentifiable> treeController;
  final Func0<List<IIdentifiable>> data;

  const BaseTreeView({super.key, required this.treeController, required this.data});

  @override
  Widget build(context, ref) {
    if (!ref.watch(clientStateProvider).state.isInitialized) //
      return const SizedBox();
    ref.watch(styleStateProvider);
    ref.watch(clientStateProvider);

    final newRoots = data();

    if (!_areRootsEqual(treeController.roots, newRoots)) {
      final hadChildrenBefore = treeController.roots.isNotEmpty;

      if (!hadChildrenBefore) {
        treeController.roots = List.of(newRoots);
        treeController.expandAll();
      } else {
        final collapsedIds = <String>{};
        void collectCollapsed(Iterable<IIdentifiable> nodes) {
          for (final node in nodes) {
            if (!treeController.getExpansionState(node) && node.id.isNotEmpty) {
              collapsedIds.add(node.id);
            }
            final group = node.safeAs<IMetaGroup>();
            if (group != null) {
              collectCollapsed(group.entries.cast<IIdentifiable>());
            }
          }
        }

        collectCollapsed(treeController.roots);

        treeController.roots = List.of(newRoots);
        treeController.toggledNodes.clear();

        void restoreCollapsed(Iterable<IIdentifiable> nodes) {
          for (final node in nodes) {
            if (collapsedIds.contains(node.id)) {
              treeController.setExpansionState(node, false);
            } else {
              treeController.setExpansionState(node, true);
            }
            final group = node.safeAs<IMetaGroup>();
            if (group != null) {
              restoreCollapsed(group.entries.cast<IIdentifiable>());
            }
          }
        }

        restoreCollapsed(newRoots);
      }
    }

    return AnimatedTreeView<IIdentifiable>(
      treeController: treeController,
      padding: const EdgeInsets.only(left: 3, top: 0, right: 3, bottom: 3),
      duration: Durations.short1,
      nodeBuilder: (BuildContext context, TreeEntry<IIdentifiable> entry) {
        return TreeNodeTile(
          entry: entry,
          onFolderPressed: (e) => treeController.toggleExpansion(e.node),
          onFolderExpand: (e) => treeController.expand(e.node),
        );
      },
    );
  }

  bool _areRootsEqual(Iterable<IIdentifiable> a, List<IIdentifiable> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    final aList = a.toList();
    for (var i = 0; i < aList.length; i++) {
      if (!identical(aList[i], b[i])) return false;
    }
    return true;
  }
}

TreeController<IIdentifiable> getTreeController() => TreeController<IIdentifiable>(
      roots: [],
      childrenProvider: (n) => n.safeAs<IMetaGroup>()?.entries.cast<IIdentifiable>() ?? [],
      parentProvider: (n) => clientModel.cache.getParent(n).safeAs<IIdentifiable>(),
      defaultExpansionState: true,
    );
