import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:path/path.dart' as path;

class ProjectPathView extends StatelessWidget {
  final TextEditingController targetPathTextController;
  final String? targetPath;
  final String defaultPath;
  final String? labelText;
  final String? defaultName;
  final bool isFile;
  final bool canBeReset;
  final ValueSetter<String?> onChange;

  ProjectPathView({
    Key? key,
    required this.targetPathTextController,
    required this.targetPath,
    required this.defaultPath,
    required this.labelText,
    required this.defaultName,
    required this.isFile,
    required this.canBeReset,
    required this.onChange,
  }) : super(key: key) {
    targetPathTextController.text = targetPath ?? defaultPath;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 70,
          child: TextField(
            enabled: false,
            style: kStyle.kTextSmall.copyWith(color: targetPath == null ? kColorPrimaryLight : kColorButtonActive),
            controller: targetPathTextController,
            decoration: kStyle.kLandingInputTextStyle.copyWith(
              hintText: targetPath,
              labelText: labelText,
            ),
          ),
        ),
        if (isFile) ...[
          SizedBox(width: 7 * kScale),
          SizedBox(
            width: 30 * kScale,
            height: 30 * kScale,
            child: ElevatedButton(
              style: kButtonContextMenu,
              onPressed: () => _handleBrowsePath(),
              child: Icon(
                FontAwesomeIcons.file,
                size: 20 * kScale,
                color: kTextColorLightest,
              ),
            ),
          ),
        ],
        if (canBeReset) ...[
          SizedBox(width: 7 * kScale),
          SizedBox(
            width: 30 * kScale,
            height: 30 * kScale,
            child: ElevatedButton(
              style: targetPath == null ? kButtonContextMenuInactive : kButtonContextMenu,
              onPressed: targetPath == null ? null : () => _handleResetPath(),
              child: Icon(
                FontAwesomeIcons.rotateLeft,
                size: 20 * kScale,
                color: targetPath == null ? kTextColorLight3 : kTextColorLightest,
              ),
            ),
          ),
        ],
        SizedBox(width: 7 * kScale),
        SizedBox(
          width: 30 * kScale,
          height: 30 * kScale,
          child: ElevatedButton(
            style: kButtonContextMenu,
            onPressed: () => _handleBrowseDirectory(),
            child: Icon(
              FontAwesomeIcons.folder,
              size: 20 * kScale,
              color: kTextColorLightest,
            ),
          ),
        ),
      ],
    );
  }

  // ignore: avoid_void_async
  void _handleBrowsePath() async {
    final file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [Config.projectFileExtension],
      dialogTitle: Loc.get.selectProjectFile,
      initialDirectory: getInitialDirectory(),
    );

    if ((file?.count ?? 0) > 0) {
      onChange.call(file!.paths[0]!);
    }
  }

  // ignore: avoid_void_async
  void _handleBrowseDirectory() async {
    final folder = await FilePicker.platform.getDirectoryPath(
      dialogTitle: Loc.get.selectProjectDirectory,
      initialDirectory: getInitialDirectory(),
    );

    if ((folder?.length ?? 0) > 0) {
      onChange.call(path.join(folder!, isFile ? defaultName : null));
    }
  }

  String? getInitialDirectory() {
    var result = isFile ? path.dirname(targetPathTextController.text) : targetPathTextController.text;
    if (result.isEmpty) return null;

    while (result.isNotEmpty) {
      if (Directory(result).existsSync()) break;
      result = path.dirname(result);
    }

    return result;
  }

  void _handleResetPath() {
    onChange.call(null);
  }
}
