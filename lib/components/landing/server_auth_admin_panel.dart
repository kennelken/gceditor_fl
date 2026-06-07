import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/managers/startup/startup_manager.dart';
import 'package:gceditor/model/app_local_storage.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/auth_list_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class ServerAuthAdminPanel extends StatefulWidget {
  const ServerAuthAdminPanel({super.key});

  @override
  ServerAuthAdminPanelState createState() => ServerAuthAdminPanelState();
}

class ServerAuthAdminPanelState extends State<ServerAuthAdminPanel> {
  late final TextEditingController _newLoginTextController;
  late final TextEditingController _newSecretTextController;

  @override
  void initState() {
    super.initState();
    _newLoginTextController = TextEditingController();
    _newSecretTextController = TextEditingController();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
    _newLoginTextController.dispose();
    _newSecretTextController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        ref.watch(startupProvider);

        ref.watch(styleStateProvider);

        final newLogin = AppLocalStorage.instance.newLogin ?? Config.defaultNewLogin;
        final newSecret = AppLocalStorage.instance.newSecret ?? Config.defaultNewSecret;

        _newLoginTextController.text = newLogin;
        _newSecretTextController.text = newSecret;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
    AppLocalStorage.instance.newLogin = _newLoginTextController.text;
    AppLocalStorage.instance.newSecret = _newSecretTextController.text;
  }

  void _handleRemoveLoginClick() {
    providerContainer.read(authListStateProvider).removeLogin(_newLoginTextController.text);
  }
}
