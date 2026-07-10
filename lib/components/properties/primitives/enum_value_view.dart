import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/delete_button.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/class_meta_entity_enum.dart';
import 'package:gceditor/model/db/enum_value.dart';
import 'package:gceditor/model/db_cmd/db_cmd_delete_enum_value.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_enum_value.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/value_change_notifier.dart';

final enumValueWidthRatioProvider = ChangeNotifierProvider((_) => ValueChangeNotifier(Config.enumColumnDefaultWidth));

class EnumValueView extends StatefulWidget {
  final ClassMetaEntityEnum entity;
  final EnumValue data;

  const EnumValueView({
    super.key,
    required this.entity,
    required this.data,
  });

  @override
  State<EnumValueView> createState() => _EnumValueViewState();
}

class _EnumValueViewState extends State<EnumValueView> {
  late final TextEditingController _idController;
  late final TextEditingController _descriptionController;
  late final FocusNode _idFocusNode;
  late final FocusNode _descriptionFocusNode;

  @override
  void initState() {
    super.initState();

    _idFocusNode = FocusNode();
    _idFocusNode.addListener(_handleIdChanged);
    _descriptionFocusNode = FocusNode();
    _descriptionFocusNode.addListener(_handleDescriptionFocusChanged);

    _idController = TextEditingController(text: widget.data.id);
    _descriptionController = TextEditingController(text: widget.data.description);
  }

  @override
  void dispose() {
    super.dispose();
    _idFocusNode.removeListener(_handleIdChanged);
    _descriptionFocusNode.removeListener(_handleDescriptionFocusChanged);
  }

  @override
  Widget build(context) {
    return Consumer(builder: (context, ref, child) {
      ref.watch(enumValueWidthRatioProvider);
      ref.watch(clientStateProvider);

      final idInputDecoration = DbModelUtils.getMetaFieldInputDecoration(
        MetaValueCoordinates(classId: widget.entity.id, enumId: widget.data.id),
        ref.watch(clientFindStateProvider).state,
        ref.watch(clientNavigationServiceProvider).state,
        defaultInputDecoration: kStyle.kInputTextStyleProperties,
      );

      return SizedBox(
        height: 38 * kScale,
        child: Row(
          children: [
            SizedBox(
              width: _clampedValueWidth() * kScale,
              child: TextField(
                controller: _idController,
                focusNode: _idFocusNode,
                inputFormatters: Config.filterId,
                readOnly: widget.entity.autoByFile,
                decoration: idInputDecoration.copyWith(
                  enabled: !widget.entity.autoByFile,
                ),
              ),
            ),
            GestureDetector(
              onHorizontalDragUpdate: (d) => _handleDragUpdate(d, context),
              onHorizontalDragEnd: _handleDragEnded,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: Container(
                  width: kDividerLineWidth,
                  color: kColorBlueMetaPropertiesGroup,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                readOnly: widget.entity.autoByFile,
                decoration: kStyle.kInputTextStyleProperties.copyWith(
                  labelText: Loc.get.classMetaPropertyDescription,
                  enabled: !widget.entity.autoByFile,
                ),
              ),
            ),
            if (ref.watch(appStateProvider).state.appMode == AppMode.standalone &&
                widget.entity.autoByFile &&
                widget.data.fullPath != null &&
                widget.data.fullPath!.isNotEmpty) ...[
              TooltipWrapper(
                message: _getAbsolutePath() ?? widget.data.fullPath!,
                child: IconButtonTransparent(
                  size: 22 * kScale,
                  icon: Icon(
                    FontAwesomeIcons.folderOpen,
                    color: kColorPrimaryLight,
                    size: 12 * kScale,
                  ),
                  onClick: _handleShowInExplorer,
                ),
              ),
              TooltipWrapper(
                message: _getAbsolutePath() ?? widget.data.fullPath!,
                child: IconButtonTransparent(
                  size: 22 * kScale,
                  icon: Icon(
                    FontAwesomeIcons.arrowUpRightFromSquare,
                    color: kColorPrimaryLight,
                    size: 12 * kScale,
                  ),
                  onClick: _handleOpenFile,
                ),
              ),
            ],
            if (ref.watch(clientViewModeStateProvider).state.actionsMode) ...[
              TooltipWrapper(
                message: Loc.get.findReferencesTooltip,
                child: IconButtonTransparent(
                  size: 22 * kScale,
                  icon: Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    color: kColorPrimaryLight,
                    size: 12 * kScale,
                  ),
                  onClick: _handleFindClick,
                ),
              ),
              if (!widget.entity.autoByFile)
                DeleteButton(
                  onAction: _handleDelete,
                  size: 14 * kScale,
                  width: 25 * kScale,
                  tooltipText: Loc.get.delete,
                ),
            ],
            SizedBox(width: 30 * kScale),
          ],
        ),
      );
    });
  }

  void _handleIdChanged() {
    if (widget.entity.autoByFile) return;
    if (_idFocusNode.hasFocus) {
      DbModelUtils.selectAllIfDefaultId(_idController);
      return;
    }

    if (_idController.text == widget.data.id) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(DbCmdEditEnumValue.values(
          entityId: widget.entity.id,
          newId: _idController.text,
          valueId: widget.data.id,
        ));
  }

  void _handleDescriptionFocusChanged() {
    if (widget.entity.autoByFile) return;
    if (_descriptionFocusNode.hasFocus) {
      DbModelUtils.selectAllIfDefault(_descriptionController, Config.newEnumValueDefaultDescription);
      return;
    }

    if (_descriptionController.text == widget.data.description) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(DbCmdEditEnumValue.values(
          entityId: widget.entity.id,
          newDescription: _descriptionController.text,
          valueId: widget.data.id,
        ));
  }

  void _handleDragUpdate(DragUpdateDetails details, BuildContext context) {
    providerContainer.read(enumValueWidthRatioProvider).setValue(_clampedValueWidth(details.delta.dx));
  }

  void _handleDragEnded(DragEndDetails details) {
    if (_clampedValueWidth() == widget.entity.valueColumnWidth) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditEnumValue.values(
            entityId: widget.entity.id,
            newWidthRatio: _clampedValueWidth(),
          ),
        );
  }

  double _clampedValueWidth([double delta = 0]) {
    return (providerContainer.read(enumValueWidthRatioProvider).value + delta).clamp(Config.enumColumnMinWidth, Config.enumColumnMaxWidth);
  }

  void _handleDelete() {
    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdDeleteEnumValue.values(
            entityId: widget.entity.id,
            valueId: widget.data.id,
          ),
        );
  }

  void _handleFindClick() {
    providerContainer.read(clientFindStateProvider).findUsage(clientModel, widget.data.id);
  }

  String? _getAbsolutePath() {
    final projectFile = providerContainer.read(appStateProvider).state.projectFile;
    if (projectFile == null || widget.data.fullPath == null) return null;
    final projectDir = projectFile.parent.path;
    return path.normalize(path.join(projectDir, widget.data.fullPath!));
  }

  void _handleShowInExplorer() {
    final absolutePath = _getAbsolutePath();
    if (absolutePath == null) return;
    final file = File(absolutePath);
    if (!file.existsSync()) return;

    if (Platform.isWindows) {
      Process.run('explorer', ['/select,', absolutePath]);
    } else if (Platform.isMacOS) {
      Process.run('open', ['-R', absolutePath]);
    } else {
      Process.run('xdg-open', [path.dirname(absolutePath)]);
    }
  }

  void _handleOpenFile() {
    final absolutePath = _getAbsolutePath();
    if (absolutePath == null) return;
    final file = File(absolutePath);
    if (!file.existsSync()) return;

    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', '', absolutePath]);
    } else if (Platform.isMacOS) {
      Process.run('open', [absolutePath]);
    } else {
      Process.run('xdg-open', [absolutePath]);
    }
  }
}
