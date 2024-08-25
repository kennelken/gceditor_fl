import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db_cmd/db_cmd_reorder_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';
import 'package:gceditor/utils/utils.dart';

class TreeNodeTile extends ConsumerWidget {
  final TreeEntry<IIdentifiable> entry;
  final Action1<TreeEntry<IIdentifiable>> onFolderPressed;
  final Action1<TreeEntry<IIdentifiable>> onFolderExpand;

  const TreeNodeTile({
    super.key,
    required this.entry,
    required this.onFolderPressed,
    required this.onFolderExpand,
  });

  @override
  Widget build(context, ref) {
    final node = entry.node;
    final isSelected = ref.watch(tableSelectionStateProvider).state.selectedId == node.id;
    ref.watch(styleStateProvider);

    final indentGuide = DefaultIndentGuide.of(context);
    final borderSide = BorderSide(
      color: kColorAccentBlue,
      width: indentGuide is AbstractLineGuide ? indentGuide.thickness : 1.0,
    );
    final borderSideInactive = borderSide.copyWith(color: borderSide.color.withAlpha(70));

    return TreeIndentation(
      entry: entry,
      guide: const IndentGuide.connectingLines(
        indent: 20,
        color: Colors.grey,
        thickness: 1.0,
        origin: 0.5,
        roundCorners: false,
      ),
      child: TreeDragTarget<IIdentifiable>(
        node: node,
        onNodeAccepted: (details) {
          if (!_canDrop(details)) //
            return;

          final dropPosition = _getDropPosition(details)!;
          _doDrop(details.draggedNode, details.targetNode, dropPosition);
          onFolderExpand(entry);
        },
        builder: (context, details) {
          Decoration? decoration;
          if (details != null) {
            final side = _canDrop(details) ? borderSide : borderSideInactive;
            decoration = BoxDecoration(
              border: details.mapDropPosition(
                whenAbove: () => Border(top: side),
                whenInside: () => Border.fromBorderSide(side),
                whenBelow: () => Border(bottom: side),
              ),
            );
          }

          Widget content = TreeDraggable(
            node: node,
            feedback: Material(
              type: MaterialType.transparency,
              child: Container(
                color: kColorTransparent,
                child: Row(
                  children: [
                    SizedBox(width: 17 * kScale),
                    Icon(
                      Icons.drag_handle,
                      color: kColorPrimaryLight,
                      size: 20 * kScale,
                    ),
                    Padding(
                      padding: EdgeInsets.all(5.0 * kScale),
                      child: Text(
                        node.id,
                        style: kStyle.kTextExtraSmall,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: Material(
              color: kColorTransparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(
                    builder: (context) {
                      return Container(
                        color: kColorTransparent,
                        width: 25 * kScale,
                        child: MouseRegion(
                          child: _getIcon(node, () => onFolderPressed(entry)),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 2 * kScale),
                  Expanded(
                    child: InkWell(
                      splashColor: kColorPrimaryLightTransparent3,
                      onTap: () {
                        providerContainer.read(tableSelectionStateProvider).setSelectedEntity(entity: isSelected ? null : node);
                      },
                      child: Builder(
                        builder: (context) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 2 * kScale),
                              TooltipWrapper(
                                message: (node is IDescribable) ? (node as IDescribable).description : null,
                                child: Row(
                                  children: [
                                    Flexible(
                                      fit: FlexFit.loose,
                                      child: Text(
                                        node.id,
                                        style: isSelected ? kStyle.kTextExtraSmallSelected : kStyle.kTextExtraSmall,
                                        maxLines: 1,
                                      ),
                                    ),
                                    if (node is IMetaGroup) ...[
                                      const SizedBox(width: 5),
                                      Text(
                                        '(${(node as IMetaGroup).entries.length})',
                                        style: kStyle.kTextExtraSmallInactive,
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                      )
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.move,
                    child: SizedBox(
                      width: 30 * kScale,
                      child: Padding(
                        padding: EdgeInsets.only(right: 6 * kScale),
                        child: FittedBox(
                          child: Icon(
                            Icons.drag_handle,
                            size: 15 * kScale,
                            color: kColorPrimaryLighter2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          if (decoration != null) {
            content = DecoratedBox(
              decoration: decoration,
              child: content,
            );
          }

          return content;
        },
      ),
    );
  }

  bool _canDrop(TreeDragAndDropDetails<IIdentifiable>? details) {
    if (details == null) //
      return false;

    final origin = details.draggedNode;
    final candidate = details.targetNode;

    if (origin == candidate) //
      return false;

    final position = _getDropPosition(details);

    if (position == null) //
      return false;

    if (origin is ClassMeta != candidate is ClassMeta) //
      return false;

    if (position == DragDropPosition.inside) {
      if (candidate is! IMetaGroup) //
        return false;
    }

    final candidateParents = providerContainer.read(clientStateProvider).state.model.cache.getParents(candidate);
    if (candidateParents.isNotEmpty && candidateParents.any((e) => e as IIdentifiable == origin)) //
      return false;

    return true;
  }

  void _doDrop(IIdentifiable item, IIdentifiable to, DragDropPosition dropPosition) {
    final model = clientModel;
    DbCmdReorderMetaEntity command;

    if (dropPosition == DragDropPosition.inside) {
      command = DbCmdReorderMetaEntity.values(
        entityId: item.id,
        index: 0,
        parentId: to.id,
      );
    } else {
      final toParent = model.cache.getParent(to) as IIdentifiable?;
      final toIndex = (model.cache.getIndex(to) ?? 0) + (dropPosition == DragDropPosition.below ? 1 : 0);

      command = DbCmdReorderMetaEntity.values(
        entityId: item.id,
        index: toIndex,
        parentId: toParent?.id,
      );
    }

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(command);
  }

  Widget _getIcon(IIdentifiable data, Action0 onFolderClicked) {
    var icon = FontAwesomeIcons.question;
    var isEmpty = false;
    Action0? pressCallback;

    if (data is ClassMetaEntity) icon = FontAwesomeIcons.tableColumns;
    if (data is ClassMetaEntityEnum) icon = FontAwesomeIcons.list;
    if (data is TableMetaEntity) icon = FontAwesomeIcons.table;
    if (data is IMetaGroup) {
      pressCallback = onFolderClicked;
      isEmpty = (data as IMetaGroup).entries.isEmpty;
      icon = entry.isExpanded
          ? FontAwesomeIcons.folderOpen
          : isEmpty
              ? FontAwesomeIcons.folderClosed
              : FontAwesomeIcons.solidFolderClosed;
    }

    return Padding(
      padding: EdgeInsets.only(right: 5 * kScale),
      child: SizedBox(
        width: 20 * kScale,
        child: InkWell(
          splashColor: kColorTransparent,
          onTap: () {
            pressCallback?.call();
          },
          child: Icon(
            icon,
            size: 12 * kScale,
            color: kColorPrimaryLight,
          ),
        ),
      ),
    );
  }

  DragDropPosition? _getDropPosition(TreeDragAndDropDetails<IIdentifiable> details) {
    if (details.targetNode is ClassMeta != details.draggedNode is ClassMeta) //
      return null;

    DragDropPosition? dropPosition;
    details.mapDropPosition(
      whenAbove: () => {dropPosition = DragDropPosition.above},
      whenBelow: () => (dropPosition = DragDropPosition.below),
      whenInside: () => {dropPosition = DragDropPosition.inside},
    );
    return dropPosition;
  }
}

extension on TreeDragAndDropDetails<IIdentifiable> {
  /// Splits the target node's height in three and checks the vertical offset
  /// of the dragging node, applying the appropriate callback.
  T mapDropPosition<T>({
    required T Function() whenAbove,
    required T Function() whenInside,
    required T Function() whenBelow,
  }) {
    final oneThirdOfTotalHeight = targetBounds.height * 0.3;
    final pointerVerticalOffset = dropPosition.dy;

    if (pointerVerticalOffset < oneThirdOfTotalHeight) {
      return whenAbove();
    } else if (pointerVerticalOffset < oneThirdOfTotalHeight * 2) {
      return whenInside();
    } else {
      return whenBelow();
    }
  }
}

enum DragDropPosition {
  above,
  inside,
  below,
}
