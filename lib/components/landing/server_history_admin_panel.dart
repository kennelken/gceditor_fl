import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/landing/project_path_view.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/managers/startup/startup_manager.dart';
import 'package:gceditor/model/app_local_storage.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/server_history_state.dart';
import 'package:gceditor/model/state/style_state.dart';

import '../../model/state/landing_page_state.dart';

class ServerHistoryAdminPanel extends StatefulWidget {
  const ServerHistoryAdminPanel({super.key});

  @override
  ServerHistoryAdminPanelState createState() => ServerHistoryAdminPanelState();
}

class ServerHistoryAdminPanelState extends State<ServerHistoryAdminPanel> {
  late final TextEditingController _historyPathTextController;
  late final TextEditingController _tagNameTextController;

  bool _initialValuesSet = false;
  String? _historyPath = '';

  @override
  void initState() {
    super.initState();
    _historyPathTextController = TextEditingController();
    _tagNameTextController = TextEditingController();

    _tagNameTextController.addListener(_handleHistoryTagChanged);
  }

  @override
  void deactivate() {
    super.deactivate();
    _tagNameTextController.removeListener(_handleHistoryTagChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _historyPathTextController.dispose();
    _tagNameTextController.dispose();
  }

  void _handleHistoryTagChanged() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => providerContainer.read(serverHistoryStateProvider).setTag(_tagNameTextController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        ref.watch(startupProvider);
        ref.watch(styleStateProvider);

        final historyPath = ref.watch(landingPageStateProvider).state.historyPath;

        if (!_initialValuesSet) {
          final historyTag = AppLocalStorage.instance.historyTag ?? Config.newHistoryDefaultTag;
          _tagNameTextController.text = historyTag;
          _initialValuesSet = true;
        }

        _historyPath = historyPath;

        _handleHistoryTagChanged();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              child: ProjectPathView(
                defaultPath: ref.read(landingPageStateProvider).getVisibleHistoryPath(),
                targetPath: _historyPath,
                targetPathTextController: _historyPathTextController,
                labelText: Loc.get.historyPath,
                defaultName: Config.newHistoryListDefaultName,
                isFile: false,
                canBeReset: true,
                onChange: (path) => ref.read(landingPageStateProvider).setHistoryPath(path),
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
