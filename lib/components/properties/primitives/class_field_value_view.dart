import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/class_meta_entity.dart';
import 'package:gceditor/model/db/class_meta_field_description.dart';
import 'package:gceditor/model/db_cmd/db_cmd_delete_class_field.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';

import 'delete_button.dart';

class ClassFieldValueView extends ConsumerWidget {
  final ClassMetaEntity entity;
  final ClassMetaFieldDescription data;

  const ClassFieldValueView({
    Key? key,
    required this.entity,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(context, watch) {
    final idInputColor = DbModelUtils.getMetaFieldColor(
      MetaValueCoordinates(classId: entity.id, fieldId: data.id),
      watch(clientFindStateProvider).state,
      watch(clientNavigationServiceProvider).state,
      kColorAccentBlue1_5,
    );

    watch(clientStateProvider);
    return Padding(
      padding: EdgeInsets.only(top: 2 * kScale, bottom: 4 * kScale),
      child: TooltipWrapper(
        message: data.description,
        child: SizedBox(
          height: 31 * kScale,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Material(
                  color: idInputColor,
                  borderRadius: kCardBorder,
                  child: InkWell(
                    onTap: _handleEdit,
                    child: Padding(
                      padding: EdgeInsets.only(left: 8 * kScale),
                      child: Center(
                        child: SizedBox(
                          width: 9999,
                          child: Text(
                            data.id,
                            overflow: TextOverflow.fade,
                            style: kStyle.kTextExtraSmallLightest,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (watch(clientViewModeStateProvider).state.actionsMode)
                DeleteButton(
                  onAction: _handleDelete,
                  size: 14 * kScale,
                  width: 25 * kScale,
                  color: kColorPrimaryLight,
                ),
              SizedBox(width: 28 * kScale),
            ],
          ),
        ),
      ),
    );
  }

  void _handleEdit() {
    providerContainer.read(tableSelectionStateProvider).setSelectedField(field: data);
  }

  void _handleDelete() {
    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdDeleteClassField.values(
            entityId: entity.id,
            fieldId: data.id,
          ),
        );
  }
}
