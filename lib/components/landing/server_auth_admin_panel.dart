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
import 'package:gceditor/model/state/auth_list_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:path/path.dart' as path;

class ServerAuthAdminPanel extends StatefulWidget {
  const ServerAuthAdminPanel({Key? key}) : super(key: key);

  @override
  _ServerAuthAdminPanelState createState() => _ServerAuthAdminPanelState();
}

class _ServerAuthAdminPanelState extends State<ServerAuthAdminPanel> {
  late final TextEditingController _authListPathTextController;
  late final TextEditingController _newLoginTextController;
  late final TextEditingController _newSecretTextController;

  @override
  void initState() {
    super.initState();
    _authListPathTextController = TextEditingController();
    _newLoginTextController = TextEditingController();
    _newSecretTextController = TextEditingController();

    _authListPathTextController.addListener(_handleAuthPathChanged);
  }

  @override
  void deactivate() {
    super.deactivate();
    _authListPathTextController.removeListener(_handleAuthPathChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _authListPathTextController.dispose();
    _newLoginTextController.dispose();
    _newSecretTextController.dispose();
  }

  void _handleAuthPathChanged() {
    WidgetsBinding.instance!.addPostFrameCallback(
      (_) => providerContainer.read(authListStateProvider).setPath(_authListPathTextController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, watch, child) {
        watch(startupProvider);
        final defaultFolder = watch(appStateProvider).state.defaultProjectFolder;
        final defaultFolderPath = defaultFolder?.path ?? '';
        final authListState = providerContainer.read(authListStateProvider).state;

        final authListPath =
            authListState.filePath ?? AppLocalStorage.instance.authListPath ?? path.join(defaultFolderPath, Config.newAuthListDefaultName);

        final newLogin = AppLocalStorage.instance.newLogin ?? Config.defaultNewLogin;
        final newSecret = AppLocalStorage.instance.newSecret ?? Config.defaultNewSecret;

        _authListPathTextController.text = authListPath;
        _newLoginTextController.text = newLogin;
        _newSecretTextController.text = newSecret;

        _handleAuthPathChanged();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              child: ProjectPathView(
                defaultFolder: defaultFolder,
                projectPath: authListPath,
                projectPathTextController: _authListPathTextController,
                labelText: Loc.get.authListPath,
                defaultName: Config.newAuthListDefaultName,
                isFile: true,
              ),
            ),
            SizedBox(height: 10 * kScale),
            TextField(
              controller: _newLoginTextController,
              decoration: kStyle.kLandingInputTextStyle.copyWith(
                hintText: Loc.get.newLoginHint,
                labelText: Loc.get.newLoginLabel,
              ),
            ),
            SizedBox(height: 10 * kScale),
            TextField(
              controller: _newSecretTextController,
              decoration: kStyle.kLandingInputTextStyle.copyWith(
                hintText: Loc.get.newSecretHint,
                labelText: Loc.get.newSecretLabel,
              ),
            ),
            SizedBox(height: 10 * kScale),
            SizedBox(
              height: 35 * kScale,
              width: 9999,
              child: ElevatedButton(
                style: kButtonContextMenu,
                onPressed: _handleRegisterLoginClick,
                child: Text(
                  Loc.get.buttonRegisterNewLogin,
                  style: kStyle.kTextRegular,
                ),
              ),
            ),
            SizedBox(height: 10 * kScale),
            SizedBox(
              height: 35 * kScale,
              width: 9999,
              child: ElevatedButton(
                style: kButtonContextMenu,
                onPressed: _handleRemoveLoginClick,
                child: Text(
                  Loc.get.buttonUnregisterLogin,
                  style: kStyle.kTextRegular,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleRegisterLoginClick() {
    providerContainer.read(authListStateProvider).registerNewLogin(_newLoginTextController.text, _newSecretTextController.text);
    AppLocalStorage.instance.authListPath = _authListPathTextController.text;
    AppLocalStorage.instance.newLogin = _newLoginTextController.text;
    AppLocalStorage.instance.newSecret = _newSecretTextController.text;
  }

  void _handleRemoveLoginClick() {
    providerContainer.read(authListStateProvider).removeLogin(_newLoginTextController.text);
  }
}
