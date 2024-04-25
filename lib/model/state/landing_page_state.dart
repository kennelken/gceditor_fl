import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../consts/config.dart';
import '../app_local_storage.dart';
import '../model_root.dart';
import 'app_state.dart';

final landingPageStateProvider = ChangeNotifierProvider((_) => LandingPageStateNotifier(LandingPageState()));

class LandingPageState {
  String? projectPath;
  String? outputPath;
  String? historyPath;
  String? authPath;
}

class LandingPageStateNotifier extends ChangeNotifier {
  final LandingPageState state;
  LandingPageStateNotifier(this.state);

  void setProjectPath(String? value) {
    state.projectPath = value;
    notifyListeners();
  }

  void setOutputPath(String? value) {
    state.outputPath = value;
    notifyListeners();
  }

  void setHistoryPath(String? value) {
    state.historyPath = value;
    notifyListeners();
  }

  void setAuthPath(String? value) {
    state.authPath = value;
    notifyListeners();
  }

  void initialize() {
    state.projectPath = AppLocalStorage.instance.projectPath;
    state.outputPath = AppLocalStorage.instance.outputPath;
    state.historyPath = AppLocalStorage.instance.historyPath;
    state.authPath = AppLocalStorage.instance.authListPath;
    notifyListeners();
  }

  String getVisibleProjectPath() {
    return state.projectPath ?? path.join(providerContainer.read(appStateProvider).state.defaultProjectFolder!.path, Config.newProjectDefaultName);
  }

  String getVisibleOutputPath() {
    return state.outputPath ?? path.join(path.dirname(getVisibleProjectPath()), Config.newOutputListDefaultName);
  }

  String getVisibleHistoryPath() {
    return state.historyPath ?? path.join(path.dirname(getVisibleProjectPath()), Config.newHistoryListDefaultName);
  }

  String getVisibleAuthPath() {
    return state.authPath ?? path.join(path.dirname(getVisibleProjectPath()), Config.newAuthListDefaultName);
  }
}
