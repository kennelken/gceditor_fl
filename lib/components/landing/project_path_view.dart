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
  final TextEditingController projectPathTextController;
  final String projectPath;
  final Directory? defaultFolder;
  final String? labelText;
  final String defaultName;
  final bool isFile;

  const ProjectPathView({
    Key? key,
    required this.projectPathTextController,
    required this.projectPath,
    required this.defaultFolder,
    required this.labelText,
    required this.defaultName,
    required this.isFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 70,
          child: TextField(
            controller: projectPathTextController,
            decoration: kStyle.kLandingInputTextStyle.copyWith(
              hintText: projectPath,
              labelText: labelText,
            ),
          ),
        ),
        if (isFile) ...[
          SizedBox(width: 15 * kScale),
          SizedBox(
            width: 30 * kScale,
            height: 30 * kScale,
            child: ElevatedButton(
              style: kButtonContextMenu,
              onPressed: () => _handleBrowseProjectPath(),
              child: Icon(
                FontAwesomeIcons.file,
                size: 20 * kScale,
                color: kTextColorLightest,
              ),
            ),
          ),
        ],
        SizedBox(width: 15 * kScale),
        SizedBox(
          width: 30 * kScale,
          height: 30 * kScale,
          child: ElevatedButton(
            style: kButtonContextMenu,
            onPressed: () => _handleBrowseProjectDirectory(defaultFolder!),
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
  void _handleBrowseProjectPath() async {
    final file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [Config.projectFileExtension],
      dialogTitle: Loc.get.selectProjectFile,
    );

    if ((file?.count ?? 0) > 0) {
      projectPathTextController.text = file!.paths[0]!;
    }
  }

  // ignore: avoid_void_async
  void _handleBrowseProjectDirectory(Directory rootDirectory) async {
    final folder = await FilePicker.platform.getDirectoryPath(
      dialogTitle: Loc.get.selectProjectDirectory,
    );

    if ((folder?.length ?? 0) > 0) {
      projectPathTextController.text = path.join(folder!, defaultName);
    }
  }
}
