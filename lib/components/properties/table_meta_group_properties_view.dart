import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/properties/primitives/class_meta_properties_container.dart';
import 'package:gceditor/components/properties/primitives/property_string_view.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/table_meta_group.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_meta_entity_description.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_meta_entity_id.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';

class TableMetaGroupPropertiesViewProperties extends ConsumerWidget {
  final TableMetaGroup data;

  const TableMetaGroupPropertiesViewProperties({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(context, watch) {
    watch(clientStateProvider);
    final idInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
      MetaValueCoordinates(tableId: data.id),
      watch(clientFindStateProvider).state,
      watch(clientNavigationServiceProvider).state,
    );

    return ClassMetaPropertiesContainer(
      children: [
        PropertyStringView(
          key: ValueKey(data.id),
          title: Loc.get.classMetaPropertyId,
          value: data.id,
          canBeEmpty: false,
          saveCallback: (v) => DbCmdEditMetaEntityId.values(entityId: data.id, newValue: v),
          inputFormatters: Config.filterId,
          inputDecoration: idInputDecoration,
          showFindIcon: watch(clientViewModeStateProvider).state.actionsMode,
        ),
        kStyle.kPropertiesVerticalDivider,
        PropertyStringView(
          key: ValueKey(data.description),
          title: Loc.get.classMetaPropertyDescription,
          value: data.description,
          defaultValue: Config.newFolderDescription,
          saveCallback: (v) => DbCmdEditMetaEntityDescription.values(entityId: data.id, newValue: v),
          multiline: true,
        ),
        kStyle.kPropertiesVerticalDivider,
      ],
    );
  }
}
