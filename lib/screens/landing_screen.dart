import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/assets.dart';
import 'package:gceditor/components/landing/client_auth_panel.dart';
import 'package:gceditor/components/landing/project_path_view.dart';
import 'package:gceditor/components/landing/server_auth_admin_panel.dart';
import 'package:gceditor/components/landing/server_history_admin_panel.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/app_local_storage.dart';
import 'package:gceditor/model/db_network/authentication_data.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/auth_list_state.dart';
import 'package:gceditor/model/state/network_state.dart';
import 'package:gceditor/model/state/server_history_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/screens/loading_screen.dart';
import 'package:gceditor/server/net_commands.dart';
import 'package:path/path.dart' as path;

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  late final TextEditingController _clientIpTextController = TextEditingController();
  late final TextEditingController _portTextController = TextEditingController();
  late final TextEditingController _projectPathTextController = TextEditingController();
  late final TextEditingController _outputPathTextController = TextEditingController();

  String _projectPath = '';
  String _outputPath = '';

  bool _initialValuesSet = false;

  String? _clientLogin;
  String? _clientSecret;
  String? _clientPassword;
  bool? _rememberClientPassword;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, watch, child) {
        final defaultFolder = watch(appStateProvider).state.defaultProjectFolder;
        final defaultFolderPath = defaultFolder?.path ?? '';
        final openPort = watch(networkStateProvider.notifier).state.openPort?.toString() ?? Config.portMin.toString();

        if (!_initialValuesSet) {
          final appState = providerContainer.read(appStateProvider).state;

          final preferredPort = appState.port?.toString() ?? (AppLocalStorage.instance.port ?? openPort).toString();
          final preferredIpAddress = appState.ipAddress ?? (AppLocalStorage.instance.ipAddress ?? Config.defaultIp).toString();

          _projectPath =
              appState.projectFile?.path ?? AppLocalStorage.instance.projectPath ?? path.join(defaultFolderPath, Config.newProjectDefaultName);
          _outputPath = appState.output?.path ?? AppLocalStorage.instance.outputPath ?? path.join(defaultFolderPath);

          _clientIpTextController.text = preferredIpAddress;
          _portTextController.text = preferredPort;
          _projectPathTextController.text = _projectPath;
          _outputPathTextController.text = _outputPath;

          _initialValuesSet = AppLocalStorage.instance.isReadySync;

          _clientLogin = appState.authData?.login;
          _clientSecret = appState.authData?.secret;
          _clientPassword = appState.authData?.password;
        }

        const isServerAvailable = !kIsWeb;

        return Container(
          color: kColorPrimary,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: kColorPrimaryLighter,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20 * kScale, right: 20 * kScale, top: 20 * kScale, bottom: 20 * kScale),
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Hero(
                                tag: LoadingScreen.appIconTag,
                                child: Image.asset(
                                  Assets.images.icon1024PNG,
                                  width: 200 * kScale,
                                ),
                              ),
                              FittedBox(
                                child: Padding(
                                  padding: EdgeInsets.all(15.0 * kScale),
                                  child: Text(
                                    Config.appName,
                                    style: kStyle.kTextBigger2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isServerAvailable) ...[
                          getModeButton(Loc.get.standaloneModeButton, _onStandalonePressed),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(left: 20 * kScale, right: 20 * kScale, top: 20 * kScale, bottom: 20 * kScale),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: ScrollController(),
                          scrollDirection: Axis.vertical,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _clientIpTextController,
                                decoration: kStyle.kLandingInputTextStyle.copyWith(
                                  hintText: _clientIpTextController.text,
                                  labelText: Loc.get.ipAddressInputTitle,
                                ),
                              ),
                              SizedBox(height: 10 * kScale),
                              TextField(
                                controller: _portTextController,
                                decoration: kStyle.kLandingInputTextStyle.copyWith(
                                  hintText: openPort,
                                  labelText: Loc.get.portInputTitle,
                                ),
                              ),
                              SizedBox(height: 60 * kScale),
                              ClientAuthPanel(
                                authData: PartialAuthenticationData.values(login: _clientLogin, secret: _clientSecret, password: _clientPassword),
                                onCredentialsChanged: _handleClientCredentialsChanged,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10 * kScale),
                      getModeButton(Loc.get.clientModeButton, _onClientPressed),
                    ],
                  ),
                ),
              ),
              if (isServerAvailable) ...[
                getDivider(),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(left: 0 * kScale, right: 20 * kScale, top: 20 * kScale, bottom: 20 * kScale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ScrollConfiguration(
                            behavior: getScrollDraggable(context),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              controller: ScrollController(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: _portTextController,
                                    decoration: kStyle.kLandingInputTextStyle.copyWith(
                                      hintText: openPort,
                                      labelText: Loc.get.portInputTitle,
                                    ),
                                  ),
                                  SizedBox(height: 10 * kScale),
                                  ProjectPathView(
                                    defaultFolder: defaultFolder,
                                    projectPath: _projectPath,
                                    projectPathTextController: _projectPathTextController,
                                    labelText: Loc.get.projectPath,
                                    defaultName: Config.newProjectDefaultName,
                                    isFile: true,
                                  ),
                                  SizedBox(height: 10 * kScale),
                                  ProjectPathView(
                                    defaultFolder: defaultFolder,
                                    projectPath: _outputPath,
                                    projectPathTextController: _outputPathTextController,
                                    labelText: Loc.get.outputPath,
                                    defaultName: '',
                                    isFile: false,
                                  ),
                                  SizedBox(height: 60 * kScale),
                                  const Flexible(
                                    child: ServerHistoryAdminPanel(),
                                  ),
                                  SizedBox(height: 60 * kScale),
                                  const Flexible(
                                    child: ServerAuthAdminPanel(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10 * kScale),
                        getModeButton(Loc.get.serverModeButton, _onServerPressed),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget getModeButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 50 * kScale,
      width: 9999,
      child: ElevatedButton(
        style: kButtonWhite,
        onPressed: onPressed,
        child: FittedBox(
            child: Text(
          label,
          style: kStyle.kTextBig.copyWith(color: kColorPrimaryLighter2, fontWeight: FontWeight.bold),
        )),
      ),
    );
  }

  Widget getDivider() {
    return SizedBox(
      width: 5 * kScale,
    );
  }

  void _onClientPressed() {
    final appStateNotifier = context.read(appStateProvider.notifier);

    final ipAddress = _clientIpTextController.text;
    final port = int.parse(_portTextController.text);

    appStateNotifier.setClientAppParams(
      ipAddress,
      port,
      AuthenticationData.values(
        login: _clientLogin!,
        secret: _clientSecret!,
        password: _clientPassword!,
      ),
    );

    _saveLocalsStorageData();

    appStateNotifier.launchApp(AppMode.client);
  }

  void _onStandalonePressed() {
    final appStateNotifier = context.read(appStateProvider.notifier);

    final port = int.parse(_portTextController.text);

    providerContainer.read(authListStateProvider).resetPasswordOrRegister(_clientLogin!, _clientSecret!);

    appStateNotifier.setStandaloneParams(
      port,
      File(_projectPathTextController.text),
      Directory(_outputPathTextController.text),
      AuthenticationData.values(
        login: _clientLogin!,
        secret: _clientSecret!,
        password: _clientPassword!,
      ),
    );

    _saveLocalsStorageData();

    appStateNotifier.launchApp(AppMode.standalone);
  }

  void _onServerPressed() {
    final appStateNotifier = context.read(appStateProvider.notifier);

    final port = int.parse(_portTextController.text);
    appStateNotifier.setServerParams(
      port,
      File(_projectPathTextController.text),
      Directory(_outputPathTextController.text),
    );

    _saveLocalsStorageData();

    appStateNotifier.launchApp(AppMode.server);
  }

  void _saveLocalsStorageData() {
    AppLocalStorage.instance.ipAddress = _clientIpTextController.text;
    AppLocalStorage.instance.port = int.parse(_portTextController.text);
    AppLocalStorage.instance.projectPath = _projectPathTextController.text;
    AppLocalStorage.instance.outputPath = _outputPathTextController.text;
    AppLocalStorage.instance.authListPath = providerContainer.read(authListStateProvider).state.filePath;

    AppLocalStorage.instance.clientLogin = _clientLogin;
    AppLocalStorage.instance.clientSecret = _clientSecret;
    AppLocalStorage.instance.clientPassword = _rememberClientPassword! ? _clientPassword : '';
    AppLocalStorage.instance.rememberClientPassword = _rememberClientPassword;

    AppLocalStorage.instance.historyPath = providerContainer.read(serverHistoryStateProvider).state.folderPath;
    AppLocalStorage.instance.historyTag = providerContainer.read(serverHistoryStateProvider).state.currentTag;
  }

  void _handleClientCredentialsChanged({required String login, required String password, required String secret, required bool rememberPassword}) {
    _clientLogin = login;
    _clientSecret = secret;
    _clientPassword = password;
    _rememberClientPassword = rememberPassword;
  }
}
