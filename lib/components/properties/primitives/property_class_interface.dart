import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/properties/primitives/drop_down_selector.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/state/client_state.dart';

import '../../../model/db_cmd/db_cmd_delete_class_interface.dart';
import '../../../model/model_root.dart';
import '../../../model/state/client_find_state.dart';
import '../../../model/state/client_view_mode_state.dart';
import '../../../model/state/db_model_extensions.dart';
import '../../../model/state/service/client_navigation_service.dart';
import 'delete_button.dart';

class PropertyClassInterface extends ConsumerWidget {
  final ClassMetaEntity entity;
  final ClassMetaEntity? interface;
  final int index;

  const PropertyClassInterface({
    Key? key,
    required this.entity,
    required this.interface,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, watch) {
    final idInputColor = DbModelUtils.getMetaFieldColor(
      MetaValueCoordinates(classId: entity.id),
      watch(clientFindStateProvider).state,
      watch(clientNavigationServiceProvider).state,
      kColorAccentBlue1_5,
    );

    final subInterfaces = clientModel.cache.getSubInterfaces(entity);

    final items = clientModel.cache.allClasses //
        .where((c) => c.classType == ClassType.interface)
        .toList();

    return Padding(
      padding: EdgeInsets.only(top: 2 * kScale, bottom: 4 * kScale),
      child: SizedBox(
        height: 31 * kScale,
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: idInputColor,
                child: DropDownSelector<ClassMetaEntity>(
                  onValueChanged: _handleValueChanged,
                  isEnabled: (e) => _checkSelectionEnabled(e, subInterfaces),
                  items: items,
                  selectedItem: interface,
                  label: '',
                  addNull: true,
                ),
              ),
            ),
            if (watch(clientViewModeStateProvider).state.actionsMode) ...[
              DeleteButton(
                onAction: _handleDelete,
                size: 14 * kScale,
                width: 25 * kScale,
                color: kColorPrimaryLight,
              ),
            ],
            SizedBox(
              width: 28 * kScale,
            ),
          ],
        ),
      ),
    );
  }

  void _handleValueChanged(ClassMetaEntity? value) {
    if (value == interface) //
      return;

    // TODO! change type command
  }

  bool _checkSelectionEnabled(ClassMetaEntity e, List<ClassMetaEntity>? subInterfaces) {
    return e != entity && (subInterfaces == null || !subInterfaces.contains(e));
  }

  void _handleDelete() {
    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdDeleteClassInterface.values(
            entityId: entity.id,
            index: index,
          ),
        );
  }
}
