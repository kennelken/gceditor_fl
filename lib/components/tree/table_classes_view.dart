import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/properties/primitives/drop_available_indicator_line.dart';
import 'package:gceditor/components/tree/tree_node_tile.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/class_meta_group.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db_cmd/db_cmd_reorder_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';

import '../../model/state/style_state.dart';

final _rootNode = TreeNode(id: '___root_node_classes');
final _treeViewController = TreeViewController(rootNode: _rootNode);
final _treeScrollController = ScrollController();

class TableClassesView extends ConsumerWidget {
  const TableClassesView({super.key});

  @override
  Widget build(context, ref) {
    if (!ref.watch(clientStateProvider).state.isInitialized) //
      return const SizedBox();
    ref.watch(styleStateProvider);

    final hadChildrenBefore = _rootNode.hasChildren;

    final dbModel = ref.watch(clientStateProvider).state.model;
    final elements = dbModel.classes;
    _buildNodes(elements);
    _treeViewController.refreshNode(_rootNode, keepExpandedNodes: true);

    if (hadChildrenBefore) {
      _treeViewController.reset(keepExpandedNodes: true);
    } else {
      _treeViewController.expandAll();
    }

    return DragTarget<IIdentifiable>(
      onAcceptWithDetails: (item) {
        if (_canDrop(item.data)) //
          _doDrop(item.data);
      },
      builder: (context, candidateData, rejectedData) {
        final canDrop = candidateData.any((c) => _canDrop(c));

        return Consumer(
          key: const ValueKey('TableTablesViewTableConmsumer'),
          builder: (context, watchInner, child) {
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 0 * kScale, horizontal: 5 * kScale),
                  child: DropAvailableIndicatorLine(visible: canDrop),
                ),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: kScrollDraggable,
                    child: TreeView(
                      key: const ValueKey('TableClassesViewTable'),
                      controller: _treeViewController,
                      theme: kTreeViewTheme,
                      scrollController: _treeScrollController,
                      nodeHeight: 22 * kScale,
                      nodeBuilder: (c, n) => const TreeNodeTile(),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _canDrop(IIdentifiable? entity) {
    return entity is ClassMeta;
  }

  void _doDrop(IIdentifiable item) {
    DbCmdReorderMetaEntity command;

    command = DbCmdReorderMetaEntity.values(
      entityId: item.id,
      index: 0,
      parentId: null,
    );
    providerContainer.read(clientOwnCommandsStateProvider).addCommand(command);
  }

  void _buildNodes(List<ClassMeta> classes) {
    _rootNode.clearChildren();

    for (final classMeta in classes) {
      _addNode(classMeta, _rootNode);
    }
  }

  void _addNode(ClassMeta classMeta, TreeNode parent) {
    final node = TreeNode(id: classMeta.id, label: classMeta.id, data: classMeta);
    parent.addChild(node);

    if (classMeta is ClassMetaGroup) {
      final group = classMeta;

      for (var child in group.entries) {
        _addNode(child, node);
      }
    }
  }
}
