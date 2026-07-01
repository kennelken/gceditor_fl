import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/managers/startup/startup_manager.dart';
import 'package:gceditor/model/app_local_storage.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/server_history_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class ServerHistoryAdminPanel extends StatefulWidget {
  const ServerHistoryAdminPanel({super.key});

  @override
  ServerHistoryAdminPanelState createState() => ServerHistoryAdminPanelState();
}

class ServerHistoryAdminPanelState extends State<ServerHistoryAdminPanel> {
  late final TextEditingController _tagNameTextController;

  bool _initialValuesSet = false;

  @override
  void initState() {
    super.initState();
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

        if (!_initialValuesSet) {
          final historyTag =
              AppLocalStorage.instance.historyTag ?? (AppLocalStorage.instance.historyTagInitialized == true ? '' : Config.newHistoryDefaultTag);
          _tagNameTextController.text = historyTag;
          _initialValuesSet = true;
          AppLocalStorage.instance.historyTagInitialized = true;
        }

        _handleHistoryTagChanged();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
