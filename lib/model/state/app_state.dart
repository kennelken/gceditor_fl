import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/client/client_app.dart';
import 'package:gceditor/model/db_network/authentification_data.dart';
import 'package:gceditor/server/server_app.dart';

final appStateProvider = ChangeNotifierProvider((_) => AppStateNotifier(AppState()));

class AppState {
  Directory? defaultProjectFolder;
  AppMode? appMode;
  String? ipAddress;
  int? port;
  AuthentificationData? authData;
  File? projectFile;
  Directory? output;
  File? authListFile;
  ServerApp? serverApp;
  ClientApp? clientApp;

  bool? serverWorking;
  int? clientsCount;
  bool? clientConnected;

  String? error;
  bool needRestart = false;
}

class AppStateNotifier extends ChangeNotifier {
  final AppState state;
  AppStateNotifier(this.state);

  void setDefaultProjectFolder(Directory folder) {
    state.defaultProjectFolder = folder;
    notifyListeners();
  }

  void setClientAppParams(
    String ipAddress,
    int port,
    AuthentificationData authData,
  ) {
    state.ipAddress = ipAddress;
    state.port = port;
    state.authData = authData;
    notifyListeners();
  }

  void setStandaloneParams(
    int port,
    File file,
    Directory output,
    AuthentificationData authData,
  ) {
    state.ipAddress = 'localhost';
    state.port = port;
    state.projectFile = file;
    state.output = output;
    state.authData = authData;
    notifyListeners();
  }

  void setServerParams(
    int port,
    File file,
    Directory output,
  ) {
    state.port = port;
    state.projectFile = file;
    state.output = output;
    notifyListeners();
  }

  void launchgApp(AppMode mode) {
    state.appMode = mode;
    notifyListeners();
  }

  Future initServerApp() async {
    final serverApp = ServerApp(
      port: state.port!,
      projectFile: state.projectFile!,
    );
    final error = await serverApp.init();

    state.error = error;
    if (error == null) {
      state.serverApp = serverApp;
    }
    notifyListeners();
  }

  Future initClientApp() async {
    final clientApp = ClientApp(
      ipAddress: state.ipAddress!,
      port: state.port!,
      authData: state.authData!,
    );
    final error = await clientApp.init();

    state.error = error;
    if (error == null) {
      state.clientApp = clientApp;
    }
    notifyListeners();
  }

  void onServerStatusChanged(bool? working, int? clientsCount) {
    state.serverWorking = working;
    state.clientsCount = clientsCount;
  }

  void onClientStatusChanged(bool? connected) {
    state.clientConnected = connected;
    notifyListeners();
  }

  void needRestart() {
    state.needRestart = true;
    notifyListeners();
  }

  void resetClientState() {
    state.appMode = null;
    state.clientApp = null;
    state.error = null;
    notifyListeners();
  }

  void requestRunGenerators() {
    state.clientApp!.requestRunGenerators();
  }
}

enum AppMode {
  undefined,
  client,
  server,
  standalone,
}
