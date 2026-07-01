import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/assets.dart';
import 'package:gceditor/components/landing/client_auth_panel.dart';
import 'package:gceditor/components/landing/project_path_view.dart';
import 'package:gceditor/components/landing/server_history_admin_panel.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/app_local_storage.dart';
import 'package:gceditor/model/db/db_model.dart';
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

import '../model/state/landing_page_state.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  LandingScreenState createState() => LandingScreenState();
}

class LandingScreenState extends State<LandingScreen> {
  late final TextEditingController _clientIpTextController = TextEditingController();
  late final TextEditingController _portTextController = TextEditingController();
  late final TextEditingController _projectPathTextController = TextEditingController();

  String? _projectPath = '';
  List<String> _recentProjects = [];

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
      builder: (context, ref, child) {
        final projectPath = ref.watch(landingPageStateProvider).state.projectPath;
        final openPort = ref.watch(networkStateProvider.notifier).state.openPort?.toString() ?? Config.portMin.toString();
        ref.watch(styleStateProvider);

        if (!_initialValuesSet) {
          final appState = providerContainer.read(appStateProvider).state;

          final preferredPort = appState.port?.toString() ?? (AppLocalStorage.instance.port ?? openPort).toString();
          final preferredIpAddress = appState.ipAddress ?? (AppLocalStorage.instance.ipAddress ?? Config.defaultIp).toString();

          _clientIpTextController.text = preferredIpAddress;
          _portTextController.text = preferredPort;

          _initialValuesSet = AppLocalStorage.instance.isReadySync;

          _clientLogin = appState.authData?.login;
          _clientSecret = appState.authData?.secret;
          _clientPassword = appState.authData?.password;
        }

        _projectPath = projectPath;
        _recentProjects = AppLocalStorage.instance.recentProjects;

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
                          SizedBox(height: 10 * kScale),
                          getModeButton(Loc.get.standaloneModeButton, _onStandalonePressed, bold: true),
                        ],
                        SizedBox(height: 10 * kScale),
                        getModeButton(Loc.get.clientModeButton, _onClientPressed),
                        if (isServerAvailable) ...[
                          SizedBox(height: 10 * kScale),
                          getModeButton(Loc.get.serverModeButton, _onServerPressed),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  color: kColorPrimaryLightToDark,
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
                      ],
                    ),
                  ),
                ),
              ),
              if (isServerAvailable) ...[
                getDivider(),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20 * kScale, right: 20 * kScale, top: 20 * kScale, bottom: 20 * kScale),
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
                                    defaultPath: ref.read(landingPageStateProvider).getVisibleProjectPath(),
                                    targetPath: _projectPath,
                                    targetPathTextController: _projectPathTextController,
                                    labelText: Loc.get.projectPath,
                                    defaultName: Config.newProjectDefaultName,
                                    isFile: true,
                                    canBeReset: true,
                                    onChange: (path) => ref.read(landingPageStateProvider).setProjectPath(path),
                                  ),
                                  if (_recentProjects.isNotEmpty) ...[
                                    SizedBox(height: 10 * kScale),
                                    InputDecorator(
                                      decoration: kStyle.kLandingInputTextStyle.copyWith(
                                        labelText: 'Recent projects',
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 8 * kScale),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: _recentProjects.length,
                                          itemBuilder: (context, index) {
                                            final p = _recentProjects[index];
                                            final isSelected = p == _projectPath;
                                            final isMissing = !File(p).existsSync();
                                            return Padding(
                                              padding: EdgeInsets.only(bottom: 2 * kScale),
                                              child: InkWell(
                                                onTap: () => _handleRecentProjectTap(p),
                                                child: Container(
                                                  height: 22 * kScale,
                                                  color: isSelected ? kColorPrimaryLightTransparent : kColorTransparent,
                                                  child: Padding(
                                                    padding: EdgeInsets.only(left: 5 * kScale, right: 10 * kScale),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            p,
                                                            style: isSelected
                                                                ? kStyle.kTextExtraSmallSelected
                                                                : (isMissing ? kStyle.kTextExtraSmallInactive : kStyle.kTextExtraSmall),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        TooltipWrapper(
                                                          message: 'Remove',
                                                          child: IconButtonTransparent(
                                                            size: 20 * kScale,
                                                            icon: Icon(
                                                              FontAwesomeIcons.trashCan,
                                                              size: 10 * kScale,
                                                              color: kColorAccentRed,
                                                            ),
                                                            onClick: () => _handleRemoveRecentProject(p),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 60 * kScale),
                                  const Flexible(
                                    child: ServerHistoryAdminPanel(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

  Widget getModeButton(String label, VoidCallback onPressed, {bool bold = false}) {
    return SizedBox(
      height: 50 * kScale,
      width: 9999,
      child: ElevatedButton(
        style: kButtonWhite,
        onPressed: onPressed,
        child: FittedBox(
            child: Text(
          label,
          style: kStyle.kTextBig.copyWith(color: kColorPrimaryLighter2, fontWeight: bold ? FontWeight.w900 : FontWeight.bold),
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
    final appStateNotifier = providerContainer.read(appStateProvider.notifier);

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
    final appStateNotifier = providerContainer.read(appStateProvider.notifier);
    final landingPageStateNotifier = providerContainer.read(landingPageStateProvider.notifier);

    _onBackendCommon();

    final port = int.parse(_portTextController.text);
    final projectFile = File(landingPageStateNotifier.getVisibleProjectPath());
    AppLocalStorage.instance.addRecentProject(projectFile.path);
    final projectDir = path.dirname(projectFile.path);
    final outputDir = Directory(path.join(projectDir, Config.newOutputListDefaultName));

    providerContainer.read(authListStateProvider).resetPasswordOrRegister(_clientLogin!, _clientSecret!);

    appStateNotifier.setStandaloneParams(
      port,
      projectFile,
      outputDir,
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
    final appStateNotifier = providerContainer.read(appStateProvider.notifier);
    final landingPageStateNotifier = providerContainer.read(landingPageStateProvider.notifier);

    _onBackendCommon();

    final port = int.parse(_portTextController.text);
    final projectFile = File(landingPageStateNotifier.getVisibleProjectPath());
    AppLocalStorage.instance.addRecentProject(projectFile.path);
    final projectDir = path.dirname(projectFile.path);
    final outputDir = Directory(path.join(projectDir, Config.newOutputListDefaultName));

    appStateNotifier.setServerParams(
      port,
      projectFile,
      outputDir,
    );

    _saveLocalsStorageData();

    appStateNotifier.launchApp(AppMode.server);
  }

  void _handleRecentProjectTap(String path) {
    providerContainer.read(landingPageStateProvider.notifier).setProjectPath(path);
  }

  void _handleRemoveRecentProject(String path) {
    AppLocalStorage.instance.removeRecentProject(path);
    setState(() {
      _recentProjects = AppLocalStorage.instance.recentProjects;
    });
  }

  void _onBackendCommon() {
    final landingPageStateNotifier = providerContainer.read(landingPageStateProvider.notifier);
    final authListStateNotifier = providerContainer.read(authListStateProvider.notifier);
    final historyStateNotifier = providerContainer.read(serverHistoryStateProvider.notifier);

    final projectFile = File(landingPageStateNotifier.getVisibleProjectPath());
    final projectDir = path.dirname(projectFile.path);

    var authRel = Config.newAuthListDefaultName;
    var historyRel = Config.newHistoryListDefaultName;
    try {
      if (projectFile.existsSync()) {
        final jsonText = projectFile.readAsStringSync();
        if (jsonText.isNotEmpty) {
          final dbModel = DbModel.fromJson(jsonDecode(jsonText));
          authRel = dbModel.settings.authPath ?? Config.newAuthListDefaultName;
          historyRel = dbModel.settings.historyPath ?? Config.newHistoryListDefaultName;
        }
      }
    } catch (_) {}

    authListStateNotifier.setPath(path.join(projectDir, authRel));
    historyStateNotifier.setPath(path.join(projectDir, historyRel));
  }

  void _saveLocalsStorageData() {
    AppLocalStorage.instance.ipAddress = _clientIpTextController.text;
    AppLocalStorage.instance.port = int.parse(_portTextController.text);
    AppLocalStorage.instance.projectPath = providerContainer.read(landingPageStateProvider).state.projectPath;

    AppLocalStorage.instance.clientLogin = _clientLogin;
    AppLocalStorage.instance.clientSecret = _clientSecret;
    AppLocalStorage.instance.clientPassword = _rememberClientPassword! ? _clientPassword : '';
    AppLocalStorage.instance.rememberClientPassword = _rememberClientPassword;

    AppLocalStorage.instance.historyTag = providerContainer.read(serverHistoryStateProvider).state.currentTag;
  }

  void _handleClientCredentialsChanged({required String login, required String password, required String secret, required bool rememberPassword}) {
    _clientLogin = login;
    _clientSecret = secret;
    _clientPassword = password;
    _rememberClientPassword = rememberPassword;
  }
}
