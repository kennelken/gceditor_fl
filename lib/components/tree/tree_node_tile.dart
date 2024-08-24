import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/drop_available_indicator_line.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/class_meta_group.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/db/table_meta_group.dart';
import 'package:gceditor/model/db_cmd/db_cmd_reorder_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';

class TreeNodeTile extends ConsumerWidget {
  const TreeNodeTile({super.key});

  @override
  Widget build(context, ref) {
    final nodeScope = TreeNodeScope.of(context);
    final entity = nodeScope.node.data as IIdentifiable;
    final isSelected = ref.watch(tableSelectionStateProvider).state.selectedId == nodeScope.node.id;
    final isExpandable = nodeScope.node.data is ClassMetaGroup || nodeScope.node.data is TableMetaGroup;
    ref.watch(styleStateProvider);

    return Draggable<IIdentifiable>(
      data: nodeScope.node.data as IIdentifiable,
      dragAnchorStrategy: pointerDragAnchorStrategy,
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
                  nodeScope.node.label,
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
            const LinesWidget(),
            if (isExpandable) //
              DragTarget<IIdentifiable>(
                onAcceptWithDetails: (item) {
                  if (_canDrop(item.data, entity)) {
                    _doDrop(item.data, entity, true);
                    nodeScope.expand(context);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  final canDrop = candidateData.any((c) => _canDrop(c, entity));
                  final iconColor = canDrop ? kColorPrimaryDarker : kColorPrimaryLight;
                  final icon = canDrop
                      ? FontAwesomeIcons.arrowDown
                      : nodeScope.isExpanded
                          ? FontAwesomeIcons.folderOpen
                          : FontAwesomeIcons.folder;

                  return Container(
                    color: canDrop ? kColorPrimaryLight : kColorTransparent,
                    width: 25 * kScale,
                    child: NodeWidgetLeadingIcon(
                      splashRadius: 15 * kScale,
                      useFoldersOnly: true,
                      padding: EdgeInsets.all(0 * kScale),
                      collapseIcon: Icon(icon, color: iconColor, size: 15 * kScale),
                      expandIcon: Icon(icon, color: iconColor, size: 15 * kScale),
                    ),
                  );
                },
              ),
            SizedBox(width: 2 * kScale),
            Expanded(
              child: InkWell(
                onTap: () {
                  providerContainer
                      .read(tableSelectionStateProvider)
                      .setSelectedEntity(entity: isSelected ? null : nodeScope.node.data as IIdentifiable);
                },
                child: DragTarget<IIdentifiable>(
                  onAcceptWithDetails: (item) {
                    if (_canDrop(item.data, entity)) {
                      _doDrop(item.data, entity, false);
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    final canDrop = candidateData.any((c) => _canDrop(c, entity));
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 2 * kScale),
                        TooltipWrapper(
                          message: (nodeScope.node.data is IDescribable) ? (nodeScope.node.data as IDescribable).description : null,
                          child: Row(
                            children: [
                              _getIcon(nodeScope.node.data as IIdentifiable),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Text(
                                  nodeScope.node.label,
                                  style: isSelected ? kStyle.kTextExtraSmallSelected : kStyle.kTextExtraSmall,
                                  maxLines: 1,
                                ),
                              ),
                              if (nodeScope.node.data is IMetaGroup) ...[
                                const SizedBox(width: 5),
                                Text(
                                  '(${nodeScope.node.children.length})',
                                  style: kStyle.kTextExtraSmallInactive,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                )
                              ],
                            ],
                          ),
                        ),
                        if (canDrop) const DropAvailableIndicatorLine()
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
  }

  bool _canDrop(IIdentifiable? entity, IIdentifiable candidate) {
    return entity != candidate &&
        (entity is ClassMeta == candidate is ClassMeta) &&
        providerContainer.read(clientStateProvider).state.model.cache.getParents(candidate).all((e) => e as IIdentifiable != entity);
  }

  void _doDrop(IIdentifiable item, IIdentifiable to, bool inside) {
    final model = clientModel;
    DbCmdReorderMetaEntity command;

    if (inside) {
      command = DbCmdReorderMetaEntity.values(
        entityId: item.id,
        index: 0,
        parentId: to.id,
      );
    } else {
      final toParent = model.cache.getParent(to) as IIdentifiable?;
      final toIndex = model.cache.getIndex(to);

      command = DbCmdReorderMetaEntity.values(
        entityId: item.id,
        index: (toIndex ?? 0) + 1,
        parentId: toParent?.id,
      );
    }

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(command);
  }

  Widget _getIcon(IIdentifiable data) {
    if (data is IMetaGroup) //
      return const SizedBox();

    var icon = FontAwesomeIcons.question;
    if (data is ClassMetaEntity) icon = FontAwesomeIcons.tableColumns;
    if (data is ClassMetaEntityEnum) icon = FontAwesomeIcons.list;
    if (data is TableMetaEntity) icon = FontAwesomeIcons.table;

    return Padding(
      padding: EdgeInsets.only(right: 5 * kScale),
      child: SizedBox(
        width: 20 * kScale,
        child: Icon(
          icon,
          size: 12 * kScale,
          color: kColorPrimaryLightTransparent,
        ),
      ),
    );
  }
}
