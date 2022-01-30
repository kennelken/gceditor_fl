import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/managers/startup/startup_manager.dart';
import 'package:gceditor/model/app_local_storage.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/server/net_commands.dart';

class ClientAuthPanel extends StatefulWidget {
  final void Function({
    required String login,
    required String secret,
    required String password,
    required bool rememberPassword,
  }) onCredentialsChanged;

  final PartialAuthentificationData authData;

  const ClientAuthPanel({
    Key? key,
    required this.authData,
    required this.onCredentialsChanged,
  }) : super(key: key);

  @override
  _ClientAuthPanelState createState() => _ClientAuthPanelState();
}

class _ClientAuthPanelState extends State<ClientAuthPanel> {
  late final TextEditingController _loginTextController;
  late final TextEditingController _secretTextController;
  late final TextEditingController _passwordTextController;
  bool? _rememberPassword;
  bool _initialValuesSet = false;

  @override
  void initState() {
    super.initState();
    _loginTextController = TextEditingController();
    _secretTextController = TextEditingController();
    _passwordTextController = TextEditingController();

    _loginTextController.addListener(_handleAnyChange);
    _secretTextController.addListener(_handleAnyChange);
    _passwordTextController.addListener(_handleAnyChange);
  }

  @override
  void deactivate() {
    super.deactivate();
    _loginTextController.removeListener(_handleAnyChange);
    _secretTextController.removeListener(_handleAnyChange);
    _passwordTextController.removeListener(_handleAnyChange);
  }

  @override
  void dispose() {
    super.dispose();
    _loginTextController.dispose();
    _secretTextController.dispose();
    _passwordTextController.dispose();
  }

  void _handleAnyChange() {
    widget.onCredentialsChanged(
      login: _loginTextController.text,
      secret: _secretTextController.text,
      password: _passwordTextController.text,
      rememberPassword: _rememberPassword ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, watch, child) {
        watch(startupProvider);

        if (!_initialValuesSet) {
          final login = widget.authData.login ?? AppLocalStorage.instance.clientLogin ?? Config.defaultNewLogin;
          final secret = widget.authData.secret ?? AppLocalStorage.instance.clientSecret ?? Config.defaultNewSecret;
          final password = widget.authData.password ?? AppLocalStorage.instance.clientPassword ?? Config.defaultPassword;
          final rememberPassword = AppLocalStorage.instance.rememberClientPassword ?? Config.defaultRememberPassword;

          _loginTextController.text = login;
          _secretTextController.text = secret;
          _passwordTextController.text = password;
          _rememberPassword ??= rememberPassword;

          _initialValuesSet = AppLocalStorage.instance.isReadySync;
        }

        _handleAnyChange();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _loginTextController,
              decoration: kStyle.kLandingInputTextStyle.copyWith(
                hintText: Loc.get.clientLoginHint,
                labelText: Loc.get.clientLoginLabel,
              ),
            ),
            SizedBox(height: 10 * kScale),
            TextField(
              controller: _secretTextController,
              decoration: kStyle.kLandingInputTextStyle.copyWith(
                hintText: Loc.get.clientSecretHint,
                labelText: Loc.get.clientSecretLabel,
              ),
            ),
            SizedBox(height: 10 * kScale),
            TextField(
              controller: _passwordTextController,
              obscureText: true,
              decoration: kStyle.kLandingInputTextStyle.copyWith(
                hintText: Loc.get.clientPasswordHint,
                labelText: Loc.get.clientPasswordLabel,
              ),
            ),
            SizedBox(height: 0 * kScale),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                kStyle.wrapCheckbox(
                  Checkbox(
                    value: _rememberPassword,
                    onChanged: (v) {
                      setState(() {
                        _rememberPassword = v!;
                        _handleAnyChange();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 2 * kScale,
                ),
                Text(
                  Loc.get.rememberPassword,
                  style: kStyle.kTextExtraSmallInactive,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
