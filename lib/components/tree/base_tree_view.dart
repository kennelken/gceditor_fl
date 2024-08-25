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

    final hadChildrenBefore = treeController.roots.isNotEmpty;

    treeController.roots = data();
    if (!hadChildrenBefore) {
      treeController.expandAll();
    }
    treeController.rebuild();

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
}

TreeController<IIdentifiable> getTreeController() => TreeController<IIdentifiable>(
      roots: [],
      childrenProvider: (n) => n.safeAs<IMetaGroup>()?.entries.cast<IIdentifiable>() ?? [],
      parentProvider: (n) => clientModel.cache.getParent(n).safeAs<IIdentifiable>(),
    );
