import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/properties/primitives/drop_down_selector.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/state/client_state.dart';

import '../../../consts/loc.dart';
import '../../../model/db_cmd/db_cmd_delete_class_interface.dart';
import '../../../model/db_cmd/db_cmd_edit_class_interface.dart';
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
  Widget build(BuildContext context, ref) {
    final subInterfaces = clientModel.cache.getSubInterfaces(entity);

    final parentInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
      MetaValueCoordinates(classId: entity.id, parentClass: interface?.id ?? ''),
      ref.watch(clientFindStateProvider).state,
      ref.watch(clientNavigationServiceProvider).state,
    );

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
              child: DropDownSelector<ClassMetaEntity>(
                onValueChanged: _handleValueChanged,
                isEnabled: (e) => _checkSelectionEnabled(e, subInterfaces),
                items: items,
                selectedItem: interface,
                label: '',
                addNull: true,
                inputDecoration: parentInputDecoration,
              ),
            ),
            if (ref.watch(clientViewModeStateProvider).state.actionsMode) ...[
              DeleteButton(
                onAction: _handleDelete,
                size: 14 * kScale,
                width: 25 * kScale,
                tooltipText: Loc.get.delete,
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

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditClassInterface.values(
            entityId: entity.id,
            index: index,
            interfaceId: value?.id,
          ),
        );
  }

  bool _checkSelectionEnabled(ClassMetaEntity e, List<ClassMetaEntity> subInterfaces) {
    final model = clientModel;

    final interfaceToReplaceId = entity.interfaces[index];

    return e != entity &&
        !subInterfaces.any((element) => element == e) &&
        !entity.interfaces.any(
          (otherInterfaceId) {
            final otherInterface = model.cache.getClass<ClassMetaEntity>(otherInterfaceId);
            if (otherInterface == null) //
              return false;

            if (otherInterfaceId == interfaceToReplaceId) //
              return false;

            if (otherInterface == e) //
              return true;

            if (model.cache.getParentInterfaces(otherInterface).contains(e)) //
              return true;

            return false;
          },
        );
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
