import 'package:flutter/material.dart';
import 'package:gceditor/components/properties/primitives/drop_down_selector.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/state/client_state.dart';

class PropertyClassInterface extends StatelessWidget {
  final ClassMetaEntity entity;
  final ClassMetaEntity? interface;

  const PropertyClassInterface({
    Key? key,
    required this.entity,
    required this.interface,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subInterfaces = clientModel.cache.getSubInterfaces(entity);

    final items = clientModel.cache.allClasses //
        .where((c) => c.classType == ClassType.interface)
        .toList();

    return Row(
      children: [
        Expanded(
          child: DropDownSelector<ClassMetaEntity>(
            onValueChanged: _handleValueChanged,
            isEnabled: (e) => _checkSelectionEnabled(e, subInterfaces),
            items: items,
            selectedItem: interface,
            label: '',
            addNull: true,
          ),
        ),
        SizedBox(
          width: 33 * kScale,
        ),
      ],
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
}
