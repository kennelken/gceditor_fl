import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/landing/project_path_view.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/managers/startup/startup_manager.dart';
import 'package:gceditor/model/app_local_storage.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/server_history_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:path/path.dart' as path;

class ServerHistoryAdminPanel extends StatefulWidget {
  const ServerHistoryAdminPanel({Key? key}) : super(key: key);

  @override
  _ServerHistoryAdminPanelState createState() => _ServerHistoryAdminPanelState();
}

class _ServerHistoryAdminPanelState extends State<ServerHistoryAdminPanel> {
  late final TextEditingController _historyPathTextController;
  late final TextEditingController _tagNameTextController;

  bool _initialValuesSet = false;
  String _historyPath = '';

  @override
  void initState() {
    super.initState();
    _historyPathTextController = TextEditingController();
    _tagNameTextController = TextEditingController();

    _historyPathTextController.addListener(_handleHistoryPathChanged);
    _tagNameTextController.addListener(_handleHistoryTagChanged);
  }

  @override
  void deactivate() {
    super.deactivate();
    _historyPathTextController.removeListener(_handleHistoryPathChanged);
    _tagNameTextController.removeListener(_handleHistoryTagChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _historyPathTextController.dispose();
    _tagNameTextController.dispose();
  }

  void _handleHistoryPathChanged() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => providerContainer.read(serverHistoryStateProvider).setPath(_historyPathTextController.text),
    );
  }

  void _handleHistoryTagChanged() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => providerContainer.read(serverHistoryStateProvider).setTag(_tagNameTextController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, watch, child) {
        watch(startupProvider);

        final defaultFolder = watch(appStateProvider).state.defaultProjectFolder;
        final defaultFolderPath = defaultFolder?.path ?? '';

        if (!_initialValuesSet) {
          final historyState = providerContainer.read(serverHistoryStateProvider).state;

          _historyPath =
              historyState.folderPath ?? AppLocalStorage.instance.historyPath ?? path.join(defaultFolderPath, Config.newHistoryDefaultFolder);

          final historyTag = AppLocalStorage.instance.historyTag ?? Config.newHistoryDefaultTag;

          _historyPathTextController.text = _historyPath;
          _tagNameTextController.text = historyTag;

          _initialValuesSet = true;
        }

        _handleHistoryPathChanged();
        _handleHistoryTagChanged();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              child: ProjectPathView(
                defaultFolder: defaultFolder,
                projectPath: _historyPath,
                projectPathTextController: _historyPathTextController,
                labelText: Loc.get.historyPath,
                defaultName: '',
                isFile: false,
              ),
            ),
            SizedBox(height: 10 * kScale),
            TextField(
              controller: _tagNameTextController,
              decoration: kStyle.kLandingInputTextStyle.copyWith(
                hintText: Loc.get.historyTagHint,
                labelText: Loc.get.historyTagLabel,
              ),
            ),
          ],
        );
      },
    );
  }
}
